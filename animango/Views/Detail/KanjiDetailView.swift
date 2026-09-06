import SwiftUI
import SwiftData

struct KanjiDetailView: View {
    let kanji: KanjiItem
    @Environment(\.modelContext) private var modelContext
    @State private var progress: UserProgress?

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Large kanji display with gesture support
                KanjiDisplayView(kanji: kanji)
                    .padding(.top, 20)

                Text("Double-tap for readings, long-press for meaning")
                    .font(.caption)
                    .foregroundStyle(.tertiary)

                AudioButton(text: kanji.character)

                Divider()

                // Readings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Readings")
                        .font(.headline)

                    if !kanji.onReadings.isEmpty {
                        readingRow(
                            label: "On'yomi (Chinese)",
                            readings: kanji.onReadings,
                            color: .blue
                        )
                    }

                    if !kanji.kunReadings.isEmpty {
                        readingRow(
                            label: "Kun'yomi (Japanese)",
                            readings: kanji.kunReadings,
                            color: .orange
                        )
                    }
                }
                .padding(.horizontal)

                // Meaning
                VStack(alignment: .leading, spacing: 8) {
                    Text("Meaning")
                        .font(.headline)
                    Text(kanji.meaning)
                        .font(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                // Details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Details")
                        .font(.headline)

                    detailRow(label: "Stroke Count", value: "\(kanji.strokeCount)")

                    if let level = kanji.jlptLevel {
                        detailRow(label: "JLPT Level", value: "N\(level)")
                    }

                    if let grade = kanji.grade {
                        detailRow(label: "School Grade", value: "Grade \(grade)")
                    }
                }
                .padding(.horizontal)

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
        .navigationTitle("Kanji Detail")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            loadProgress()
        }
    }

    private func readingRow(label: String, readings: [String], color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            FlowLayout(spacing: 6) {
                ForEach(readings, id: \.self) { reading in
                    HStack(spacing: 4) {
                        Text(reading)
                            .font(.body)
                        AudioButtonCompact(text: reading)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(color.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
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
        let char = kanji.character
        let type = StudyItemType.kanji
        let predicate = #Predicate<UserProgress> {
            $0.itemID == char && $0.itemType == type
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
                itemID: kanji.character,
                itemType: .kanji,
                knowledgeState: state
            )
            newProgress.lastReviewedDate = Date()
            modelContext.insert(newProgress)
            progress = newProgress
        }
        try? modelContext.save()
    }
}

#Preview {
    NavigationStack {
        KanjiDetailView(
            kanji: KanjiItem(
                character: "食",
                onReadings: ["ショク", "ジキ"],
                kunReadings: ["た.べる", "く.う"],
                meaning: "eat, food",
                strokeCount: 9,
                jlptLevel: 4,
                grade: 2
            )
        )
    }
    .modelContainer(for: [UserProgress.self], inMemory: true)
}
