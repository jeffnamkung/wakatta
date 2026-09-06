import Foundation
import FoundationModels

// MARK: - Generable Types for Structured Generation

@Generable(description: "A Japanese vocabulary word for language learning")
struct GeneratedVocabItem {
    @Guide(description: "Japanese word in kanji or kana")
    var word: String

    @Guide(description: "Hiragana reading of the word")
    var reading: String

    @Guide(description: "English meaning")
    var meaning: String
}

@Generable(description: "An exercise for practicing Japanese")
struct GeneratedExercise {
    @Guide(description: "Exercise prompt in English or Japanese")
    var prompt: String

    @Guide(description: "Expected correct answer")
    var answer: String

    @Guide(description: "Helpful hint for the learner")
    var hint: String

    @Guide(description: "Exercise type")
    var exerciseType: GeneratedExerciseType
}

@Generable
enum GeneratedExerciseType {
    case vocabRecall
    case kanjiReading
    case grammarFill
    case translation
    case pronunciation
}

@Generable(description: "A grammar lesson with exercises")
struct GeneratedLesson {
    @Guide(description: "Grammar pattern in Japanese, e.g. 〜ている")
    var grammarPattern: String

    @Guide(description: "Short lesson title in English")
    var title: String

    @Guide(description: "Grammar explanation in English")
    var explanation: String

    @Guide(description: "Example sentences showing the grammar pattern")
    var examples: [GeneratedExample]

    @Guide(description: "Exercises using this grammar point")
    var exercises: [GeneratedExercise]
}

@Generable(description: "An example sentence for a grammar point")
struct GeneratedExample {
    @Guide(description: "Japanese sentence")
    var japanese: String

    @Guide(description: "Hiragana reading")
    var reading: String

    @Guide(description: "English translation")
    var english: String
}

@Generable(description: "Complete learning content for an episode")
struct GeneratedEpisodeContent {
    @Guide(description: "Vocabulary items from this episode")
    var vocabulary: [GeneratedVocabItem]

    @Guide(description: "Grammar-focused lessons with exercises")
    var lessons: [GeneratedLesson]
}

// MARK: - Foundation Model Service

@Observable @MainActor
final class FoundationModelService {
    private let model = SystemLanguageModel.default

    var isGenerating = false

    var isAvailable: Bool {
        if case .available = model.availability {
            return true
        }
        return false
    }

    var unavailableReason: String? {
        switch model.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return "This device doesn't support Apple Intelligence."
        case .unavailable(.appleIntelligenceNotEnabled):
            return "Please enable Apple Intelligence in Settings."
        case .unavailable(.modelNotReady):
            return "The AI model is still downloading. Please try again later."
        case .unavailable:
            return "The AI model is currently unavailable."
        }
    }

    func generateEpisodeContent(
        mediaTitle: String,
        episodeTitle: String,
        episodeNumber: Int,
        mediaType: String
    ) async throws -> GeneratedEpisodeContent {
        isGenerating = true
        defer { isGenerating = false }

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

        return response.content
    }
}
