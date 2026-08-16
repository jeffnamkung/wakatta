import SwiftUI

struct LibraryMediaRow: View {
    let media: Media
    let comprehension: Double

    var body: some View {
        HStack(spacing: 12) {
            // Poster thumbnail
            AsyncImage(url: URL(string: media.imageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(2/3, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray5))
                    .overlay {
                        Image(systemName: media.mediaType.iconName)
                            .foregroundStyle(.secondary)
                    }
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 6) {
                Text(media.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)

                if let jpTitle = media.titleJapanese {
                    Text(jpTitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                HStack(spacing: 8) {
                    // Type badge
                    HStack(spacing: 3) {
                        Image(systemName: media.mediaType.iconName)
                            .font(.system(size: 9))
                        Text(media.mediaType.displayName)
                            .font(.caption2)
                    }
                    .foregroundStyle(.secondary)

                    if let score = media.score, score > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.yellow)
                            Text(String(format: "%.1f", score))
                                .font(.caption2)
                        }
                    }
                }

                // Comprehension bar
                VStack(alignment: .leading, spacing: 2) {
                    ComprehensionBarView(percentage: comprehension)
                    Text("\(Int(comprehension))% understood")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        LibraryMediaRow(
            media: Media(
                externalID: "anime_1",
                mediaType: .anime,
                title: "Attack on Titan",
                titleJapanese: "進撃の巨人",
                score: 8.9
            ),
            comprehension: 42
        )
    }
}
