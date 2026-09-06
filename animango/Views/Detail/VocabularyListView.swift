import SwiftUI
import SwiftData

struct VocabularyListView: View {
    let media: Media
    @State private var viewModel = VocabularyListViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            // Summary stats
            Section {
                HStack(spacing: 8) {
                    ForEach(KnowledgeState.allCases, id: \.self) { state in
                        statPill(count: viewModel.count(for: state), label: state.shortName, color: state.color)
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

            // Vocabulary list
            Section {
                if viewModel.filteredItems.isEmpty {
                    Text("No vocabulary items yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(viewModel.filteredItems, id: \.word) { vocab in
                        NavigationLink(value: vocab) {
                            VocabularyRow(
                                vocab: vocab,
                                state: viewModel.knowledgeState(for: vocab.word)
                            )
                        }
                    }
                }
            }
        }
        .navigationTitle("Vocabulary")
        .searchable(text: $viewModel.searchText, prompt: "Search vocabulary...")
        .navigationDestination(for: VocabularyItem.self) { vocab in
            WordDetailView(vocabulary: vocab)
        }
        .task {
            viewModel.loadVocabulary(for: media, modelContext: modelContext)
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
            viewModel.filterState = state
        } label: {
            Text(title)
                .font(.subheadline)
                .fontWeight(viewModel.filterState == state ? .semibold : .regular)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(viewModel.filterState == state ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(viewModel.filterState == state ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

private struct VocabularyRow: View {
    let vocab: VocabularyItem
    let state: KnowledgeState

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(vocab.word)
                        .font(.body)
                        .fontWeight(.medium)
                    Text(vocab.reading)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    AudioButtonCompact(text: vocab.word)
                }
                Text(vocab.meaning)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            KnowledgeStateBadge(state: state)
        }
    }
}

#Preview {
    NavigationStack {
        VocabularyListView(
            media: Media(
                externalID: "anime_1",
                mediaType: .anime,
                title: "Attack on Titan"
            )
        )
    }
    .modelContainer(for: [
        Media.self, VocabularyItem.self, MediaVocabulary.self, UserProgress.self
    ], inMemory: true)
}
