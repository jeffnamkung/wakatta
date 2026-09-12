import Foundation

actor GeminiProvider: LLMServiceProvider {
    private let apiKey: String
    private let model: String
    private let client = APIClient()

    nonisolated var isAvailable: Bool { !apiKey.isEmpty }
    nonisolated var unavailableReason: String? {
        apiKey.isEmpty ? "Please add your Google AI API key in Settings." : nil
    }

    init(apiKey: String, model: String = "gemini-2.5-flash") {
        self.apiKey = apiKey
        self.model = model
    }

    // MARK: - API Types

    private struct GenerateRequest: Encodable {
        let contents: [Content]
        let systemInstruction: Content?
        let generationConfig: GenerationConfig?

        struct Content: Encodable {
            let role: String
            let parts: [Part]
        }

        struct Part: Encodable {
            let text: String
        }

        struct GenerationConfig: Encodable {
            let maxOutputTokens: Int?
            let temperature: Double?
        }
    }

    private struct GenerateResponse: Decodable {
        let candidates: [Candidate]?
        let error: ErrorDetail?

        struct Candidate: Decodable {
            let content: ContentResponse?
        }

        struct ContentResponse: Decodable {
            let parts: [PartResponse]?
        }

        struct PartResponse: Decodable {
            let text: String?
        }

        struct ErrorDetail: Decodable {
            let message: String
            let code: Int?
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
        let systemMessage = messages.first { $0.role == .system }?.content
        let chatMessages = messages.filter { $0.role != .system }

        let contents = chatMessages.map { msg in
            GenerateRequest.Content(
                role: msg.role == .user ? "user" : "model",
                parts: [GenerateRequest.Part(text: msg.content)]
            )
        }

        let systemInstruction: GenerateRequest.Content?
        if let system = systemMessage {
            systemInstruction = GenerateRequest.Content(
                role: "user",
                parts: [GenerateRequest.Part(text: system)]
            )
        } else {
            systemInstruction = nil
        }

        let request = GenerateRequest(
            contents: contents,
            systemInstruction: systemInstruction,
            generationConfig: GenerateRequest.GenerationConfig(
                maxOutputTokens: 2048,
                temperature: nil
            )
        )

        let responseText = try await executeRequest(request)
        return responseText
    }

    // MARK: - Helpers

    private func sendRequest(system: String, userMessage: String, maxTokens: Int) async throws -> String {
        let contents = [
            GenerateRequest.Content(
                role: "user",
                parts: [GenerateRequest.Part(text: userMessage)]
            )
        ]

        let systemInstruction = GenerateRequest.Content(
            role: "user",
            parts: [GenerateRequest.Part(text: system)]
        )

        let request = GenerateRequest(
            contents: contents,
            systemInstruction: systemInstruction,
            generationConfig: GenerateRequest.GenerationConfig(
                maxOutputTokens: maxTokens,
                temperature: nil
            )
        )

        return try await executeRequest(request)
    }

    private func executeRequest(_ request: GenerateRequest) async throws -> String {
        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKey)") else {
            throw LLMServiceError.requestFailed("Invalid API URL")
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try JSONEncoder().encode(request)

        let (data, response) = try await URLSession.shared.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMServiceError.invalidResponse
        }

        if httpResponse.statusCode == 400 || httpResponse.statusCode == 403 {
            if let errorResponse = try? JSONDecoder().decode(GenerateResponse.self, from: data),
               let error = errorResponse.error {
                if error.message.lowercased().contains("api key") {
                    throw LLMServiceError.invalidAPIKey
                }
                throw LLMServiceError.requestFailed(error.message)
            }
            throw LLMServiceError.invalidAPIKey
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            if let errorResponse = try? JSONDecoder().decode(GenerateResponse.self, from: data),
               let error = errorResponse.error {
                throw LLMServiceError.requestFailed(error.message)
            }
            throw LLMServiceError.requestFailed("HTTP \(httpResponse.statusCode)")
        }

        let generateResponse = try JSONDecoder().decode(GenerateResponse.self, from: data)

        guard let text = generateResponse.candidates?.first?.content?.parts?.first?.text else {
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
