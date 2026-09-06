import SwiftUI
import SwiftData

struct GrammarListView: View {
    let media: Media
    @State private var grammarPoints: [GrammarPoint] = []
    @State private var progressMap: [String: UserProgress] = [:]
    @State private var filterState: KnowledgeState?
    @State private var searchText = ""
    @Environment(\.modelContext) private var modelContext

    var filteredItems: [GrammarPoint] {
        var items = grammarPoints

        if let filter = filterState {
            items = items.filter { grammar in
                let state = progressMap[grammar.pattern]?.knowledgeState ?? .neverLearned
                return state == filter
            }
        }

        if !searchText.isEmpty {
            items = items.filter { grammar in
                grammar.pattern.localizedCaseInsensitiveContains(searchText) ||
                grammar.explanation.localizedCaseInsensitiveContains(searchText)
            }
        }

        return items
    }

    func count(for state: KnowledgeState) -> Int {
        if state == .neverLearned {
            return grammarPoints.filter { progressMap[$0.pattern]?.knowledgeState == nil || progressMap[$0.pattern]?.knowledgeState == .neverLearned }.count
        }
        return grammarPoints.filter { progressMap[$0.pattern]?.knowledgeState == state }.count
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

            // Grammar list
            Section {
                if filteredItems.isEmpty {
                    Text("No grammar points yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(filteredItems, id: \.pattern) { grammar in
                        NavigationLink {
                            GrammarDetailView(grammar: grammar)
                        } label: {
                            GrammarRow(
                                grammar: grammar,
                                state: progressMap[grammar.pattern]?.knowledgeState ?? .neverLearned
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Grammar")
        .searchable(text: $searchText, prompt: "Search grammar...")
        .task {
            loadGrammar()
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

    private func loadGrammar() {
        let mediaID = media.externalID
        let predicate = #Predicate<MediaGrammar> { $0.mediaExternalID == mediaID }
        let descriptor = FetchDescriptor(predicate: predicate)
        let mappings = (try? modelContext.fetch(descriptor)) ?? []

        let patterns = Set(mappings.map(\.grammarPattern))
        if !patterns.isEmpty {
            let allGrammar = (try? modelContext.fetch(FetchDescriptor<GrammarPoint>())) ?? []
            grammarPoints = allGrammar.filter { patterns.contains($0.pattern) }
        }

        let allProgress = (try? modelContext.fetch(FetchDescriptor<UserProgress>())) ?? []
        progressMap = Dictionary(
            uniqueKeysWithValues: allProgress
                .filter { $0.itemType == .grammar }
                .map { ($0.itemID, $0) }
        )
    }
}

private struct GrammarRow: View {
    let grammar: GrammarPoint
    let state: KnowledgeState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(grammar.pattern)
                    .font(.body)
                    .fontWeight(.medium)

                Text(grammar.explanation)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let level = grammar.jlptLevel {
                    Text("JLPT N\(level)")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.accentColor.opacity(0.15))
                        .foregroundStyle(Color.accentColor)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            KnowledgeStateBadge(state: state)
        }
    }
}

#Preview {
    NavigationStack {
        GrammarListView(
            media: Media(
                externalID: "anime_1",
                mediaType: .anime,
                title: "Attack on Titan"
            )
        )
    }
    .modelContainer(for: [
        Media.self, GrammarPoint.self, MediaGrammar.self, UserProgress.self
    ], inMemory: true)
}
