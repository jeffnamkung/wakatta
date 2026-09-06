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
}
