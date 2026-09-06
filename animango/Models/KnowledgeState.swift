import Foundation
import SwiftUI

enum KnowledgeState: String, Codable, CaseIterable {
    case neverLearned
    case learning
    case developing
    case mastered

    var displayName: String {
        switch self {
        case .neverLearned: return "Never Learned"
        case .learning: return "Learning"
        case .developing: return "Needs Work"
        case .mastered: return "Mastered"
        }
    }

    var shortName: String {
        switch self {
        case .neverLearned: return "New"
        case .learning: return "Learning"
        case .developing: return "Developing"
        case .mastered: return "Mastered"
        }
    }

    var iconName: String {
        switch self {
        case .neverLearned: return "circle"
        case .learning: return "circle.lefthalf.filled"
        case .developing: return "circle.inset.filled"
        case .mastered: return "checkmark.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .neverLearned: return .gray
        case .learning: return .orange
        case .developing: return .blue
        case .mastered: return .green
        }
    }

    /// Weight used in comprehension calculation
    var comprehensionWeight: Double {
        switch self {
        case .neverLearned: return 0.0
        case .learning: return 0.3
        case .developing: return 0.7
        case .mastered: return 1.0
        }
    }
}
