import SwiftUI
import SwiftData

struct ProfileView: View {
    @State private var viewModel = ProfileViewModel()
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Stats cards
                    HStack(spacing: 12) {
                        StatsCardView(
                            icon: "text.book.closed",
                            value: "\(viewModel.totalKnownWords)",
                            label: "Words Known",
                            color: .green
                        )
                        StatsCardView(
                            icon: "character.ja",
                            value: "\(viewModel.totalKnownKanji)",
                            label: "Kanji Known",
                            color: .blue
                        )
                        StatsCardView(
                            icon: "flame",
                            value: "\(viewModel.studyStreak)",
                            label: "Day Streak",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)

                    // Learning stats
                    HStack(spacing: 12) {
                        StatsCardView(
                            icon: "arrow.triangle.2.circlepath",
                            value: "\(viewModel.totalLearningWords)",
                            label: "Words Learning",
                            color: .orange
                        )
                        StatsCardView(
                            icon: "arrow.triangle.2.circlepath",
                            value: "\(viewModel.totalLearningKanji)",
                            label: "Kanji Learning",
                            color: .orange
                        )
                        StatsCardView(
                            icon: "text.alignleft",
                            value: "\(viewModel.totalGrammarStudied)",
                            label: "Grammar",
                            color: .purple
                        )
                    }
                    .padding(.horizontal)

                    // JLPT breakdown
                    if !viewModel.jlptBreakdown.isEmpty {
                        JLPTBreakdownChart(breakdown: viewModel.jlptBreakdown)
                            .padding(.horizontal)
                    }

                    // Legend
                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Circle().fill(.green).frame(width: 8, height: 8)
                            Text("Known").font(.caption).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 4) {
                            Circle().fill(.orange).frame(width: 8, height: 8)
                            Text("Learning").font(.caption).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 4) {
                            Circle().fill(Color(.systemGray4)).frame(width: 8, height: 8)
                            Text("New").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .task {
                viewModel.loadStats(modelContext: modelContext)
            }
            .refreshable {
                viewModel.loadStats(modelContext: modelContext)
            }
        }
    }
}

#Preview {
    ProfileView()
        .modelContainer(for: [
            VocabularyItem.self, KanjiItem.self, GrammarPoint.self,
            UserProgress.self
        ], inMemory: true)
}
