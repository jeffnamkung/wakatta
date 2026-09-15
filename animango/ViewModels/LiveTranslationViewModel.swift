import Foundation
import SwiftData

// MARK: - Display Models

struct TranscriptionSegment: Identifiable {
    let id: String
    let text: String
    let words: [AnnotatedWord]
    let timestamp: Date

    init(text: String, words: [AnnotatedWord]) {
        self.id = UUID().uuidString
        self.text = text
        self.words = words
        self.timestamp = Date()
    }
}

struct TranslationSegment: Identifiable {
    let id: String
    let sourceText: String
    let translatedText: String
    let words: [AnnotatedWord]
    let language: SupportedLanguage
    let timestamp: Date

    init(sourceText: String, translatedText: String, words: [AnnotatedWord], language: SupportedLanguage) {
        self.id = UUID().uuidString
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.words = words
        self.language = language
        self.timestamp = Date()
    }
}

struct WordDefinition {
    let word: String
    let reading: String?
    let meanings: [String]
    let jlptLevel: Int?
    let partOfSpeech: String?
}

/// Audio playback mode for translated languages
enum AudioPlaybackMode: Equatable {
    case off
    case single(SupportedLanguage)
    case all
}

// MARK: - ViewModel

@Observable @MainActor
final class LiveTranslationViewModel {

    enum Mode {
        case idle
        case listening
    }

    // MARK: - State

    var mode: Mode = .idle
    var sourceLanguage: SupportedLanguage = .japanese
    var targetLanguages: Set<SupportedLanguage> = [.english]
    var showFurigana: Bool = true
    var audioLevel: Float = 0

    // Transcription
    var currentPartialText: String = ""
    var transcriptionSegments: [TranscriptionSegment] = []

    // Translation — keyed by target language
    var translationsByLanguage: [SupportedLanguage: [TranslationSegment]] = [:]
    var isTranslating: Bool = false

    // Audio playback
    var audioPlaybackMode: AudioPlaybackMode = .off
    private let speechService = SpeechService()
    var isSpeakingLanguage: SupportedLanguage?

    // Word popup
    var selectedWord: AnnotatedWord?
    var wordDefinition: WordDefinition?
    var isLoadingDefinition: Bool = false
    var showWordPopup: Bool = false
    /// Track which language panel the word was tapped in for context
    var wordLookupLanguage: SupportedLanguage?

    // Configuration
    var isConfigured: Bool = false
    var errorMessage: String?

    // MARK: - Dependencies

    private let speechRecognizer = LiveSpeechRecognizer()
    private let translationService = TranslationService()
    private let jishoService = JishoService()
    private var modelContext: ModelContext?

    // Debounce
    private var pendingSegmentText: String = ""
    private var debounceTask: Task<Void, Never>?

    // MARK: - Computed

    /// Ordered list of target languages for consistent display
    var orderedTargetLanguages: [SupportedLanguage] {
        SupportedLanguage.allCases.filter { targetLanguages.contains($0) }
    }

    /// All translation segments are empty
    var hasAnyTranslations: Bool {
        translationsByLanguage.values.contains { !$0.isEmpty }
    }

    // MARK: - Configuration

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        translationService.configure(modelContext: modelContext)
        isConfigured = translationService.isConfigured
        
        speechRecognizer.onFinalSegment = { [weak self] text in
            Task { @MainActor [weak self] in
                await self?.handleFinalSegment(text)
            }
        }
    }

    func requestAuthorization() async {
        await speechRecognizer.requestAuthorization()
    }

    var isAuthorized: Bool { speechRecognizer.isAuthorized }
    var authorizationError: String? { speechRecognizer.authorizationError }

    // MARK: - Target Language Management

    func addTargetLanguage(_ language: SupportedLanguage) {
        guard language != sourceLanguage else { return }
        targetLanguages.insert(language)
        if translationsByLanguage[language] == nil {
            translationsByLanguage[language] = []
        }
    }

    func removeTargetLanguage(_ language: SupportedLanguage) {
        guard targetLanguages.count > 1 else { return } // Keep at least one
        targetLanguages.remove(language)
        translationsByLanguage.removeValue(forKey: language)
        // Update audio mode if removed language was selected
        if case .single(let lang) = audioPlaybackMode, lang == language {
            audioPlaybackMode = .off
        }
    }

    func toggleTargetLanguage(_ language: SupportedLanguage) {
        if targetLanguages.contains(language) {
            removeTargetLanguage(language)
        } else {
            addTargetLanguage(language)
        }
    }

    // MARK: - Audio Controls

    func setAudioMode(_ mode: AudioPlaybackMode) {
        audioPlaybackMode = mode
        if mode == .off {
            speechService.stop()
            isSpeakingLanguage = nil
        }
    }

    func speakLatestTranslation(for language: SupportedLanguage) {
        // Pause listening before playing TTS to avoid audio session conflict
        if mode == .listening {
            speechRecognizer.stopListening()
            mode = .idle
        }
        guard let segments = translationsByLanguage[language],
              let latest = segments.last else { return }
        isSpeakingLanguage = language
        speechService.speak(latest.translatedText, language: language.rawValue)
    }

    func stopSpeaking() {
        speechService.stop()
        isSpeakingLanguage = nil
    }

    var isSpeaking: Bool { speechService.isSpeaking }

    // MARK: - Actions

    func toggleListening() async {
        switch mode {
        case .idle:
            await startListening()
        case .listening:
            stopListening()
        }
    }

    /// Manually submit text as if it were a transcribed speech segment.
    /// Useful for testing in the Simulator without microphone input.
    func submitText(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        await handleFinalSegment(trimmed)
    }

    func swapLanguages() {
        // Only works well with single target language
        guard targetLanguages.count == 1, let target = targetLanguages.first else { return }
        let oldSource = sourceLanguage
        sourceLanguage = target
        targetLanguages = [oldSource]
        translationsByLanguage = [:]
    }

    func clearAll() {
        transcriptionSegments = []
        translationsByLanguage = [:]
        currentPartialText = ""
        pendingSegmentText = ""
        errorMessage = nil
        speechService.stop()
        isSpeakingLanguage = nil
    }

    func lookupWord(_ word: AnnotatedWord, in language: SupportedLanguage? = nil) async {
        selectedWord = word
        wordLookupLanguage = language
        showWordPopup = true
        isLoadingDefinition = true
        wordDefinition = nil

        let lookupLang = language ?? sourceLanguage

        do {
            if lookupLang.isJapanese || containsKanji(word.surface) {
                let results = try await jishoService.searchWords(keyword: word.surface)
                if let first = results.first {
                    let data = await jishoService.toVocabularyData(first)
                    wordDefinition = WordDefinition(
                        word: data.word,
                        reading: data.reading,
                        meanings: data.meaning.components(separatedBy: ", "),
                        jlptLevel: data.jlpt,
                        partOfSpeech: data.partOfSpeech
                    )
                } else {
                    wordDefinition = WordDefinition(
                        word: word.surface,
                        reading: word.reading,
                        meanings: ["No definition found"],
                        jlptLevel: nil,
                        partOfSpeech: nil
                    )
                }
            } else {
                // For other languages, use LLM
                let contextSegments = translationsByLanguage[lookupLang]
                let contextSentence = contextSegments?.last?.translatedText ?? word.surface
                let definition = try await translationService.lookupWordDefinition(
                    word: word.surface,
                    context: contextSentence,
                    language: lookupLang
                )
                wordDefinition = WordDefinition(
                    word: word.surface,
                    reading: nil,
                    meanings: [definition],
                    jlptLevel: nil,
                    partOfSpeech: nil
                )
            }
        } catch {
            wordDefinition = WordDefinition(
                word: word.surface,
                reading: word.reading,
                meanings: ["Failed to look up definition: \(error.localizedDescription)"],
                jlptLevel: nil,
                partOfSpeech: nil
            )
        }

        isLoadingDefinition = false
    }

    // MARK: - Listening

    private func startListening() async {
        do {
            try speechRecognizer.startListening(locale: sourceLanguage.locale)
            mode = .listening
            errorMessage = nil

            Task { @MainActor in
                while self.mode == .listening {
                    self.audioLevel = self.speechRecognizer.audioLevel
                    self.currentPartialText = self.speechRecognizer.partialText
                    try? await Task.sleep(for: .milliseconds(50))
                }
            }
        } catch {
            errorMessage = "Failed to start listening: \(error.localizedDescription)"
            mode = .idle
        }
    }

    private func stopListening() {
        speechRecognizer.stopListening()
        mode = .idle
        audioLevel = 0
        currentPartialText = ""
    }

    // MARK: - Segment Processing

    private func handleFinalSegment(_ text: String) async {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Build transcription segment
        let words: [AnnotatedWord]
        if sourceLanguage.isJapanese {
            words = await annotateJapaneseText(trimmed)
        } else {
            words = [AnnotatedWord(surface: trimmed)]
        }

        let segment = TranscriptionSegment(text: trimmed, words: words)
        transcriptionSegments.append(segment)

        // Debounce translation
        pendingSegmentText += (pendingSegmentText.isEmpty ? "" : " ") + trimmed
        debounceTask?.cancel()
        debounceTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            await self.translatePendingText()
        }
    }

    private func translatePendingText() async {
        let text = pendingSegmentText
        pendingSegmentText = ""

        guard !text.isEmpty, isConfigured else { return }
        let targets = orderedTargetLanguages

        isTranslating = true

        // Translate to all target languages in parallel
        await withTaskGroup(of: (SupportedLanguage, TranslationSegment?).self) { group in
            for target in targets {
                group.addTask { @MainActor in
                    do {
                        let result = try await self.translationService.translate(
                            text: text,
                            from: self.sourceLanguage,
                            to: target
                        )

                        let translationWords: [AnnotatedWord]
                        if target.isJapanese {
                            if let annotated = result.annotatedWords, !annotated.isEmpty {
                                translationWords = annotated
                            } else {
                                translationWords = await self.annotateJapaneseText(result.translatedText)
                            }
                        } else {
                            let wordStrings = result.translatedText.components(separatedBy: " ")
                            translationWords = wordStrings.map { AnnotatedWord(surface: $0) }
                        }

                        let segment = TranslationSegment(
                            sourceText: text,
                            translatedText: result.translatedText,
                            words: translationWords,
                            language: target
                        )
                        return (target, segment)
                    } catch {
                        return (target, nil)
                    }
                }
            }

            for await (language, segment) in group {
                if let segment = segment {
                    if translationsByLanguage[language] == nil {
                        translationsByLanguage[language] = []
                    }
                    translationsByLanguage[language]?.append(segment)

                    // Auto-play audio based on mode
                    autoPlayIfNeeded(for: language, text: segment.translatedText)
                }
            }
        }

        isTranslating = false
    }

    // MARK: - Auto-play Audio

    private func autoPlayIfNeeded(for language: SupportedLanguage, text: String) {
        // Don't play TTS while microphone is actively recording — the audio
        // session is in .record mode and starting playback would crash or
        // kill the recording session.
        guard mode != .listening else { return }

        switch audioPlaybackMode {
        case .off:
            break
        case .single(let selectedLang):
            if language == selectedLang {
                isSpeakingLanguage = language
                speechService.speak(text, language: language.rawValue)
            }
        case .all:
            // For "all" mode, speak each language sequentially
            // (AVSpeechSynthesizer queues utterances)
            isSpeakingLanguage = language
            speechService.speak(text, language: language.rawValue)
        }
    }

    // MARK: - Japanese Annotation

    private func annotateJapaneseText(_ text: String) async -> [AnnotatedWord] {
        let segmented = JapaneseTextSegmenter.segment(text)

        var annotatedWords: [AnnotatedWord] = []
        for word in segmented {
            if word.containsKanji {
                if let reading = lookupLocalReading(for: word.surface) {
                    annotatedWords.append(AnnotatedWord(surface: word.surface, reading: reading))
                } else {
                    if let reading = await lookupJishoReading(for: word.surface) {
                        annotatedWords.append(AnnotatedWord(surface: word.surface, reading: reading))
                    } else {
                        annotatedWords.append(AnnotatedWord(surface: word.surface))
                    }
                }
            } else {
                annotatedWords.append(AnnotatedWord(surface: word.surface))
            }
        }

        return annotatedWords
    }

    private func lookupLocalReading(for word: String) -> String? {
        guard let modelContext = modelContext else { return nil }
        let predicate = #Predicate<VocabularyItem> { $0.word == word }
        let descriptor = FetchDescriptor<VocabularyItem>(predicate: predicate)
        let results = try? modelContext.fetch(descriptor)
        return results?.first?.reading
    }

    private func lookupJishoReading(for word: String) async -> String? {
        do {
            let results = try await jishoService.searchWords(keyword: word)
            if let first = results.first {
                let data = await jishoService.toVocabularyData(first)
                return data.reading
            }
        } catch {
            // Silently fail — we just won't show furigana for this word
        }
        return nil
    }
}
