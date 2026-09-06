import Foundation
import SwiftData

@Model
final class EpisodeVocabulary {
    var episodeID: String
    var vocabularyWord: String
    var frequency: Int

    init(episodeID: String, vocabularyWord: String, frequency: Int = 1) {
        self.episodeID = episodeID
        self.vocabularyWord = vocabularyWord
        self.frequency = frequency
    }
}
