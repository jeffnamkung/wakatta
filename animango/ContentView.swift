import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            Tab("Discover", systemImage: "sparkles") {
                DiscoverView()
            }

            Tab("Library", systemImage: "books.vertical") {
                LibraryView()
            }

            Tab("Study", systemImage: "brain.head.profile") {
                StudyView()
            }

            Tab("Profile", systemImage: "person.crop.circle") {
                ProfileView()
            }
        }
        .task {
            SampleData.loadIfNeeded(modelContext: modelContext)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Media.self,
            VocabularyItem.self,
            KanjiItem.self,
            GrammarPoint.self,
            UserProgress.self,
            MediaVocabulary.self,
            MediaKanji.self,
            MediaGrammar.self
        ], inMemory: true)
}
