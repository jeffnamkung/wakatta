import Foundation

struct TMDBSearchResponse: Decodable, Sendable {
    let results: [TMDBShow]
    let page: Int
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case results, page
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDBShow: Decodable, Sendable {
    let id: Int
    let name: String
    let originalName: String?
    let overview: String?
    let posterPath: String?
    let voteAverage: Double?
    let firstAirDate: String?
    let genreIds: [Int]?
    let originCountry: [String]?
    let numberOfEpisodes: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, overview
        case originalName = "original_name"
        case posterPath = "poster_path"
        case voteAverage = "vote_average"
        case firstAirDate = "first_air_date"
        case genreIds = "genre_ids"
        case originCountry = "origin_country"
        case numberOfEpisodes = "number_of_episodes"
    }
}

struct TMDBMovieSearchResponse: Decodable, Sendable {
    let results: [TMDBMovie]
    let page: Int
    let totalPages: Int
    let totalResults: Int

    enum CodingKeys: String, CodingKey {
        case results, page
        case totalPages = "total_pages"
        case totalResults = "total_results"
    }
}

struct TMDBMovie: Decodable, Sendable {
    let id: Int
    let title: String
    let originalTitle: String?
    let overview: String?
    let posterPath: String?
    let voteAverage: Double?
    let releaseDate: String?
    let genreIds: [Int]?
    let originalLanguage: String?

    enum CodingKeys: String, CodingKey {
        case id, title, overview
        case originalTitle = "original_title"
        case posterPath = "poster_path"
        case voteAverage = "vote_average"
        case releaseDate = "release_date"
        case genreIds = "genre_ids"
        case originalLanguage = "original_language"
    }
}

actor TMDBService {
    private let client = APIClient()

    private func getHeaders() async -> [String: String] {
        let token = await MainActor.run { Config.tmdbAPIToken }
        return [
            "Authorization": "Bearer \(token)",
            "accept": "application/json"
        ]
    }

    func searchDrama(query: String, page: Int = 1) async throws -> (shows: [Media], hasNextPage: Bool) {
        let token = await MainActor.run { Config.tmdbAPIToken }
        guard !token.isEmpty else { return ([], false) }

        let baseURL = Config.tmdbBaseURL
        var components = URLComponents(string: "\(baseURL)/search/tv")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "language", value: "en-US")
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let headers = await getHeaders()
        let response: TMDBSearchResponse = try await client.fetch(url, headers: headers)

        let japaneseShows = response.results.filter { show in
            show.originCountry?.contains("JP") ?? false
        }

        let mediaItems = japaneseShows.map { $0.toMedia() }
        let hasNext = response.page < response.totalPages
        return (mediaItems, hasNext)
    }

    func discoverJDrama(page: Int = 1) async throws -> [Media] {
        let token = await MainActor.run { Config.tmdbAPIToken }
        guard !token.isEmpty else { return [] }

        let baseURL = Config.tmdbBaseURL
        var components = URLComponents(string: "\(baseURL)/discover/tv")!
        components.queryItems = [
            URLQueryItem(name: "with_origin_country", value: "JP"),
            URLQueryItem(name: "with_original_language", value: "ja"),
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "page", value: String(page))
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let headers = await getHeaders()
        let response: TMDBSearchResponse = try await client.fetch(url, headers: headers)
        return response.results.map { $0.toMedia() }
    }

    func searchMovies(query: String, page: Int = 1) async throws -> (movies: [Media], hasNextPage: Bool) {
        let token = await MainActor.run { Config.tmdbAPIToken }
        guard !token.isEmpty else { return ([], false) }

        let baseURL = Config.tmdbBaseURL
        var components = URLComponents(string: "\(baseURL)/search/movie")!
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "page", value: String(page)),
            URLQueryItem(name: "language", value: "en-US")
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let headers = await getHeaders()
        let response: TMDBMovieSearchResponse = try await client.fetch(url, headers: headers)

        let japaneseMovies = response.results.filter { movie in
            movie.originalLanguage == "ja"
        }

        let mediaItems = japaneseMovies.map { $0.toMedia() }
        let hasNext = response.page < response.totalPages
        return (mediaItems, hasNext)
    }

    func discoverJapaneseMovies(page: Int = 1) async throws -> [Media] {
        let token = await MainActor.run { Config.tmdbAPIToken }
        guard !token.isEmpty else { return [] }

        let baseURL = Config.tmdbBaseURL
        var components = URLComponents(string: "\(baseURL)/discover/movie")!
        components.queryItems = [
            URLQueryItem(name: "with_original_language", value: "ja"),
            URLQueryItem(name: "sort_by", value: "popularity.desc"),
            URLQueryItem(name: "page", value: String(page))
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        let headers = await getHeaders()
        let response: TMDBMovieSearchResponse = try await client.fetch(url, headers: headers)
        return response.results.map { $0.toMedia() }
    }
}

extension TMDBMovie {
    func toMedia() -> Media {
        let imageURL = posterPath.map { "\(Config.tmdbImageBaseURL)/w500\($0)" }
        let year: Int? = releaseDate.flatMap { dateStr in
            let components = dateStr.split(separator: "-")
            return components.first.flatMap { Int($0) }
        }

        return Media(
            externalID: "movie_\(id)",
            mediaType: .movie,
            title: title,
            titleJapanese: originalTitle,
            synopsis: overview,
            imageURL: imageURL,
            score: voteAverage,
            episodeCount: nil,
            genres: [],
            releaseYear: year,
            isInLibrary: false
        )
    }
}

extension TMDBShow {
    func toMedia() -> Media {
        let imageURL = posterPath.map { "\(Config.tmdbImageBaseURL)/w500\($0)" }
        let year: Int? = firstAirDate.flatMap { dateStr in
            let components = dateStr.split(separator: "-")
            return components.first.flatMap { Int($0) }
        }

        return Media(
            externalID: "drama_\(id)",
            mediaType: .jdrama,
            title: name,
            titleJapanese: originalName,
            synopsis: overview,
            imageURL: imageURL,
            score: voteAverage,
            episodeCount: numberOfEpisodes,
            genres: [],
            releaseYear: year,
            isInLibrary: false
        )
    }
}
