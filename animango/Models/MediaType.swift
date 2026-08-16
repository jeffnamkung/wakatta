import Foundation

enum MediaType: String, Codable, CaseIterable, Identifiable {
    case anime
    case manga
    case game
    case jdrama

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anime: return "Anime"
        case .manga: return "Manga"
        case .game: return "Games"
        case .jdrama: return "JDrama"
        }
    }

    var iconName: String {
        switch self {
        case .anime: return "sparkles.tv"
        case .manga: return "book.closed"
        case .game: return "gamecontroller"
        case .jdrama: return "tv"
        }
    }
}
