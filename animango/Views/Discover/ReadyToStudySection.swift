import SwiftUI

struct ReadyToStudySection: View {
    let media: [Media]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "book.circle.fill")
                    .foregroundStyle(.green)
                Text("Ready to Study")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)

            Text("Anime with vocabulary, kanji & grammar available")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(media, id: \.externalID) { item in
                        NavigationLink(value: item) {
                            ReadyToStudyCard(media: item)
                                .frame(width: 150)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

private struct ReadyToStudyCard: View {
    let media: Media

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: media.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(2/3, contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .aspectRatio(2/3, contentMode: .fill)
                        .overlay {
                            VStack(spacing: 4) {
                                Image(systemName: media.mediaType.iconName)
                                    .font(.title2)
                                    .foregroundStyle(.secondary)
                                Text(media.title)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 4)
                            }
                        }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.green.opacity(0.4), lineWidth: 2)
                )

                // Episode count badge
                if let status = media.status {
                    Text(status)
                        .font(.system(size: 9, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(.green)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                        .padding(6)
                }
            }

            Text(media.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)

            if let jpTitle = media.titleJapanese {
                Text(jpTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }
}

#Preview {
    let sampleMedia = [
        Media(externalID: "anime_5114", mediaType: .anime, title: "Fullmetal Alchemist: Brotherhood", titleJapanese: "鋼の錬金術師", status: "3 episodes ready"),
        Media(externalID: "anime_1535", mediaType: .anime, title: "Death Note", titleJapanese: "デスノート", status: "2 episodes ready"),
        Media(externalID: "anime_16498", mediaType: .anime, title: "Attack on Titan", titleJapanese: "進撃の巨人", status: "5 episodes ready"),
    ]
    return NavigationStack {
        ReadyToStudySection(media: sampleMedia)
    }
}
