import Foundation

enum KnowledgeState: String, Codable, CaseIterable {
    case unknown
    case learning
    case known

    var displayName: String {
        switch self {
        case .unknown: return "New"
        case .learning: return "Learning"
        case .known: return "Known"
        }
    }

    /// Weight used in comprehension calculation
    var comprehensionWeight: Double {
        switch self {
        case .unknown: return 0.0
        case .learning: return 0.5
        case .known: return 1.0
        }
    }
}
