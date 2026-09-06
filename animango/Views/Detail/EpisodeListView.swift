import SwiftUI
import SwiftData

struct EpisodeListView: View {
    let media: Media
    @State private var viewModel = EpisodeListViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        List {
            ForEach(viewModel.episodes, id: \.id) { episode in
                NavigationLink(value: episode) {
                    EpisodeRow(
                        episode: episode,
                        unitLabel: viewModel.unitLabel(for: media.mediaType)
                    )
                }
            }
        }
        .navigationTitle(viewModel.sectionTitle(for: media.mediaType))
        .navigationDestination(for: Episode.self) { episode in
            EpisodeDetailView(episode: episode, media: media)
        }
        .overlay {
            if !viewModel.isLoading && viewModel.episodes.isEmpty {
                let label = media.mediaType == .manga ? "chapters" : "episodes"
                EmptyStateView(
                    icon: "list.number",
                    title: "No \(label.capitalized) Yet",
                    message: "\(label.capitalized) will appear here when available."
                )
            }
        }
        .task {
            viewModel.loadEpisodes(for: media, modelContext: modelContext)
        }
    }
}

private struct EpisodeRow: View {
    let episode: Episode
    let unitLabel: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("\(unitLabel) \(episode.episodeNumber)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(episode.title)
                .font(.body)
                .fontWeight(.medium)

            if let jpTitle = episode.titleJapanese {
                Text(jpTitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let synopsis = episode.synopsis {
                Text(synopsis)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}
