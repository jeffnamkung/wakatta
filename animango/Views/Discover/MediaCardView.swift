import SwiftUI

struct MediaCardView: View {
    let media: Media

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Poster image
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
                            Image(systemName: media.mediaType.iconName)
                                .font(.title2)
                                .foregroundStyle(.secondary)
                        }
                }
                .clipShape(RoundedRectangle(cornerRadius: 8))

                // Score badge
                if let score = media.score, score > 0 {
                    Text(String(format: "%.1f", score))
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                        .padding(6)
                }
            }

            // Title
            Text(media.title)
                .font(.caption)
                .fontWeight(.medium)
                .lineLimit(2)

            // Japanese title if available
            if let jpTitle = media.titleJapanese {
                Text(jpTitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            // Media type badge
            HStack(spacing: 4) {
                Image(systemName: media.mediaType.iconName)
                    .font(.system(size: 9))
                Text(media.mediaType.displayName)
                    .font(.system(size: 10))
            }
            .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    let media = Media(
        externalID: "anime_1",
        mediaType: .anime,
        title: "Attack on Titan",
        titleJapanese: "進撃の巨人",
        synopsis: "A great anime",
        score: 8.9,
        genres: ["Action", "Drama"]
    )
    return MediaCardView(media: media)
        .frame(width: 150)
        .padding()
}
