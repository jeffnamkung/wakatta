import SwiftUI
import SwiftData

@main
struct animangoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            Media.self,
            VocabularyItem.self,
            KanjiItem.self,
            GrammarPoint.self,
            UserProgress.self,
            MediaVocabulary.self,
            MediaKanji.self,
            MediaGrammar.self
        ])
    }
}
