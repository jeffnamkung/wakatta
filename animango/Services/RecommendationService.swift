import Foundation
import SwiftData

struct Recommendation: Identifiable {
    var id: String { media.externalID }
    let media: Media
    let score: Double
    let reasons: [String]
}

struct RecommendationService {

    /// Generate recommendations based on user's library, progress, and interests
    static func getRecommendations(
        candidates: [Media],
        library: [Media],
        modelContext: ModelContext
    ) -> [Recommendation] {
        guard !library.isEmpty else {
            // No library — just return popular items
            return candidates.prefix(10).map {
                Recommendation(media: $0, score: 1.0, reasons: ["Popular title"])
            }
        }

        // Build user profile
        let userGenres = genreVector(from: library)
        let userMediaTypes = mediaTypeWeights(from: library)

        // Get user's known vocabulary
        let allProgress = (try? modelContext.fetch(FetchDescriptor<UserProgress>())) ?? []
        let knownItemIDs = Set(
            allProgress
                .filter { $0.knowledgeState == .mastered || $0.knowledgeState == .developing || $0.knowledgeState == .learning }
                .map(\.itemID)
        )

        let libraryIDs = Set(library.map(\.externalID))

        return candidates
            .filter { !libraryIDs.contains($0.externalID) }
            .map { candidate in
                let genreScore = cosineSimilarity(
                    genreVector(from: [candidate]),
                    userGenres
                )

                let typeScore = userMediaTypes[candidate.mediaType] ?? 0.3

                // Vocabulary overlap with this candidate
                let mediaID = candidate.externalID
                let predicate = #Predicate<MediaVocabulary> { $0.mediaExternalID == mediaID }
                let descriptor = FetchDescriptor(predicate: predicate)
                let mappings = (try? modelContext.fetch(descriptor)) ?? []
                let mediaWords = Set(mappings.map(\.vocabularyWord))

                let overlapScore: Double
                if mediaWords.isEmpty {
                    overlapScore = 0.5
                } else {
                    let overlap = mediaWords.intersection(knownItemIDs).count
                    overlapScore = Double(overlap) / Double(mediaWords.count)
                }

                // Prefer media where user knows some but not all vocabulary
                // Sweet spot is 20-60% overlap
                let noveltyScore: Double
                if overlapScore < 0.2 {
                    noveltyScore = 0.3 // Too hard
                } else if overlapScore > 0.8 {
                    noveltyScore = 0.4 // Too easy
                } else {
                    noveltyScore = 1.0 // Just right
                }

                let totalScore = genreScore * 0.35 + noveltyScore * 0.30 + typeScore * 0.20 + (candidate.score ?? 5.0) / 10.0 * 0.15

                var reasons: [String] = []
                if genreScore > 0.5 { reasons.append("Matches your favorite genres") }
                if overlapScore > 0.2 && overlapScore < 0.8 { reasons.append("Good difficulty for your level") }
                if !mediaWords.isEmpty && overlapScore < 0.5 { reasons.append("Lots of new vocabulary") }
                if reasons.isEmpty { reasons.append("Recommended for you") }

                return Recommendation(media: candidate, score: totalScore, reasons: reasons)
            }
            .sorted { $0.score > $1.score }
    }

    // MARK: - Private Helpers

    private static let allGenres = [
        "Action", "Adventure", "Comedy", "Drama", "Fantasy",
        "Horror", "Mystery", "Romance", "Sci-Fi", "Slice of Life",
        "Sports", "Thriller", "Supernatural", "Music", "Mecha",
        "Psychological", "Military", "School"
    ]

    private static func genreVector(from media: [Media]) -> [Double] {
        let genreCounts = media.flatMap(\.genres).reduce(into: [String: Int]()) { $0[$1, default: 0] += 1 }
        let maxCount = max(Double(genreCounts.values.max() ?? 1), 1.0)
        return allGenres.map { Double(genreCounts[$0, default: 0]) / maxCount }
    }

    private static func mediaTypeWeights(from media: [Media]) -> [MediaType: Double] {
        let total = Double(media.count)
        guard total > 0 else { return [:] }
        let counts = media.reduce(into: [MediaType: Int]()) { $0[$1.mediaType, default: 0] += 1 }
        return counts.mapValues { Double($0) / total }
    }

    private static func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        guard a.count == b.count, !a.isEmpty else { return 0 }
        let dot = zip(a, b).map(*).reduce(0, +)
        let magA = sqrt(a.map { $0 * $0 }.reduce(0, +))
        let magB = sqrt(b.map { $0 * $0 }.reduce(0, +))
        guard magA > 0 && magB > 0 else { return 0 }
        return dot / (magA * magB)
    }
}
