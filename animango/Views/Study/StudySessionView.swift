import SwiftUI
import SwiftData

struct StudySessionView: View {
    let media: Media?
    let sessionType: StudyItemType?
    @State private var viewModel = StudySessionViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 20) {
            if viewModel.isSessionActive, let card = viewModel.currentCard {
                // Progress bar
                VStack(spacing: 4) {
                    ProgressView(value: viewModel.progress)
                        .tint(.accentColor)
                    HStack {
                        Text("\(viewModel.currentIndex + 1) of \(viewModel.cards.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(viewModel.remainingCards) remaining")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)

                Spacer()

                // Card
                StudyCard(
                    frontText: card.frontText,
                    frontSubtext: card.frontSubtext,
                    reading: card.reading,
                    meaning: card.meaning,
                    itemType: card.itemType,
                    isFlipped: viewModel.isFlipped
                )
                .padding(.horizontal)
                .onTapGesture {
                    if !viewModel.isFlipped {
                        viewModel.revealAnswer()
                    }
                }

                Spacer()

                // Grade buttons
                if viewModel.isFlipped {
                    HStack(spacing: 12) {
                        ForEach(SRSEngine.Grade.allCases, id: \.rawValue) { grade in
                            Button {
                                viewModel.gradeCard(grade, modelContext: modelContext)
                            } label: {
                                VStack(spacing: 4) {
                                    Text(grade.displayName)
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(gradeColor(grade))
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                            }
                        }
                    }
                    .padding(.horizontal)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    Text("Tap the card to reveal the answer")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

            } else if !viewModel.isSessionActive && viewModel.sessionResult.totalCards > 0 {
                // Session complete
                StudyResultView(result: viewModel.sessionResult) {
                    dismiss()
                }
            } else if viewModel.cards.isEmpty && !viewModel.isSessionActive {
                // No cards available
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 48))
                        .foregroundStyle(.green)
                    Text("All caught up!")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("No cards are due for review right now.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Button("Go Back") { dismiss() }
                        .buttonStyle(.bordered)
                }
            }
        }
        .padding(.vertical)
        .navigationTitle("Study Session")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("End") { dismiss() }
            }
        }
        .task {
            viewModel.startSession(
                media: media,
                sessionType: sessionType,
                modelContext: modelContext
            )
        }
    }

    private func gradeColor(_ grade: SRSEngine.Grade) -> Color {
        switch grade {
        case .again: return .red
        case .hard: return .orange
        case .good: return .blue
        case .easy: return .green
        }
    }
}

#Preview {
    NavigationStack {
        StudySessionView(media: nil, sessionType: nil)
    }
    .modelContainer(for: [
        VocabularyItem.self, KanjiItem.self, GrammarPoint.self,
        MediaVocabulary.self, MediaKanji.self, MediaGrammar.self,
        UserProgress.self
    ], inMemory: true)
}
