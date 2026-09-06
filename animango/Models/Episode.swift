import Foundation
import SwiftData

@Model
final class Episode {
    @Attribute(.unique) var id: String
    var mediaExternalID: String
    var episodeNumber: Int
    var title: String
    var titleJapanese: String?
    var synopsis: String?
    var airDate: String?

    init(
        id: String,
        mediaExternalID: String,
        episodeNumber: Int,
        title: String,
        titleJapanese: String? = nil,
        synopsis: String? = nil,
        airDate: String? = nil
    ) {
        self.id = id
        self.mediaExternalID = mediaExternalID
        self.episodeNumber = episodeNumber
        self.title = title
        self.titleJapanese = titleJapanese
        self.synopsis = synopsis
        self.airDate = airDate
    }
}
