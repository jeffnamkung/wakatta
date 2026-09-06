import SwiftUI
import SwiftData

struct WordDetailView: View {
    let vocabulary: VocabularyItem
    @Environment(\.modelContext) private var modelContext
    @State private var showFurigana = false
    @State private var progress: UserProgress?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Main word display
                VStack(spacing: 8) {
                    FuriganaTextView(
                        text: vocabulary.word,
                        reading: vocabulary.reading,
                        showFurigana: showFurigana,
                        textFont: .system(size: 48, weight: .medium),
                        readingFont: .title3
                    )
                    .onTapGesture(count: 2) {
                        withAnimation { showFurigana.toggle() }
                    }

                    AudioButton(text: vocabulary.word)

                    Text(vocabulary.meaning)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                Divider()

                // Details
                VStack(alignment: .leading, spacing: 16) {
                    if let pos = vocabulary.partOfSpeech {
                        detailRow(label: "Part of Speech", value: pos)
                    }

                    detailRow(label: "Reading", value: vocabulary.reading)

                    if let level = vocabulary.jlptLevel {
                        detailRow(label: "JLPT Level", value: "N\(level)")
                    }

                    if let freq = vocabulary.frequency {
                        detailRow(label: "Frequency Rank", value: "#\(freq)")
                    }
                }
                .padding(.horizontal)

                // Example sentences
                if let exJP = vocabulary.exampleSentenceJP,
                   let exEN = vocabulary.exampleSentenceEN {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Example")
                            .font(.headline)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(exJP)
                                    .font(.body)
                                AudioButtonCompact(text: exJP)
                            }
                            Text(exEN)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal)
                }

                // Knowledge state
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Progress")
                        .font(.headline)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        stateButton(.neverLearned)
                        stateButton(.learning)
                        stateButton(.developing)
                        stateButton(.mastered)
                    }
                }
                .padding(.horizontal)

                Spacer()
            }
        }
        .navigationTitle("Word Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation { showFurigana.toggle() }
                } label: {
                    Image(systemName: showFurigana ? "eye.fill" : "eye.slash")
                }
            }
        }
        .task {
            loadProgress()
        }
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }

    private func stateButton(_ state: KnowledgeState) -> some View {
        let currentState = progress?.knowledgeState ?? .neverLearned
        let isSelected = currentState == state

        return Button {
            updateState(to: state)
        } label: {
            Label(state.shortName, systemImage: state.iconName)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isSelected ? state.color : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }

    private func loadProgress() {
        let word = vocabulary.word
        let type = StudyItemType.vocabulary
        let predicate = #Predicate<UserProgress> {
            $0.itemID == word && $0.itemType == type
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        progress = try? modelContext.fetch(descriptor).first
    }

    private func updateState(to state: KnowledgeState) {
        if let existing = progress {
            existing.knowledgeState = state
            existing.lastReviewedDate = Date()
        } else {
            let newProgress = UserProgress(
                itemID: vocabulary.word,
                itemType: .vocabulary,
                knowledgeState: state
            )
            newProgress.lastReviewedDate = Date()
            modelContext.insert(newProgress)
            progress = newProgress
        }
        try? modelContext.save()
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        WordDetailView(
            vocabulary: VocabularyItem(
                word: "食べる",
                reading: "たべる",
                meaning: "to eat",
                jlptLevel: 5,
                frequency: 200,
                partOfSpeech: "Verb (Ichidan)",
                exampleSentenceJP: "毎日りんごを食べる。",
                exampleSentenceEN: "I eat an apple every day."
            )
        )
    }
    .modelContainer(for: [UserProgress.self], inMemory: true)
}
