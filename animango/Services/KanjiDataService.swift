import Foundation
import SwiftData

struct KanjiDataService {

    /// Get all kanji items for a specific media
    static func kanji(for mediaExternalID: String, modelContext: ModelContext) -> [KanjiItem] {
        let predicate = #Predicate<MediaKanji> { $0.mediaExternalID == mediaExternalID }
        let descriptor = FetchDescriptor(predicate: predicate)
        let mappings = (try? modelContext.fetch(descriptor)) ?? []

        let chars = Set(mappings.map(\.kanjiCharacter))
        guard !chars.isEmpty else { return [] }

        let allKanji = (try? modelContext.fetch(FetchDescriptor<KanjiItem>())) ?? []
        return allKanji
            .filter { chars.contains($0.character) }
            .sorted { ($0.jlptLevel ?? 0) > ($1.jlptLevel ?? 0) }
    }

    /// Get all kanji the user has studied
    static func studiedKanji(modelContext: ModelContext) -> [KanjiItem] {
        let type = StudyItemType.kanji
        let predicate = #Predicate<UserProgress> { $0.itemType == type }
        let descriptor = FetchDescriptor(predicate: predicate)
        let progress = (try? modelContext.fetch(descriptor)) ?? []

        let studiedChars = Set(progress.map(\.itemID))
        guard !studiedChars.isEmpty else { return [] }

        let allKanji = (try? modelContext.fetch(FetchDescriptor<KanjiItem>())) ?? []
        return allKanji.filter { studiedChars.contains($0.character) }
    }
}
