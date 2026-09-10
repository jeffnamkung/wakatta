import Foundation
import SwiftData

struct ChatMessage: Identifiable {
    let id = UUID()
    let role: LLMRole
    let content: String
    let timestamp = Date()
}

@Observable @MainActor
final class ChatTutorViewModel {
    var messages: [ChatMessage] = []
    var inputText: String = ""
    var isLoading = false
    var errorMessage: String?
    var isConfigured = false

    private let llmManager = LLMServiceManager()
    private var context: String = ""

    func configure(modelContext: ModelContext, grammarPoint: GrammarPoint? = nil) {
        llmManager.loadConfiguration(modelContext: modelContext)
        isConfigured = llmManager.isAvailable

        if let grammar = grammarPoint {
            context = """
            The user is studying the Japanese grammar pattern: \(grammar.pattern)
            Explanation: \(grammar.explanation)
            Examples: \(grammar.examples.map { "\($0.japanese) — \($0.english)" }.joined(separator: "; "))
            Focus the conversation on this grammar pattern.
            """
        }

        if messages.isEmpty {
            let greeting: String
            if let grammar = grammarPoint {
                greeting = "Let's study the grammar pattern **\(grammar.pattern)**!\n\n\(grammar.explanation)\n\nTry using this pattern in a sentence, or ask me anything about it."
            } else {
                greeting = "Welcome to your Japanese language tutor! You can:\n\n• Ask about any grammar pattern\n• Practice making sentences\n• Get vocabulary help\n• Ask about kanji readings\n\nWhat would you like to study?"
            }
            messages.append(ChatMessage(role: .assistant, content: greeting))
        }
    }

    func sendMessage() async {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        messages.append(ChatMessage(role: .user, content: text))
        inputText = ""
        isLoading = true
        errorMessage = nil

        let systemPrompt = """
        You are a friendly Japanese language tutor in a mobile learning app called Perapera. \
        Help the user learn Japanese through anime, manga, drama, and movie contexts. \
        Keep responses concise (2-4 paragraphs max) since this is a mobile chat interface. \
        Always include Japanese text with readings in parentheses, e.g. 食べる（たべる）. \
        Use markdown formatting for emphasis. \
        When the user writes Japanese, evaluate it and give constructive feedback. \
        When explaining grammar, give 2-3 clear examples with translations. \
        \(context)
        """

        var llmMessages: [LLMMessage] = [
            LLMMessage(role: .system, content: systemPrompt)
        ]

        // Include recent conversation history (last 10 messages)
        let recentMessages = messages.suffix(10)
        for msg in recentMessages {
            if msg.role == .user || msg.role == .assistant {
                llmMessages.append(LLMMessage(role: msg.role, content: msg.content))
            }
        }

        do {
            let response = try await llmManager.chat(messages: llmMessages)
            messages.append(ChatMessage(role: .assistant, content: response))
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
