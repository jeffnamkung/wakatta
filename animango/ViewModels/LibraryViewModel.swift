import Foundation
import SwiftData

@Observable
final class LibraryViewModel {
    var comprehensionScores: [String: Double] = [:]
    var selectedType: MediaType?
    var sortOrder: SortOrder = .dateAdded

    enum SortOrder: String, CaseIterable {
        case dateAdded = "Date Added"
        case title = "Title"
        case comprehension = "Comprehension"

        var iconName: String {
            switch self {
            case .dateAdded: return "calendar"
            case .title: return "textformat.abc"
            case .comprehension: return "chart.bar"
            }
        }
    }

    func refreshComprehension(modelContext: ModelContext) {
        comprehensionScores = ComprehensionCalculator.calculateAll(modelContext: modelContext)
    }

    func comprehension(for media: Media) -> Double {
        comprehensionScores[media.externalID] ?? 0
    }

    func sortedMedia(_ media: [Media]) -> [Media] {
        var filtered = media
        if let type = selectedType {
            filtered = filtered.filter { $0.mediaType == type }
        }

        switch sortOrder {
        case .dateAdded:
            return filtered.sorted { ($0.dateAdded ?? .distantPast) > ($1.dateAdded ?? .distantPast) }
        case .title:
            return filtered.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .comprehension:
            return filtered.sorted { comprehension(for: $0) > comprehension(for: $1) }
        }
    }

    func removeFromLibrary(_ media: Media, modelContext: ModelContext) {
        media.isInLibrary = false
        media.dateAdded = nil
        try? modelContext.save()
    }
}
