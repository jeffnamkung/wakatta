import SwiftUI

struct AudioButton: View {
    let text: String
    @State private var speechService = SpeechService()

    var body: some View {
        Button {
            if speechService.isSpeaking {
                speechService.stop()
            } else {
                speechService.speak(text)
            }
        } label: {
            Image(systemName: speechService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                .font(.title3)
                .foregroundStyle(speechService.isSpeaking ? Color.accentColor : .secondary)
                .symbolEffect(.variableColor, isActive: speechService.isSpeaking)
        }
        .buttonStyle(.plain)
    }
}

struct AudioButtonCompact: View {
    let text: String
    @State private var speechService = SpeechService()

    var body: some View {
        Button {
            if speechService.isSpeaking {
                speechService.stop()
            } else {
                speechService.speak(text)
            }
        } label: {
            Image(systemName: speechService.isSpeaking ? "speaker.wave.3.fill" : "speaker.wave.2")
                .font(.caption)
                .foregroundStyle(speechService.isSpeaking ? Color.accentColor : .secondary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack(spacing: 20) {
        AudioButton(text: "こんにちは")
        AudioButtonCompact(text: "食べる")
    }
}
