import Foundation
import SwiftData

enum LLMProvider: String, Codable, CaseIterable, Identifiable {
    case apple
    case anthropic
    case openAI

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .apple: return "Apple Intelligence"
        case .anthropic: return "Claude (Anthropic)"
        case .openAI: return "ChatGPT (OpenAI)"
        }
    }

    var iconName: String {
        switch self {
        case .apple: return "apple.intelligence"
        case .anthropic: return "brain.head.profile"
        case .openAI: return "bubble.left.and.text.bubble.right"
        }
    }

    var requiresAPIKey: Bool {
        switch self {
        case .apple: return false
        case .anthropic, .openAI: return true
        }
    }

    var defaultModel: String {
        switch self {
        case .apple: return "default"
        case .anthropic: return "claude-sonnet-4-20250514"
        case .openAI: return "gpt-4o"
        }
    }

    var availableModels: [String] {
        switch self {
        case .apple: return ["default"]
        case .anthropic: return ["claude-sonnet-4-20250514", "claude-haiku-4-20250414", "claude-opus-4-20250514"]
        case .openAI: return ["gpt-4o", "gpt-4o-mini", "gpt-4.1"]
        }
    }
}

@Model
final class LLMConfiguration {
    var provider: LLMProvider
    var apiKey: String
    var selectedModel: String

    init(
        provider: LLMProvider = .apple,
        apiKey: String = "",
        selectedModel: String = "default"
    ) {
        self.provider = provider
        self.apiKey = apiKey
        self.selectedModel = selectedModel
    }
}
