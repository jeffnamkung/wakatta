import SwiftUI

struct PronunciationScoreView: View {
    let feedback: PronunciationFeedback

    var body: some View {
        VStack(spacing: 16) {
            // Overall score gauge
            ZStack {
                Circle()
                    .stroke(Color(.systemGray5), lineWidth: 8)
                    .frame(width: 100, height: 100)

                Circle()
                    .trim(from: 0, to: feedback.overallScore)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 2) {
                    Text("\(Int(feedback.overallScore * 100))")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Score")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            // Feedback message
            Text(feedback.feedbackMessage)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(scoreColor)
                .multilineTextAlignment(.center)

            // Sub-scores
            VStack(spacing: 8) {
                scoreBar(label: "Accuracy", value: feedback.textAccuracy, icon: "text.magnifyingglass")
                scoreBar(label: "Pitch", value: feedback.pitchScore, icon: "waveform")
                scoreBar(label: "Fluency", value: feedback.fluencyScore, icon: "metronome")
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Recognized vs expected text
            if feedback.recognizedText != feedback.expectedText {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "mic.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("You said:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(feedback.recognizedText.isEmpty ? "(no speech detected)" : feedback.recognizedText)
                        .font(.body)

                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Expected:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Text(feedback.expectedText)
                        .font(.body)
                        .foregroundStyle(.green)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    private var scoreColor: Color {
        if feedback.overallScore >= 0.85 {
            return .green
        } else if feedback.overallScore >= 0.6 {
            return .orange
        } else {
            return .red
        }
    }

    private func scoreBar(label: String, value: Double, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray4))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor(for: value))
                        .frame(width: geometry.size.width * value, height: 6)
                }
            }
            .frame(height: 6)

            Text("\(Int(value * 100))%")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .frame(width: 32, alignment: .trailing)
        }
    }

    private func barColor(for value: Double) -> Color {
        if value >= 0.8 { return .green }
        if value >= 0.5 { return .orange }
        return .red
    }
}
