import SwiftUI
import SwiftData

struct StudyView: View {
    @State private var viewModel = StudyViewModel()
    @Environment(\.modelContext) private var modelContext

    @Query(filter: #Predicate<Media> { $0.isInLibrary == true })
    private var libraryMedia: [Media]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Due items summary
                    VStack(spacing: 8) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 40))
                            .foregroundStyle(Color.accentColor)

                        Text("\(viewModel.dueItemCount)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))

                        Text("items to study")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Session type picker
                    SessionTypePickerView(selectedType: $viewModel.selectedSessionType)
                        .padding(.horizontal)

                    // Media picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Study From")
                            .font(.headline)

                        Button {
                            viewModel.selectedMedia = nil
                        } label: {
                            HStack {
                                Image(systemName: "square.grid.2x2")
                                Text("All Items")
                                Spacer()
                                if viewModel.selectedMedia == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .padding()
                            .background(viewModel.selectedMedia == nil ? Color.accentColor.opacity(0.1) : Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                        .buttonStyle(.plain)

                        ForEach(libraryMedia, id: \.externalID) { media in
                            Button {
                                viewModel.selectedMedia = media
                            } label: {
                                HStack {
                                    Image(systemName: media.mediaType.iconName)
                                    Text(media.title)
                                        .lineLimit(1)
                                    Spacer()
                                    if viewModel.selectedMedia?.externalID == media.externalID {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(Color.accentColor)
                                    }
                                }
                                .padding()
                                .background(
                                    viewModel.selectedMedia?.externalID == media.externalID
                                    ? Color.accentColor.opacity(0.1)
                                    : Color(.systemGray6)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)

                    // Start button
                    NavigationLink {
                        StudySessionView(
                            media: viewModel.selectedMedia,
                            sessionType: viewModel.selectedSessionType
                        )
                    } label: {
                        Text("Start Study Session")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal)
                    .disabled(viewModel.dueItemCount == 0 && libraryMedia.isEmpty)


                }
                .padding(.vertical)
            }
            .navigationTitle("Study")
            .task {
                viewModel.loadDueItems(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    StudyView()
        .modelContainer(for: [
            Media.self, VocabularyItem.self, KanjiItem.self,
            GrammarPoint.self, UserProgress.self,
            MediaVocabulary.self, MediaKanji.self, MediaGrammar.self
        ], inMemory: true)
}
