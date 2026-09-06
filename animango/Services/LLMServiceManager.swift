import Foundation
import SwiftData

@Observable @MainActor
final class LLMServiceManager {

    var currentProvider: LLMProvider = .apple
    var isConfigured: Bool { provider != nil && (provider?.isAvailable ?? false) }

    private var provider: (any LLMServiceProvider)?

    /// Load configuration from SwiftData and create the appropriate provider
    func loadConfiguration(modelContext: ModelContext) {
        let configs = (try? modelContext.fetch(FetchDescriptor<LLMConfiguration>())) ?? []

        if let config = configs.first {
            currentProvider = config.provider
            configureProvider(config)
        } else {
            // Default to Apple Intelligence
            currentProvider = .apple
            provider = AppleIntelligenceProvider()
        }
    }

    /// Update the provider when settings change
    func updateProvider(config: LLMConfiguration) {
        currentProvider = config.provider
        configureProvider(config)
    }

    var isAvailable: Bool {
        provider?.isAvailable ?? false
    }

    var unavailableReason: String? {
        guard let provider = provider else {
            return "No LLM provider configured."
        }
        return provider.unavailableReason
    }

    func generateEpisodeContent(
        mediaTitle: String,
        episodeTitle: String,
        episodeNumber: Int,
        mediaType: String
    ) async throws -> LLMGeneratedContent {
        guard let provider = provider else {
            throw LLMServiceError.notConfigured
        }
        guard provider.isAvailable else {
            throw LLMServiceError.providerUnavailable(
                provider.unavailableReason ?? "Provider is unavailable."
            )
        }
        return try await provider.generateEpisodeContent(
            mediaTitle: mediaTitle,
            episodeTitle: episodeTitle,
            episodeNumber: episodeNumber,
            mediaType: mediaType
        )
    }

    func chat(messages: [LLMMessage]) async throws -> String {
        guard let provider = provider else {
            throw LLMServiceError.notConfigured
        }
        guard provider.isAvailable else {
            throw LLMServiceError.providerUnavailable(
                provider.unavailableReason ?? "Provider is unavailable."
            )
        }
        return try await provider.chat(messages: messages)
    }

    // MARK: - Private

    private func configureProvider(_ config: LLMConfiguration) {
        switch config.provider {
        case .apple:
            provider = AppleIntelligenceProvider()
        case .anthropic:
            provider = AnthropicProvider(
                apiKey: config.apiKey,
                model: config.selectedModel
            )
        case .openAI:
            provider = OpenAIProvider(
                apiKey: config.apiKey,
                model: config.selectedModel
            )
        }
    }
}
