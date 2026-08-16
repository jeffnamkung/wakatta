import Foundation
import SwiftData

@Model
final class MediaKanji {
    var mediaExternalID: String
    var kanjiCharacter: String

    init(
        mediaExternalID: String,
        kanjiCharacter: String
    ) {
        self.mediaExternalID = mediaExternalID
        self.kanjiCharacter = kanjiCharacter
    }
}
