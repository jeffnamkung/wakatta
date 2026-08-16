import Foundation
import SwiftData

@Observable
final class ProfileViewModel {
    var totalKnownWords = 0
    var totalLearningWords = 0
    var totalKnownKanji = 0
    var totalLearningKanji = 0
    var totalGrammarStudied = 0
    var studyStreak = 0
    var jlptBreakdown: [Int: (known: Int, learning: Int, total: Int)] = [:]
    var recentActivity: [UserProgress] = []

    func loadStats(modelContext: ModelContext) {
        let allProgress = (try? modelContext.fetch(FetchDescriptor<UserProgress>())) ?? []

        let vocabType = StudyItemType.vocabulary
        let kanjiType = StudyItemType.kanji
        let grammarType = StudyItemType.grammar

        let vocabProgress = allProgress.filter { $0.itemType == vocabType }
        let kanjiProgress = allProgress.filter { $0.itemType == kanjiType }
        let grammarProgress = allProgress.filter { $0.itemType == grammarType }

        totalKnownWords = vocabProgress.filter { $0.knowledgeState == .known }.count
        totalLearningWords = vocabProgress.filter { $0.knowledgeState == .learning }.count
        totalKnownKanji = kanjiProgress.filter { $0.knowledgeState == .known }.count
        totalLearningKanji = kanjiProgress.filter { $0.knowledgeState == .learning }.count
        totalGrammarStudied = grammarProgress.count

        // JLPT breakdown from vocabulary
        let allVocab = (try? modelContext.fetch(FetchDescriptor<VocabularyItem>())) ?? []
        let progressByID = Dictionary(uniqueKeysWithValues: vocabProgress.map { ($0.itemID, $0) })

        var breakdown: [Int: (known: Int, learning: Int, total: Int)] = [:]
        for level in 1...5 {
            let levelVocab = allVocab.filter { $0.jlptLevel == level }
            let known = levelVocab.filter { progressByID[$0.word]?.knowledgeState == .known }.count
            let learning = levelVocab.filter { progressByID[$0.word]?.knowledgeState == .learning }.count
            breakdown[level] = (known: known, learning: learning, total: levelVocab.count)
        }
        jlptBreakdown = breakdown

        // Calculate streak
        calculateStreak(from: allProgress)

        // Recent activity
        recentActivity = allProgress
            .filter { $0.lastReviewedDate != nil }
            .sorted { ($0.lastReviewedDate ?? .distantPast) > ($1.lastReviewedDate ?? .distantPast) }
            .prefix(10)
            .map { $0 }
    }

    private func calculateStreak(from progress: [UserProgress]) {
        let reviewDates = Set(progress.compactMap { prog -> String? in
            guard let date = prog.lastReviewedDate else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: date)
        })

        var streak = 0
        var date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        while reviewDates.contains(formatter.string(from: date)) {
            streak += 1
            date = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        }

        studyStreak = streak
    }
}
