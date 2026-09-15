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
    private var isRestarting = false
    private var hasTapInstalled = false

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
        // Prevent re-entrant calls during restart
        guard !isRestarting else { return }

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

        // Clean up any existing audio tap before installing a new one
        cleanupAudioEngine()

        partialText = ""
        state = .listening

        // Configure audio session — use .playAndRecord so other audio (PiP video,
        // music, etc.) continues playing while the mic captures it for transcription.
        // .defaultToSpeaker routes playback to speaker so the mic can pick it up.
        // .mixWithOthers prevents interrupting other apps' audio sessions.
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .measurement, options: [.defaultToSpeaker, .mixWithOthers, .allowBluetooth])
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

        guard recordingFormat.sampleRate > 0 else {
            state = .error("Audio input format is not available.")
            return
        }

        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)

            // Calculate audio level for waveform
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = Int(buffer.frameLength)
            guard frameLength > 0 else { return }
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
        hasTapInstalled = true

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
                    // Don't treat cancellation or "no speech detected" as fatal errors
                    let ignorableCodes = [216, 209, 203, 1110]
                    if nsError.domain == "kAFAssistantErrorDomain" && ignorableCodes.contains(nsError.code) {
                        // Emit any partial text before restarting
                        if !self.partialText.isEmpty {
                            self.onFinalSegment?(self.partialText)
                            self.partialText = ""
                        }
                        // Restart for continuous listening
                        if self.state == .listening {
                            self.restartRecognition()
                        }
                    } else {
                        // Emit any partial text
                        if !self.partialText.isEmpty {
                            self.onFinalSegment?(self.partialText)
                            self.partialText = ""
                        }
                        // Restart for continuous listening
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
        isRestarting = false
        recognitionTask?.cancel()
        recognitionTask = nil
        cleanupAudioEngine()
    }

    // MARK: - Private Helpers

    /// Safely tears down the audio engine and removes the tap
    private func cleanupAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        if hasTapInstalled {
            audioEngine.inputNode.removeTap(onBus: 0)
            hasTapInstalled = false
        }
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        audioLevel = 0
    }

    /// Restart recognition to enable continuous listening (SFSpeechRecognizer has a ~60s limit per task)
    private func restartRecognition() {
        guard state == .listening, let locale = currentLocale, !isRestarting else { return }

        isRestarting = true
        cleanupAudioEngine()

        // Small delay before restarting to let the audio session settle
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(200))
            guard self.state == .listening else {
                self.isRestarting = false
                return
            }
            self.isRestarting = false
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
