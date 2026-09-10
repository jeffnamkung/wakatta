import Foundation

actor AnimangoAPIService {
    private let client = APIClient()
    private let baseURL = "http://44.210.75.181/api/v1"

    // MARK: - Response DTOs

    struct EpisodeContentDTO: Decodable {
        let mediaId: String
        let episodeNumber: Int
        let vocabulary: [VocabularyDTO]
        let kanji: [KanjiDTO]
        let grammar: [GrammarDTO]
        let stats: StatsDTO

        enum CodingKeys: String, CodingKey {
            case mediaId = "media_id"
            case episodeNumber = "episode_number"
            case vocabulary, kanji, grammar, stats
        }
    }

    struct MediaContentDTO: Decodable {
        let mediaId: String
        let episodes: [EpisodeContentDTO]
        let totalVocabulary: Int
        let totalKanji: Int
        let totalGrammar: Int

        enum CodingKeys: String, CodingKey {
            case mediaId = "media_id"
            case episodes
            case totalVocabulary = "total_vocabulary"
            case totalKanji = "total_kanji"
            case totalGrammar = "total_grammar"
        }
    }

    struct VocabularyDTO: Decodable {
        let word: String
        let reading: String?
        let meaning: String?
        let jlptLevel: Int?
        let frequency: Int?
        let partOfSpeech: String?
        let exampleSentenceJp: String?
        let exampleSentenceEn: String?
        let episodeFrequency: Int?

        enum CodingKeys: String, CodingKey {
            case word, reading, meaning, frequency
            case jlptLevel = "jlpt_level"
            case partOfSpeech = "part_of_speech"
            case exampleSentenceJp = "example_sentence_jp"
            case exampleSentenceEn = "example_sentence_en"
            case episodeFrequency = "episode_frequency"
        }
    }

    struct KanjiDTO: Decodable {
        let character: String
        let onReadings: [String]
        let kunReadings: [String]
        let meaning: String?
        let strokeCount: Int?
        let jlptLevel: Int?
        let grade: Int?

        enum CodingKeys: String, CodingKey {
            case character, meaning, grade
            case onReadings = "on_readings"
            case kunReadings = "kun_readings"
            case strokeCount = "stroke_count"
            case jlptLevel = "jlpt_level"
        }
    }

    struct GrammarDTO: Decodable {
        let pattern: String
        let explanation: String?
        let jlptLevel: Int?
        let examples: [GrammarExampleDTO]

        enum CodingKeys: String, CodingKey {
            case pattern, explanation, examples
            case jlptLevel = "jlpt_level"
        }
    }

    struct GrammarExampleDTO: Decodable {
        let japanese: String
        let reading: String?
        let english: String?
    }

    struct StatsDTO: Decodable {
        let totalLines: Int
        let uniqueWords: Int
        let uniqueKanji: Int
        let jlptBreakdown: [String: Int]

        enum CodingKeys: String, CodingKey {
            case totalLines = "total_lines"
            case uniqueWords = "unique_words"
            case uniqueKanji = "unique_kanji"
            case jlptBreakdown = "jlpt_breakdown"
        }
    }

    struct HealthResponse: Decodable {
        let status: String
    }

    // MARK: - Available Content DTOs

    struct AvailableMediaItemDTO: Decodable {
        let mediaId: String
        let mediaType: String
        let title: String
        let titleJapanese: String?
        let malId: Int?
        let tmdbId: Int?
        let totalEpisodes: Int?
        let processedEpisodes: Int
        let imageUrl: String?

        enum CodingKeys: String, CodingKey {
            case title
            case mediaId = "media_id"
            case mediaType = "media_type"
            case titleJapanese = "title_japanese"
            case malId = "mal_id"
            case tmdbId = "tmdb_id"
            case totalEpisodes = "total_episodes"
            case processedEpisodes = "processed_episodes"
            case imageUrl = "image_url"
        }
    }

    struct AvailableMediaResponseDTO: Decodable {
        let items: [AvailableMediaItemDTO]
        let total: Int
    }

    // MARK: - Pipeline DTOs

    struct PipelineHealthDTO: Decodable {
        let schedulerRunning: Bool
        let trackedMediaCount: Int
        let pendingJobs: Int
        let completedJobs: Int
        let failedJobs: Int

        enum CodingKeys: String, CodingKey {
            case schedulerRunning = "scheduler_running"
            case trackedMediaCount = "tracked_media_count"
            case pendingJobs = "pending_jobs"
            case completedJobs = "completed_jobs"
            case failedJobs = "failed_jobs"
        }
    }

    struct TrackedMediaDTO: Decodable {
        let id: Int
        let mediaId: String
        let mediaType: String
        let title: String
        let titleJapanese: String?
        let totalEpisodes: Int?
        let airedEpisodes: Int
        let status: String?
        let isActive: Bool
        let createdAt: String

        enum CodingKeys: String, CodingKey {
            case id, title, status
            case mediaId = "media_id"
            case mediaType = "media_type"
            case titleJapanese = "title_japanese"
            case totalEpisodes = "total_episodes"
            case airedEpisodes = "aired_episodes"
            case isActive = "is_active"
            case createdAt = "created_at"
        }
    }

    struct TrackedMediaListDTO: Decodable {
        let items: [TrackedMediaDTO]
        let total: Int
    }

    struct ContentJobDTO: Decodable {
        let id: Int
        let mediaId: String
        let episodeNumber: Int
        let status: String
        let source: String?
        let attempts: Int
        let maxAttempts: Int
        let lastError: String?
        let createdAt: String
        let startedAt: String?
        let completedAt: String?

        enum CodingKeys: String, CodingKey {
            case id, status, source, attempts
            case mediaId = "media_id"
            case episodeNumber = "episode_number"
            case maxAttempts = "max_attempts"
            case lastError = "last_error"
            case createdAt = "created_at"
            case startedAt = "started_at"
            case completedAt = "completed_at"
        }
    }

    struct ContentJobListDTO: Decodable {
        let items: [ContentJobDTO]
        let total: Int
    }

    struct TriggerResponseDTO: Decodable {
        let message: String
    }

    // MARK: - Public API

    func fetchEpisodeContent(mediaID: String, episodeNumber: Int) async throws -> EpisodeContentDTO {
        guard let url = URL(string: "\(baseURL)/media/\(mediaID)/episodes/\(episodeNumber)/content") else {
            throw APIError.invalidURL
        }
        return try await client.fetch(url)
    }

    func fetchMediaContent(mediaID: String) async throws -> MediaContentDTO {
        guard let url = URL(string: "\(baseURL)/media/\(mediaID)/content") else {
            throw APIError.invalidURL
        }
        return try await client.fetch(url)
    }

    func isReachable() async -> Bool {
        guard let url = URL(string: "\(baseURL)/health") else { return false }
        do {
            let response: HealthResponse = try await client.fetch(url)
            return response.status == "ok"
        } catch {
            return false
        }
    }

    // MARK: - Available Content API

    func fetchAvailableMedia(mediaType: String? = nil, limit: Int = 50) async throws -> AvailableMediaResponseDTO {
        var urlString = "\(baseURL)/media/available?limit=\(limit)"
        if let mediaType {
            urlString += "&media_type=\(mediaType)"
        }
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        return try await client.fetch(url)
    }

    // MARK: - Content Request DTOs

    struct ContentRequestResponseDTO: Decodable {
        let status: String
        let message: String
        let mediaId: String?
        let processedEpisodes: Int
        let pendingEpisodes: Int

        enum CodingKeys: String, CodingKey {
            case status, message
            case mediaId = "media_id"
            case processedEpisodes = "processed_episodes"
            case pendingEpisodes = "pending_episodes"
        }
    }

    // MARK: - Content Request API

    func requestContent(malId: Int, mediaType: String = "anime") async throws -> ContentRequestResponseDTO {
        guard let url = URL(string: "\(baseURL)/media/request") else {
            throw APIError.invalidURL
        }
        let body: [String: Any] = [
            "mal_id": malId,
            "media_type": mediaType,
        ]
        let data = try JSONSerialization.data(withJSONObject: body)
        return try await client.post(url, body: data, headers: ["Content-Type": "application/json"])
    }

    // MARK: - Pipeline API

    func fetchPipelineHealth() async throws -> PipelineHealthDTO {
        guard let url = URL(string: "\(baseURL)/pipeline/health") else {
            throw APIError.invalidURL
        }
        return try await client.fetch(url)
    }

    func fetchTrackedMedia(mediaType: String? = nil, limit: Int = 50) async throws -> TrackedMediaListDTO {
        var urlString = "\(baseURL)/pipeline/tracked?limit=\(limit)"
        if let mediaType {
            urlString += "&media_type=\(mediaType)"
        }
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        return try await client.fetch(url)
    }

    func fetchJobs(status: String? = nil, mediaId: String? = nil, limit: Int = 50) async throws -> ContentJobListDTO {
        var urlString = "\(baseURL)/pipeline/jobs?limit=\(limit)"
        if let status {
            urlString += "&status=\(status)"
        }
        if let mediaId {
            urlString += "&media_id=\(mediaId)"
        }
        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }
        return try await client.fetch(url)
    }

    func triggerDiscovery() async throws -> TriggerResponseDTO {
        guard let url = URL(string: "\(baseURL)/pipeline/trigger/discovery") else {
            throw APIError.invalidURL
        }
        return try await client.post(url, body: nil)
    }

    func triggerMonitor() async throws -> TriggerResponseDTO {
        guard let url = URL(string: "\(baseURL)/pipeline/trigger/monitor") else {
            throw APIError.invalidURL
        }
        return try await client.post(url, body: nil)
    }

    func triggerProcess() async throws -> TriggerResponseDTO {
        guard let url = URL(string: "\(baseURL)/pipeline/trigger/process") else {
            throw APIError.invalidURL
        }
        return try await client.post(url, body: nil)
    }
}
