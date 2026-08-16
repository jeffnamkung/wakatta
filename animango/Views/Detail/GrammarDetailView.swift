import SwiftUI
import SwiftData

struct GrammarDetailView: View {
    let grammar: GrammarPoint
    @State private var showFurigana = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Pattern display
                VStack(spacing: 8) {
                    Text(grammar.pattern)
                        .font(.system(size: 36, weight: .bold))
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)

                    if let level = grammar.jlptLevel {
                        Text("JLPT N\(level)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentColor.opacity(0.15))
                            .foregroundStyle(Color.accentColor)
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 20)

                Divider()

                // Explanation
                VStack(alignment: .leading, spacing: 8) {
                    Text("Explanation")
                        .font(.headline)
                    Text(grammar.explanation)
                        .font(.body)
                }

                // Examples
                if !grammar.examples.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Examples")
                                .font(.headline)
                            Spacer()
                            Button {
                                withAnimation { showFurigana.toggle() }
                            } label: {
                                Image(systemName: showFurigana ? "eye.fill" : "eye.slash")
                                    .font(.caption)
                            }
                        }

                        ForEach(grammar.examples, id: \.japanese) { example in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    if showFurigana {
                                        FuriganaTextView(
                                            text: example.japanese,
                                            reading: example.reading,
                                            textFont: .body,
                                            readingFont: .caption
                                        )
                                    } else {
                                        Text(example.japanese)
                                            .font(.body)
                                    }
                                    Spacer()
                                    AudioButtonCompact(text: example.japanese)
                                }
                                Text(example.english)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            .background(Color(.systemGray6))
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Grammar")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        GrammarDetailView(
            grammar: GrammarPoint(
                pattern: "〜ている",
                explanation: "Expresses an ongoing action or state. Similar to the English present progressive (-ing form). Used with action verbs to indicate an action in progress, and with state verbs to describe a current state.",
                jlptLevel: 5,
                examples: [
                    GrammarExample(
                        japanese: "今、本を読んでいる。",
                        reading: "いま、ほんをよんでいる。",
                        english: "I am reading a book right now."
                    ),
                    GrammarExample(
                        japanese: "彼女は東京に住んでいる。",
                        reading: "かのじょはとうきょうにすんでいる。",
                        english: "She lives in Tokyo."
                    )
                ]
            )
        )
    }
}
