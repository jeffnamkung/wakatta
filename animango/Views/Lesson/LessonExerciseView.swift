import SwiftUI

struct LessonExerciseView: View {
    let exercise: LessonExercise
    @Binding var userAnswer: String
    let isRevealed: Bool
    let onCheck: () -> Void
    let onNext: () -> Void
    @State private var speechService = SpeechService()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 40)

                // Exercise type badge
                Label(exercise.exerciseType.displayName, systemImage: exercise.exerciseType.iconName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())

                // Prompt with optional TTS button
                HStack(spacing: 8) {
                    Text(exercise.prompt)
                        .font(.title3)
                        .fontWeight(.medium)
                        .multilineTextAlignment(.center)

                    if containsJapanese(exercise.prompt) {
                        Button {
                            if speechService.isSpeaking {
                                speechService.stop()
                            } else {
                                speechService.speak(exercise.prompt)
                            }
                        } label: {
                            Image(systemName: speechService.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                                .font(.body)
                                .foregroundStyle(speechService.isSpeaking ? Color.accentColor : .secondary)
                        }
                    }
                }
                .padding(.horizontal)

                // Hint
                if let hint = exercise.hint, !isRevealed {
                    HStack(spacing: 4) {
                        Image(systemName: "lightbulb.fill")
                            .font(.caption)
                        Text(hint)
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(Capsule())
                }

                if isRevealed {
                    revealedView
                } else {
                    inputView
                }

                Spacer(minLength: 40)
            }
        }
    }

    private var inputView: some View {
        VStack(spacing: 16) {
            TextField("Your answer...", text: $userAnswer)
                .textFieldStyle(.roundedBorder)
                .font(.body)
                .padding(.horizontal, 40)
                .onSubmit { onCheck() }

            Button {
                onCheck()
            } label: {
                Text("Check Answer")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
            .disabled(userAnswer.trimmingCharacters(in: .whitespaces).isEmpty)
        }
    }

    private var revealedView: some View {
        VStack(spacing: 16) {
            let isCorrect = userAnswer.trimmingCharacters(in: .whitespaces).lowercased()
                == exercise.answer.lowercased()

            // Result indicator
            HStack(spacing: 8) {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .font(.title2)
                Text(isCorrect ? "Correct!" : "Not quite")
                    .font(.headline)
            }
            .foregroundStyle(isCorrect ? .green : .red)

            if !isCorrect {
                VStack(spacing: 4) {
                    Text("Your answer:")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(userAnswer)
                        .font(.body)
                        .strikethrough()
                        .foregroundStyle(.red.opacity(0.7))
                }
            }

            VStack(spacing: 4) {
                Text("Correct answer:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(exercise.answer)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(.green)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.green.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal, 40)

            Button {
                onNext()
            } label: {
                Text("Next")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .buttonStyle(.borderedProminent)
            .padding(.horizontal, 40)
        }
    }

    // MARK: - Helpers

    private func containsJapanese(_ text: String) -> Bool {
        text.unicodeScalars.contains { scalar in
            // Hiragana, Katakana, CJK Unified Ideographs
            (0x3040...0x309F).contains(scalar.value) ||
            (0x30A0...0x30FF).contains(scalar.value) ||
            (0x4E00...0x9FFF).contains(scalar.value)
        }
    }
}
