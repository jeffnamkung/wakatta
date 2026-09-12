import SwiftUI

/// A sheet that displays the definition of a tapped word
struct WordPopupView: View {
    let word: AnnotatedWord?
    let definition: WordDefinition?
    let isLoading: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let word = word {
                    // Large word display with furigana
                    FuriganaTextView(
                        text: word.surface,
                        reading: word.reading ?? word.surface,
                        showFurigana: word.reading != nil,
                        textFont: .system(size: 36, weight: .medium),
                        readingFont: .title3
                    )
                    .padding(.top, 8)

                    // Audio playback
                    AudioButton(text: word.surface)

                    Divider()

                    if isLoading {
                        ProgressView("Looking up definition...")
                            .padding()
                    } else if let def = definition {
                        VStack(alignment: .leading, spacing: 12) {
                            // Meanings
                            ForEach(def.meanings, id: \.self) { meaning in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundStyle(.secondary)
                                    Text(meaning)
                                        .font(.body)
                                }
                            }

                            // Reading (if different from word display)
                            if let reading = def.reading, reading != word.surface {
                                HStack {
                                    Text("Reading:")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(reading)
                                        .font(.caption)
                                }
                            }

                            // JLPT badge + Part of speech
                            HStack(spacing: 8) {
                                if let level = def.jlptLevel {
                                    Text("JLPT N\(level)")
                                        .font(.caption)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.jlptColor(level: level).opacity(0.2))
                                        .foregroundStyle(Color.jlptColor(level: level))
                                        .clipShape(Capsule())
                                }

                                if let pos = def.partOfSpeech {
                                    Text(pos)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.secondary.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    }

                    Spacer()
                } else {
                    Text("No word selected")
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .navigationTitle("Definition")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    WordPopupView(
        word: AnnotatedWord(surface: "食べる", reading: "たべる"),
        definition: WordDefinition(
            word: "食べる",
            reading: "たべる",
            meanings: ["to eat", "to live on (e.g. a salary)"],
            jlptLevel: 5,
            partOfSpeech: "Ichidan verb"
        ),
        isLoading: false
    )
}
