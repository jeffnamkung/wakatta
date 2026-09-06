import Foundation
import SwiftData

@Model
final class EpisodeKanji {
    var episodeID: String
    var kanjiCharacter: String

    init(episodeID: String, kanjiCharacter: String) {
        self.episodeID = episodeID
        self.kanjiCharacter = kanjiCharacter
    }
}
