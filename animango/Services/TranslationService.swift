import Foundation
import SwiftData

// MARK: - Response Models

struct TranslationResult {
    let translatedText: String
    let annotatedWords: [AnnotatedWord]?
}

struct AnnotatedWord: Identifiable, Codable {
    let id: String
    let surface: String
    let reading: String?

    init(surface: String, reading: String? = nil) {
        self.id = UUID().uuidString
        self.surface = surface
        self.reading = reading
    }

    enum CodingKeys: String, CodingKey {
        case id, surface, reading
    }
}

private struct LLMTranslationResponse: Codable {
    let translation: String
    let words: [LLMWordAnnotation]?
}

private struct LLMWordAnnotation: Codable {
    let surface: String
    let reading: String?
}

// MARK: - Service

@Observable @MainActor
final class TranslationService {

    private let llmManager = LLMServiceManager()

    var isConfigured: Bool { llmManager.isAvailable }

    func configure(modelContext: ModelContext) {
        llmManager.loadConfiguration(modelContext: modelContext)
    }

    /// Translate text from one language to another.
    /// Returns the translation and, if the target is Japanese, word-level furigana annotations.
    func translate(
        text: String,
        from source: SupportedLanguage,
        to target: SupportedLanguage
    ) async throws -> TranslationResult {
        let systemPrompt = buildSystemPrompt(source: source, target: target)
        let userPrompt = buildUserPrompt(text: text)

        let messages = [
            LLMMessage(role: .system, content: systemPrompt),
            LLMMessage(role: .user, content: userPrompt)
        ]

        let response = try await llmManager.chat(messages: messages)
        return parseResponse(response, targetLanguage: target)
    }

    /// Look up a word definition using the LLM (for non-Japanese words)
    func lookupWordDefinition(word: String, context: String, language: SupportedLanguage) async throws -> String {
        let messages = [
            LLMMessage(role: .system, content: """
                You are a dictionary assistant. Given a word and the sentence it appears in, provide a brief definition. \
                Reply with ONLY the definition in English, 1-2 sentences max. Include the part of speech.
                """),
            LLMMessage(role: .user, content: "Word: \"\(word)\" in the sentence: \"\(context)\" (language: \(language.displayName))")
        ]

        return try await llmManager.chat(messages: messages)
    }

    // MARK: - Prompt Building

    private func buildSystemPrompt(source: SupportedLanguage, target: SupportedLanguage) -> String {
        if target.isJapanese {
            return """
                You are a translation engine. Translate the user's text from \(source.displayName) to Japanese.
                
                Respond ONLY with valid JSON in this exact format:
                {"translation": "<translated text>", "words": [{"surface": "<word>", "reading": "<hiragana reading or null>"}]}
                
                Rules for the "words" array:
                - Split the translation into individual words/particles
                - For words containing kanji, provide the hiragana reading
                - For words that are already hiragana/katakana, set reading to null
                - Do not include any explanation, only the JSON
                """
        } else {
            return """
                You are a translation engine. Translate the user's text from \(source.displayName) to \(target.displayName).
                
                Respond ONLY with valid JSON in this exact format:
                {"translation": "<translated text>"}
                
                Do not include any explanation, only the JSON.
                """
        }
    }

    private func buildUserPrompt(text: String) -> String {
        text
    }

    // MARK: - Response Parsing

    private func parseResponse(_ response: String, targetLanguage: SupportedLanguage) -> TranslationResult {
        // Try to parse as JSON
        let cleaned = response.trimmingCharacters(in: .whitespacesAndNewlines)

        // Extract JSON from markdown code blocks if present
        let jsonString: String
        if cleaned.hasPrefix("```") {
            let lines = cleaned.components(separatedBy: "\n")
            let filtered = lines.filter { !$0.hasPrefix("```") }
            jsonString = filtered.joined(separator: "\n")
        } else {
            jsonString = cleaned
        }

        guard let data = jsonString.data(using: .utf8) else {
            return TranslationResult(translatedText: response, annotatedWords: nil)
        }

        do {
            let decoded = try JSONDecoder().decode(LLMTranslationResponse.self, from: data)

            let annotatedWords: [AnnotatedWord]?
            if targetLanguage.isJapanese, let words = decoded.words {
                annotatedWords = words.map { word in
                    AnnotatedWord(surface: word.surface, reading: word.reading)
                }
            } else {
                annotatedWords = nil
            }

            return TranslationResult(
                translatedText: decoded.translation,
                annotatedWords: annotatedWords
            )
        } catch {
            // Fallback: use the raw response as the translation
            return TranslationResult(translatedText: response, annotatedWords: nil)
        }
    }
}
