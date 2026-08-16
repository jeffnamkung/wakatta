import Foundation
import SwiftData

@Model
final class Media {
    @Attribute(.unique) var externalID: String
    var mediaType: MediaType
    var title: String
    var titleJapanese: String?
    var synopsis: String?
    var imageURL: String?
    var score: Double?
    var episodeCount: Int?
    var status: String?
    var genres: [String]
    var releaseYear: Int?
    var dateAdded: Date?
    var isInLibrary: Bool

    init(
        externalID: String,
        mediaType: MediaType,
        title: String,
        titleJapanese: String? = nil,
        synopsis: String? = nil,
        imageURL: String? = nil,
        score: Double? = nil,
        episodeCount: Int? = nil,
        status: String? = nil,
        genres: [String] = [],
        releaseYear: Int? = nil,
        dateAdded: Date? = nil,
        isInLibrary: Bool = false
    ) {
        self.externalID = externalID
        self.mediaType = mediaType
        self.title = title
        self.titleJapanese = titleJapanese
        self.synopsis = synopsis
        self.imageURL = imageURL
        self.score = score
        self.episodeCount = episodeCount
        self.status = status
        self.genres = genres
        self.releaseYear = releaseYear
        self.dateAdded = dateAdded
        self.isInLibrary = isInLibrary
    }
}
