import Foundation
import SwiftData

@Observable
final class VocabularyListViewModel {
    var vocabularyItems: [VocabularyItem] = []
    var progressMap: [String: UserProgress] = [:]
    var filterState: KnowledgeState?
    var searchText = ""

    var filteredItems: [VocabularyItem] {
        var items = vocabularyItems

        if let filter = filterState {
            items = items.filter { vocab in
                let state = progressMap[vocab.word]?.knowledgeState ?? .unknown
                return state == filter
            }
        }

        if !searchText.isEmpty {
            items = items.filter { vocab in
                vocab.word.localizedCaseInsensitiveContains(searchText) ||
                vocab.reading.localizedCaseInsensitiveContains(searchText) ||
                vocab.meaning.localizedCaseInsensitiveContains(searchText)
            }
        }

        return items
    }

    var knownCount: Int {
        vocabularyItems.filter { progressMap[$0.word]?.knowledgeState == .known }.count
    }

    var learningCount: Int {
        vocabularyItems.filter { progressMap[$0.word]?.knowledgeState == .learning }.count
    }

    var unknownCount: Int {
        vocabularyItems.count - knownCount - learningCount
    }

    func loadVocabulary(for media: Media, modelContext: ModelContext) {
        let mediaID = media.externalID
        let predicate = #Predicate<MediaVocabulary> { $0.mediaExternalID == mediaID }
        let descriptor = FetchDescriptor(predicate: predicate)
        let mappings = (try? modelContext.fetch(descriptor)) ?? []

        let words = Set(mappings.map(\.vocabularyWord))
        if !words.isEmpty {
            let allVocab = (try? modelContext.fetch(FetchDescriptor<VocabularyItem>())) ?? []
            vocabularyItems = allVocab.filter { words.contains($0.word) }
        }

        // Load user progress
        let allProgress = (try? modelContext.fetch(FetchDescriptor<UserProgress>())) ?? []
        progressMap = Dictionary(
            uniqueKeysWithValues: allProgress
                .filter { $0.itemType == .vocabulary }
                .map { ($0.itemID, $0) }
        )
    }

    func knowledgeState(for word: String) -> KnowledgeState {
        progressMap[word]?.knowledgeState ?? .unknown
    }
}
