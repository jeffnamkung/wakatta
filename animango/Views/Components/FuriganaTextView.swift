import SwiftUI

/// Displays Japanese text with furigana reading above
struct FuriganaTextView: View {
    let text: String
    let reading: String
    var showFurigana: Bool = true
    var textFont: Font = .title3
    var readingFont: Font = .caption

    var body: some View {
        VStack(spacing: 2) {
            if showFurigana {
                Text(reading)
                    .font(readingFont)
                    .foregroundStyle(.secondary)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
            Text(text)
                .font(textFont)
        }
    }
}

/// A word row that shows furigana on double-tap
struct FuriganaWordView: View {
    let word: String
    let reading: String
    @State private var showFurigana = false

    var body: some View {
        VStack(spacing: 2) {
            if showFurigana {
                Text(reading)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .transition(.opacity)
            }
            Text(word)
                .font(.body)
        }
        .onTapGesture(count: 2) {
            withAnimation(.easeInOut(duration: 0.15)) {
                showFurigana.toggle()
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        FuriganaTextView(text: "食べる", reading: "たべる")
        FuriganaTextView(text: "食べる", reading: "たべる", showFurigana: false)
        FuriganaWordView(word: "進撃", reading: "しんげき")
    }
}
