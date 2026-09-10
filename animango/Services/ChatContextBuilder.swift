import Foundation
import SwiftData

struct UserFluencyProfile {
    enum FluencyTier: String {
        case beginner
        case elementary
        case intermediate
        case advanced

        var japaneseRatio: Int {
            switch self {
            case .beginner: 10
            case .elementary: 30
            case .intermediate: 60
            case .advanced: 85
            }
        }

        var maxJLPTUsage: Int {
            switch self {
            case .beginner: 5
            case .elementary: 4
            case .intermediate: 3
            case .advanced: 2
            }
        }

        var displayName: String {
            switch self {
            case .beginner: "Beginner"
            case .elementary: "Elementary"
            case .intermediate: "Intermediate"
            case .advanced: "Advanced"
            }
        }
    }

    let tier: FluencyTier
    let totalKnownWords: Int
    let totalKnownKanji: Int
    let highestConfidentJLPTLevel: Int
    let studyStreak: Int
    let mediaInLibrary: [(title: String, japaneseTitle: String?, externalID: String)]
    let learningVocabSample: [(word: String, meaning: String, reading: String)]
    let mediaVocabSample: [(word: String, meaning: String)]
    let mediaGrammarSample: [String]

    // Lesson plan: items the bot should proactively teach this session
    let vocabToTeach: [(word: String, reading: String, meaning: String, partOfSpeech: String?)]
    let grammarToTeach: [(pattern: String, explanation: String, example: GrammarExample?)]
}

struct ChatContextBuilder {

    // MARK: - Build Profile

    static func buildFluencyProfile(
        modelContext: ModelContext,
        mediaContextID: String? = nil
    ) -> UserFluencyProfile {
        let allProgress = (try? modelContext.fetch(FetchDescriptor<UserProgress>())) ?? []

        let vocabProgress = allProgress.filter { $0.itemType == .vocabulary }
        let totalKnownWords = vocabProgress.filter {
            $0.knowledgeState == .mastered || $0.knowledgeState == .developing
        }.count

        let learningVocabIDs = vocabProgress
            .filter { $0.knowledgeState == .learning }
            .map { $0.itemID }

        let kanjiProgress = allProgress.filter { $0.itemType == .kanji }
        let totalKnownKanji = kanjiProgress.filter {
            $0.knowledgeState == .mastered || $0.knowledgeState == .developing
        }.count

        let tier = computeTier(knownWords: totalKnownWords)
        let highestJLPT = computeHighestJLPTLevel(modelContext: modelContext, vocabProgress: vocabProgress)
        let streak = computeStreak(from: allProgress)
        let libraryMedia = fetchLibraryMedia(modelContext: modelContext)
        let learningVocabSample = fetchVocabSample(ids: learningVocabIDs, modelContext: modelContext, limit: 10)

        var mediaVocabSample: [(word: String, meaning: String)] = []
        var mediaGrammarSample: [String] = []
        if let mediaID = mediaContextID {
            mediaVocabSample = fetchMediaVocabSample(mediaID: mediaID, modelContext: modelContext, limit: 12)
            mediaGrammarSample = fetchMediaGrammarSample(mediaID: mediaID, modelContext: modelContext, limit: 6)
        }

        // Build lesson plan: pick unlearned vocab and grammar to teach this session
        let lessonPlan = buildLessonPlan(
            modelContext: modelContext,
            allProgress: allProgress,
            tier: tier,
            maxJLPT: highestJLPT,
            mediaContextID: mediaContextID,
            libraryMedia: libraryMedia
        )

        return UserFluencyProfile(
            tier: tier,
            totalKnownWords: totalKnownWords,
            totalKnownKanji: totalKnownKanji,
            highestConfidentJLPTLevel: highestJLPT,
            studyStreak: streak,
            mediaInLibrary: libraryMedia,
            learningVocabSample: learningVocabSample,
            mediaVocabSample: mediaVocabSample,
            mediaGrammarSample: mediaGrammarSample,
            vocabToTeach: lessonPlan.vocab,
            grammarToTeach: lessonPlan.grammar
        )
    }

    // MARK: - Build System Prompt

    static func buildSystemPrompt(from profile: UserFluencyProfile) -> String {
        let identity = """
        You are Manga-chan (マンガちゃん), an enthusiastic and encouraging Japanese language tutor \
        built into Wakatta — an app for learning Japanese through anime, manga, drama, and games. \
        Your personality: warm, playful, uses light anime references, celebrates user progress, \
        never condescending. You use emojis sparingly but expressively. \
        Keep responses concise (2-4 short paragraphs max) — this is a mobile chat interface.

        ## Teaching Style (CRITICAL — follow strictly)
        You are a PROACTIVE teacher, not a passive assistant. You do NOT ask "what do you want to learn?" \
        or "how can I help you?" — instead, you DRIVE the lesson. You always have a plan: \
        teach new words, explain grammar, quiz the user, and move forward. \
        Think of yourself as a fun sensei running a class, not a help desk. \
        Each message should teach something, quiz something, or build on what you just taught. \
        When the user responds, acknowledge their answer (correct or gently correct), \
        then continue teaching the next item in the lesson.
        """

        let levelSection = """
        ## User's Current Japanese Level
        - Fluency tier: \(profile.tier.displayName)
        - Known vocabulary: ~\(profile.totalKnownWords) words
        - Known kanji: ~\(profile.totalKnownKanji) characters
        - Highest JLPT confidence: N\(profile.highestConfidentJLPTLevel)
        - Study streak: \(profile.studyStreak) days

        ## Language Mixing Rules (CRITICAL — follow strictly)
        Use Japanese for approximately \(profile.tier.japaneseRatio)% of your output. \
        The remaining \(100 - profile.tier.japaneseRatio)% should be English.
        \(languageMixingInstructions(for: profile.tier))

        When you use a Japanese word the user likely doesn't know yet (above N\(profile.tier.maxJLPTUsage)), \
        always provide its reading in parentheses and a brief English gloss immediately after, \
        e.g. 諦める（あきらめる, "to give up").
        """

        let librarySection: String
        if profile.mediaInLibrary.isEmpty {
            librarySection = """
            ## User's Library
            The user hasn't added any shows to their library yet. \
            Encourage them to explore the Discover tab and add a show to study from.
            """
        } else {
            let showList = profile.mediaInLibrary
                .map { "- \($0.title)\($0.japaneseTitle.map { " (\($0))" } ?? "")" }
                .joined(separator: "\n")
            librarySection = """
            ## User's Library (shows they are actively studying)
            \(showList)

            Reference these titles naturally in examples and conversation. \
            If the user asks to learn vocab from one of these shows, teach it directly.
            """
        }

        var mediaContextSection = ""
        if !profile.mediaVocabSample.isEmpty || !profile.mediaGrammarSample.isEmpty {
            let vocabList = profile.mediaVocabSample
                .map { "- \($0.word): \($0.meaning)" }
                .joined(separator: "\n")
            let grammarList = profile.mediaGrammarSample
                .map { "- \($0)" }
                .joined(separator: "\n")
            mediaContextSection = """

            ## Focused Media Context
            This conversation is specifically about a show the user is studying. \
            Below is a sample of its vocabulary and grammar — weave these naturally \
            into your teaching when relevant:

            Vocabulary sample:
            \(vocabList)

            Grammar patterns found in this show:
            \(grammarList)
            """
        }

        var quizSection = ""
        if !profile.learningVocabSample.isEmpty {
            let items = profile.learningVocabSample
                .map { "\($0.word)（\($0.reading)）= \($0.meaning)" }
                .joined(separator: ", ")
            quizSection = """

            ## Words Currently In User's SRS Queue
            These are words the user is actively learning right now: \(items)
            Occasionally — no more than once every 5 messages — you can naturally test \
            the user on one of these. Don't make it feel like a test; keep it conversational.
            """
        }

        var lessonPlanSection = ""
        if !profile.vocabToTeach.isEmpty || !profile.grammarToTeach.isEmpty {
            var parts: [String] = []
            parts.append("""
            ## Today's Lesson Plan (TEACH THESE PROACTIVELY)
            You MUST work through these items during this conversation. \
            Introduce them naturally — teach 1-2 vocab per message, give examples, \
            then quiz the user before moving on. Do not dump all items at once.
            """)

            if !profile.vocabToTeach.isEmpty {
                let vocabList = profile.vocabToTeach.map { item in
                    let pos = item.partOfSpeech.map { " [\($0)]" } ?? ""
                    return "- \(item.word)（\(item.reading)）: \(item.meaning)\(pos)"
                }.joined(separator: "\n")
                parts.append("""
                Vocabulary to teach:
                \(vocabList)
                """)
            }

            if !profile.grammarToTeach.isEmpty {
                let grammarList = profile.grammarToTeach.map { item in
                    var line = "- \(item.pattern): \(item.explanation)"
                    if let ex = item.example {
                        line += "\n  Example: \(ex.japanese) (\(ex.english))"
                    }
                    return line
                }.joined(separator: "\n")
                parts.append("""
                Grammar to teach:
                \(grammarList)
                """)
            }

            parts.append("""
            Teaching flow: Introduce a word → give an example sentence using it → \
            ask the user to try using it or translate something → praise/correct → \
            introduce next word or grammar point. Keep momentum — always end your \
            message with something that moves the lesson forward (a question, a challenge, \
            or introducing the next item).
            """)

            lessonPlanSection = parts.joined(separator: "\n\n")
        }

        let rules = """

        ## Core Behavioral Rules
        1. Always write Japanese with furigana in parentheses for words the user may not know.
        2. When the user makes a grammar mistake in Japanese, correct it gently and explain why.
        3. Connect vocabulary and grammar explanations to anime/manga scenes when possible.
        4. If the user seems frustrated, back off difficulty and use more English temporarily.
        5. If the user responds consistently in Japanese, gradually increase your Japanese ratio.
        6. Stay focused on Japanese learning. You can chat casually about anime but always tie it back to language.
        7. NEVER ask "what would you like to learn?" or "how can I help?" — always drive the conversation forward with teaching.
        8. End every message with either a question, a mini-challenge, or the next thing you're about to teach.
        """

        return [identity, levelSection, librarySection, mediaContextSection, quizSection, lessonPlanSection, rules]
            .filter { !$0.isEmpty }
            .joined(separator: "\n\n")
    }

    // MARK: - Language Mixing Instructions

    private static func languageMixingInstructions(for tier: UserFluencyProfile.FluencyTier) -> String {
        switch tier {
        case .beginner:
            return """
            Since the user is a beginner, write almost entirely in English. \
            Introduce Japanese only for greetings (こんにちは, ありがとう), \
            single nouns, and direct translations. Always provide full English translations.
            """
        case .elementary:
            return """
            Mix in simple Japanese sentences at N5/N4 level. \
            Use Japanese for greetings, simple statements, and questions. \
            Provide English translation in brackets after each Japanese sentence. \
            Example: "今日は何を勉強したい？[What do you want to study today?]"
            """
        case .intermediate:
            return """
            Use Japanese freely for explanations and examples at N4/N3 level. \
            Switch to English for complex grammar explanations or when clarifying. \
            You do NOT need to translate every sentence — only when introducing \
            new vocabulary or when meaning might be unclear.
            """
        case .advanced:
            return """
            Conduct most of the conversation in Japanese. \
            Use English only for nuanced grammatical distinctions that are hard \
            to express in Japanese, or when the user explicitly asks in English. \
            Target N2/N1 level naturally — don't dumb it down.
            """
        }
    }

    // MARK: - Lesson Plan Builder

    private static func buildLessonPlan(
        modelContext: ModelContext,
        allProgress: [UserProgress],
        tier: UserFluencyProfile.FluencyTier,
        maxJLPT: Int,
        mediaContextID: String?,
        libraryMedia: [(title: String, japaneseTitle: String?, externalID: String)]
    ) -> (
        vocab: [(word: String, reading: String, meaning: String, partOfSpeech: String?)],
        grammar: [(pattern: String, explanation: String, example: GrammarExample?)]
    ) {
        let knownIDs = Set(
            allProgress.filter {
                $0.knowledgeState == .mastered || $0.knowledgeState == .developing || $0.knowledgeState == .learning
            }.map { $0.itemID }
        )

        // Determine which media to pull vocab/grammar from
        let mediaIDs: [String]
        if let contextID = mediaContextID {
            mediaIDs = [contextID]
        } else {
            mediaIDs = libraryMedia.map { $0.externalID }
        }

        // Fetch vocab from the user's media that they haven't learned yet
        var candidateWords: Set<String> = []
        for mediaID in mediaIDs {
            let predicate = #Predicate<MediaVocabulary> { $0.mediaExternalID == mediaID }
            let mappings = (try? modelContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
            let words = mappings
                .sorted { $0.frequency > $1.frequency }
                .map { $0.vocabularyWord }
            candidateWords.formUnion(words)
        }

        // Filter to unlearned vocab at appropriate JLPT level
        let allVocab = (try? modelContext.fetch(FetchDescriptor<VocabularyItem>())) ?? []
        let targetLevels = Set(maxJLPT...5)
        let unlearnedVocab = allVocab
            .filter { candidateWords.contains($0.word) && !knownIDs.contains($0.word) }
            .filter { targetLevels.contains($0.jlptLevel ?? 5) }
            .sorted { ($0.frequency ?? 0) > ($1.frequency ?? 0) }
            .prefix(5)
            .map { (word: $0.word, reading: $0.reading, meaning: $0.meaning, partOfSpeech: $0.partOfSpeech) }

        // If no media-specific vocab, fall back to JLPT-level vocab
        let vocabToTeach: [(word: String, reading: String, meaning: String, partOfSpeech: String?)]
        if unlearnedVocab.isEmpty {
            vocabToTeach = allVocab
                .filter { !knownIDs.contains($0.word) && targetLevels.contains($0.jlptLevel ?? 5) }
                .prefix(5)
                .map { (word: $0.word, reading: $0.reading, meaning: $0.meaning, partOfSpeech: $0.partOfSpeech) }
        } else {
            vocabToTeach = Array(unlearnedVocab)
        }

        // Fetch grammar from the user's media that they haven't learned yet
        var candidatePatterns: Set<String> = []
        for mediaID in mediaIDs {
            let predicate = #Predicate<MediaGrammar> { $0.mediaExternalID == mediaID }
            let mappings = (try? modelContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
            candidatePatterns.formUnion(mappings.map { $0.grammarPattern })
        }

        let allGrammar = (try? modelContext.fetch(FetchDescriptor<GrammarPoint>())) ?? []
        let grammarToTeach = allGrammar
            .filter { candidatePatterns.contains($0.pattern) && !knownIDs.contains($0.pattern) }
            .filter { targetLevels.contains($0.jlptLevel ?? 5) }
            .prefix(2)
            .map { (pattern: $0.pattern, explanation: $0.explanation, example: $0.examples.first) }

        return (vocab: vocabToTeach, grammar: Array(grammarToTeach))
    }

    // MARK: - Helpers

    private static func computeTier(knownWords: Int) -> UserFluencyProfile.FluencyTier {
        switch knownWords {
        case 0..<100: .beginner
        case 100..<500: .elementary
        case 500..<1500: .intermediate
        default: .advanced
        }
    }

    private static func computeHighestJLPTLevel(
        modelContext: ModelContext,
        vocabProgress: [UserProgress]
    ) -> Int {
        let allVocab = (try? modelContext.fetch(FetchDescriptor<VocabularyItem>())) ?? []
        let progressByID = Dictionary(uniqueKeysWithValues: vocabProgress.map { ($0.itemID, $0) })

        for level in stride(from: 5, through: 1, by: -1) {
            let levelVocab = allVocab.filter { $0.jlptLevel == level }
            guard !levelVocab.isEmpty else { continue }
            let knownCount = levelVocab.filter {
                let state = progressByID[$0.word]?.knowledgeState
                return state == .mastered || state == .developing
            }.count
            if Double(knownCount) / Double(levelVocab.count) >= 0.50 {
                return level
            }
        }
        return 5
    }

    private static func computeStreak(from progress: [UserProgress]) -> Int {
        let calendar = Calendar.current
        let reviewDates = Set(
            progress.compactMap { $0.lastReviewedDate }
                .map { calendar.startOfDay(for: $0) }
        )
        guard !reviewDates.isEmpty else { return 0 }

        var streak = 0
        var day = calendar.startOfDay(for: .now)
        while reviewDates.contains(day) {
            streak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previousDay
        }
        return streak
    }

    private static func fetchLibraryMedia(
        modelContext: ModelContext
    ) -> [(title: String, japaneseTitle: String?, externalID: String)] {
        let predicate = #Predicate<Media> { $0.isInLibrary == true }
        let media = (try? modelContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
        return media.map { ($0.title, $0.titleJapanese, $0.externalID) }
    }

    private static func fetchVocabSample(
        ids: [String],
        modelContext: ModelContext,
        limit: Int
    ) -> [(word: String, meaning: String, reading: String)] {
        guard !ids.isEmpty else { return [] }
        let sampleSet = Set(ids.prefix(limit))
        let allVocab = (try? modelContext.fetch(FetchDescriptor<VocabularyItem>())) ?? []
        return allVocab
            .filter { sampleSet.contains($0.word) }
            .map { ($0.word, $0.meaning, $0.reading) }
    }

    private static func fetchMediaVocabSample(
        mediaID: String,
        modelContext: ModelContext,
        limit: Int
    ) -> [(word: String, meaning: String)] {
        let predicate = #Predicate<MediaVocabulary> { $0.mediaExternalID == mediaID }
        let mappings = (try? modelContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
        let topWords = Set(
            mappings.sorted { $0.frequency > $1.frequency }
                .prefix(limit)
                .map { $0.vocabularyWord }
        )
        let allVocab = (try? modelContext.fetch(FetchDescriptor<VocabularyItem>())) ?? []
        return allVocab
            .filter { topWords.contains($0.word) }
            .map { ($0.word, $0.meaning) }
    }

    private static func fetchMediaGrammarSample(
        mediaID: String,
        modelContext: ModelContext,
        limit: Int
    ) -> [String] {
        let predicate = #Predicate<MediaGrammar> { $0.mediaExternalID == mediaID }
        let mappings = (try? modelContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
        return Array(mappings.prefix(limit).map { $0.grammarPattern })
    }
}
