import SwiftUI
import SwiftData

struct MediaDetailView: View {
    let media: Media
    @Environment(\.modelContext) private var modelContext
    @State private var isInLibrary: Bool
    @State private var detailViewModel = MediaDetailViewModel()
    @State private var movieEpisode: Episode?

    init(media: Media) {
        self.media = media
        self._isInLibrary = State(initialValue: media.isInLibrary)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Hero section
                heroSection

                // Action buttons
                actionButtons

                // Synopsis
                if let synopsis = media.synopsis, !synopsis.isEmpty {
                    synopsisSection(synopsis)
                }

                // Info section
                infoSection

                // Episodes / Chapters section (not for movies or games)
                if media.mediaType != .movie && media.mediaType != .game {
                    episodesSection
                }

                // For movies, show lessons directly
                if media.mediaType == .movie {
                    movieLessonsSection
                }

                // Language points section
                vocabularySection
            }
            .padding()
        }
        .navigationTitle(media.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            detailViewModel.loadLanguageData(for: media, modelContext: modelContext)
            if media.mediaType == .movie {
                let mediaID = media.externalID
                let predicate = #Predicate<Episode> { $0.mediaExternalID == mediaID }
                movieEpisode = (try? modelContext.fetch(FetchDescriptor(predicate: predicate)))?.first
            }
        }
    }

    private var heroSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // Poster
            AsyncImage(url: URL(string: media.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .aspectRatio(2/3, contentMode: .fill)
                    .overlay {
                        Image(systemName: media.mediaType.iconName)
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 140)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 8) {
                Text(media.title)
                    .font(.title2)
                    .fontWeight(.bold)

                if let jpTitle = media.titleJapanese {
                    Text(jpTitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 4) {
                    Image(systemName: media.mediaType.iconName)
                        .font(.caption)
                    Text(media.mediaType.displayName)
                        .font(.caption)
                }
                .foregroundStyle(.secondary)

                if let score = media.score, score > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                            .font(.caption)
                        Text(String(format: "%.1f", score))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }

                if let count = media.episodeCount {
                    switch media.mediaType {
                    case .manga:
                        Text("\(count) chapters")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    case .movie:
                        EmptyView()
                    default:
                        Text("\(count) episodes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                // Genre tags
                if !media.genres.isEmpty {
                    FlowLayout(spacing: 4) {
                        ForEach(media.genres, id: \.self) { genre in
                            Text(genre)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(.systemGray5))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                toggleLibrary()
            } label: {
                Label(
                    isInLibrary ? "In Library" : "Add to Library",
                    systemImage: isInLibrary ? "checkmark.circle.fill" : "plus.circle"
                )
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(isInLibrary ? .green : .accentColor)

            NavigationLink(value: media) {
                Label("Study", systemImage: "brain.head.profile")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
    }

    private func synopsisSection(_ synopsis: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Synopsis")
                .font(.headline)
            Text(synopsis)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Info")
                .font(.headline)

            if let year = media.releaseYear {
                infoRow(label: "Year", value: String(year))
            }
            if let status = media.status {
                infoRow(label: "Status", value: status)
            }
        }
    }

    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
        }
    }

    private var vocabularySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Language Points")
                .font(.headline)

            HStack(spacing: 12) {
                NavigationLink {
                    VocabularyListView(media: media)
                } label: {
                    languageStatCard(
                        icon: "text.book.closed",
                        label: "Vocabulary",
                        count: detailViewModel.vocabularyItems.count,
                        progressCounts: detailViewModel.vocabProgressCounts
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    KanjiListView(media: media)
                } label: {
                    languageStatCard(
                        icon: "character.ja",
                        label: "Kanji",
                        count: detailViewModel.kanjiItems.count,
                        progressCounts: detailViewModel.kanjiProgressCounts
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    GrammarListView(media: media)
                } label: {
                    languageStatCard(
                        icon: "text.alignleft",
                        label: "Grammar",
                        count: detailViewModel.grammarPoints.count,
                        progressCounts: detailViewModel.grammarProgressCounts
                    )
                }
                .buttonStyle(.plain)
            }

            if detailViewModel.vocabularyItems.isEmpty && detailViewModel.kanjiItems.isEmpty && detailViewModel.grammarPoints.isEmpty {
                Text("Add this to your library to start learning the vocabulary and kanji needed to understand this title.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func languageStatCard(icon: String, label: String, count: Int, progressCounts: [KnowledgeState: Int]) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(Color.accentColor)
            Text("\(count)")
                .font(.title3)
                .fontWeight(.bold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)

            // Progress indicator bar
            if count > 0 {
                GeometryReader { geometry in
                    let width = geometry.size.width
                    HStack(spacing: 0) {
                        ForEach(KnowledgeState.allCases, id: \.self) { state in
                            let stateCount = progressCounts[state] ?? 0
                            if stateCount > 0 {
                                Rectangle()
                                    .fill(state.color)
                                    .frame(width: width * (Double(stateCount) / Double(count)))
                            }
                        }
                    }
                    .clipShape(Capsule())
                }
                .frame(height: 4)
                .padding(.horizontal, 8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var movieLessonsSection: some View {
        if let episode = movieEpisode {
            VStack(alignment: .leading, spacing: 8) {
                Text("Lessons")
                    .font(.headline)

                NavigationLink {
                    EpisodeDetailView(episode: episode, media: media)
                } label: {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .foregroundStyle(Color.accentColor)
                        Text("View Lessons")
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var episodesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let sectionLabel = media.mediaType == .manga ? "Chapters" :
                               media.mediaType == .movie ? "Lessons" : "Episodes"

            Text(sectionLabel)
                .font(.headline)

            NavigationLink {
                EpisodeListView(media: media)
            } label: {
                HStack {
                    Image(systemName: "list.number")
                        .foregroundStyle(Color.accentColor)
                    Text("View \(sectionLabel)")
                        .foregroundStyle(.primary)
                    Spacer()
                    if let count = media.episodeCount, media.mediaType != .movie {
                        Text("\(count)")
                            .foregroundStyle(.secondary)
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
        }
    }

    private func toggleLibrary() {
        let externalID = media.externalID
        let predicate = #Predicate<Media> { $0.externalID == externalID }
        let descriptor = FetchDescriptor(predicate: predicate)

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.isInLibrary.toggle()
            existing.dateAdded = existing.isInLibrary ? Date() : nil
            isInLibrary = existing.isInLibrary
        } else {
            media.isInLibrary = true
            media.dateAdded = Date()
            modelContext.insert(media)
            isInLibrary = true
        }

        try? modelContext.save()
    }
}

/// Simple flow layout for genre tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    NavigationStack {
        MediaDetailView(
            media: Media(
                externalID: "anime_1",
                mediaType: .anime,
                title: "Attack on Titan",
                titleJapanese: "進撃の巨人",
                synopsis: "Centuries ago, mankind was slaughtered to near extinction by monstrous humanoid creatures called Titans, forcing humans to hide in fear behind enormous concentric walls.",
                score: 8.9,
                episodeCount: 25,
                status: "Finished Airing",
                genres: ["Action", "Drama", "Fantasy", "Military"],
                releaseYear: 2013
            )
        )
    }
    .modelContainer(for: [Media.self], inMemory: true)
}
