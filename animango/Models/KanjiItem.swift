import Foundation
import SwiftData

@Model
final class KanjiItem {
    @Attribute(.unique) var character: String
    var onReadings: [String]
    var kunReadings: [String]
    var meaning: String
    var strokeCount: Int
    var jlptLevel: Int?
    var grade: Int?

    init(
        character: String,
        onReadings: [String] = [],
        kunReadings: [String] = [],
        meaning: String,
        strokeCount: Int,
        jlptLevel: Int? = nil,
        grade: Int? = nil
    ) {
        self.character = character
        self.onReadings = onReadings
        self.kunReadings = kunReadings
        self.meaning = meaning
        self.strokeCount = strokeCount
        self.jlptLevel = jlptLevel
        self.grade = grade
    }
}
