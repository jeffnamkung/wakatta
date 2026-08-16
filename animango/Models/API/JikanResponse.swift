import Foundation

// MARK: - Shared Response Types

struct JikanPagination: Decodable, Sendable {
    let lastVisiblePage: Int?
    let hasNextPage: Bool?

    enum CodingKeys: String, CodingKey {
        case lastVisiblePage = "last_visible_page"
        case hasNextPage = "has_next_page"
    }
}

struct JikanImages: Decodable, Sendable {
    let jpg: JikanImageURLs?

    struct JikanImageURLs: Decodable, Sendable {
        let imageURL: String?
        let smallImageURL: String?
        let largeImageURL: String?

        enum CodingKeys: String, CodingKey {
            case imageURL = "image_url"
            case smallImageURL = "small_image_url"
            case largeImageURL = "large_image_url"
        }
    }
}

struct JikanGenre: Decodable, Sendable {
    let malID: Int
    let name: String

    enum CodingKeys: String, CodingKey {
        case malID = "mal_id"
        case name
    }
}

// MARK: - Anime

struct JikanSearchResponse: Decodable, Sendable {
    let data: [JikanAnime]
    let pagination: JikanPagination?
}

struct JikanAnime: Decodable, Sendable {
    let malID: Int
    let title: String
    let titleEnglish: String?
    let titleJapanese: String?
    let images: JikanImages?
    let synopsis: String?
    let episodes: Int?
    let score: Double?
    let status: String?
    let year: Int?
    let genres: [JikanGenre]?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case malID = "mal_id"
        case title
        case titleEnglish = "title_english"
        case titleJapanese = "title_japanese"
        case images, synopsis, episodes, score, status, year, genres, type
    }
}

struct JikanAnimeDetailResponse: Decodable, Sendable {
    let data: JikanAnime
}

// MARK: - Manga

struct JikanMangaSearchResponse: Decodable, Sendable {
    let data: [JikanManga]
    let pagination: JikanPagination?
}

struct JikanManga: Decodable, Sendable {
    let malID: Int
    let title: String
    let titleEnglish: String?
    let titleJapanese: String?
    let images: JikanImages?
    let synopsis: String?
    let chapters: Int?
    let volumes: Int?
    let score: Double?
    let status: String?
    let genres: [JikanGenre]?
    let type: String?
    let published: JikanPublished?

    enum CodingKeys: String, CodingKey {
        case malID = "mal_id"
        case title
        case titleEnglish = "title_english"
        case titleJapanese = "title_japanese"
        case images, synopsis, chapters, volumes, score, status, genres, type, published
    }
}

struct JikanPublished: Decodable, Sendable {
    let from: String?
}

struct JikanMangaDetailResponse: Decodable, Sendable {
    let data: JikanManga
}
