import Foundation

enum SupportedLanguage: String, CaseIterable, Identifiable, Codable {
    case japanese = "ja-JP"
    case english = "en-US"
    case korean = "ko-KR"
    case chinese = "zh-CN"
    case spanish = "es-ES"
    case french = "fr-FR"
    case german = "de-DE"
    case portuguese = "pt-BR"
    case italian = "it-IT"

    var id: String { rawValue }

    var locale: Locale { Locale(identifier: rawValue) }

    var displayName: String {
        switch self {
        case .japanese: return "Japanese"
        case .english: return "English"
        case .korean: return "Korean"
        case .chinese: return "Chinese"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .german: return "German"
        case .portuguese: return "Portuguese"
        case .italian: return "Italian"
        }
    }

    var flagEmoji: String {
        switch self {
        case .japanese: return "🇯🇵"
        case .english: return "🇺🇸"
        case .korean: return "🇰🇷"
        case .chinese: return "🇨🇳"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .german: return "🇩🇪"
        case .portuguese: return "🇧🇷"
        case .italian: return "🇮🇹"
        }
    }

    var isJapanese: Bool { self == .japanese }

    /// BCP 47 language tag for speech recognizer
    var languageTag: String { rawValue }
}
