import SwiftUI

struct KanjiDisplayView: View {
    let kanji: KanjiItem
    @State private var showFurigana = false
    @State private var showMeaning = false

    var body: some View {
        VStack(spacing: 4) {
            // Furigana (readings) shown on double-tap
            if showFurigana {
                VStack(spacing: 2) {
                    if !kanji.kunReadings.isEmpty {
                        Text(kanji.kunReadings.joined(separator: "、"))
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                    if !kanji.onReadings.isEmpty {
                        Text(kanji.onReadings.joined(separator: "、"))
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }

            // Kanji character
            Text(kanji.character)
                .font(.system(size: 64))
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showFurigana.toggle()
                    }
                }
                .onLongPressGesture {
                    showMeaning = true
                }
                .popover(isPresented: $showMeaning) {
                    VStack(spacing: 8) {
                        Text(kanji.meaning)
                            .font(.headline)
                        if let level = kanji.jlptLevel {
                            Text("JLPT N\(level)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("\(kanji.strokeCount) strokes")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .presentationCompactAdaptation(.popover)
                }
        }
    }
}

struct KanjiDisplayCompactView: View {
    let kanji: KanjiItem
    @State private var showFurigana = false
    @State private var showMeaning = false

    var body: some View {
        VStack(spacing: 2) {
            if showFurigana {
                Text(kanji.kunReadings.first ?? kanji.onReadings.first ?? "")
                    .font(.system(size: 8))
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }

            Text(kanji.character)
                .font(.title2)
                .onTapGesture(count: 2) {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        showFurigana.toggle()
                    }
                }
                .onLongPressGesture {
                    showMeaning = true
                }
                .popover(isPresented: $showMeaning) {
                    Text(kanji.meaning)
                        .font(.subheadline)
                        .padding()
                        .presentationCompactAdaptation(.popover)
                }
        }
    }
}

#Preview {
    let sampleKanji = KanjiItem(
        character: "食",
        onReadings: ["ショク", "ジキ"],
        kunReadings: ["た.べる", "く.う"],
        meaning: "eat, food",
        strokeCount: 9,
        jlptLevel: 4,
        grade: 2
    )
    return VStack(spacing: 40) {
        KanjiDisplayView(kanji: sampleKanji)
        Text("Double-tap for readings, long-press for meaning")
            .font(.caption)
            .foregroundStyle(.secondary)
    }
}
