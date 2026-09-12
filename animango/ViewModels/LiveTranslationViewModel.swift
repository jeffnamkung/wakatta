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
    let timestamp: Date

    init(sourceText: String, translatedText: String, words: [AnnotatedWord]) {
        self.id = UUID().uuidString
        self.sourceText = sourceText
        self.translatedText = translatedText
        self.words = words
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
    var targetLanguage: SupportedLanguage = .english
    var showFurigana: Bool = true
    var audioLevel: Float = 0

    // Transcription
    var currentPartialText: String = ""
    var transcriptionSegments: [TranscriptionSegment] = []

    // Translation
    var translationSegments: [TranslationSegment] = []
    var isTranslating: Bool = false

    // Word popup
    var selectedWord: AnnotatedWord?
    var wordDefinition: WordDefinition?
    var isLoadingDefinition: Bool = false
    var showWordPopup: Bool = false

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

    // MARK: - Actions

    func toggleListening() async {
        switch mode {
        case .idle:
            await startListening()
        case .listening:
            stopListening()
        }
    }

    func swapLanguages() {
        let temp = sourceLanguage
        sourceLanguage = targetLanguage
        targetLanguage = temp
    }

    func clearAll() {
        transcriptionSegments = []
        translationSegments = []
        currentPartialText = ""
        pendingSegmentText = ""
        errorMessage = nil
    }

    func lookupWord(_ word: AnnotatedWord) async {
        selectedWord = word
        showWordPopup = true
        isLoadingDefinition = true
        wordDefinition = nil

        do {
            // For Japanese words, use Jisho
            if sourceLanguage.isJapanese || targetLanguage.isJapanese {
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
                let contextSentence = translationSegments.last?.translatedText ?? word.surface
                let definition = try await translationService.lookupWordDefinition(
                    word: word.surface,
                    context: contextSentence,
                    language: targetLanguage
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

            // Observe audio level changes
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

        // Debounce translation — accumulate text and send after 0.5s pause
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

        isTranslating = true
        do {
            let result = try await translationService.translate(
                text: text,
                from: sourceLanguage,
                to: targetLanguage
            )

            let translationWords: [AnnotatedWord]
            if targetLanguage.isJapanese {
                // Use LLM-provided annotations, or fall back to segmenter
                if let annotated = result.annotatedWords, !annotated.isEmpty {
                    translationWords = annotated
                } else {
                    translationWords = await annotateJapaneseText(result.translatedText)
                }
            } else {
                // For non-Japanese targets, split into words for tapping
                let wordStrings = result.translatedText.components(separatedBy: " ")
                translationWords = wordStrings.map { AnnotatedWord(surface: $0) }
            }

            let segment = TranslationSegment(
                sourceText: text,
                translatedText: result.translatedText,
                words: translationWords
            )
            translationSegments.append(segment)
        } catch {
            errorMessage = "Translation failed: \(error.localizedDescription)"
        }
        isTranslating = false
    }

    // MARK: - Japanese Annotation

    /// Segment Japanese text and look up readings for kanji words
    private func annotateJapaneseText(_ text: String) async -> [AnnotatedWord] {
        let segmented = JapaneseTextSegmenter.segment(text)

        var annotatedWords: [AnnotatedWord] = []
        for word in segmented {
            if word.containsKanji {
                // Try to find reading from local VocabularyItem store
                if let reading = lookupLocalReading(for: word.surface) {
                    annotatedWords.append(AnnotatedWord(surface: word.surface, reading: reading))
                } else {
                    // Try Jisho lookup
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

    /// Check local SwiftData VocabularyItem store for a reading
    private func lookupLocalReading(for word: String) -> String? {
        guard let modelContext = modelContext else { return nil }
        let predicate = #Predicate<VocabularyItem> { $0.word == word }
        let descriptor = FetchDescriptor<VocabularyItem>(predicate: predicate)
        let results = try? modelContext.fetch(descriptor)
        return results?.first?.reading
    }

    /// Look up reading from Jisho API
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
