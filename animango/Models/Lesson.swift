import Foundation
import SwiftData

@Model
final class Lesson {
    @Attribute(.unique) var id: String
    var episodeID: String
    var grammarPattern: String
    var title: String
    var order: Int

    init(
        id: String,
        episodeID: String,
        grammarPattern: String,
        title: String,
        order: Int
    ) {
        self.id = id
        self.episodeID = episodeID
        self.grammarPattern = grammarPattern
        self.title = title
        self.order = order
    }
}
