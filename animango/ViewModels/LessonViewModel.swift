import Foundation
import SwiftData

@Observable
final class LessonViewModel {
    var lesson: Lesson?
    var grammarPoint: GrammarPoint?
    var exercises: [LessonExercise] = []
    var currentExerciseIndex = 0
    var userAnswer = ""
    var isAnswerRevealed = false
    var showingGrammarIntro = true
    var isLessonComplete = false
    var correctCount = 0
    var totalAttempted = 0

    var currentExercise: LessonExercise? {
        guard currentExerciseIndex < exercises.count else { return nil }
        return exercises[currentExerciseIndex]
    }

    var progress: Double {
        guard !exercises.isEmpty else { return 0 }
        return Double(currentExerciseIndex) / Double(exercises.count)
    }

    func loadLesson(_ lesson: Lesson, modelContext: ModelContext) {
        self.lesson = lesson
        showingGrammarIntro = true
        currentExerciseIndex = 0
        isAnswerRevealed = false
        isLessonComplete = false
        correctCount = 0
        totalAttempted = 0
        userAnswer = ""

        // Fetch the grammar point
        let pattern = lesson.grammarPattern
        let grammarPredicate = #Predicate<GrammarPoint> { $0.pattern == pattern }
        grammarPoint = (try? modelContext.fetch(FetchDescriptor(predicate: grammarPredicate)))?.first

        // Fetch exercises
        let lessonID = lesson.id
        let exercisePredicate = #Predicate<LessonExercise> { $0.lessonID == lessonID }
        var descriptor = FetchDescriptor(predicate: exercisePredicate)
        descriptor.sortBy = [SortDescriptor(\.order)]
        exercises = (try? modelContext.fetch(descriptor)) ?? []
    }

    func startExercises() {
        showingGrammarIntro = false
    }

    func checkAnswer() {
        isAnswerRevealed = true
        totalAttempted += 1
        let trimmedAnswer = userAnswer.trimmingCharacters(in: .whitespaces).lowercased()
        let correctAnswer = currentExercise?.answer.lowercased() ?? ""
        if trimmedAnswer == correctAnswer {
            correctCount += 1
        }
    }

    func nextExercise() {
        currentExerciseIndex += 1
        userAnswer = ""
        isAnswerRevealed = false
        if currentExerciseIndex >= exercises.count {
            isLessonComplete = true
        }
    }

    func pronunciationCompleted(score: Double) {
        totalAttempted += 1
        if score >= 0.6 {
            correctCount += 1
        }
        nextExercise()
    }
}
