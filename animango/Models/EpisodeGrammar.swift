import Foundation
import SwiftData

@Model
final class EpisodeGrammar {
    var episodeID: String
    var grammarPattern: String

    init(episodeID: String, grammarPattern: String) {
        self.episodeID = episodeID
        self.grammarPattern = grammarPattern
    }
}
