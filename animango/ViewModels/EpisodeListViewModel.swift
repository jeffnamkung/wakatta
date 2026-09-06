import Foundation
import SwiftData

@Observable
final class EpisodeListViewModel {
    var episodes: [Episode] = []
    var isLoading = false

    func loadEpisodes(for media: Media, modelContext: ModelContext) {
        isLoading = true
        let mediaID = media.externalID
        let predicate = #Predicate<Episode> { $0.mediaExternalID == mediaID }
        var descriptor = FetchDescriptor(predicate: predicate)
        descriptor.sortBy = [SortDescriptor(\.episodeNumber)]
        episodes = (try? modelContext.fetch(descriptor)) ?? []
        isLoading = false
    }

    func unitLabel(for mediaType: MediaType) -> String {
        switch mediaType {
        case .manga: return "Chapter"
        case .movie: return "Full Movie"
        default: return "Episode"
        }
    }

    func sectionTitle(for mediaType: MediaType) -> String {
        switch mediaType {
        case .manga: return "Chapters"
        case .movie: return "Lessons"
        default: return "Episodes"
        }
    }
}
