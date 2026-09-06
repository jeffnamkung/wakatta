import Foundation
import SwiftUI
import SwiftData

struct StudyCardData: Identifiable {
    let id = UUID()
    let itemID: String
    let itemType: StudyItemType
    let frontText: String
    let frontSubtext: String?
    let reading: String
    let meaning: String
}

struct SessionResult {
    var totalCards: Int = 0
    var correctCount: Int = 0
    var incorrectCount: Int = 0
    var promotedToKnown: Int = 0
}

@Observable
final class StudySessionViewModel {
    var cards: [StudyCardData] = []
    var currentIndex = 0
    var isFlipped = false
    var isSessionActive = false
    var sessionResult = SessionResult()

    var currentCard: StudyCardData? {
        guard currentIndex < cards.count else { return nil }
        return cards[currentIndex]
    }

    var remainingCards: Int {
        max(0, cards.count - currentIndex)
    }

    var progress: Double {
        guard !cards.isEmpty else { return 0 }
        return Double(currentIndex) / Double(cards.count)
    }

    func startSession(media: Media?, sessionType: StudyItemType?, modelContext: ModelContext) {
        var allCards: [StudyCardData] = []

        // Load vocabulary cards
        if sessionType == nil || sessionType == .vocabulary {
            let vocabItems: [VocabularyItem]
            if let media = media {
                let mediaID = media.externalID
                let predicate = #Predicate<MediaVocabulary> { $0.mediaExternalID == mediaID }
                let mappings = (try? modelContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
                let words = Set(mappings.map(\.vocabularyWord))
                let allVocab = (try? modelContext.fetch(FetchDescriptor<VocabularyItem>())) ?? []
                vocabItems = allVocab.filter { words.contains($0.word) }
            } else {
                vocabItems = (try? modelContext.fetch(FetchDescriptor<VocabularyItem>())) ?? []
            }

            allCards.append(contentsOf: vocabItems.map { vocab in
                StudyCardData(
                    itemID: vocab.word,
                    itemType: .vocabulary,
                    frontText: vocab.word,
                    frontSubtext: nil,
                    reading: vocab.reading,
                    meaning: vocab.meaning
                )
            })
        }

        // Load kanji cards
        if sessionType == nil || sessionType == .kanji {
            let kanjiItems: [KanjiItem]
            if let media = media {
                let mediaID = media.externalID
                let predicate = #Predicate<MediaKanji> { $0.mediaExternalID == mediaID }
                let mappings = (try? modelContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
                let chars = Set(mappings.map(\.kanjiCharacter))
                let allKanji = (try? modelContext.fetch(FetchDescriptor<KanjiItem>())) ?? []
                kanjiItems = allKanji.filter { chars.contains($0.character) }
            } else {
                kanjiItems = (try? modelContext.fetch(FetchDescriptor<KanjiItem>())) ?? []
            }

            allCards.append(contentsOf: kanjiItems.map { kanji in
                StudyCardData(
                    itemID: kanji.character,
                    itemType: .kanji,
                    frontText: kanji.character,
                    frontSubtext: nil,
                    reading: (kanji.kunReadings + kanji.onReadings).joined(separator: "、"),
                    meaning: kanji.meaning
                )
            })
        }

        // Load grammar cards
        if sessionType == nil || sessionType == .grammar {
            let grammarItems: [GrammarPoint]
            if let media = media {
                let mediaID = media.externalID
                let predicate = #Predicate<MediaGrammar> { $0.mediaExternalID == mediaID }
                let mappings = (try? modelContext.fetch(FetchDescriptor(predicate: predicate))) ?? []
                let patterns = Set(mappings.map(\.grammarPattern))
                let allGrammar = (try? modelContext.fetch(FetchDescriptor<GrammarPoint>())) ?? []
                grammarItems = allGrammar.filter { patterns.contains($0.pattern) }
            } else {
                grammarItems = (try? modelContext.fetch(FetchDescriptor<GrammarPoint>())) ?? []
            }

            allCards.append(contentsOf: grammarItems.map { grammar in
                StudyCardData(
                    itemID: grammar.pattern,
                    itemType: .grammar,
                    frontText: grammar.pattern,
                    frontSubtext: grammar.jlptLevel.map { "JLPT N\($0)" },
                    reading: grammar.examples.first?.japanese ?? "",
                    meaning: grammar.explanation
                )
            })
        }

        // Filter to items that are due for review or new
        let allProgress = (try? modelContext.fetch(FetchDescriptor<UserProgress>())) ?? []
        let progressByID = Dictionary(uniqueKeysWithValues: allProgress.map { ($0.itemID, $0) })
        let now = Date()

        cards = allCards.filter { card in
            guard let prog = progressByID[card.itemID] else { return true }
            if prog.knowledgeState == .mastered {
                return prog.nextReviewDate.map { $0 <= now } ?? false
            }
            return true
        }.shuffled()

        // Limit session to 20 cards
        if cards.count > 20 {
            cards = Array(cards.prefix(20))
        }

        currentIndex = 0
        isFlipped = false
        isSessionActive = true
        sessionResult = SessionResult(totalCards: cards.count)
    }

    func revealAnswer() {
        withAnimation(.easeInOut(duration: 0.3)) {
            isFlipped = true
        }
    }

    func gradeCard(_ grade: SRSEngine.Grade, modelContext: ModelContext) {
        guard let card = currentCard else { return }

        // Find or create progress
        let itemID = card.itemID
        let itemType = card.itemType
        let predicate = #Predicate<UserProgress> {
            $0.itemID == itemID && $0.itemType == itemType
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        let progress: UserProgress

        if let existing = try? modelContext.fetch(descriptor).first {
            progress = existing
        } else {
            progress = UserProgress(itemID: card.itemID, itemType: card.itemType)
            modelContext.insert(progress)
        }

        let previousState = progress.knowledgeState
        let _ = SRSEngine.processReview(progress: progress, grade: grade)

        // Track results
        if grade == .again {
            sessionResult.incorrectCount += 1
        } else {
            sessionResult.correctCount += 1
        }

        if previousState != .mastered && progress.knowledgeState == .mastered {
            sessionResult.promotedToKnown += 1
        }

        try? modelContext.save()

        // Move to next card
        withAnimation {
            currentIndex += 1
            isFlipped = false
        }

        if currentIndex >= cards.count {
            isSessionActive = false
        }
    }
}
