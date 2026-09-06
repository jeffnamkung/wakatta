import Foundation
import FoundationModels

/// Wraps the existing FoundationModelService as an LLMServiceProvider
actor AppleIntelligenceProvider: LLMServiceProvider {
    private let model = SystemLanguageModel.default

    nonisolated var isAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability {
            return true
        }
        return false
    }

    nonisolated var unavailableReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "This device doesn't support Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Please enable Apple Intelligence in Settings."
        case .unavailable(.modelNotReady):
            return "The AI model is still downloading. Please try again later."
        case .unavailable:
            return "Apple Intelligence is currently unavailable."
        }
    }

    func generateEpisodeContent(
        mediaTitle: String,
        episodeTitle: String,
        episodeNumber: Int,
        mediaType: String
    ) async throws -> LLMGeneratedContent {
        let session = LanguageModelSession(
            instructions: """
            You are a Japanese language teacher creating learning materials. \
            Generate vocabulary and grammar lessons based on anime, manga, drama, and movie content. \
            All Japanese text must use correct kanji, hiragana, and katakana. \
            Readings must be in hiragana. \
            Create exercises that test vocabulary recall, kanji reading, grammar usage, translation, and pronunciation. \
            Include a mix of beginner (N5/N4) and intermediate (N3) level content. \
            You MUST respond in U.S. English for explanations and hints, and Japanese for vocabulary and examples.
            """
        )

        let prompt = """
        Generate Japanese language learning content for the \(mediaType) "\(mediaTitle)", \
        specifically for \(mediaType == "movie" ? "the full movie" : "episode \(episodeNumber): \(episodeTitle)"). \
        Include 8-12 vocabulary items that would appear in this content, \
        and 2-3 grammar lessons each with 4-6 exercises. \
        Make the vocabulary and grammar contextually relevant to the themes and setting of this media.
        """

        let response = try await session.respond(
            to: prompt,
            generating: GeneratedEpisodeContent.self
        )

        // Convert @Generable types to LLM types
        let content = response.content
        return LLMGeneratedContent(
            vocabulary: content.vocabulary.map {
                LLMVocabItem(word: $0.word, reading: $0.reading, meaning: $0.meaning)
            },
            lessons: content.lessons.map { lesson in
                LLMLesson(
                    grammarPattern: lesson.grammarPattern,
                    title: lesson.title,
                    explanation: lesson.explanation,
                    examples: lesson.examples.map {
                        LLMExample(japanese: $0.japanese, reading: $0.reading, english: $0.english)
                    },
                    exercises: lesson.exercises.map { ex in
                        LLMExercise(
                            prompt: ex.prompt,
                            answer: ex.answer,
                            hint: ex.hint,
                            exerciseType: mapExerciseType(ex.exerciseType)
                        )
                    }
                )
            }
        )
    }

    private func mapExerciseType(_ type: GeneratedExerciseType) -> String {
        switch type {
        case .vocabRecall: return "vocabRecall"
        case .kanjiReading: return "kanjiReading"
        case .grammarFill: return "grammarFill"
        case .translation: return "translation"
        case .pronunciation: return "pronunciation"
        }
    }

    func chat(messages: [LLMMessage]) async throws -> String {
        let session = LanguageModelSession(
            instructions: messages.first { $0.role == .system }?.content ?? """
            You are a helpful Japanese language tutor. Respond in a clear and educational manner. \
            Use Japanese examples with readings in parentheses when appropriate.
            """
        )

        // Build conversation from messages (skip system)
        var lastResponse = ""
        for message in messages where message.role != .system {
            if message.role == .user {
                let response = try await session.respond(to: message.content)
                lastResponse = response.content
            }
        }

        return lastResponse
    }
}
