import SwiftUI

extension Color {
    // JLPT level colors
    static func jlptColor(level: Int) -> Color {
        switch level {
        case 5: return .green
        case 4: return .teal
        case 3: return .blue
        case 2: return .purple
        case 1: return .red
        default: return .gray
        }
    }

    // Media type colors
    static func mediaTypeColor(_ type: MediaType) -> Color {
        switch type {
        case .anime: return .purple
        case .manga: return .pink
        case .game: return .blue
        case .jdrama: return .orange
        case .movie: return .indigo
        }
    }
}
