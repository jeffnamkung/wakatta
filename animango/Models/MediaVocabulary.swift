import Foundation
import SwiftData

@Model
final class MediaVocabulary {
    var mediaExternalID: String
    var vocabularyWord: String
    var frequency: Int

    init(
        mediaExternalID: String,
        vocabularyWord: String,
        frequency: Int = 1
    ) {
        self.mediaExternalID = mediaExternalID
        self.vocabularyWord = vocabularyWord
        self.frequency = frequency
    }
}
