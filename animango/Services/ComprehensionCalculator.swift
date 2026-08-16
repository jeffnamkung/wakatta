import Foundation
import SwiftData

struct ComprehensionCalculator {

    /// Calculate comprehension percentage for a specific media
    static func calculate(mediaExternalID: String, modelContext: ModelContext) -> Double {
        let predicate = #Predicate<MediaVocabulary> { $0.mediaExternalID == mediaExternalID }
        let descriptor = FetchDescriptor(predicate: predicate)
        let mappings = (try? modelContext.fetch(descriptor)) ?? []

        guard !mappings.isEmpty else { return 0 }

        let allProgress = (try? modelContext.fetch(FetchDescriptor<UserProgress>())) ?? []
        let progressByID = Dictionary(
            uniqueKeysWithValues: allProgress.map { ($0.itemID, $0) }
        )

        var totalWeight = 0.0
        var weightedScore = 0.0

        for mapping in mappings {
            let weight = Double(mapping.frequency)
            totalWeight += weight
            if let progress = progressByID[mapping.vocabularyWord] {
                weightedScore += progress.knowledgeState.comprehensionWeight * weight
            }
        }

        return totalWeight > 0 ? (weightedScore / totalWeight) * 100 : 0
    }

    /// Calculate comprehension for all library media
    static func calculateAll(modelContext: ModelContext) -> [String: Double] {
        let predicate = #Predicate<Media> { $0.isInLibrary == true }
        let descriptor = FetchDescriptor(predicate: predicate)
        let libraryMedia = (try? modelContext.fetch(descriptor)) ?? []

        var results: [String: Double] = [:]
        for media in libraryMedia {
            results[media.externalID] = calculate(
                mediaExternalID: media.externalID,
                modelContext: modelContext
            )
        }
        return results
    }
}
