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

        // JDrama mappings
        let dramaVocab = ["事件", "犯人", "恋愛", "会社", "医者", "話す", "見る", "約束"]
        for word in dramaVocab {
            modelContext.insert(MediaVocabulary(mediaExternalID: "drama_1", vocabularyWord: word, frequency: Int.random(in: 1...10)))
        }
    }
}
