import Foundation

actor JikanService {
    private let client = APIClient()
    private var lastRequestTime: Date = .distantPast

    /// Enforce Jikan's rate limit of ~3 requests/second
    private func throttle() async {
        let elapsed = Date().timeIntervalSince(lastRequestTime)
        if elapsed < 0.35 {
            try? await Task.sleep(for: .milliseconds(Int((0.35 - elapsed) * 1000)))
        }
        lastRequestTime = Date()
    }

    // MARK: - Anime

    func searchAnime(query: String, page: Int = 1) async throws -> (anime: [Media], hasNextPage: Bool) {
        await throttle()

        var components = URLComponents(string: "\(Config.jikanBaseURL)/anime")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "sfw", value: "true")
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let response: JikanSearchResponse = try await client.fetch(url)
        let mediaItems = response.data.map { $0.toMedia() }
        let hasNext = response.pagination?.hasNextPage ?? false
        return (mediaItems, hasNext)
    }

    func getAnimeDetail(malID: Int) async throws -> Media {
        await throttle()

        guard let url = URL(string: "\(Config.jikanBaseURL)/anime/\(malID)") else {
            throw APIError.invalidURL
        }

        let response: JikanAnimeDetailResponse = try await client.fetch(url)
        return response.data.toMedia()
    }

    func getTopAnime(page: Int = 1) async throws -> [Media] {
        await throttle()

        var components = URLComponents(string: "\(Config.jikanBaseURL)/top/anime")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "sfw", value: "true")
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let response: JikanSearchResponse = try await client.fetch(url)
        return response.data.map { $0.toMedia() }
    }

    func getSeasonalAnime(year: Int, season: String) async throws -> [Media] {
        await throttle()

        guard let url = URL(string: "\(Config.jikanBaseURL)/seasons/\(year)/\(season)") else {
            throw APIError.invalidURL
        }

        let response: JikanSearchResponse = try await client.fetch(url)
        return response.data.map { $0.toMedia() }
    }

    // MARK: - Manga

    func searchManga(query: String, page: Int = 1) async throws -> (manga: [Media], hasNextPage: Bool) {
        await throttle()

        var components = URLComponents(string: "\(Config.jikanBaseURL)/manga")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "sfw", value: "true")
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let response: JikanMangaSearchResponse = try await client.fetch(url)
        let mediaItems = response.data.map { $0.toMedia() }
        let hasNext = response.pagination?.hasNextPage ?? false
        return (mediaItems, hasNext)
    }

    func getMangaDetail(malID: Int) async throws -> Media {
        await throttle()

        guard let url = URL(string: "\(Config.jikanBaseURL)/manga/\(malID)") else {
            throw APIError.invalidURL
        }

        let response: JikanMangaDetailResponse = try await client.fetch(url)
        return response.data.toMedia()
    }

    func getTopManga(page: Int = 1) async throws -> [Media] {
        await throttle()

        var components = URLComponents(string: "\(Config.jikanBaseURL)/top/manga")!
        components.queryItems = [
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "limit", value: "20"),
            URLQueryItem(name: "sfw", value: "true")
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let response: JikanMangaSearchResponse = try await client.fetch(url)
        return response.data.map { $0.toMedia() }
    }
}

// MARK: - DTO to Domain Mapping

extension JikanAnime {
    func toMedia() -> Media {
        Media(
            externalID: "anime_\(malID)",
            mediaType: .anime,
            title: titleEnglish ?? title,
            titleJapanese: titleJapanese,
            synopsis: synopsis,
            imageURL: images?.jpg?.largeImageURL ?? images?.jpg?.imageURL,
            score: score,
            episodeCount: episodes,
            status: status,
            genres: genres?.map(\.name) ?? [],
            releaseYear: year,
            isInLibrary: false
        )
    }
}

extension JikanManga {
    func toMedia() -> Media {
        let releaseYear: Int? = published?.from.flatMap { dateStr in
            let components = dateStr.split(separator: "-")
            return components.first.flatMap { Int($0) }
        }

        return Media(
            externalID: "manga_\(malID)",
            mediaType: .manga,
            title: titleEnglish ?? title,
            titleJapanese: titleJapanese,
            synopsis: synopsis,
            imageURL: images?.jpg?.largeImageURL ?? images?.jpg?.imageURL,
            score: score,
            episodeCount: chapters,
            status: status,
            genres: genres?.map(\.name) ?? [],
            releaseYear: releaseYear,
            isInLibrary: false
        )
    }
}
