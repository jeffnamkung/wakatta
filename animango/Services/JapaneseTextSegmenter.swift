import Foundation
import NaturalLanguage

struct SegmentedWord: Identifiable {
    let id: String
    let surface: String
    let containsKanji: Bool

    init(surface: String) {
        self.id = UUID().uuidString
        self.surface = surface
        self.containsKanji = Self.checkKanji(surface)
    }

    private static func checkKanji(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            (0x4E00...0x9FFF).contains(scalar.value) ||
            (0x3400...0x4DBF).contains(scalar.value)
        }
    }
}

struct JapaneseTextSegmenter {

    /// Segment Japanese text into individual words using NLTokenizer
    static func segment(_ text: String) -> [SegmentedWord] {
        guard !text.isEmpty else { return [] }

        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = text
        tokenizer.setLanguage(.japanese)

        var words: [SegmentedWord] = []
        var lastEnd = text.startIndex

        tokenizer.enumerateTokens(in: text.startIndex..<text.endIndex) { range, _ in
            // Capture any whitespace or punctuation between tokens
            if lastEnd < range.lowerBound {
                let gap = String(text[lastEnd..<range.lowerBound])
                if !gap.trimmingCharacters(in: .whitespaces).isEmpty {
                    words.append(SegmentedWord(surface: gap))
                }
            }

            let word = String(text[range])
            words.append(SegmentedWord(surface: word))
            lastEnd = range.upperBound
            return true
        }

        // Capture any trailing text
        if lastEnd < text.endIndex {
            let trailing = String(text[lastEnd..<text.endIndex])
            if !trailing.trimmingCharacters(in: .whitespaces).isEmpty {
                words.append(SegmentedWord(surface: trailing))
            }
        }

        return words
    }
}

/// Utility to check if a string contains kanji characters
func containsKanji(_ text: String) -> Bool {
    text.unicodeScalars.contains { scalar in
        (0x4E00...0x9FFF).contains(scalar.value) ||
        (0x3400...0x4DBF).contains(scalar.value)
    }
}
