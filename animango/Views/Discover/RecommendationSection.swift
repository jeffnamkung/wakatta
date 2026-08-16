import SwiftUI

struct RecommendationSection: View {
    let title: String
    let media: [Media]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 12) {
                    ForEach(media, id: \.externalID) { item in
                        NavigationLink(value: item) {
                            MediaCardView(media: item)
                                .frame(width: 130)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

#Preview {
    let sampleMedia = [
        Media(externalID: "anime_1", mediaType: .anime, title: "Attack on Titan", titleJapanese: "進撃の巨人", score: 8.9),
        Media(externalID: "anime_2", mediaType: .anime, title: "Demon Slayer", titleJapanese: "鬼滅の刃", score: 8.5),
        Media(externalID: "anime_3", mediaType: .anime, title: "Jujutsu Kaisen", titleJapanese: "呪術廻戦", score: 8.7),
    ]
    return NavigationStack {
        RecommendationSection(title: "Popular Anime", media: sampleMedia)
    }
}
