import Foundation
import SwiftData

struct VocabularyDataService {

    /// Get all vocabulary items for a specific media
    static func vocabulary(for mediaExternalID: String, modelContext: ModelContext) -> [VocabularyItem] {
        let predicate = #Predicate<MediaVocabulary> { $0.mediaExternalID == mediaExternalID }
        let descriptor = FetchDescriptor(predicate: predicate)
        let mappings = (try? modelContext.fetch(descriptor)) ?? []

        let words = Set(mappings.map(\.vocabularyWord))
        guard !words.isEmpty else { return [] }

        let allVocab = (try? modelContext.fetch(FetchDescriptor<VocabularyItem>())) ?? []
        return allVocab
            .filter { words.contains($0.word) }
            .sorted { ($0.frequency ?? Int.max) < ($1.frequency ?? Int.max) }
    }

    /// Get all vocabulary items the user has studied
    static func studiedVocabulary(modelContext: ModelContext) -> [VocabularyItem] {
        let type = StudyItemType.vocabulary
        let predicate = #Predicate<UserProgress> { $0.itemType == type }
        let descriptor = FetchDescriptor(predicate: predicate)
        let progress = (try? modelContext.fetch(descriptor)) ?? []

        let studiedWords = Set(progress.map(\.itemID))
        guard !studiedWords.isEmpty else { return [] }

        let allVocab = (try? modelContext.fetch(FetchDescriptor<VocabularyItem>())) ?? []
        return allVocab.filter { studiedWords.contains($0.word) }
    }
}
