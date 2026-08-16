import Foundation

enum StudyItemType: String, Codable, CaseIterable {
    case vocabulary
    case kanji
    case grammar

    var displayName: String {
        switch self {
        case .vocabulary: return "Vocabulary"
        case .kanji: return "Kanji"
        case .grammar: return "Grammar"
        }
    }

    var iconName: String {
        switch self {
        case .vocabulary: return "text.book.closed"
        case .kanji: return "character.ja"
        case .grammar: return "text.alignleft"
        }
    }
}
