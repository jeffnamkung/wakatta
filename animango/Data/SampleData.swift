import Foundation
import SwiftData

/// Loads sample vocabulary, kanji, grammar data and media mappings
/// for a few popular titles so the app has content to demonstrate
struct SampleData {

    static func loadIfNeeded(modelContext: ModelContext) {
        // Check if we've already loaded data
        let vocabCount = (try? modelContext.fetchCount(FetchDescriptor<VocabularyItem>())) ?? 0
        guard vocabCount == 0 else { return }

        loadVocabulary(modelContext: modelContext)
        loadKanji(modelContext: modelContext)
        loadGrammar(modelContext: modelContext)
        loadMappings(modelContext: modelContext)
        loadEpisodes(modelContext: modelContext)
        loadEpisodeMappings(modelContext: modelContext)
        loadLessons(modelContext: modelContext)

        try? modelContext.save()
    }

    // MARK: - Vocabulary

    private static func loadVocabulary(modelContext: ModelContext) {
        let items: [(String, String, String, Int?, Int?, String?, String?, String?)] = [
            // Attack on Titan / 進撃の巨人
            ("巨人", "きょじん", "giant; titan", 2, 3000, "Noun", "巨人が壁を破壊した。", "The titan destroyed the wall."),
            ("進撃", "しんげき", "advance; charge", 1, 8000, "Noun", "兵士たちは進撃した。", "The soldiers advanced."),
            ("壁", "かべ", "wall", 3, 1500, "Noun", "壁の外に何がある？", "What is outside the wall?"),
            ("兵士", "へいし", "soldier", 2, 4000, "Noun", "兵士たちは訓練している。", "The soldiers are training."),
            ("戦う", "たたかう", "to fight; to battle", 3, 2000, "Verb (Godan)", "彼は巨人と戦う。", "He fights against the titans."),
            ("人類", "じんるい", "humanity; mankind", 2, 3500, "Noun", "人類は生き残れるか？", "Can humanity survive?"),
            ("調査", "ちょうさ", "investigation; survey", 2, 2500, "Noun", "調査兵団が出発した。", "The Survey Corps departed."),
            ("自由", "じゆう", "freedom; liberty", 3, 1000, "Noun/Adj", "自由になりたい。", "I want to be free."),

            // Demon Slayer / 鬼滅の刃
            ("鬼", "おに", "demon; ogre", 2, 5000, "Noun", "鬼を倒すために修行する。", "Training to defeat the demons."),
            ("刃", "やいば", "blade; sword", 1, 7000, "Noun", "日輪刀の刃が光る。", "The blade of the Nichirin sword shines."),
            ("呼吸", "こきゅう", "breathing", 3, 3000, "Noun", "水の呼吸を使う。", "Using Water Breathing."),
            ("修行", "しゅぎょう", "training; ascetic practice", 2, 6000, "Noun", "厳しい修行を受ける。", "Undertaking harsh training."),
            ("妹", "いもうと", "younger sister", 5, 800, "Noun", "妹を守りたい。", "I want to protect my sister."),
            ("強い", "つよい", "strong", 4, 500, "Adjective", "彼はとても強い。", "He is very strong."),

            // General anime vocabulary
            ("友達", "ともだち", "friend", 5, 300, "Noun", "彼は私の友達です。", "He is my friend."),
            ("学校", "がっこう", "school", 5, 200, "Noun", "学校に行きます。", "I go to school."),
            ("食べる", "たべる", "to eat", 5, 100, "Verb (Ichidan)", "毎日りんごを食べる。", "I eat an apple every day."),
            ("見る", "みる", "to see; to watch", 5, 80, "Verb (Ichidan)", "アニメを見る。", "I watch anime."),
            ("話す", "はなす", "to speak; to talk", 4, 250, "Verb (Godan)", "日本語を話す。", "I speak Japanese."),
            ("走る", "はしる", "to run", 4, 400, "Verb (Godan)", "速く走る。", "Run fast."),
            ("勝つ", "かつ", "to win", 3, 1200, "Verb (Godan)", "絶対に勝つ！", "I will definitely win!"),
            ("負ける", "まける", "to lose; to be defeated", 3, 1800, "Verb (Ichidan)", "負けたくない。", "I don't want to lose."),
            ("守る", "まもる", "to protect; to guard", 3, 1500, "Verb (Godan)", "仲間を守る。", "Protect your comrades."),
            ("約束", "やくそく", "promise", 3, 2000, "Noun", "約束を守る。", "Keep a promise."),
            ("仲間", "なかま", "companion; comrade", 3, 2200, "Noun", "仲間と一緒に戦う。", "Fight together with comrades."),
            ("力", "ちから", "power; strength", 3, 800, "Noun", "もっと力が必要だ。", "I need more power."),

            // Video game vocabulary
            ("冒険", "ぼうけん", "adventure", 3, 3500, "Noun", "新しい冒険が始まる。", "A new adventure begins."),
            ("魔法", "まほう", "magic; sorcery", 2, 4000, "Noun", "魔法を使う。", "Use magic."),
            ("武器", "ぶき", "weapon", 2, 3000, "Noun", "新しい武器を手に入れた。", "Obtained a new weapon."),
            ("敵", "てき", "enemy", 3, 1500, "Noun", "敵を倒す。", "Defeat the enemy."),
            ("宝物", "たからもの", "treasure", 3, 5000, "Noun", "宝物を見つけた。", "Found a treasure."),

            // JDrama vocabulary
            ("事件", "じけん", "incident; case", 3, 1000, "Noun", "大きな事件が起きた。", "A major incident occurred."),
            ("犯人", "はんにん", "criminal; culprit", 2, 3000, "Noun", "犯人は誰だ？", "Who is the culprit?"),
            ("恋愛", "れんあい", "romance; love affair", 2, 2500, "Noun", "恋愛ドラマが好き。", "I like romance dramas."),
            ("会社", "かいしゃ", "company; corporation", 4, 400, "Noun", "会社に行く。", "I go to the company."),
            ("医者", "いしゃ", "doctor", 4, 600, "Noun", "医者になりたい。", "I want to become a doctor."),
        ]

        for item in items {
            let vocab = VocabularyItem(
                word: item.0,
                reading: item.1,
                meaning: item.2,
                jlptLevel: item.3,
                frequency: item.4,
                partOfSpeech: item.5,
                exampleSentenceJP: item.6,
                exampleSentenceEN: item.7
            )
            modelContext.insert(vocab)
        }
    }

    // MARK: - Kanji

    private static func loadKanji(modelContext: ModelContext) {
        let items: [(String, [String], [String], String, Int, Int?, Int?)] = [
            ("巨", ["キョ"], ["おお.きい"], "gigantic, enormous", 5, 2, nil),
            ("人", ["ジン", "ニン"], ["ひと"], "person, people", 2, 5, 1),
            ("進", ["シン"], ["すす.む", "すす.める"], "advance, proceed", 11, 3, 3),
            ("撃", ["ゲキ"], ["う.つ"], "attack, strike", 15, 1, nil),
            ("壁", ["ヘキ"], ["かべ"], "wall, fence", 16, 2, nil),
            ("兵", ["ヘイ"], ["つわもの"], "soldier, warrior", 7, 3, 4),
            ("戦", ["セン"], ["いくさ", "たたか.う"], "war, battle, fight", 13, 3, 4),
            ("鬼", ["キ"], ["おに"], "demon, devil, ogre", 10, 1, nil),
            ("刃", ["ジン"], ["は", "やいば"], "blade, edge", 3, 1, nil),
            ("食", ["ショク", "ジキ"], ["た.べる", "く.う"], "eat, food", 9, 4, 2),
            ("見", ["ケン"], ["み.る", "み.える"], "see, look, watch", 7, 5, 1),
            ("話", ["ワ"], ["はな.す", "はなし"], "talk, speak, story", 13, 4, 2),
            ("力", ["リョク", "リキ"], ["ちから"], "power, strength, force", 2, 4, 1),
            ("友", ["ユウ"], ["とも"], "friend, companion", 4, 4, 2),
            ("学", ["ガク"], ["まな.ぶ"], "study, learning", 8, 4, 1),
            ("魔", ["マ"], [], "demon, evil spirit, magic", 21, 2, nil),
            ("法", ["ホウ"], [], "law, method, way", 8, 3, 4),
            ("冒", ["ボウ"], ["おか.す"], "risk, brave, dare", 9, 2, nil),
            ("険", ["ケン"], ["けわ.しい"], "danger, steep, rugged", 11, 3, nil),
            ("自", ["ジ", "シ"], ["みずか.ら"], "self, oneself", 6, 4, 2),
            ("由", ["ユウ", "ユ"], ["よし"], "reason, cause, from", 5, 3, 3),
        ]

        for item in items {
            let kanji = KanjiItem(
                character: item.0,
                onReadings: item.1,
                kunReadings: item.2,
                meaning: item.3,
                strokeCount: item.4,
                jlptLevel: item.5,
                grade: item.6
            )
            modelContext.insert(kanji)
        }
    }

    // MARK: - Grammar

    private static func loadGrammar(modelContext: ModelContext) {
        let items: [(String, String, Int, [GrammarExample])] = [
            (
                "〜ている",
                "Expresses an ongoing action or a resulting state. With action verbs, it indicates something currently happening. With change-of-state verbs, it describes the result of a completed change.",
                5,
                [
                    GrammarExample(japanese: "今、本を読んでいる。", reading: "いま、ほんをよんでいる。", english: "I am reading a book right now."),
                    GrammarExample(japanese: "窓が開いている。", reading: "まどがあいている。", english: "The window is open.")
                ]
            ),
            (
                "〜たい",
                "Expresses the speaker's desire or wish to do something. Conjugates like an i-adjective. Only used for first person in statements; for questions, can ask about second person.",
                5,
                [
                    GrammarExample(japanese: "日本に行きたい。", reading: "にほんにいきたい。", english: "I want to go to Japan."),
                    GrammarExample(japanese: "何が食べたいですか？", reading: "なにがたべたいですか？", english: "What do you want to eat?")
                ]
            ),
            (
                "〜てもいい",
                "Asks for or grants permission. Literally means 'even if you do X, it's good/fine.'",
                4,
                [
                    GrammarExample(japanese: "ここに座ってもいいですか？", reading: "ここにすわってもいいですか？", english: "May I sit here?"),
                    GrammarExample(japanese: "帰ってもいいよ。", reading: "かえってもいいよ。", english: "You may go home.")
                ]
            ),
            (
                "〜なければならない",
                "Expresses obligation or necessity — 'must do' or 'have to do'. Common in formal contexts. Casual forms: 〜なきゃ, 〜ないと.",
                4,
                [
                    GrammarExample(japanese: "宿題をしなければならない。", reading: "しゅくだいをしなければならない。", english: "I have to do my homework."),
                    GrammarExample(japanese: "もっと強くならなければならない。", reading: "もっとつよくならなければならない。", english: "I must become stronger.")
                ]
            ),
            (
                "〜ようにする",
                "Expresses making an effort or taking steps to do something habitually. 'Try to do' or 'make sure to do.'",
                3,
                [
                    GrammarExample(japanese: "毎日運動するようにしている。", reading: "まいにちうんどうするようにしている。", english: "I try to exercise every day."),
                    GrammarExample(japanese: "遅刻しないようにする。", reading: "ちこくしないようにする。", english: "I'll make sure not to be late.")
                ]
            ),
            (
                "〜ことにする",
                "Expresses a decision made by the speaker. 'Decide to do.' Past tense (〜ことにした) means the decision has been made.",
                3,
                [
                    GrammarExample(japanese: "来年日本に行くことにした。", reading: "らいねんにほんにいくことにした。", english: "I decided to go to Japan next year."),
                    GrammarExample(japanese: "毎朝走ることにする。", reading: "まいあさはしることにする。", english: "I'll decide to run every morning.")
                ]
            ),
        ]

        for item in items {
            let grammar = GrammarPoint(
                pattern: item.0,
                explanation: item.1,
                jlptLevel: item.2,
                examples: item.3
            )
            modelContext.insert(grammar)
        }
    }

    // MARK: - Media-to-Language Mappings

    private static func loadMappings(modelContext: ModelContext) {
        // Attack on Titan vocabulary
        let aotVocab = ["巨人", "進撃", "壁", "兵士", "戦う", "人類", "調査", "自由", "強い", "守る", "仲間", "力", "敵"]
        for word in aotVocab {
            modelContext.insert(MediaVocabulary(mediaExternalID: "anime_16498", vocabularyWord: word, frequency: Int.random(in: 1...20)))
        }
        let aotKanji = ["巨", "人", "進", "撃", "壁", "兵", "戦", "力", "自", "由"]
        for char in aotKanji {
            modelContext.insert(MediaKanji(mediaExternalID: "anime_16498", kanjiCharacter: char))
        }
        let aotGrammar = ["〜ている", "〜なければならない"]
        for pattern in aotGrammar {
            modelContext.insert(MediaGrammar(mediaExternalID: "anime_16498", grammarPattern: pattern))
        }

        // Demon Slayer vocabulary
        let dsVocab = ["鬼", "刃", "呼吸", "修行", "妹", "強い", "戦う", "守る", "力", "仲間"]
        for word in dsVocab {
            modelContext.insert(MediaVocabulary(mediaExternalID: "anime_38000", vocabularyWord: word, frequency: Int.random(in: 1...15)))
        }
        let dsKanji = ["鬼", "刃", "食", "見", "力", "友", "学"]
        for char in dsKanji {
            modelContext.insert(MediaKanji(mediaExternalID: "anime_38000", kanjiCharacter: char))
        }
        let dsGrammar = ["〜たい", "〜ている", "〜てもいい"]
        for pattern in dsGrammar {
            modelContext.insert(MediaGrammar(mediaExternalID: "anime_38000", grammarPattern: pattern))
        }

        // General anime mappings (basic vocabulary)
        let basicVocab = ["友達", "学校", "食べる", "見る", "話す", "走る"]
        for word in basicVocab {
            modelContext.insert(MediaVocabulary(mediaExternalID: "anime_16498", vocabularyWord: word, frequency: Int.random(in: 1...10)))
            modelContext.insert(MediaVocabulary(mediaExternalID: "anime_38000", vocabularyWord: word, frequency: Int.random(in: 1...10)))
        }

        // Final Fantasy (game) mappings
        let ffVocab = ["冒険", "魔法", "武器", "敵", "宝物", "力", "仲間", "勝つ"]
        for word in ffVocab {
            modelContext.insert(MediaVocabulary(mediaExternalID: "game_1", vocabularyWord: word, frequency: Int.random(in: 1...12)))
        }
        let ffKanji = ["魔", "法", "冒", "険", "力"]
        for char in ffKanji {
            modelContext.insert(MediaKanji(mediaExternalID: "game_1", kanjiCharacter: char))
        }

        // FMA: Brotherhood mappings
        let fmaVocab = ["戦う", "兵士", "力", "仲間", "敵", "守る", "勝つ", "約束"]
        for word in fmaVocab {
            modelContext.insert(MediaVocabulary(mediaExternalID: "anime_5114", vocabularyWord: word, frequency: Int.random(in: 1...15)))
        }
        let fmaKanji = ["人", "力", "戦", "友", "学"]
        for char in fmaKanji {
            modelContext.insert(MediaKanji(mediaExternalID: "anime_5114", kanjiCharacter: char))
        }
        let fmaGrammar = ["〜なければならない", "〜ている"]
        for pattern in fmaGrammar {
            modelContext.insert(MediaGrammar(mediaExternalID: "anime_5114", grammarPattern: pattern))
        }

        // Hunter x Hunter mappings
        let hxhVocab = ["友達", "冒険", "力", "戦う", "敵", "強い", "仲間", "走る"]
        for word in hxhVocab {
            modelContext.insert(MediaVocabulary(mediaExternalID: "anime_11061", vocabularyWord: word, frequency: Int.random(in: 1...15)))
        }
        let hxhGrammar = ["〜たい", "〜ようにする"]
        for pattern in hxhGrammar {
            modelContext.insert(MediaGrammar(mediaExternalID: "anime_11061", grammarPattern: pattern))
        }

        // Death Note mappings
        let dnVocab = ["事件", "犯人", "力", "見る", "話す", "敵", "自由", "約束"]
        for word in dnVocab {
            modelContext.insert(MediaVocabulary(mediaExternalID: "anime_1535", vocabularyWord: word, frequency: Int.random(in: 1...15)))
        }
        let dnGrammar = ["〜ている", "〜ことにする"]
        for pattern in dnGrammar {
            modelContext.insert(MediaGrammar(mediaExternalID: "anime_1535", grammarPattern: pattern))
        }

        // One Punch Man mappings
        let opmVocab = ["強い", "戦う", "敵", "力", "走る", "勝つ", "負ける"]
        for word in opmVocab {
            modelContext.insert(MediaVocabulary(mediaExternalID: "anime_21", vocabularyWord: word, frequency: Int.random(in: 1...15)))
        }
        let opmGrammar = ["〜ている", "〜たい"]
        for pattern in opmGrammar {
            modelContext.insert(MediaGrammar(mediaExternalID: "anime_21", grammarPattern: pattern))
        }

        // Manga mappings — shared vocabulary
        let mangaAction = ["戦う", "力", "敵", "仲間", "強い", "守る", "勝つ", "負ける"]
        for mediaID in ["manga_2", "manga_13", "manga_1706", "manga_656", "manga_44347", "manga_25"] {
            for word in mangaAction {
                modelContext.insert(MediaVocabulary(mediaExternalID: mediaID, vocabularyWord: word, frequency: Int.random(in: 1...12)))
            }
            for pattern in ["〜ている", "〜たい"] {
                modelContext.insert(MediaGrammar(mediaExternalID: mediaID, grammarPattern: pattern))
            }
        }
        // Additional manga-specific vocab
        for word in ["冒険", "武器", "魔法"] {
            modelContext.insert(MediaVocabulary(mediaExternalID: "manga_13", vocabularyWord: word, frequency: Int.random(in: 1...10)))
            modelContext.insert(MediaVocabulary(mediaExternalID: "manga_1706", vocabularyWord: word, frequency: Int.random(in: 1...10)))
        }

        // JDrama mappings
        let dramaCommon = ["事件", "犯人", "恋愛", "会社", "医者", "話す", "見る", "約束"]
        for word in dramaCommon {
            for mediaID in ["drama_tls", "drama_hn", "drama_th"] {
                modelContext.insert(MediaVocabulary(mediaExternalID: mediaID, vocabularyWord: word, frequency: Int.random(in: 1...10)))
            }
        }
        for mediaID in ["drama_tls", "drama_hn", "drama_th"] {
            for pattern in ["〜ている", "〜たい", "〜てもいい"] {
                modelContext.insert(MediaGrammar(mediaExternalID: mediaID, grammarPattern: pattern))
            }
        }

        // Movie mappings (Your Name)
        let movieVocab = ["友達", "学校", "見る", "話す", "約束", "守る", "自由", "恋愛"]
        for word in movieVocab {
            modelContext.insert(MediaVocabulary(mediaExternalID: "movie_372058", vocabularyWord: word, frequency: Int.random(in: 1...10)))
        }
        let movieKanji = ["友", "学", "見", "話", "自", "由"]
        for char in movieKanji {
            modelContext.insert(MediaKanji(mediaExternalID: "movie_372058", kanjiCharacter: char))
        }
        let movieGrammar = ["〜たい", "〜ている", "〜ことにする"]
        for pattern in movieGrammar {
            modelContext.insert(MediaGrammar(mediaExternalID: "movie_372058", grammarPattern: pattern))
        }

        // Other movie mappings
        let otherMovieVocab = ["友達", "見る", "話す", "約束", "守る", "食べる"]
        for mediaID in ["movie_129", "movie_149870", "movie_508883", "movie_4935", "movie_568160"] {
            for word in otherMovieVocab {
                modelContext.insert(MediaVocabulary(mediaExternalID: mediaID, vocabularyWord: word, frequency: Int.random(in: 1...10)))
            }
            for pattern in ["〜ている", "〜たい"] {
                modelContext.insert(MediaGrammar(mediaExternalID: mediaID, grammarPattern: pattern))
            }
        }
    }

    // MARK: - Episodes

    private static func loadEpisodes(modelContext: ModelContext) {
        // Attack on Titan episodes
        let aotEpisodes: [(String, Int, String, String?, String?)] = [
            ("anime_16498_ep1", 1, "To You, in 2000 Years", "二千年後の君へ",
             "After 100 years of peace, humanity's calm is shattered when a colossal Titan breaches the wall."),
            ("anime_16498_ep2", 2, "That Day", "その日",
             "After the Titans break through the wall, Eren vows to kill every last Titan."),
            ("anime_16498_ep3", 3, "A Dim Light Amid Despair", "絶望の中で鈍く光る",
             "Eren begins his training as a cadet in the Survey Corps.")
        ]

        for ep in aotEpisodes {
            modelContext.insert(Episode(
                id: ep.0, mediaExternalID: "anime_16498", episodeNumber: ep.1,
                title: ep.2, titleJapanese: ep.3, synopsis: ep.4
            ))
        }

        // Demon Slayer episodes
        let dsEpisodes: [(String, Int, String, String?, String?)] = [
            ("anime_38000_ep1", 1, "Cruelty", "残酷",
             "Tanjiro returns home to find his family slaughtered by demons. Only his sister Nezuko survives, but she has been turned into a demon."),
            ("anime_38000_ep2", 2, "Trainer Sakonji Urokodaki", "育手・鱗滝左近次",
             "Tanjiro begins his training under Urokodaki to become a demon slayer.")
        ]

        for ep in dsEpisodes {
            modelContext.insert(Episode(
                id: ep.0, mediaExternalID: "anime_38000", episodeNumber: ep.1,
                title: ep.2, titleJapanese: ep.3, synopsis: ep.4
            ))
        }

        // Fullmetal Alchemist: Brotherhood episodes
        let fmaEpisodes: [(String, Int, String, String?, String?)] = [
            ("anime_5114_ep1", 1, "Fullmetal Alchemist", "鋼の錬金術師",
             "The Elric brothers accept a mission to capture a rogue alchemist terrorizing a small town."),
            ("anime_5114_ep2", 2, "The First Day", "はじまりの日",
             "Ed and Al recall the tragedy that started their journey to find the Philosopher's Stone."),
            ("anime_5114_ep3", 3, "City of Heresy", "邪教の街",
             "The brothers arrive in Liore, where a priest claims to perform miracles.")
        ]

        for ep in fmaEpisodes {
            modelContext.insert(Episode(
                id: ep.0, mediaExternalID: "anime_5114", episodeNumber: ep.1,
                title: ep.2, titleJapanese: ep.3, synopsis: ep.4
            ))
        }

        // Hunter x Hunter episodes
        let hxhEpisodes: [(String, Int, String, String?, String?)] = [
            ("anime_11061_ep1", 1, "Departure × And × Friends", "タビダチ×ト×ナカマタチ",
             "Gon sets out from Whale Island to take the Hunter Exam and find his father."),
            ("anime_11061_ep2", 2, "Test × Of × Tests", "シケン×ノ×シケン",
             "Gon, Kurapika, and Leorio face the first phase of the notoriously difficult Hunter Exam."),
            ("anime_11061_ep3", 3, "Rivals × For × Survival", "ライバル×ガ×サバイバル",
             "The examinees must navigate a treacherous path through the Milsy Wetlands.")
        ]

        for ep in hxhEpisodes {
            modelContext.insert(Episode(
                id: ep.0, mediaExternalID: "anime_11061", episodeNumber: ep.1,
                title: ep.2, titleJapanese: ep.3, synopsis: ep.4
            ))
        }

        // Death Note episodes
        let dnEpisodes: [(String, Int, String, String?, String?)] = [
            ("anime_1535_ep1", 1, "Rebirth", "新生",
             "Light Yagami discovers the Death Note and begins to test its terrifying power."),
            ("anime_1535_ep2", 2, "Confrontation", "対決",
             "The mysterious detective L begins his investigation to find the identity of Kira."),
            ("anime_1535_ep3", 3, "Dealings", "取引",
             "Light learns about the Shinigami Eyes from Ryuk while L narrows down his search.")
        ]

        for ep in dnEpisodes {
            modelContext.insert(Episode(
                id: ep.0, mediaExternalID: "anime_1535", episodeNumber: ep.1,
                title: ep.2, titleJapanese: ep.3, synopsis: ep.4
            ))
        }

        // One Punch Man episodes
        let opmEpisodes: [(String, Int, String, String?, String?)] = [
            ("anime_21_ep1", 1, "The Strongest Man", "最強の男",
             "Saitama recalls how he became a hero for fun and defeats every villain with a single punch."),
            ("anime_21_ep2", 2, "The Lone Cyborg", "孤独のサイボーグ",
             "A powerful cyborg named Genos seeks Saitama as his master after witnessing his strength."),
            ("anime_21_ep3", 3, "The Obsessive Scientist", "執念の科学者",
             "Saitama and Genos face the House of Evolution and its dangerous creations.")
        ]

        for ep in opmEpisodes {
            modelContext.insert(Episode(
                id: ep.0, mediaExternalID: "anime_21", episodeNumber: ep.1,
                title: ep.2, titleJapanese: ep.3, synopsis: ep.4
            ))
        }

        // Manga chapters
        // Berserk
        let berserkChapters: [(String, Int, String, String?, String?)] = [
            ("manga_2_ch1", 1, "The Black Swordsman", "黒い剣士",
             "A lone swordsman arrives at a town terrorized by a demon and confronts it head-on."),
            ("manga_2_ch2", 2, "The Brand of Sacrifice", "生贄の烙印",
             "The Black Swordsman's cursed brand draws demons to him wherever he goes."),
            ("manga_2_ch3", 3, "Guardians of Desire (1)", "望みの守護天使①",
             "Guts encounters a demonic entity guarding a castle and the count within.")
        ]

        for ch in berserkChapters {
            modelContext.insert(Episode(
                id: ch.0, mediaExternalID: "manga_2", episodeNumber: ch.1,
                title: ch.2, titleJapanese: ch.3, synopsis: ch.4
            ))
        }

        // One Piece
        let opChapters: [(String, Int, String, String?, String?)] = [
            ("manga_13_ch1", 1, "Romance Dawn", "ROMANCE DAWN -冒険の夜明け-",
             "Monkey D. Luffy sets out to sea to become the King of the Pirates."),
            ("manga_13_ch2", 2, "They Call Him 'Straw Hat Luffy'", "その男「麦わらのルフィ」",
             "Luffy arrives at a marine base and encounters the pirate hunter Roronoa Zoro."),
            ("manga_13_ch3", 3, "Enter Zoro: Pirate Hunter", "海賊狩りのゾロ登場",
             "Luffy frees Zoro from captivity and recruits him as his first crewmate.")
        ]

        for ch in opChapters {
            modelContext.insert(Episode(
                id: ch.0, mediaExternalID: "manga_13", episodeNumber: ch.1,
                title: ch.2, titleJapanese: ch.3, synopsis: ch.4
            ))
        }

        // JoJo's Steel Ball Run
        let sbrChapters: [(String, Int, String, String?, String?)] = [
            ("manga_1706_ch1", 1, "The Steel Ball Run Press Conference", "スティール・ボール・ラン記者会見",
             "A grand cross-country horse race across America is announced, drawing competitors worldwide."),
            ("manga_1706_ch2", 2, "Gyro Zeppeli", "ジャイロ・ツェペリ",
             "A mysterious Italian competitor demonstrates the power of his spinning steel balls."),
            ("manga_1706_ch3", 3, "Johnny Joestar", "ジョニィ・ジョースター",
             "A paraplegic former jockey witnesses Gyro's power and decides to enter the race.")
        ]

        for ch in sbrChapters {
            modelContext.insert(Episode(
                id: ch.0, mediaExternalID: "manga_1706", episodeNumber: ch.1,
                title: ch.2, titleJapanese: ch.3, synopsis: ch.4
            ))
        }

        // Vagabond
        let vagabondChapters: [(String, Int, String, String?, String?)] = [
            ("manga_656_ch1", 1, "Shinmen Takezō", "新免武蔵",
             "After the Battle of Sekigahara, a young warrior named Takezō struggles to survive."),
            ("manga_656_ch2", 2, "On the Run", "逃亡",
             "Takezō and his companion Matahachi flee through the countryside after the devastating battle."),
            ("manga_656_ch3", 3, "A Wanted Man", "お尋ね者",
             "Takezō becomes a fugitive, hunted by the villagers and samurai alike.")
        ]

        for ch in vagabondChapters {
            modelContext.insert(Episode(
                id: ch.0, mediaExternalID: "manga_656", episodeNumber: ch.1,
                title: ch.2, titleJapanese: ch.3, synopsis: ch.4
            ))
        }

        // Chainsaw Man
        let csmChapters: [(String, Int, String, String?, String?)] = [
            ("manga_44347_ch1", 1, "Dog & Chainsaw", "犬とチェンソー",
             "Denji, a young man burdened by debt, merges with his devil dog Pochita to become Chainsaw Man."),
            ("manga_44347_ch2", 2, "The Place Where Pochita Is", "ポチタのいる場所",
             "Denji is recruited by Makima into the Public Safety Devil Hunters."),
            ("manga_44347_ch3", 3, "Arrival in Tokyo", "東京到着",
             "Denji experiences city life for the first time and meets his new partner Power.")
        ]

        for ch in csmChapters {
            modelContext.insert(Episode(
                id: ch.0, mediaExternalID: "manga_44347", episodeNumber: ch.1,
                title: ch.2, titleJapanese: ch.3, synopsis: ch.4
            ))
        }

        // Fullmetal Alchemist (manga)
        let fmaMangaChapters: [(String, Int, String, String?, String?)] = [
            ("manga_25_ch1", 1, "The Two Alchemists", "二人の錬金術師",
             "The Elric brothers arrive in Liore, exposing a fraudulent priest using a Philosopher's Stone."),
            ("manga_25_ch2", 2, "The Price of Life", "命の代価",
             "Edward and Alphonse recall the terrible cost of their attempt to resurrect their mother."),
            ("manga_25_ch3", 3, "The Mining Town", "炭鉱の街",
             "The brothers travel to Youswell and help the townspeople against a corrupt military officer.")
        ]

        for ch in fmaMangaChapters {
            modelContext.insert(Episode(
                id: ch.0, mediaExternalID: "manga_25", episodeNumber: ch.1,
                title: ch.2, titleJapanese: ch.3, synopsis: ch.4
            ))
        }

        // Movies
        // Your Name (existing)
        modelContext.insert(Episode(
            id: "movie_372058_full", mediaExternalID: "movie_372058", episodeNumber: 1,
            title: "Full Movie", titleJapanese: "君の名は。",
            synopsis: "Two teenagers share a profound, magical connection upon discovering they are swapping bodies."
        ))

        // Spirited Away
        modelContext.insert(Episode(
            id: "movie_129_full", mediaExternalID: "movie_129", episodeNumber: 1,
            title: "Full Movie", titleJapanese: "千と千尋の神隠し",
            synopsis: "A young girl becomes trapped in a strange new world of spirits and must find the courage to free herself and her parents."
        ))

        // Suzume
        modelContext.insert(Episode(
            id: "movie_149870_full", mediaExternalID: "movie_149870", episodeNumber: 1,
            title: "Full Movie", titleJapanese: "すずめの戸締まり",
            synopsis: "A 17-year-old girl helps a mysterious young man close doors releasing disasters across Japan."
        ))

        // Princess Mononoke
        modelContext.insert(Episode(
            id: "movie_508883_full", mediaExternalID: "movie_508883", episodeNumber: 1,
            title: "Full Movie", titleJapanese: "もののけ姫",
            synopsis: "A cursed prince journeys west and finds himself caught in a war between forest gods and a mining colony."
        ))

        // Howl's Moving Castle
        modelContext.insert(Episode(
            id: "movie_4935_full", mediaExternalID: "movie_4935", episodeNumber: 1,
            title: "Full Movie", titleJapanese: "ハウルの動く城",
            synopsis: "A shy young woman cursed with an old body seeks the help of a wizard and his magical moving castle."
        ))

        // Weathering with You
        modelContext.insert(Episode(
            id: "movie_568160_full", mediaExternalID: "movie_568160", episodeNumber: 1,
            title: "Full Movie", titleJapanese: "天気の子",
            synopsis: "A runaway high school boy befriends a girl who can manipulate the weather in rain-soaked Tokyo."
        ))

        // JDrama episodes
        // Tokyo Love Story
        let tlsEpisodes: [(String, Int, String, String?, String?)] = [
            ("drama_tls_ep1", 1, "Love in Tokyo", "東京での恋",
             "Kanji returns to Tokyo and reunites with Rika, a free-spirited coworker who declares her love for him."),
            ("drama_tls_ep2", 2, "Crossed Signals", "すれ違い",
             "Misunderstandings arise as Kanji struggles between his feelings for Rika and his childhood friend Satomi."),
            ("drama_tls_ep3", 3, "The Distance Between Us", "二人の距離",
             "Rika's bold personality clashes with Kanji's indecisiveness, testing their budding relationship.")
        ]

        for ep in tlsEpisodes {
            modelContext.insert(Episode(
                id: ep.0, mediaExternalID: "drama_tls", episodeNumber: ep.1,
                title: ep.2, titleJapanese: ep.3, synopsis: ep.4
            ))
        }

        // Hanzawa Naoki
        let hnEpisodes: [(String, Int, String, String?, String?)] = [
            ("drama_hn_ep1", 1, "The Trap", "罠",
             "Banker Hanzawa Naoki discovers he's been set up to take the fall for a massive bad loan."),
            ("drama_hn_ep2", 2, "Counterattack", "反撃",
             "Hanzawa begins his investigation to uncover the truth and clear his name."),
            ("drama_hn_ep3", 3, "Double Payback", "倍返し",
             "Hanzawa confronts his superiors with evidence and delivers his signature promise of revenge.")
        ]

        for ep in hnEpisodes {
            modelContext.insert(Episode(
                id: ep.0, mediaExternalID: "drama_hn", episodeNumber: ep.1,
                title: ep.2, titleJapanese: ep.3, synopsis: ep.4
            ))
        }

        // Terrace House
        let thEpisodes: [(String, Int, String, String?, String?)] = [
            ("drama_th_ep1", 1, "New Beginnings", "新しい始まり",
             "Six strangers move into a shared house in Tokyo and begin to navigate life together."),
            ("drama_th_ep2", 2, "First Impressions", "第一印象",
             "The housemates get to know each other through daily interactions and shared meals."),
            ("drama_th_ep3", 3, "Unspoken Feelings", "言えない気持ち",
             "Romantic tensions begin to surface as the housemates grow closer.")
        ]

        for ep in thEpisodes {
            modelContext.insert(Episode(
                id: ep.0, mediaExternalID: "drama_th", episodeNumber: ep.1,
                title: ep.2, titleJapanese: ep.3, synopsis: ep.4
            ))
        }
    }

    // MARK: - Episode-to-Language Mappings

    private static func loadEpisodeMappings(modelContext: ModelContext) {
        // AoT Episode 1: titans, walls, humanity
        let aotEp1Vocab = ["巨人", "壁", "進撃", "人類", "見る", "食べる"]
        for word in aotEp1Vocab {
            modelContext.insert(EpisodeVocabulary(episodeID: "anime_16498_ep1", vocabularyWord: word))
        }
        for char in ["巨", "人", "壁"] {
            modelContext.insert(EpisodeKanji(episodeID: "anime_16498_ep1", kanjiCharacter: char))
        }
        modelContext.insert(EpisodeGrammar(episodeID: "anime_16498_ep1", grammarPattern: "〜ている"))

        // AoT Episode 2: soldiers, fighting, freedom
        let aotEp2Vocab = ["兵士", "戦う", "自由", "力", "敵", "守る"]
        for word in aotEp2Vocab {
            modelContext.insert(EpisodeVocabulary(episodeID: "anime_16498_ep2", vocabularyWord: word))
        }
        for char in ["兵", "戦", "自", "由", "力"] {
            modelContext.insert(EpisodeKanji(episodeID: "anime_16498_ep2", kanjiCharacter: char))
        }
        modelContext.insert(EpisodeGrammar(episodeID: "anime_16498_ep2", grammarPattern: "〜なければならない"))

        // AoT Episode 3: training, comrades, school
        let aotEp3Vocab = ["調査", "仲間", "強い", "学校", "走る", "友達"]
        for word in aotEp3Vocab {
            modelContext.insert(EpisodeVocabulary(episodeID: "anime_16498_ep3", vocabularyWord: word))
        }
        for char in ["進", "撃", "友", "学"] {
            modelContext.insert(EpisodeKanji(episodeID: "anime_16498_ep3", kanjiCharacter: char))
        }
        modelContext.insert(EpisodeGrammar(episodeID: "anime_16498_ep3", grammarPattern: "〜ようにする"))

        // DS Episode 1: demons, sister, strong
        let dsEp1Vocab = ["鬼", "妹", "強い", "守る", "見る", "食べる"]
        for word in dsEp1Vocab {
            modelContext.insert(EpisodeVocabulary(episodeID: "anime_38000_ep1", vocabularyWord: word))
        }
        for char in ["鬼", "見", "食"] {
            modelContext.insert(EpisodeKanji(episodeID: "anime_38000_ep1", kanjiCharacter: char))
        }
        modelContext.insert(EpisodeGrammar(episodeID: "anime_38000_ep1", grammarPattern: "〜たい"))

        // DS Episode 2: training, breathing, blade
        let dsEp2Vocab = ["刃", "呼吸", "修行", "戦う", "力", "仲間"]
        for word in dsEp2Vocab {
            modelContext.insert(EpisodeVocabulary(episodeID: "anime_38000_ep2", vocabularyWord: word))
        }
        for char in ["刃", "力", "友"] {
            modelContext.insert(EpisodeKanji(episodeID: "anime_38000_ep2", kanjiCharacter: char))
        }
        modelContext.insert(EpisodeGrammar(episodeID: "anime_38000_ep2", grammarPattern: "〜ている"))
        modelContext.insert(EpisodeGrammar(episodeID: "anime_38000_ep2", grammarPattern: "〜てもいい"))

        // Movie: Your Name
        let movieVocab = ["友達", "学校", "見る", "話す", "約束", "守る"]
        for word in movieVocab {
            modelContext.insert(EpisodeVocabulary(episodeID: "movie_372058_full", vocabularyWord: word))
        }
        for char in ["友", "学", "見", "話"] {
            modelContext.insert(EpisodeKanji(episodeID: "movie_372058_full", kanjiCharacter: char))
        }
        modelContext.insert(EpisodeGrammar(episodeID: "movie_372058_full", grammarPattern: "〜たい"))
        modelContext.insert(EpisodeGrammar(episodeID: "movie_372058_full", grammarPattern: "〜ことにする"))
    }

    // MARK: - Lessons and Exercises

    private static func loadLessons(modelContext: ModelContext) {
        // AoT Episode 1 — Lesson: Ongoing Actions with 〜ている
        loadLesson(
            modelContext: modelContext,
            id: "anime_16498_ep1_lesson1",
            episodeID: "anime_16498_ep1",
            grammarPattern: "〜ている",
            title: "Describing What's Happening",
            order: 1,
            exercises: [
                (.vocabRecall, "What does 巨人 mean?", "giant; titan", "Think about the show's title"),
                (.kanjiReading, "How do you read 壁?", "かべ", "It protects the city"),
                (.grammarFill, "巨人が壁を破壊___。(is destroying)", "している", "Use 〜ている for ongoing action"),
                (.translation, "Translate: 人類は壁の中に住んでいる。", "Humanity is living inside the walls.", nil),
                (.pronunciation, "Say: 人類は壁の中に住んでいる。", "人類は壁の中に住んでいる。", "Speak clearly and at a natural pace"),
            ]
        )

        // AoT Episode 2 — Lesson: Obligation with 〜なければならない
        loadLesson(
            modelContext: modelContext,
            id: "anime_16498_ep2_lesson1",
            episodeID: "anime_16498_ep2",
            grammarPattern: "〜なければならない",
            title: "Expressing 'Must Do'",
            order: 1,
            exercises: [
                (.vocabRecall, "What does 兵士 mean?", "soldier", "They fight the titans"),
                (.kanjiReading, "How do you read 戦?", "いくさ / たたか.う", "War and battle"),
                (.grammarFill, "兵士たちは戦わ___。(must fight)", "なければならない", "Express obligation"),
                (.translation, "Translate: 自由のために戦わなければならない。", "We must fight for freedom.", nil),
            ]
        )

        // AoT Episode 3 — Lesson: Making Effort with 〜ようにする
        loadLesson(
            modelContext: modelContext,
            id: "anime_16498_ep3_lesson1",
            episodeID: "anime_16498_ep3",
            grammarPattern: "〜ようにする",
            title: "Making an Effort To Do",
            order: 1,
            exercises: [
                (.vocabRecall, "What does 仲間 mean?", "companion; comrade", "Your fellow soldiers"),
                (.kanjiReading, "How do you read 友?", "とも", "A close companion"),
                (.grammarFill, "毎日走る___している。(trying to)", "ように", "Express making an effort"),
                (.translation, "Translate: 強くなるようにする。", "I'll make an effort to become strong.", nil),
            ]
        )

        // DS Episode 1 — Lesson: Expressing Desire with 〜たい
        loadLesson(
            modelContext: modelContext,
            id: "anime_38000_ep1_lesson1",
            episodeID: "anime_38000_ep1",
            grammarPattern: "〜たい",
            title: "Saying What You Want",
            order: 1,
            exercises: [
                (.vocabRecall, "What does 妹 mean?", "younger sister", "Tanjiro's motivation"),
                (.kanjiReading, "How do you read 鬼?", "おに", "The enemies in this show"),
                (.grammarFill, "妹を守り___。(want to protect)", "たい", "Express your desire"),
                (.translation, "Translate: 強くなりたい。", "I want to become strong.", nil),
                (.pronunciation, "Say: 強くなりたい。", "強くなりたい。", "Speak clearly and at a natural pace"),
            ]
        )

        // DS Episode 2 — Lesson: Ongoing State with 〜ている
        loadLesson(
            modelContext: modelContext,
            id: "anime_38000_ep2_lesson1",
            episodeID: "anime_38000_ep2",
            grammarPattern: "〜ている",
            title: "Describing Ongoing Training",
            order: 1,
            exercises: [
                (.vocabRecall, "What does 修行 mean?", "training; ascetic practice", "What Tanjiro is doing"),
                (.kanjiReading, "How do you read 刃?", "やいば", "The weapon's edge"),
                (.grammarFill, "水の呼吸を練習___。(is practicing)", "している", "Use 〜ている for ongoing action"),
                (.translation, "Translate: 仲間と一緒に戦っている。", "Fighting together with comrades.", nil),
            ]
        )

        // DS Episode 2 — Lesson 2: Permission with 〜てもいい
        loadLesson(
            modelContext: modelContext,
            id: "anime_38000_ep2_lesson2",
            episodeID: "anime_38000_ep2",
            grammarPattern: "〜てもいい",
            title: "Asking for Permission",
            order: 2,
            exercises: [
                (.vocabRecall, "What does 呼吸 mean?", "breathing", "A key technique in the show"),
                (.grammarFill, "この刀を使っ___ですか？(may I use?)", "てもいい", "Ask for permission"),
                (.translation, "Translate: ここで休んでもいいですか？", "May I rest here?", nil),
            ]
        )

        // Movie: Your Name — Lesson: Decisions with 〜ことにする
        loadLesson(
            modelContext: modelContext,
            id: "movie_372058_full_lesson1",
            episodeID: "movie_372058_full",
            grammarPattern: "〜たい",
            title: "Expressing Wishes",
            order: 1,
            exercises: [
                (.vocabRecall, "What does 約束 mean?", "promise", "Something you keep"),
                (.kanjiReading, "How do you read 見?", "み.る", "To watch or see"),
                (.grammarFill, "もう一度会い___。(want to meet)", "たい", "Express your desire"),
                (.translation, "Translate: あの人に会いたい。", "I want to meet that person.", nil),
            ]
        )

        loadLesson(
            modelContext: modelContext,
            id: "movie_372058_full_lesson2",
            episodeID: "movie_372058_full",
            grammarPattern: "〜ことにする",
            title: "Making Decisions",
            order: 2,
            exercises: [
                (.vocabRecall, "What does 守る mean?", "to protect; to guard", "To keep someone safe"),
                (.grammarFill, "東京に行く___した。(decided to)", "ことに", "Express a decision made"),
                (.translation, "Translate: 約束を守ることにした。", "I decided to keep my promise.", nil),
            ]
        )
    }

    // MARK: - Lesson Helper

    private static func loadLesson(
        modelContext: ModelContext,
        id: String,
        episodeID: String,
        grammarPattern: String,
        title: String,
        order: Int,
        exercises: [(ExerciseType, String, String, String?)]
    ) {
        let lesson = Lesson(
            id: id,
            episodeID: episodeID,
            grammarPattern: grammarPattern,
            title: title,
            order: order
        )
        modelContext.insert(lesson)

        for (index, ex) in exercises.enumerated() {
            modelContext.insert(LessonExercise(
                id: "\(id)_ex\(index + 1)",
                lessonID: id,
                exerciseType: ex.0,
                prompt: ex.1,
                answer: ex.2,
                hint: ex.3,
                order: index + 1
            ))
        }
    }
}
