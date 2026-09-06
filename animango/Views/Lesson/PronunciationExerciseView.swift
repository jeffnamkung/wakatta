import SwiftUI

struct PronunciationExerciseView: View {
    let exercise: LessonExercise
    @State private var pronunciationService = PronunciationService()
    @State private var speechService = SpeechService()
    let onComplete: (Double) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 20)

                // Exercise type badge
                Label("Pronunciation", systemImage: "mic.fill")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.accentColor.opacity(0.1))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(Capsule())

                // Target text to speak
                VStack(spacing: 8) {
                    Text("Say this in Japanese:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(exercise.prompt)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                // Reference audio button
                Button {
                    if speechService.isSpeaking {
                        speechService.stop()
                    } else {
                        speechService.speak(exercise.answer)
                    }
                } label: {
                    Label(
                        speechService.isSpeaking ? "Stop" : "Listen to reference",
                        systemImage: speechService.isSpeaking ? "stop.circle.fill" : "speaker.wave.2.fill"
                    )
                    .font(.subheadline)
                    .fontWeight(.medium)
                }
                .buttonStyle(.bordered)

                // Hint
                if let hint = exercise.hint {
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

                // Recording section
                switch pronunciationService.state {
                case .idle:
                    idleView
                case .listening:
                    listeningView
                case .processing:
                    processingView
                case .result:
                    resultView
                }

                Spacer(minLength: 20)
            }
        }
        .task {
            await pronunciationService.requestAuthorization()
        }
    }

    // MARK: - State Views

    private var idleView: some View {
        VStack(spacing: 16) {
            if let error = pronunciationService.authorizationError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                startRecording()
            } label: {
                Image(systemName: "mic.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(pronunciationService.isAuthorized ? Color.accentColor : .gray)
            }
            .disabled(!pronunciationService.isAuthorized)

            Text("Tap to start recording")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var listeningView: some View {
        VStack(spacing: 16) {
            WaveformView(audioLevel: pronunciationService.audioLevel)
                .padding(.horizontal, 40)

            if !pronunciationService.partialText.isEmpty {
                Text(pronunciationService.partialText)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .transition(.opacity)
            }

            Button {
                pronunciationService.stopRecording()
            } label: {
                Image(systemName: "stop.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.red)
            }

            Text("Tap to stop recording")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var processingView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Analyzing pronunciation...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var resultView: some View {
        VStack(spacing: 20) {
            if let feedback = pronunciationService.feedback {
                PronunciationScoreView(feedback: feedback)
                    .padding(.horizontal)

                HStack(spacing: 12) {
                    // Retry button
                    Button {
                        pronunciationService.reset()
                    } label: {
                        Label("Try Again", systemImage: "arrow.counterclockwise")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.bordered)

                    // Next button
                    Button {
                        onComplete(feedback.overallScore)
                    } label: {
                        Text("Next")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 40)
            }
        }
    }

    // MARK: - Actions

    private func startRecording() {
        // Stop any TTS that might be playing
        speechService.stop()

        do {
            try pronunciationService.startRecording(expectedText: exercise.answer)
        } catch {
            // Error starting recording — authorization issue or device problem
        }
    }
}
