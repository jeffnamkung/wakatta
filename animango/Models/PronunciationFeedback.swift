import Foundation

struct PronunciationFeedback {
    let recognizedText: String
    let expectedText: String
    let textAccuracy: Double      // 0-1, character-level similarity
    let pitchScore: Double        // 0-1, from voice analytics pitch stability
    let fluencyScore: Double      // 0-1, from speaking rate + pause analysis
    let overallScore: Double      // weighted: 50% text, 25% pitch, 25% fluency
    let feedbackMessage: String   // e.g. "Great!" or "Try speaking more slowly"

    static func compute(
        recognizedText: String,
        expectedText: String,
        pitchJitter: Double?,
        speakingRate: Double?,
        averagePauseDuration: TimeInterval?
    ) -> PronunciationFeedback {
        let textAccuracy = Self.calculateTextAccuracy(recognized: recognizedText, expected: expectedText)
        let pitchScore = Self.calculatePitchScore(jitter: pitchJitter)
        let fluencyScore = Self.calculateFluencyScore(rate: speakingRate, pauseDuration: averagePauseDuration)
        let overallScore = textAccuracy * 0.5 + pitchScore * 0.25 + fluencyScore * 0.25
        let feedbackMessage = Self.feedbackMessage(for: overallScore, textAccuracy: textAccuracy)

        return PronunciationFeedback(
            recognizedText: recognizedText,
            expectedText: expectedText,
            textAccuracy: textAccuracy,
            pitchScore: pitchScore,
            fluencyScore: fluencyScore,
            overallScore: overallScore,
            feedbackMessage: feedbackMessage
        )
    }

    // MARK: - Text Accuracy (Character-level Levenshtein)

    private static func calculateTextAccuracy(recognized: String, expected: String) -> Double {
        guard !expected.isEmpty else { return recognized.isEmpty ? 1.0 : 0.0 }

        let recognizedChars = Array(recognized)
        let expectedChars = Array(expected)
        let distance = levenshteinDistance(recognizedChars, expectedChars)
        let maxLen = max(recognizedChars.count, expectedChars.count)

        return max(0, 1.0 - Double(distance) / Double(maxLen))
    }

    private static func levenshteinDistance(_ a: [Character], _ b: [Character]) -> Int {
        let m = a.count
        let n = b.count

        if m == 0 { return n }
        if n == 0 { return m }

        var prev = Array(0...n)
        var curr = Array(repeating: 0, count: n + 1)

        for i in 1...m {
            curr[0] = i
            for j in 1...n {
                let cost = a[i - 1] == b[j - 1] ? 0 : 1
                curr[j] = min(
                    prev[j] + 1,       // deletion
                    curr[j - 1] + 1,   // insertion
                    prev[j - 1] + cost // substitution
                )
            }
            prev = curr
        }

        return prev[n]
    }

    // MARK: - Pitch Score

    private static func calculatePitchScore(jitter: Double?) -> Double {
        guard let jitter = jitter else { return 0.7 } // default if unavailable
        // Lower jitter = more stable pitch = better score
        // Typical jitter for normal speech: 0.5-1.5%
        // Scale: 0% jitter → 1.0, 3%+ jitter → 0.3
        return max(0.3, min(1.0, 1.0 - (jitter / 3.0) * 0.7))
    }

    // MARK: - Fluency Score

    private static func calculateFluencyScore(rate: Double?, pauseDuration: TimeInterval?) -> Double {
        var score = 0.7 // default

        if let rate = rate {
            // Japanese normal speaking rate: ~300-400 morae per minute
            // For learners, 100-250 is acceptable
            // Too slow (< 50) or too fast (> 500) → lower score
            if rate >= 100 && rate <= 400 {
                score = 1.0
            } else if rate >= 50 && rate < 100 {
                score = 0.7
            } else if rate > 400 && rate <= 500 {
                score = 0.7
            } else {
                score = 0.4
            }
        }

        if let pauseDuration = pauseDuration {
            // Long pauses reduce fluency score
            // < 0.3s: natural, 0.3-0.8s: acceptable, > 0.8s: hesitant
            if pauseDuration > 0.8 {
                score *= 0.7
            } else if pauseDuration > 0.5 {
                score *= 0.85
            }
        }

        return max(0, min(1.0, score))
    }

    // MARK: - Feedback Message

    private static func feedbackMessage(for overall: Double, textAccuracy: Double) -> String {
        if overall >= 0.85 {
            return "Excellent pronunciation!"
        } else if overall >= 0.7 {
            return "Good job! Keep practicing."
        } else if overall >= 0.5 {
            if textAccuracy < 0.5 {
                return "Try listening to the reference audio again."
            }
            return "Not bad! Try speaking more clearly."
        } else {
            return "Keep practicing! Listen to the reference audio and try again."
        }
    }
}
