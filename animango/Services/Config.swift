import Foundation

enum Config {
    // MARK: - Jikan API (no auth needed)
    static let jikanBaseURL = "https://api.jikan.moe/v4"

    // MARK: - TMDB API
    static let tmdbBaseURL = "https://api.themoviedb.org/3"
    static let tmdbImageBaseURL = "https://image.tmdb.org/t/p"

    static var tmdbAPIToken: String {
        Bundle.main.infoDictionary?["TMDB_API_TOKEN"] as? String ?? ""
    }

    // MARK: - IGDB API
    static let igdbBaseURL = "https://api.igdb.com/v4"
    static let twitchTokenURL = "https://id.twitch.tv/oauth2/token"

    static var igdbClientID: String {
        Bundle.main.infoDictionary?["IGDB_CLIENT_ID"] as? String ?? ""
    }
    static var igdbClientSecret: String {
        Bundle.main.infoDictionary?["IGDB_CLIENT_SECRET"] as? String ?? ""
    }
}
