import SwiftUI
import SwiftData

struct KanjiListView: View {
    let media: Media
    @State private var kanjiItems: [KanjiItem] = []
    @State private var progressMap: [String: UserProgress] = [:]
    @State private var filterState: KnowledgeState?
    @State private var searchText = ""
    @Environment(\.modelContext) private var modelContext

    var filteredItems: [KanjiItem] {
        var items = kanjiItems

        if let filter = filterState {
            items = items.filter { kanji in
                let state = progressMap[kanji.character]?.knowledgeState ?? .neverLearned
                return state == filter
            }
        }

        if !searchText.isEmpty {
            items = items.filter { kanji in
                kanji.character.localizedCaseInsensitiveContains(searchText) ||
                kanji.meaning.localizedCaseInsensitiveContains(searchText) ||
                kanji.onReadings.joined(separator: " ").localizedCaseInsensitiveContains(searchText) ||
                kanji.kunReadings.joined(separator: " ").localizedCaseInsensitiveContains(searchText)
            }
        }

        return items
    }

    func count(for state: KnowledgeState) -> Int {
        if state == .neverLearned {
            return kanjiItems.filter { progressMap[$0.character]?.knowledgeState == nil || progressMap[$0.character]?.knowledgeState == .neverLearned }.count
        }
        return kanjiItems.filter { progressMap[$0.character]?.knowledgeState == state }.count
    }

    var body: some View {
        List {
            // Summary stats
            Section {
                HStack(spacing: 8) {
                    ForEach(KnowledgeState.allCases, id: \.self) { state in
                        statPill(count: count(for: state), label: state.shortName, color: state.color)
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            }

            // Filter bar
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterButton(title: "All", state: nil)
                        ForEach(KnowledgeState.allCases, id: \.self) { state in
                            filterButton(title: state.shortName, state: state)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))
            }

            // Kanji list
            Section {
                if filteredItems.isEmpty {
                    Text("No kanji items yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredItems, id: \.character) { kanji in
                        NavigationLink {
                            KanjiDetailView(kanji: kanji)
                        } label: {
                            KanjiRow(
                                kanji: kanji,
                                state: progressMap[kanji.character]?.knowledgeState ?? .neverLearned
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Kanji")
        .searchable(text: $searchText, prompt: "Search kanji...")
        .task {
            loadKanji()
        }
    }

    private func statPill(count: Int, label: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private func filterButton(title: String, state: KnowledgeState?) -> some View {
        Button {
            filterState = state
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(filterState == state ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(filterState == state ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(filterState == state ? .white : .primary)
                .clipShape(Capsule())
        }
    }

    private func loadKanji() {
        let mediaID = media.externalID
        let predicate = #Predicate<MediaKanji> { $0.mediaExternalID == mediaID }
        let descriptor = FetchDescriptor(predicate: predicate)
        let mappings = (try? modelContext.fetch(descriptor)) ?? []

        let chars = Set(mappings.map(\.kanjiCharacter))
        if !chars.isEmpty {
            let allKanji = (try? modelContext.fetch(FetchDescriptor<KanjiItem>())) ?? []
            kanjiItems = allKanji.filter { chars.contains($0.character) }
        }

        let allProgress = (try? modelContext.fetch(FetchDescriptor<UserProgress>())) ?? []
        progressMap = Dictionary(
            uniqueKeysWithValues: allProgress
                .filter { $0.itemType == .kanji }
                .map { ($0.itemID, $0) }
        )
    }
}

private struct KanjiRow: View {
    let kanji: KanjiItem
    let state: KnowledgeState

    var body: some View {
        HStack {
            Text(kanji.character)
                .font(.system(size: 32, weight: .medium))
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(kanji.meaning)
                    .font(.body)
                    .fontWeight(.medium)

                HStack(spacing: 8) {
                    if !kanji.onReadings.isEmpty {
                        Text(kanji.onReadings.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    if !kanji.kunReadings.isEmpty {
                        Text(kanji.kunReadings.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            KnowledgeStateBadge(state: state)
        }
    }
}

#Preview {
    NavigationStack {
        KanjiListView(
            media: Media(
                externalID: "anime_1",
                mediaType: .anime,
                title: "Attack on Titan"
            )
        )
    }
    .modelContainer(for: [
        Media.self, KanjiItem.self, MediaKanji.self, UserProgress.self
    ], inMemory: true)
}
