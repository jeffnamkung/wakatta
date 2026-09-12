import Foundation
import Speech
import AVFoundation

@Observable @MainActor
final class LiveSpeechRecognizer: NSObject, SFSpeechRecognizerDelegate {

    enum State: Equatable {
        case idle
        case listening
        case error(String)
    }

    // MARK: - Published State

    var state: State = .idle
    var partialText: String = ""
    var audioLevel: Float = 0
    var isAuthorized = false
    var authorizationError: String?

    /// Called when a final transcription segment is available
    var onFinalSegment: ((String) -> Void)?

    // MARK: - Private

    private var speechRecognizer: SFSpeechRecognizer?
    private nonisolated(unsafe) let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var currentLocale: Locale?

    // MARK: - Authorization

    func requestAuthorization() async {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        guard speechStatus == .authorized else {
            authorizationError = "Speech recognition permission is required for live translation."
            isAuthorized = false
            return
        }

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
            authorizationError = "Microphone access is required for live translation."
            isAuthorized = false
            return
        }

        isAuthorized = true
        authorizationError = nil
    }

    // MARK: - Listening

    func startListening(locale: Locale) throws {
        // Create or recreate recognizer if locale changed
        if currentLocale != locale || speechRecognizer == nil {
            speechRecognizer = SFSpeechRecognizer(locale: locale)
            speechRecognizer?.delegate = self
            currentLocale = locale
        }

        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            state = .error("Speech recognition is not available for this language.")
            return
        }

        // Cancel any existing task
        recognitionTask?.cancel()
        recognitionTask = nil

        partialText = ""
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

            // Calculate audio level for waveform
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            var sum: Float = 0
            for i in 0..<frameLength {
                sum += abs(channelData[i])
            }
            let average = sum / Float(frameLength)
            let level = min(1.0, average * 10)

            Task { @MainActor [weak self] in
                self?.audioLevel = level
            }
        }

        // Start audio engine
        audioEngine.prepare()
        try audioEngine.start()

        // Start recognition
        recognitionTask = speechRecognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let result = result {
                    self.partialText = result.bestTranscription.formattedString

                    if result.isFinal {
                        let finalText = result.bestTranscription.formattedString
                        self.onFinalSegment?(finalText)
                        self.partialText = ""

                        // Restart recognition for continuous listening
                        self.restartRecognition()
                    }
                }

                if let error = error {
                    let nsError = error as NSError
                    // Don't treat cancellation as an error
                    if nsError.domain != "kAFAssistantErrorDomain" || nsError.code != 216 {
                        // If we have partial text, emit it as a final segment
                        if !self.partialText.isEmpty {
                            self.onFinalSegment?(self.partialText)
                            self.partialText = ""
                        }
                        // Restart for continuous listening (speech recognizer times out naturally)
                        if self.state == .listening {
                            self.restartRecognition()
                        }
                    }
                }
            }
        }
    }

    func stopListening() {
        state = .idle
        recognitionTask?.cancel()
        recognitionTask = nil
        stopAudioEngine()
    }

    // MARK: - Private Helpers

    private func stopAudioEngine() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        audioLevel = 0
    }

    /// Restart recognition to enable continuous listening (SFSpeechRecognizer has a ~60s limit per task)
    private func restartRecognition() {
        guard state == .listening, let locale = currentLocale else { return }

        stopAudioEngine()

        // Small delay before restarting to let the audio session settle
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(100))
            guard self.state == .listening else { return }
            do {
                try self.startListening(locale: locale)
            } catch {
                self.state = .error("Failed to restart recognition: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - SFSpeechRecognizerDelegate

    nonisolated func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        // No action needed — availability is checked at start
    }
}
