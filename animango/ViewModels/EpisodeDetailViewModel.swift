import Foundation
import SwiftData

@Observable
final class EpisodeDetailViewModel {
    var vocabularyItems: [VocabularyItem] = []
    var kanjiItems: [KanjiItem] = []
    var grammarPoints: [GrammarPoint] = []
    var lessons: [Lesson] = []
    var isLoading = false

    let contentGenerator = ContentGenerationService()

    var hasContent: Bool {
        !vocabularyItems.isEmpty || !kanjiItems.isEmpty || !grammarPoints.isEmpty || !lessons.isEmpty
    }

    func generateContent(for episode: Episode, media: Media, modelContext: ModelContext) async {
        await contentGenerator.generateContentForEpisode(
            episode: episode,
            media: media,
            modelContext: modelContext
        )
        // Reload content after generation
        loadContent(for: episode, modelContext: modelContext)
    }

    func loadContent(for episode: Episode, modelContext: ModelContext) {
        isLoading = true
        let episodeID = episode.id

        // Load episode vocabulary
        let vocabPredicate = #Predicate<EpisodeVocabulary> { $0.episodeID == episodeID }
        let vocabMappings = (try? modelContext.fetch(FetchDescriptor(predicate: vocabPredicate))) ?? []
        let vocabWords = Set(vocabMappings.map(\.vocabularyWord))
        if !vocabWords.isEmpty {
            let allVocab = (try? modelContext.fetch(FetchDescriptor<VocabularyItem>())) ?? []
            vocabularyItems = allVocab.filter { vocabWords.contains($0.word) }
        }

        // Load episode kanji
        let kanjiPredicate = #Predicate<EpisodeKanji> { $0.episodeID == episodeID }
        let kanjiMappings = (try? modelContext.fetch(FetchDescriptor(predicate: kanjiPredicate))) ?? []
        let kanjiChars = Set(kanjiMappings.map(\.kanjiCharacter))
        if !kanjiChars.isEmpty {
            let allKanji = (try? modelContext.fetch(FetchDescriptor<KanjiItem>())) ?? []
            kanjiItems = allKanji.filter { kanjiChars.contains($0.character) }
        }

        // Load episode grammar
        let grammarPredicate = #Predicate<EpisodeGrammar> { $0.episodeID == episodeID }
        let grammarMappings = (try? modelContext.fetch(FetchDescriptor(predicate: grammarPredicate))) ?? []
        let grammarPatterns = Set(grammarMappings.map(\.grammarPattern))
        if !grammarPatterns.isEmpty {
            let allGrammar = (try? modelContext.fetch(FetchDescriptor<GrammarPoint>())) ?? []
            grammarPoints = allGrammar.filter { grammarPatterns.contains($0.pattern) }
        }

        // Load lessons
        let lessonPredicate = #Predicate<Lesson> { $0.episodeID == episodeID }
        var lessonDescriptor = FetchDescriptor(predicate: lessonPredicate)
        lessonDescriptor.sortBy = [SortDescriptor(\.order)]
        lessons = (try? modelContext.fetch(lessonDescriptor)) ?? []

        isLoading = false
    }
}
