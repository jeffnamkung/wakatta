import Foundation

/// Response format expected from any LLM provider for episode content generation
struct LLMGeneratedContent: Codable {
    let vocabulary: [LLMVocabItem]
    let lessons: [LLMLesson]
}

struct LLMVocabItem: Codable {
    let word: String
    let reading: String
    let meaning: String
}

struct LLMLesson: Codable {
    let grammarPattern: String
    let title: String
    let explanation: String
    let examples: [LLMExample]
    let exercises: [LLMExercise]
}

struct LLMExample: Codable {
    let japanese: String
    let reading: String
    let english: String
}

struct LLMExercise: Codable {
    let prompt: String
    let answer: String
    let hint: String
    let exerciseType: String
}

/// Chat message for conversational LLM features
struct LLMMessage {
    let role: LLMRole
    let content: String
}

enum LLMRole: String {
    case system
    case user
    case assistant
}

/// Protocol that all LLM providers must implement
protocol LLMServiceProvider {
    var isAvailable: Bool { get }
    var unavailableReason: String? { get }

    func generateEpisodeContent(
        mediaTitle: String,
        episodeTitle: String,
        episodeNumber: Int,
        mediaType: String
    ) async throws -> LLMGeneratedContent

    func chat(messages: [LLMMessage]) async throws -> String
}

enum LLMServiceError: LocalizedError {
    case notConfigured
    case invalidAPIKey
    case requestFailed(String)
    case invalidResponse
    case providerUnavailable(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "LLM provider is not configured. Please set up your API key in Settings."
        case .invalidAPIKey:
            return "Invalid API key. Please check your key in Settings."
        case .requestFailed(let message):
            return "Request failed: \(message)"
        case .invalidResponse:
            return "Received an invalid response from the AI provider."
        case .providerUnavailable(let reason):
            return reason
        }
    }
}
