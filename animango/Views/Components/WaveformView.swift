import SwiftUI

struct WaveformView: View {
    let audioLevel: Float
    let barCount: Int

    init(audioLevel: Float, barCount: Int = 7) {
        self.audioLevel = audioLevel
        self.barCount = barCount
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<barCount, id: \.self) { index in
                WaveformBar(
                    audioLevel: audioLevel,
                    index: index,
                    totalBars: barCount
                )
            }
        }
        .frame(height: 40)
    }
}

private struct WaveformBar: View {
    let audioLevel: Float
    let index: Int
    let totalBars: Int

    @State private var animatedHeight: CGFloat = 0.1

    // Create a natural wave pattern — bars in the center are taller
    private var centerFactor: Double {
        let center = Double(totalBars - 1) / 2.0
        let distance = abs(Double(index) - center) / center
        return 1.0 - (distance * 0.4)
    }

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.accentColor.opacity(0.8))
            .frame(width: 4, height: max(4, animatedHeight * 40))
            .onChange(of: audioLevel) { _, newLevel in
                withAnimation(.easeInOut(duration: 0.1)) {
                    let level = Double(newLevel)
                    // Add slight variation per bar for natural look
                    let variation = 0.8 + Double.random(in: 0...0.4)
                    animatedHeight = CGFloat(max(0.1, level * centerFactor * variation))
                }
            }
    }
}
