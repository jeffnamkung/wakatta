import Foundation

struct IGDBGame: Decodable, Sendable {
    let id: Int
    let name: String
    let summary: String?
    let cover: IGDBCover?
    let genres: [IGDBGenre]?
    let firstReleaseDate: TimeInterval?
    let rating: Double?

    enum CodingKeys: String, CodingKey {
        case id, name, summary, cover, genres, rating
        case firstReleaseDate = "first_release_date"
    }
}

struct IGDBCover: Decodable, Sendable {
    let url: String?
}

struct IGDBGenre: Decodable, Sendable {
    let id: Int
    let name: String
}

actor IGDBService {
    private let client = APIClient()
    private var accessToken: String?
    private var tokenExpiresAt: Date?

    private func ensureToken() async throws {
        let clientID = await MainActor.run { Config.igdbClientID }
        let clientSecret = await MainActor.run { Config.igdbClientSecret }
        guard !clientID.isEmpty, !clientSecret.isEmpty else { return }

        if let _ = accessToken, let expiry = tokenExpiresAt, expiry > Date() {
            return
        }

        var components = URLComponents(string: Config.twitchTokenURL)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "client_secret", value: clientSecret),
            URLQueryItem(name: "grant_type", value: "client_credentials")
        ]

        guard let url = components.url else { throw APIError.invalidURL }

        struct TokenResponse: Decodable, Sendable {
            let accessToken: String
            let expiresIn: Int
            enum CodingKeys: String, CodingKey {
                case accessToken = "access_token"
                case expiresIn = "expires_in"
            }
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        let response: TokenResponse = try await client.fetch(request)
        accessToken = response.accessToken
        tokenExpiresAt = Date().addingTimeInterval(TimeInterval(response.expiresIn - 300))
    }

    func searchGames(query: String) async throws -> [Media] {
        let clientID = await MainActor.run { Config.igdbClientID }
        guard !clientID.isEmpty else { return [] }

        try await ensureToken()
        guard let currentToken = accessToken else { return [] }

        guard let url = URL(string: "\(Config.igdbBaseURL)/games") else {
            throw APIError.invalidURL
        }

        let body = """
        search "\(query)";
        fields name,summary,cover.url,genres.name,first_release_date,rating;
        limit 20;
        """

        let headers = [
            "Client-ID": clientID,
            "Authorization": "Bearer \(currentToken)",
            "Content-Type": "text/plain"
        ]

        let games: [IGDBGame] = try await client.post(
            url,
            body: body.data(using: .utf8),
            headers: headers
        )

        return games.map { $0.toMedia() }
    }
}

extension IGDBGame {
    func toMedia() -> Media {
        let imageURL = cover?.url.map { url in
            "https:\(url.replacingOccurrences(of: "t_thumb", with: "t_cover_big"))"
        }
        let year: Int? = firstReleaseDate.map { timestamp in
            Calendar.current.component(.year, from: Date(timeIntervalSince1970: timestamp))
        }

        return Media(
            externalID: "game_\(id)",
            mediaType: .game,
            title: name,
            synopsis: summary,
            imageURL: imageURL,
            score: rating.map { $0 / 10.0 },
            genres: genres?.map(\.name) ?? [],
            releaseYear: year,
            isInLibrary: false
        )
    }
}
