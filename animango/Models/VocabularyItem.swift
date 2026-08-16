import Foundation
import SwiftData

@Model
final class VocabularyItem {
    @Attribute(.unique) var word: String
    var reading: String
    var meaning: String
    var jlptLevel: Int?
    var frequency: Int?
    var partOfSpeech: String?
    var exampleSentenceJP: String?
    var exampleSentenceEN: String?

    init(
        word: String,
        reading: String,
        meaning: String,
        jlptLevel: Int? = nil,
        frequency: Int? = nil,
        partOfSpeech: String? = nil,
        exampleSentenceJP: String? = nil,
        exampleSentenceEN: String? = nil
    ) {
        self.word = word
        self.reading = reading
        self.meaning = meaning
        self.jlptLevel = jlptLevel
        self.frequency = frequency
        self.partOfSpeech = partOfSpeech
        self.exampleSentenceJP = exampleSentenceJP
        self.exampleSentenceEN = exampleSentenceEN
    }
}
