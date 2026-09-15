import AVFoundation

@Observable @MainActor
final class SpeechService: NSObject, AVSpeechSynthesizerDelegate {
    private nonisolated(unsafe) let synthesizer = AVSpeechSynthesizer()
    private(set) var isSpeaking = false

    // Spatial audio components
    private var engine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    private var environmentNode: AVAudioEnvironmentNode?
    private(set) var isSpatialEnabled = false

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Basic TTS

    func speak(_ text: String, rate: Float = 0.4, language: String = "ja-JP") {
        stopSpatialEngine()

        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func speakSlowly(_ text: String, language: String = "ja-JP") {
        speak(text, rate: 0.25, language: language)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        stopSpatialEngine()
        isSpeaking = false
    }

    // MARK: - Spatial Audio

    /// Checks if headphones are connected (wired or Bluetooth)
    var isHeadphonesConnected: Bool {
        let route = AVAudioSession.sharedInstance().currentRoute
        return route.outputs.contains { output in
            output.portType == .headphones ||
            output.portType == .bluetoothA2DP ||
            output.portType == .bluetoothLE ||
            output.portType == .bluetoothHFP
        }
    }

    /// Sets up the spatial audio engine with 3D environment
    func enableSpatialAudio() {
        guard engine == nil else { return }

        let audioEngine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        let environment = AVAudioEnvironmentNode()

        audioEngine.attach(player)
        audioEngine.attach(environment)

        // Connect: playerNode → environmentNode → mainMixerNode
        let format = AVAudioFormat(standardFormatWithSampleRate: 22050, channels: 1)!
        audioEngine.connect(player, to: environment, format: format)
        audioEngine.connect(environment, to: audioEngine.mainMixerNode, format: nil)

        // Set listener at origin, looking forward
        environment.listenerPosition = AVAudio3DPoint(x: 0, y: 0, z: 0)
        environment.listenerAngularOrientation = AVAudio3DAngularOrientation(yaw: 0, pitch: 0, roll: 0)

        // Default player position: slightly in front
        player.position = AVAudio3DPoint(x: 0, y: 0, z: -1)
        player.renderingAlgorithm = .HRTFHQ

        self.engine = audioEngine
        self.playerNode = player
        self.environmentNode = environment
        self.isSpatialEnabled = true
    }

    /// Speaks text using spatial audio at a given 3D position
    func speakSpatial(_ text: String, position: AVAudio3DPoint = AVAudio3DPoint(x: 0, y: 0, z: -1), rate: Float = 0.4, language: String = "ja-JP") {
        guard let engine = engine, let playerNode = playerNode else {
            // Fall back to regular speech if spatial isn't set up
            speak(text, rate: rate, language: language)
            return
        }

        // Stop any current playback
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        playerNode.stop()

        // Set 3D position for this utterance
        playerNode.position = position

        isSpeaking = true

        // Configure audio session for playback
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.setCategory(.playback, mode: .default, options: [])
        try? audioSession.setActive(true)

        // Create utterance for buffer generation
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: language)
        utterance.rate = rate
        utterance.pitchMultiplier = 1.0

        // Use write to get audio buffers, then play through spatial engine
        synthesizer.write(utterance) { [weak self] buffer in
            guard let self = self, let pcmBuffer = buffer as? AVAudioPCMBuffer else { return }

            // Skip empty buffers
            guard pcmBuffer.frameLength > 0 else {
                Task { @MainActor [weak self] in
                    self?.isSpeaking = false
                }
                return
            }

            // Start engine if needed
            if !engine.isRunning {
                try? engine.start()
            }

            playerNode.scheduleBuffer(pcmBuffer, completionHandler: nil)
            if !playerNode.isPlaying {
                playerNode.play()
            }
        }
    }

    /// Disables spatial audio and tears down the engine
    func disableSpatialAudio() {
        stopSpatialEngine()
        engine = nil
        playerNode = nil
        environmentNode = nil
        isSpatialEnabled = false
    }

    private func stopSpatialEngine() {
        playerNode?.stop()
        if engine?.isRunning == true {
            engine?.stop()
        }
    }

    // MARK: - AVSpeechSynthesizerDelegate

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isSpeaking = false
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor [weak self] in
            self?.isSpeaking = false
        }
    }
}
