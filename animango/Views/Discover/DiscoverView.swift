import SwiftUI
import SwiftData

struct DiscoverView: View {
    @State private var viewModel = DiscoverViewModel()
    @Environment(\.modelContext) private var modelContext

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Media type filter
                    MediaTypeFilterBar(selectedType: $viewModel.selectedMediaType)
                        .onChange(of: viewModel.selectedMediaType) {
                            if viewModel.isShowingSearchResults {
                                viewModel.search()
                            }
                        }

                    if viewModel.isShowingSearchResults {
                        searchResultsContent
                    } else {
                        browseContent
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Discover")
            .searchable(
                text: $viewModel.searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search anime, manga, movies, games, jdrama..."
            )
            .onSubmit(of: .search) {
                viewModel.search()
            }
            .onChange(of: viewModel.searchText) {
                if viewModel.searchText.isEmpty {
                    viewModel.searchResults = []
                }
            }
            .navigationDestination(for: Media.self) { media in
                MediaDetailView(media: media)
            }
            .task {
                await viewModel.loadInitialContent()
            }
        }
    }

    @ViewBuilder
    private var searchResultsContent: some View {
        if viewModel.isSearching {
            LoadingView(message: "Searching...")
                .frame(height: 300)
        } else if viewModel.filteredResults.isEmpty {
            EmptyStateView(
                title: "No Results",
                message: "Try a different search term or change the media type filter"
            )
            .frame(height: 300)
        } else {
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(viewModel.filteredResults, id: \.externalID) { media in
                    NavigationLink(value: media) {
                        MediaCardView(media: media)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var browseContent: some View {
        if viewModel.isLoading {
            LoadingView()
                .frame(height: 300)
        } else {
            if !viewModel.readyToStudy.isEmpty {
                ReadyToStudySection(media: viewModel.readyToStudy)
            }

            if !viewModel.topAnime.isEmpty {
                RecommendationSection(
                    title: "Popular Anime",
                    media: viewModel.topAnime
                )
            }

            if !viewModel.topManga.isEmpty {
                RecommendationSection(
                    title: "Popular Manga",
                    media: viewModel.topManga
                )
            }

            if !viewModel.popularMovies.isEmpty {
                RecommendationSection(
                    title: "Japanese Movies",
                    media: viewModel.popularMovies
                )
            }

            if !viewModel.popularDrama.isEmpty {
                RecommendationSection(
                    title: "Popular JDrama",
                    media: viewModel.popularDrama
                )
            }
        }
    }
}

#Preview {
    DiscoverView()
        .modelContainer(for: [Media.self], inMemory: true)
}
