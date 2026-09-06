import Foundation

actor OpenAIProvider: LLMServiceProvider {
    private let apiKey: String
    private let model: String
    private let client = APIClient()

    nonisolated var isAvailable: Bool { !apiKey.isEmpty }
    nonisolated var unavailableReason: String? {
        apiKey.isEmpty ? "Please add your OpenAI API key in Settings." : nil
    }

    init(apiKey: String, model: String = "gpt-4o") {
        self.apiKey = apiKey
        self.model = model
    }

    // MARK: - API Types

    private struct ChatRequest: Encodable {
        let model: String
        let messages: [Message]
        let max_tokens: Int?

        struct Message: Encodable {
            let role: String
            let content: String
        }
    }

    private struct ChatResponse: Decodable {
        let choices: [Choice]

        struct Choice: Decodable {
            let message: ResponseMessage
        }

        struct ResponseMessage: Decodable {
            let content: String?
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

        let responseText = try await sendRequest(
            system: systemPrompt,
            userMessage: userPrompt,
            maxTokens: 4096
        )

        return try parseJSON(responseText)
    }

    // MARK: - Chat

    func chat(messages: [LLMMessage]) async throws -> String {
        let requestMessages = messages.map { msg in
            ChatRequest.Message(
                role: msg.role.rawValue,
                content: msg.content
            )
        }

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw LLMServiceError.requestFailed("Invalid API URL")
        }

        let request = ChatRequest(
            model: model,
            messages: requestMessages,
            max_tokens: 2048
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let text = chatResponse.choices.first?.message.content else {
            throw LLMServiceError.invalidResponse
        }

        return text
    }

    // MARK: - Helpers

    private func sendRequest(system: String, userMessage: String, maxTokens: Int) async throws -> String {
        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            throw LLMServiceError.requestFailed("Invalid API URL")
        }

        let request = ChatRequest(
            model: model,
            messages: [
                ChatRequest.Message(role: "system", content: system),
                ChatRequest.Message(role: "user", content: userMessage)
            ],
            max_tokens: maxTokens
        )

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
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

        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        guard let text = chatResponse.choices.first?.message.content else {
            throw LLMServiceError.invalidResponse
        }

        return text
    }

    private func parseJSON(_ text: String) throws -> LLMGeneratedContent {
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
