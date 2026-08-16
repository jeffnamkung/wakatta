import Foundation
import SwiftData

@Model
final class MediaGrammar {
    var mediaExternalID: String
    var grammarPattern: String

    init(
        mediaExternalID: String,
        grammarPattern: String
    ) {
        self.mediaExternalID = mediaExternalID
        self.grammarPattern = grammarPattern
    }
}
