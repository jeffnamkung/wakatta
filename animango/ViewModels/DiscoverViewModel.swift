import Foundation
import SwiftData

@Observable
final class DiscoverViewModel {
    var searchText = ""
    var searchResults: [Media] = []
    var topAnime: [Media] = []
    var topManga: [Media] = []
    var popularMovies: [Media] = []
    var popularDrama: [Media] = []
    var selectedMediaType: MediaType?
    var isLoading = false
    var isSearching = false
    var errorMessage: String?

    private let searchService = MediaSearchService()
    private var searchTask: Task<Void, Never>?

    var filteredResults: [Media] {
        guard let type = selectedMediaType else { return searchResults }
        return searchResults.filter { $0.mediaType == type }
    }

    var isShowingSearchResults: Bool {
        !searchText.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func loadInitialContent() async {
        guard topAnime.isEmpty && topManga.isEmpty else { return }
        isLoading = true
        errorMessage = nil

        async let anime = searchService.getTopAnime()
        async let manga = searchService.getTopManga()
        async let movies = searchService.getPopularMovies()
        async let drama = searchService.getPopularDrama()

        topAnime = await anime
        topManga = await manga
        popularMovies = await movies
        popularDrama = await drama

        // Use fallback data when APIs are unavailable
        if topAnime.isEmpty {
            topAnime = Self.fallbackAnime
        }
        if topManga.isEmpty {
            topManga = Self.fallbackManga
        }
        if popularMovies.isEmpty {
            popularMovies = Self.fallbackMovies
        }
        if popularDrama.isEmpty {
            popularDrama = Self.fallbackDrama
        }
        isLoading = false
    }

    func retryLoading() async {
        topAnime = []
        topManga = []
        popularMovies = []
        popularDrama = []
        errorMessage = nil
        await loadInitialContent()
    }

    func search() {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else {
            searchResults = []
            return
        }

        searchTask?.cancel()
        searchTask = Task {
            isSearching = true
            errorMessage = nil

            let types: Set<MediaType>
            if let selected = selectedMediaType {
                types = [selected]
            } else {
                types = Set(MediaType.allCases)
            }

            let results = await searchService.search(query: query, mediaTypes: types)

            if !Task.isCancelled {
                searchResults = results
                isSearching = false
            }
        }
    }

    // MARK: - Fallback Data

    private static let fallbackAnime: [Media] = [
        Media(externalID: "anime_16498", mediaType: .anime, title: "Attack on Titan", titleJapanese: "進撃の巨人",
              synopsis: "Centuries ago, mankind was slaughtered to near extinction by monstrous humanoid creatures called Titans, forcing humans to hide in fear behind enormous concentric walls.", imageURL: "https://cdn.myanimelist.net/images/anime/10/47347l.jpg", score: 8.54, episodeCount: 25, status: "Finished Airing", genres: ["Action", "Drama", "Fantasy", "Military"], releaseYear: 2013, isInLibrary: false),
        Media(externalID: "anime_38000", mediaType: .anime, title: "Demon Slayer", titleJapanese: "鬼滅の刃",
              synopsis: "A family is attacked by demons and only two members survive—Tanjiro and his sister Nezuko, who is turning into a demon slowly. Tanjiro sets out to become a demon slayer to avenge his family and cure his sister.", imageURL: "https://cdn.myanimelist.net/images/anime/1286/99889l.jpg", score: 8.45, episodeCount: 26, status: "Finished Airing", genres: ["Action", "Fantasy", "Shounen"], releaseYear: 2019, isInLibrary: false),
        Media(externalID: "anime_5114", mediaType: .anime, title: "Fullmetal Alchemist: Brotherhood", titleJapanese: "鋼の錬金術師 FULLMETAL ALCHEMIST",
              synopsis: "Two brothers search for a Philosopher's Stone after an pointless attempt to resurrect their mother costs them dearly.", imageURL: "https://cdn.myanimelist.net/images/anime/1208/94745l.jpg", score: 9.09, episodeCount: 64, status: "Finished Airing", genres: ["Action", "Adventure", "Drama", "Fantasy"], releaseYear: 2009, isInLibrary: false),
        Media(externalID: "anime_11061", mediaType: .anime, title: "Hunter x Hunter (2011)", titleJapanese: "HUNTER×HUNTER (2011)",
              synopsis: "Gon Freecss aspires to become a Hunter, an exceptional being capable of greatness. With his friends, he begins the journey to find his father.", imageURL: "https://cdn.myanimelist.net/images/anime/1337/99013l.jpg", score: 9.04, episodeCount: 148, status: "Finished Airing", genres: ["Action", "Adventure", "Fantasy"], releaseYear: 2011, isInLibrary: false),
        Media(externalID: "anime_1535", mediaType: .anime, title: "Death Note", titleJapanese: "デスノート",
              synopsis: "A high school student discovers a supernatural notebook that grants its user the ability to kill anyone whose name and face they know.", imageURL: "https://cdn.myanimelist.net/images/anime/9/9453l.jpg", score: 8.62, episodeCount: 37, status: "Finished Airing", genres: ["Supernatural", "Suspense", "Thriller"], releaseYear: 2006, isInLibrary: false),
        Media(externalID: "anime_21", mediaType: .anime, title: "One Punch Man", titleJapanese: "ワンパンマン",
              synopsis: "Saitama is a hero who only became one for fun. After three years of special training, he has become so strong that he can defeat enemies with a single punch.", imageURL: "https://cdn.myanimelist.net/images/anime/12/73775l.jpg", score: 8.50, episodeCount: 12, status: "Finished Airing", genres: ["Action", "Comedy", "Sci-Fi"], releaseYear: 2015, isInLibrary: false),
    ]

    private static let fallbackManga: [Media] = [
        Media(externalID: "manga_2", mediaType: .manga, title: "Berserk", titleJapanese: "ベルセルク",
              synopsis: "Guts, a former mercenary now known as the Black Swordsman, is out for revenge, hunting down the man who sacrificed his companions.", imageURL: "https://cdn.myanimelist.net/images/manga/1/157897l.jpg", score: 9.43, episodeCount: 380, status: "Publishing", genres: ["Action", "Adventure", "Drama", "Fantasy", "Horror"], releaseYear: 1989, isInLibrary: false),
        Media(externalID: "manga_13", mediaType: .manga, title: "One Piece", titleJapanese: "ワンピース",
              synopsis: "Monkey D. Luffy refuses to let anyone or anything stand in the way of his quest to become the king of all pirates.", imageURL: "https://cdn.myanimelist.net/images/manga/2/253146l.jpg", score: 9.21, episodeCount: 1125, status: "Publishing", genres: ["Action", "Adventure", "Fantasy"], releaseYear: 1997, isInLibrary: false),
        Media(externalID: "manga_1706", mediaType: .manga, title: "JoJo's Bizarre Adventure Part 7: Steel Ball Run", titleJapanese: "ジョジョの奇妙な冒険 Part7 スティール・ボール・ラン",
              synopsis: "The story of a paraplegic jockey and a mysterious Italian who enter a cross-country horse race across the American frontier.", imageURL: "https://cdn.myanimelist.net/images/manga/3/179882l.jpg", score: 9.27, episodeCount: 96, status: "Finished", genres: ["Action", "Adventure", "Mystery", "Supernatural"], releaseYear: 2004, isInLibrary: false),
        Media(externalID: "manga_656", mediaType: .manga, title: "Vagabond", titleJapanese: "バガボンド",
              synopsis: "Growing up in the late 1500s Sengoku era Japan, Shinmen Takezou is shunned by the local villagers as a devil child due to his wild and violent nature.", imageURL: "https://cdn.myanimelist.net/images/manga/1/259070l.jpg", score: 9.20, episodeCount: 327, status: "On Hiatus", genres: ["Action", "Adventure", "Drama"], releaseYear: 1998, isInLibrary: false),
        Media(externalID: "manga_44347", mediaType: .manga, title: "Chainsaw Man", titleJapanese: "チェンソーマン",
              synopsis: "Denji has a simple dream—to live a happy and peaceful life, spending time with a girl he likes. But owing a huge debt to the yakuza has left him with no such luck.", imageURL: "https://cdn.myanimelist.net/images/manga/3/216464l.jpg", score: 8.70, episodeCount: 97, status: "Publishing", genres: ["Action", "Fantasy", "Horror"], releaseYear: 2018, isInLibrary: false),
        Media(externalID: "manga_25", mediaType: .manga, title: "Fullmetal Alchemist", titleJapanese: "鋼の錬金術師",
              synopsis: "Alchemy is bound by the Law of Equivalent Exchange—to obtain, something of equal value must be lost.", imageURL: "https://cdn.myanimelist.net/images/manga/1/27600l.jpg", score: 9.07, episodeCount: 116, status: "Finished", genres: ["Action", "Adventure", "Drama", "Fantasy"], releaseYear: 2001, isInLibrary: false),
    ]

    private static let fallbackMovies: [Media] = [
        Media(externalID: "movie_372058", mediaType: .movie, title: "Your Name", titleJapanese: "君の名は。",
              synopsis: "Two teenagers share a profound, magical connection upon discovering they are swapping bodies.", imageURL: "https://image.tmdb.org/t/p/w500/q719jXXEhI1THMotlPeGtMFr7Jd.jpg", score: 8.4, episodeCount: nil, status: "Released", genres: ["Animation", "Romance", "Drama"], releaseYear: 2016, isInLibrary: false),
        Media(externalID: "movie_129", mediaType: .movie, title: "Spirited Away", titleJapanese: "千と千尋の神隠し",
              synopsis: "A young girl becomes trapped in a strange new world of spirits. When her parents undergo a mysterious transformation, she must call upon the courage she never knew she had.", imageURL: "https://image.tmdb.org/t/p/w500/39wmItIWsg5sZMyRUHLkWBcuVCM.jpg", score: 8.5, episodeCount: nil, status: "Released", genres: ["Animation", "Fantasy", "Adventure"], releaseYear: 2001, isInLibrary: false),
        Media(externalID: "movie_149870", mediaType: .movie, title: "Suzume", titleJapanese: "すずめの戸締まり",
              synopsis: "A modern action adventure road story where a 17-year-old girl named Suzume helps a mysterious young man close doors from the other side that are releasing disasters all over Japan.", imageURL: "https://image.tmdb.org/t/p/w500/vIeu8WysZrTSFb2uhPViKjX9EcC.jpg", score: 7.9, episodeCount: nil, status: "Released", genres: ["Animation", "Adventure", "Fantasy"], releaseYear: 2022, isInLibrary: false),
        Media(externalID: "movie_508883", mediaType: .movie, title: "Princess Mononoke", titleJapanese: "もののけ姫",
              synopsis: "Ashitaka, a prince, is cursed by a demon boar and seeks a cure in the lands to the west. He finds himself in the middle of a war between the forest gods and a mining colony.", imageURL: "https://image.tmdb.org/t/p/w500/cMYCDADoLKLbB83g4WnJegaZimC.jpg", score: 8.3, episodeCount: nil, status: "Released", genres: ["Animation", "Adventure", "Fantasy"], releaseYear: 1997, isInLibrary: false),
        Media(externalID: "movie_4935", mediaType: .movie, title: "Howl's Moving Castle", titleJapanese: "ハウルの動く城",
              synopsis: "When Sophie, a shy young woman, is cursed with an old body by a spiteful witch, her only chance of breaking the spell lies with a self-indulgent yet insecure young wizard and his companions.", imageURL: "https://image.tmdb.org/t/p/w500/TkTPELv4kC3u1lkloush8skOjE.jpg", score: 8.2, episodeCount: nil, status: "Released", genres: ["Animation", "Fantasy", "Adventure"], releaseYear: 2004, isInLibrary: false),
        Media(externalID: "movie_568160", mediaType: .movie, title: "Weathering with You", titleJapanese: "天気の子",
              synopsis: "A high school boy who has run away to Tokyo befriends a girl who appears to be able to manipulate the weather.", imageURL: "https://image.tmdb.org/t/p/w500/qgrk7r1fV4IjuoeiGS5HOhXNdLJ.jpg", score: 8.0, episodeCount: nil, status: "Released", genres: ["Animation", "Romance", "Drama", "Fantasy"], releaseYear: 2019, isInLibrary: false),
    ]

    private static let fallbackDrama: [Media] = [
        Media(externalID: "drama_tls", mediaType: .jdrama, title: "Tokyo Love Story", titleJapanese: "東京ラブストーリー",
              synopsis: "A young woman falls in love with her coworker, but their relationship is complicated by old friendships and misunderstandings in 1990s Tokyo.", imageURL: nil, score: 8.2, episodeCount: 11, status: "Finished", genres: ["Romance", "Drama"], releaseYear: 1991, isInLibrary: false),
        Media(externalID: "drama_hn", mediaType: .jdrama, title: "Hanzawa Naoki", titleJapanese: "半沢直樹",
              synopsis: "A talented banker fights against corruption within his own organization, vowing to repay wrongdoing with double the vengeance.", imageURL: nil, score: 9.0, episodeCount: 10, status: "Finished", genres: ["Drama", "Business", "Thriller"], releaseYear: 2013, isInLibrary: false),
        Media(externalID: "drama_th", mediaType: .jdrama, title: "Terrace House", titleJapanese: "テラスハウス",
              synopsis: "Six strangers live together in a house, creating unscripted drama as they navigate work, love, and friendships in modern Japan.", imageURL: nil, score: 7.8, episodeCount: 46, status: "Finished", genres: ["Reality", "Romance", "Slice of Life"], releaseYear: 2012, isInLibrary: false),
        Media(externalID: "drama_alicein", mediaType: .jdrama, title: "Alice in Borderland", titleJapanese: "今際の国のアリス",
              synopsis: "A gamer and his friends find themselves in a deserted Tokyo where they must compete in dangerous games to survive.", imageURL: nil, score: 8.5, episodeCount: 8, status: "Finished", genres: ["Thriller", "Sci-Fi", "Action"], releaseYear: 2020, isInLibrary: false),
    ]

    func addToLibrary(_ media: Media, modelContext: ModelContext) {
        // Check if media already exists in the database
        let externalID = media.externalID
        let predicate = #Predicate<Media> { $0.externalID == externalID }
        let descriptor = FetchDescriptor(predicate: predicate)

        if let existing = try? modelContext.fetch(descriptor).first {
            existing.isInLibrary = true
            existing.dateAdded = Date()
        } else {
            media.isInLibrary = true
            media.dateAdded = Date()
            modelContext.insert(media)
        }

        try? modelContext.save()
    }
}
