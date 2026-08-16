import SwiftUI

struct StudyCard: View {
    let frontText: String
    let frontSubtext: String?
    let reading: String
    let meaning: String
    let itemType: StudyItemType
    let isFlipped: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)

            if isFlipped {
                backContent
            } else {
                frontContent
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 300)
    }

    private var frontContent: some View {
        VStack(spacing: 16) {
            // Item type indicator
            HStack(spacing: 4) {
                Image(systemName: itemType.iconName)
                    .font(.caption)
                Text(itemType.displayName)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            Spacer()

            Text(frontText)
                .font(.system(size: 48, weight: .medium))
                .minimumScaleFactor(0.5)

            if let subtext = frontSubtext {
                Text(subtext)
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text("Tap to reveal")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
    }

    private var backContent: some View {
        VStack(spacing: 16) {
            HStack(spacing: 4) {
                Image(systemName: itemType.iconName)
                    .font(.caption)
                Text(itemType.displayName)
                    .font(.caption)
            }
            .foregroundStyle(.secondary)

            Spacer()

            Text(frontText)
                .font(.system(size: 36, weight: .medium))
                .minimumScaleFactor(0.5)

            Text(reading)
                .font(.title3)
                .foregroundStyle(.orange)

            Text(meaning)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()

            AudioButton(text: frontText)
        }
        .padding(24)
    }
}

#Preview {
    VStack(spacing: 20) {
        StudyCard(
            frontText: "食べる",
            frontSubtext: nil,
            reading: "たべる",
            meaning: "to eat",
            itemType: .vocabulary,
            isFlipped: false
        )
        StudyCard(
            frontText: "食べる",
            frontSubtext: nil,
            reading: "たべる",
            meaning: "to eat",
            itemType: .vocabulary,
            isFlipped: true
        )
    }
    .padding()
}
