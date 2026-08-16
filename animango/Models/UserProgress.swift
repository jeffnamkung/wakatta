import Foundation
import SwiftData

@Model
final class UserProgress {
    var itemID: String
    var itemType: StudyItemType
    var knowledgeState: KnowledgeState
    var nextReviewDate: Date?
    var easeFactor: Double
    var interval: Int
    var repetitions: Int
    var lastReviewedDate: Date?

    init(
        itemID: String,
        itemType: StudyItemType,
        knowledgeState: KnowledgeState = .unknown,
        nextReviewDate: Date? = nil,
        easeFactor: Double = 2.5,
        interval: Int = 0,
        repetitions: Int = 0,
        lastReviewedDate: Date? = nil
    ) {
        self.itemID = itemID
        self.itemType = itemType
        self.knowledgeState = knowledgeState
        self.nextReviewDate = nextReviewDate
        self.easeFactor = easeFactor
        self.interval = interval
        self.repetitions = repetitions
        self.lastReviewedDate = lastReviewedDate
    }
}
