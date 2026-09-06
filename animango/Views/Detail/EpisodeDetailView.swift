import SwiftUI
import SwiftData

struct EpisodeDetailView: View {
    let episode: Episode
    let media: Media
    @State private var viewModel = EpisodeDetailViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Episode header
                episodeHeader

                // Generate content button (when no content exists)
                if !viewModel.hasContent && !viewModel.isLoading {
                    generateContentSection
                }

                // Language stats
                if !viewModel.vocabularyItems.isEmpty || !viewModel.kanjiItems.isEmpty || !viewModel.grammarPoints.isEmpty {
                    languageSection
                }

                // Lessons
                if !viewModel.lessons.isEmpty {
                    lessonsSection
                }
            }
            .padding()
        }
        .navigationTitle(episode.title)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Lesson.self) { lesson in
            LessonView(lesson: lesson)
        }
        .task {
            viewModel.loadContent(for: episode, modelContext: modelContext)
        }
    }

    private var generateContentSection: some View {
        VStack(spacing: 16) {
            if viewModel.contentGenerator.isGenerating {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                    Text(viewModel.contentGenerator.generationProgress)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.vertical, 20)
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 36))
                    .foregroundStyle(Color.accentColor)

                Text("No lessons yet")
                    .font(.headline)

                if viewModel.contentGenerator.isAIAvailable {
                    Text("Generate vocabulary and grammar lessons using \(viewModel.contentGenerator.llmManager.currentProvider.displayName).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text(viewModel.contentGenerator.aiUnavailableReason ?? "AI generation unavailable. Configure your AI provider in Settings, or basic lessons will be created from dictionary lookups.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                Button {
                    Task {
                        await viewModel.generateContent(for: episode, media: media, modelContext: modelContext)
                    }
                } label: {
                    Label("Generate Lessons", systemImage: "sparkles")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)

                if let error = viewModel.contentGenerator.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var episodeHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            let unitLabel = media.mediaType == .manga ? "Chapter" :
                            media.mediaType == .movie ? "" : "Episode"
            if !unitLabel.isEmpty {
                Text("\(unitLabel) \(episode.episodeNumber)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            if let jpTitle = episode.titleJapanese, jpTitle != episode.title {
                Text(jpTitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            if let synopsis = episode.synopsis {
                Text(synopsis)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Language Points")
                .font(.headline)

            HStack(spacing: 12) {
                statCard(icon: "text.book.closed", label: "Vocab", count: viewModel.vocabularyItems.count)
                statCard(icon: "character.ja", label: "Kanji", count: viewModel.kanjiItems.count)
                statCard(icon: "text.alignleft", label: "Grammar", count: viewModel.grammarPoints.count)
            }

            // Vocabulary list
            if !viewModel.vocabularyItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Vocabulary")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(viewModel.vocabularyItems, id: \.word) { vocab in
                        HStack {
                            Text(vocab.word)
                                .font(.body)
                                .fontWeight(.medium)
                            Text(vocab.reading)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(vocab.meaning)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Kanji list
            if !viewModel.kanjiItems.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Kanji")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
                        ForEach(viewModel.kanjiItems, id: \.character) { kanji in
                            VStack(spacing: 2) {
                                Text(kanji.character)
                                    .font(.title2)
                                Text(kanji.meaning.components(separatedBy: ",").first ?? "")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        }
                    }
                }
            }

            // Grammar points
            if !viewModel.grammarPoints.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Grammar")
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    ForEach(viewModel.grammarPoints, id: \.pattern) { grammar in
                        NavigationLink {
                            ChatTutorView(grammarPoint: grammar)
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(grammar.pattern)
                                        .font(.body)
                                        .fontWeight(.medium)
                                        .foregroundStyle(.primary)
                                    Text(grammar.explanation)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                if let level = grammar.jlptLevel {
                                    Text("N\(level)")
                                        .font(.caption2)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.jlptColor(level: level).opacity(0.2))
                                        .clipShape(Capsule())
                                }
                                Image(systemName: "brain.head.profile")
                                    .font(.caption)
                                    .foregroundStyle(Color.accentColor)
                            }
                            .padding(.vertical, 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
    }

    private var lessonsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Lessons")
                .font(.headline)

            ForEach(viewModel.lessons, id: \.id) { lesson in
                NavigationLink(value: lesson) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Lesson \(lesson.order)")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundStyle(.secondary)
                            Text(lesson.title)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                            Text("Grammar: \(lesson.grammarPattern)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func statCard(icon: String, label: String, count: Int) -> some View {
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
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
