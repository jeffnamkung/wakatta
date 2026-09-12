import SwiftUI

/// Displays segmented Japanese text in a wrapping flow layout with optional furigana.
/// Each word is tappable to trigger a definition lookup.
struct TappableJapaneseTextView: View {
    let words: [AnnotatedWord]
    let showFurigana: Bool
    var onWordTap: (AnnotatedWord) -> Void

    var body: some View {
        WordFlowLayout(spacing: 1) {
            ForEach(words) { word in
                TappableWordView(
                    word: word,
                    showFurigana: showFurigana && word.reading != nil && containsKanji(word.surface)
                )
                .onTapGesture {
                    onWordTap(word)
                }
            }
        }
    }
}

/// A single tappable word with optional furigana reading above
struct TappableWordView: View {
    let word: AnnotatedWord
    let showFurigana: Bool

    var body: some View {
        VStack(spacing: 1) {
            if showFurigana, let reading = word.reading {
                Text(reading)
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
            Text(word.surface)
                .font(.body)
        }
        .padding(.horizontal, 1)
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.15), value: showFurigana)
    }
}

/// Flow layout for wrapping words inline, similar to FlowLayout in MediaDetailView
struct WordFlowLayout: Layout {
    var spacing: CGFloat = 1

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var totalHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            totalHeight = y + rowHeight
        }

        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

#Preview {
    TappableJapaneseTextView(
        words: [
            AnnotatedWord(surface: "今日", reading: "きょう"),
            AnnotatedWord(surface: "は"),
            AnnotatedWord(surface: "天気", reading: "てんき"),
            AnnotatedWord(surface: "が"),
            AnnotatedWord(surface: "いい"),
            AnnotatedWord(surface: "です")
        ],
        showFurigana: true,
        onWordTap: { _ in }
    )
    .padding()
}
