import Foundation
import SwiftData

@Observable
final class MediaDetailViewModel {
    var vocabularyItems: [VocabularyItem] = []
    var kanjiItems: [KanjiItem] = []
    var grammarPoints: [GrammarPoint] = []
    var comprehensionPercentage: Double = 0
    var isLoading = false

    // Progress counts per category
    var vocabProgressCounts: [KnowledgeState: Int] = [:]
    var kanjiProgressCounts: [KnowledgeState: Int] = [:]
    var grammarProgressCounts: [KnowledgeState: Int] = [:]

    // Content request state
    var isRequestingContent = false
    var contentRequestMessage: String?
    var contentRequestStatus: String?

    func loadLanguageData(for media: Media, modelContext: ModelContext) {
        let mediaID = media.externalID

        // Fetch vocabulary mapped to this media
        let vocabPredicate = #Predicate<MediaVocabulary> { $0.mediaExternalID == mediaID }
        let vocabDescriptor = FetchDescriptor(predicate: vocabPredicate)
        let vocabMappings = (try? modelContext.fetch(vocabDescriptor)) ?? []

        let vocabWords = Set(vocabMappings.map(\.vocabularyWord))
        if !vocabWords.isEmpty {
            let allVocab = (try? modelContext.fetch(FetchDescriptor<VocabularyItem>())) ?? []
            vocabularyItems = allVocab.filter { vocabWords.contains($0.word) }
        }

        // Fetch kanji mapped to this media
        let kanjiPredicate = #Predicate<MediaKanji> { $0.mediaExternalID == mediaID }
        let kanjiDescriptor = FetchDescriptor(predicate: kanjiPredicate)
        let kanjiMappings = (try? modelContext.fetch(kanjiDescriptor)) ?? []

        let kanjiChars = Set(kanjiMappings.map(\.kanjiCharacter))
        if !kanjiChars.isEmpty {
            let allKanji = (try? modelContext.fetch(FetchDescriptor<KanjiItem>())) ?? []
            kanjiItems = allKanji.filter { kanjiChars.contains($0.character) }
        }

        // Fetch grammar mapped to this media
        let grammarPredicate = #Predicate<MediaGrammar> { $0.mediaExternalID == mediaID }
        let grammarDescriptor = FetchDescriptor(predicate: grammarPredicate)
        let grammarMappings = (try? modelContext.fetch(grammarDescriptor)) ?? []

        let grammarPatterns = Set(grammarMappings.map(\.grammarPattern))
        if !grammarPatterns.isEmpty {
            let allGrammar = (try? modelContext.fetch(FetchDescriptor<GrammarPoint>())) ?? []
            grammarPoints = allGrammar.filter { grammarPatterns.contains($0.pattern) }
        }

        // Load progress data
        loadProgressData(modelContext: modelContext)
    }

    private func loadProgressData(modelContext: ModelContext) {
        let progressRecords = (try? modelContext.fetch(FetchDescriptor<UserProgress>())) ?? []
        let progressByID = Dictionary(uniqueKeysWithValues: progressRecords.map { ($0.itemID, $0) })

        // Compute per-category progress counts
        vocabProgressCounts = countStates(items: vocabularyItems.map(\.word), progressByID: progressByID)
        kanjiProgressCounts = countStates(items: kanjiItems.map(\.character), progressByID: progressByID)
        grammarProgressCounts = countStates(items: grammarPoints.map(\.pattern), progressByID: progressByID)

        // Calculate comprehension
        var totalWeight = 0.0
        var weightedScore = 0.0

        for vocab in vocabularyItems {
            totalWeight += 1.0
            if let progress = progressByID[vocab.word] {
                weightedScore += progress.knowledgeState.comprehensionWeight
            }
        }

        comprehensionPercentage = totalWeight > 0 ? (weightedScore / totalWeight) * 100 : 0
    }

    func requestContent(for media: Media) async {
        // Extract MAL ID from externalID (e.g. "anime_16498" → 16498)
        guard media.mediaType == .anime,
              let malIdString = media.externalID.split(separator: "_").last,
              let malId = Int(malIdString) else {
            contentRequestMessage = "Content requests are currently only supported for anime."
            contentRequestStatus = "error"
            return
        }

        isRequestingContent = true
        contentRequestMessage = nil
        contentRequestStatus = nil

        let apiService = AnimangoAPIService()
        do {
            let response = try await apiService.requestContent(malId: malId)
            contentRequestMessage = response.message
            contentRequestStatus = response.status
        } catch {
            contentRequestMessage = "Failed to send request. Please try again later."
            contentRequestStatus = "error"
        }
        isRequestingContent = false
    }

    private func countStates(items: [String], progressByID: [String: UserProgress]) -> [KnowledgeState: Int] {
        var counts: [KnowledgeState: Int] = [:]
        for state in KnowledgeState.allCases {
            counts[state] = 0
        }
        for itemID in items {
            let state = progressByID[itemID]?.knowledgeState ?? .neverLearned
            counts[state, default: 0] += 1
        }
        return counts
    }
}
