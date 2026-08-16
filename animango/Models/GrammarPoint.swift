import Foundation
import SwiftData

struct GrammarExample: Codable, Hashable {
    var japanese: String
    var reading: String
    var english: String
}

@Model
final class GrammarPoint {
    @Attribute(.unique) var pattern: String
    var explanation: String
    var jlptLevel: Int?
    var examples: [GrammarExample]

    init(
        pattern: String,
        explanation: String,
        jlptLevel: Int? = nil,
        examples: [GrammarExample] = []
    ) {
        self.pattern = pattern
        self.explanation = explanation
        self.jlptLevel = jlptLevel
        self.examples = examples
    }
}
