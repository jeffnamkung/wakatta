import Foundation
import SwiftData

enum ExerciseType: String, Codable, CaseIterable {
    case vocabRecall
    case kanjiReading
    case grammarFill
    case translation
    case pronunciation

    var displayName: String {
        switch self {
        case .vocabRecall: return "Vocabulary"
        case .kanjiReading: return "Kanji Reading"
        case .grammarFill: return "Grammar"
        case .translation: return "Translation"
        case .pronunciation: return "Pronunciation"
        }
    }

    var iconName: String {
        switch self {
        case .vocabRecall: return "character.book.closed"
        case .kanjiReading: return "character.ja"
        case .grammarFill: return "text.insert"
        case .translation: return "arrow.left.arrow.right"
        case .pronunciation: return "mic.fill"
        }
    }
}

@Model
final class LessonExercise {
    @Attribute(.unique) var id: String
    var lessonID: String
    var exerciseType: ExerciseType
    var prompt: String
    var answer: String
    var hint: String?
    var order: Int

    init(
        id: String,
        lessonID: String,
        exerciseType: ExerciseType,
        prompt: String,
        answer: String,
        hint: String? = nil,
        order: Int
    ) {
        self.id = id
        self.lessonID = lessonID
        self.exerciseType = exerciseType
        self.prompt = prompt
        self.answer = answer
        self.hint = hint
        self.order = order
    }
}
