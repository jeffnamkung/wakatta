import Foundation
import Speech
import AVFoundation

@Observable @MainActor
final class PronunciationService: NSObject, SFSpeechRecognizerDelegate {

    enum RecordingState {
        case idle
        case listening
        case processing
        case result
    }

    // MARK: - Properties

    private nonisolated(unsafe) let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private nonisolated(unsafe) let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var expectedText: String = ""

    var state: RecordingState = .idle
    var partialText: String = ""
    var feedback: PronunciationFeedback?
    var audioLevel: Float = 0
    var isAuthorized = false
    var authorizationError: String?

    // MARK: - Init

    override init() {
        super.init()
        speechRecognizer?.delegate = self
    }

    // MARK: - Authorization

    func requestAuthorization() async {
        // Request speech recognition permission
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            authorizationError = "Speech recognition permission is required for pronunciation practice."
            isAuthorized = false
            return
        }

        // Request microphone permission
        let micGranted: Bool
        if #available(iOS 17, *) {
            micGranted = await AVAudioApplication.requestRecordPermission()
        } else {
            micGranted = await withCheckedContinuation { continuation in
                AVAudioSession.sharedInstance().requestRecordPermission { granted in
                    continuation.resume(returning: granted)
                }
            }
        }

        guard micGranted else {
            authorizationError = "Microphone access is required for pronunciation practice."
            isAuthorized = false
            return
        }

        isAuthorized = true
        authorizationError = nil
    }

    // MARK: - Recording

    func startRecording(expectedText: String) throws {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            throw PronunciationError.recognizerUnavailable
        }

        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

        self.expectedText = expectedText
        partialText = ""
        feedback = nil
        state = .listening

        // Configure audio session
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        // Create recognition request
        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if speechRecognizer.supportsOnDeviceRecognition {
            request.requiresOnDeviceRecognition = true
        }
        recognitionRequest = request

        // Install tap on audio engine input
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // Calculate audio level for waveform visualization
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<frameLength {
                sum += abs(channelData[i])
            }
            let average = sum / Float(frameLength)
            let level = min(1.0, average * 10) // Normalize to 0-1

            Task { @MainActor [weak self] in
                self?.audioLevel = level
            }
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition
        let capturedExpectedText = expectedText
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let result = result {
                    self.partialText = result.bestTranscription.formattedString

                    if result.isFinal {
                        self.state = .processing
                        let computedFeedback = self.computeFeedback(
                            result: result,
                            expectedText: capturedExpectedText
                        )
                        self.feedback = computedFeedback
                        self.state = .result
                    }
                }

                if let error = error {
                    // Don't treat cancellation as an error
                    let nsError = error as NSError
                    if nsError.domain != "kAFAssistantErrorDomain" || nsError.code != 216 {
                        self.stopRecordingInternal()
                        if self.state != .result {
                            // If we have partial text, compute feedback from it
                            if !self.partialText.isEmpty {
                                self.feedback = PronunciationFeedback.compute(
                                    recognizedText: self.partialText,
                                    expectedText: capturedExpectedText,
                                    pitchJitter: nil,
                                    speakingRate: nil,
                                    averagePauseDuration: nil
                                )
                                self.state = .result
                            } else {
                                self.state = .idle
                            }
                        }
                    }
                }
            }
        }
    }

    func stopRecording() {
        stopRecordingInternal()

        // If we're still listening (manual stop), end audio to trigger final result
        recognitionRequest?.endAudio()

        if state == .listening {
            state = .processing
        }
    }

    private func stopRecordingInternal() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest = nil
        audioLevel = 0
    }

    func reset() {
        recognitionTask?.cancel()
        recognitionTask = nil
        stopRecordingInternal()
        state = .idle
        partialText = ""
        feedback = nil
        audioLevel = 0
    }

    // MARK: - Feedback Computation

    private func computeFeedback(
        result: SFSpeechRecognitionResult,
        expectedText: String
    ) -> PronunciationFeedback {
        let recognizedText = result.bestTranscription.formattedString

        // Extract voice analytics from transcription segments
        var averageJitter: Double?
        let segments = result.bestTranscription.segments

        if !segments.isEmpty {
            var jitterSum = 0.0
            var jitterCount = 0

            for segment in segments {
                if let analytics = segment.voiceAnalytics {
                    let jitterValues = analytics.jitter.acousticFeatureValuePerFrame
                    if !jitterValues.isEmpty {
                        jitterSum += jitterValues.reduce(0, +) / Double(jitterValues.count)
                        jitterCount += 1
                    }
                }
            }

            if jitterCount > 0 {
                averageJitter = jitterSum / Double(jitterCount)
            }
        }

        // Extract metadata
        let metadata = result.speechRecognitionMetadata
        let speakingRate = metadata?.speakingRate
        let averagePauseDuration = metadata?.averagePauseDuration

        return PronunciationFeedback.compute(
            recognizedText: recognizedText,
            expectedText: expectedText,
            pitchJitter: averageJitter,
            speakingRate: speakingRate,
            averagePauseDuration: averagePauseDuration
        )
    }

    // MARK: - SFSpeechRecognizerDelegate

    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // Availability changed — no action needed since we check at recording start
    }
}

// MARK: - Errors

enum PronunciationError: LocalizedError {
    case recognizerUnavailable
    case notAuthorized

    var errorDescription: String? {
        switch self {
        case .recognizerUnavailable:
            return "Japanese speech recognition is not available on this device."
        case .notAuthorized:
            return "Speech recognition or microphone permission not granted."
        }
    }
}
