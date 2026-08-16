import Foundation

@Observable
final class MediaSearchService {
    private let jikanService = JikanService()
    private let tmdbService = TMDBService()
    private let igdbService = IGDBService()

    func search(
        query: String,
        mediaTypes: Set<MediaType> = Set(MediaType.allCases)
    ) async -> [Media] {
        await withTaskGroup(of: [Media].self) { group in
            if mediaTypes.contains(.anime) {
                group.addTask {
                    (try? await self.jikanService.searchAnime(query: query).anime) ?? []
                }
            }
            if mediaTypes.contains(.jdrama) {
                group.addTask {
                    (try? await self.tmdbService.searchDrama(query: query).shows) ?? []
                }
            }
            if mediaTypes.contains(.manga) {
                group.addTask {
                    (try? await self.jikanService.searchManga(query: query).manga) ?? []
                }
            }
            if mediaTypes.contains(.game) {
                group.addTask {
                    (try? await self.igdbService.searchGames(query: query)) ?? []
                }
            }

            var results: [Media] = []
            for await items in group {
                results.append(contentsOf: items)
            }
            return results.sorted { ($0.score ?? 0) > ($1.score ?? 0) }
        }
    }

    func getTopAnime() async -> [Media] {
        (try? await jikanService.getTopAnime()) ?? []
    }

    func getPopularDrama() async -> [Media] {
        (try? await tmdbService.discoverJDrama()) ?? []
    }

    func getTopManga() async -> [Media] {
        (try? await jikanService.getTopManga()) ?? []
    }
}
