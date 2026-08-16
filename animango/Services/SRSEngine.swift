import Foundation

/// SM-2 based spaced repetition engine
struct SRSEngine {

    enum Grade: Int, CaseIterable {
        case again = 0
        case hard = 3
        case good = 4
        case easy = 5

        var displayName: String {
            switch self {
            case .again: return "Again"
            case .hard: return "Hard"
            case .good: return "Good"
            case .easy: return "Easy"
            }
        }
    }

    /// Process a review and update the user's progress
    static func processReview(progress: UserProgress, grade: Grade) -> UserProgress {
        let quality = Double(grade.rawValue)

        var newEaseFactor = progress.easeFactor + (0.1 - (5.0 - quality) * (0.08 + (5.0 - quality) * 0.02))
        newEaseFactor = max(1.3, newEaseFactor)

        var newInterval: Int
        var newRepetitions: Int
        var newState: KnowledgeState

        if grade == .again {
            // Reset — card goes back to learning
            newInterval = 1
            newRepetitions = 0
            newState = .learning
        } else {
            newRepetitions = progress.repetitions + 1

            switch newRepetitions {
            case 1:
                newInterval = 1
            case 2:
                newInterval = 3
            default:
                newInterval = Int(Double(progress.interval) * newEaseFactor)
            }

            if grade == .hard {
                newInterval = max(1, Int(Double(newInterval) * 0.8))
            } else if grade == .easy {
                newInterval = Int(Double(newInterval) * 1.3)
            }

            // Determine knowledge state based on repetition count
            if newRepetitions >= 4 {
                newState = .known
            } else {
                newState = .learning
            }
        }

        progress.easeFactor = newEaseFactor
        progress.interval = newInterval
        progress.repetitions = newRepetitions
        progress.knowledgeState = newState
        progress.lastReviewedDate = Date()
        progress.nextReviewDate = Calendar.current.date(
            byAdding: .day,
            value: newInterval,
            to: Date()
        )

        return progress
    }

    /// Get items that are due for review
    static func dueItems(from progress: [UserProgress]) -> [UserProgress] {
        let now = Date()
        return progress.filter { item in
            guard let nextReview = item.nextReviewDate else {
                return item.knowledgeState != .known
            }
            return nextReview <= now
        }
    }
}
