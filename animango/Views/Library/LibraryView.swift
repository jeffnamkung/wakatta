import SwiftUI
import SwiftData

struct LibraryView: View {
    @Query(filter: #Predicate<Media> { $0.isInLibrary == true })
    private var libraryMedia: [Media]

    @State private var viewModel = LibraryViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            Group {
                if libraryMedia.isEmpty {
                    EmptyStateView(
                        icon: "books.vertical",
                        title: "Your Library is Empty",
                        message: "Search for anime, games, or jdrama in the Discover tab and add them to your library to start learning"
                    )
                } else {
                    List {
                        // Filter and sort controls
                        Section {
                            HStack {
                                MediaTypeFilterBar(selectedType: $viewModel.selectedType)

                                Menu {
                                    ForEach(LibraryViewModel.SortOrder.allCases, id: \.rawValue) { order in
                                        Button {
                                            viewModel.sortOrder = order
                                        } label: {
                                            Label(order.rawValue, systemImage: order.iconName)
                                        }
                                    }
                                } label: {
                                    Image(systemName: "arrow.up.arrow.down")
                                        .font(.caption)
                                }
                            }
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 16))
                        }

                        // Media list
                        Section {
                            ForEach(viewModel.sortedMedia(libraryMedia), id: \.externalID) { media in
                                NavigationLink(value: media) {
                                    LibraryMediaRow(
                                        media: media,
                                        comprehension: viewModel.comprehension(for: media)
                                    )
                                }
                            }
                            .onDelete { indexSet in
                                let sorted = viewModel.sortedMedia(libraryMedia)
                                for index in indexSet {
                                    viewModel.removeFromLibrary(sorted[index], modelContext: modelContext)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("My Library")
            .navigationDestination(for: Media.self) { media in
                MediaDetailView(media: media)
            }
            .task {
                viewModel.refreshComprehension(modelContext: modelContext)
            }
            .refreshable {
                viewModel.refreshComprehension(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: [
            Media.self, MediaVocabulary.self, UserProgress.self
        ], inMemory: true)
}
