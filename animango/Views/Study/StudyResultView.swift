import SwiftUI

struct StudyResultView: View {
    let result: SessionResult
    let onDismiss: () -> Void

    var accuracy: Double {
        guard result.totalCards > 0 else { return 0 }
        return Double(result.correctCount) / Double(result.totalCards) * 100
    }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Result icon
            Image(systemName: accuracy >= 70 ? "star.fill" : "arrow.counterclockwise")
                .font(.system(size: 48))
                .foregroundStyle(accuracy >= 70 ? .yellow : .orange)

            Text("Session Complete")
                .font(.title)
                .fontWeight(.bold)

            // Stats grid
            VStack(spacing: 16) {
                HStack(spacing: 24) {
                    resultStat(value: "\(result.totalCards)", label: "Cards", color: .primary)
                    resultStat(value: "\(Int(accuracy))%", label: "Accuracy", color: accuracy >= 70 ? .green : .orange)
                }

                HStack(spacing: 24) {
                    resultStat(value: "\(result.correctCount)", label: "Correct", color: .green)
                    resultStat(value: "\(result.incorrectCount)", label: "Again", color: .red)
                }

                if result.promotedToKnown > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundStyle(.green)
                        Text("\(result.promotedToKnown) items promoted to Known")
                            .font(.subheadline)
                    }
                    .padding(.top, 8)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Spacer()

            Button(action: onDismiss) {
                Text("Done")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal)
        }
        .padding()
    }

    private func resultStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(color)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    StudyResultView(
        result: SessionResult(
            totalCards: 20,
            correctCount: 15,
            incorrectCount: 5,
            promotedToKnown: 3
        )
    ) {}
}
