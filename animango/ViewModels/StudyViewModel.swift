import Foundation
import SwiftData

@Observable
final class StudyViewModel {
    var selectedMedia: Media?
    var selectedSessionType: StudyItemType?
    var dueItemCount = 0
    var showingSession = false

    func loadDueItems(modelContext: ModelContext) {
        let allProgress = (try? modelContext.fetch(FetchDescriptor<UserProgress>())) ?? []
        dueItemCount = SRSEngine.dueItems(from: allProgress).count

        // Also count items with no progress (new items)
        let progressedItems = Set(allProgress.map(\.itemID))

        let allVocab = (try? modelContext.fetch(FetchDescriptor<VocabularyItem>())) ?? []
        let allKanji = (try? modelContext.fetch(FetchDescriptor<KanjiItem>())) ?? []
        let allGrammar = (try? modelContext.fetch(FetchDescriptor<GrammarPoint>())) ?? []

        let newVocab = allVocab.filter { !progressedItems.contains($0.word) }.count
        let newKanji = allKanji.filter { !progressedItems.contains($0.character) }.count
        let newGrammar = allGrammar.filter { !progressedItems.contains($0.pattern) }.count

        dueItemCount += newVocab + newKanji + newGrammar
    }
}
