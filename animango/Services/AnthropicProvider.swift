import Foundation

actor AnthropicProvider: LLMServiceProvider {
    private let apiKey: String
    private let model: String
    private let client = APIClient()

    nonisolated var isAvailable: Bool { !apiKey.isEmpty }
    nonisolated var unavailableReason: String? {
        apiKey.isEmpty ? "Please add your Anthropic API key in Settings." : nil
    }

    init(apiKey: String, model: String = "claude-sonnet-4-20250514") {
        self.apiKey = apiKey
        self.model = model
    }

    // MARK: - API Types

    private struct MessageRequest: Encodable {
        let model: String
        let max_tokens: Int
        let system: String?
        let messages: [Message]

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    private struct MessageResponse: Decodable {
        let content: [ContentBlock]

        struct ContentBlock: Decodable {
            let type: String
            let text: String?
        }
    }

    private struct ErrorResponse: Decodable {
        let error: ErrorDetail
        struct ErrorDetail: Decodable {
            let message: String
        }
    }

    // MARK: - Episode Content Generation

    func generateEpisodeContent(
        mediaTitle: String,
        episodeTitle: String,
        episodeNumber: Int,
        mediaType: String
    ) async throws -> LLMGeneratedContent {
        let systemPrompt = """
        You are a Japanese language teacher creating learning materials. \
        Generate vocabulary and grammar lessons based on anime, manga, drama, and movie content. \
        All Japanese text must use correct kanji, hiragana, and katakana. \
        Readings must be in hiragana. \
        Create exercises that test vocabulary recall, kanji reading, grammar usage, translation, and pronunciation. \
        Include a mix of beginner (N5/N4) and intermediate (N3) level content. \
        Respond ONLY with valid JSON matching the specified schema. No markdown, no explanation, just JSON.
        """

        let userPrompt = """
        Generate Japanese language learning content for the \(mediaType) "\(mediaTitle)", \
        specifically for \(mediaType == "movie" ? "the full movie" : "episode \(episodeNumber): \(episodeTitle)").

        Respond with JSON in this exact format:
        {
          "vocabulary": [
            {"word": "日本語", "reading": "にほんご", "meaning": "Japanese language"}
          ],
          "lessons": [
            {
              "grammarPattern": "〜ている",
              "title": "Describing Ongoing Actions",
              "explanation": "Explanation in English",
              "examples": [
                {"japanese": "食べている", "reading": "たべている", "english": "is eating"}
              ],
              "exercises": [
                {"prompt": "What does X mean?", "answer": "answer", "hint": "hint", "exerciseType": "vocabRecall"}
              ]
            }
          ]
        }

        Include 8-12 vocabulary items and 2-3 grammar lessons each with 4-6 exercises. \
        Valid exerciseType values: vocabRecall, kanjiReading, grammarFill, translation, pronunciation. \
        Make content contextually relevant to the themes and setting of this media.
        """

        let responseText = try await sendMessage(
            system: systemPrompt,
            userMessage: userPrompt,
            maxTokens: 4096
        )

        return try parseJSON(responseText)
    }

    // MARK: - Chat

    func chat(messages: [LLMMessage]) async throws -> String {
        let systemMessage = messages.first { $0.role == .system }?.content
        let chatMessages = messages.filter { $0.role != .system }

        let requestMessages = chatMessages.map { msg in
            MessageRequest.Message(
                role: msg.role.rawValue,
                content: msg.content
            )
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw LLMServiceError.requestFailed("Invalid API URL")
        }

        let request = MessageRequest(
            model: model,
            max_tokens: 2048,
            system: systemMessage,
            messages: requestMessages
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw LLMServiceError.invalidAPIKey
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw LLMServiceError.requestFailed(errorResponse.error.message)
            }
            throw LLMServiceError.requestFailed("HTTP \(httpResponse.statusCode)")
        }

        let messageResponse = try JSONDecoder().decode(MessageResponse.self, from: data)
        guard let text = messageResponse.content.first?.text else {
            throw LLMServiceError.invalidResponse
        }

        return text
    }

    // MARK: - Helpers

    private func sendMessage(system: String, userMessage: String, maxTokens: Int) async throws -> String {
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            throw LLMServiceError.requestFailed("Invalid API URL")
        }

        let request = MessageRequest(
            model: model,
            max_tokens: maxTokens,
            system: system,
            messages: [MessageRequest.Message(role: "user", content: userMessage)]
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMServiceError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw LLMServiceError.invalidAPIKey
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw LLMServiceError.requestFailed(errorResponse.error.message)
            }
            throw LLMServiceError.requestFailed("HTTP \(httpResponse.statusCode)")
        }

        let messageResponse = try JSONDecoder().decode(MessageResponse.self, from: data)
        guard let text = messageResponse.content.first?.text else {
            throw LLMServiceError.invalidResponse
        }

        return text
    }

    private func parseJSON(_ text: String) throws -> LLMGeneratedContent {
        // Try to extract JSON from the response (handle markdown code blocks)
        var jsonString = text.trimmingCharacters(in: .whitespacesAndNewlines)

        if jsonString.hasPrefix("```json") {
            jsonString = String(jsonString.dropFirst(7))
        } else if jsonString.hasPrefix("```") {
            jsonString = String(jsonString.dropFirst(3))
        }
        if jsonString.hasSuffix("```") {
            jsonString = String(jsonString.dropLast(3))
        }
        jsonString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let data = jsonString.data(using: .utf8) else {
            throw LLMServiceError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(LLMGeneratedContent.self, from: data)
        } catch {
            throw LLMServiceError.requestFailed("Failed to parse response: \(error.localizedDescription)")
        }
    }
}
