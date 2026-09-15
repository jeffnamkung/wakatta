import SwiftUI
import SwiftData

struct LiveTranslationView: View {
    @State private var viewModel = LiveTranslationViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var showLanguagePicker = false
    @State private var manualInputText = ""
    @FocusState private var isManualInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if !viewModel.isConfigured {
                    unconfiguredView
                } else if !viewModel.isAuthorized {
                    authorizationView
                } else {
                    // Language selector
                    languageSelectorBar

                    Divider()

                    // Split: transcription + translation(s)
                    GeometryReader { geo in
                        let transcriptionHeight = geo.size.height * 0.35
                        let translationHeight = geo.size.height * 0.65

                        VStack(spacing: 0) {
                            transcriptionPanel
                                .frame(height: transcriptionHeight)

                            Divider()

                            translationPanels
                                .frame(height: translationHeight)
                        }
                    }

                    Divider()

                    // Manual text input for testing without mic
                    manualInputBar

                    Divider()

                    // Control bar
                    controlBar
                }
            }
            .navigationTitle("Live Translation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if viewModel.isConfigured && viewModel.isAuthorized {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            viewModel.clearAll()
                        } label: {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .disabled(viewModel.transcriptionSegments.isEmpty && !viewModel.hasAnyTranslations)
                    }
                }
            }
            .task {
                viewModel.configure(modelContext: modelContext)
                await viewModel.requestAuthorization()
            }
            .sheet(isPresented: $viewModel.showWordPopup) {
                WordPopupView(
                    word: viewModel.selectedWord,
                    definition: viewModel.wordDefinition,
                    isLoading: viewModel.isLoadingDefinition
                )
                .presentationDetents([.medium])
            }
            .sheet(isPresented: $showLanguagePicker) {
                targetLanguagePickerSheet
            }
        }
    }

    // MARK: - Unconfigured State

    private var unconfiguredView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "waveform.and.mic")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("AI Provider Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Live Translation uses your configured AI provider for translation. Set up Claude, ChatGPT, Gemini, or Apple Intelligence in Settings.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            NavigationLink {
                SettingsView()
            } label: {
                Label("Go to Settings", systemImage: "gear")
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.top, 8)

            Spacer()
        }
    }

    // MARK: - Authorization State

    private var authorizationView: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "mic.slash")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)

            Text("Permissions Required")
                .font(.title2)
                .fontWeight(.semibold)

            Text(viewModel.authorizationError ?? "Microphone and speech recognition permissions are required for live translation.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Button {
                Task {
                    await viewModel.requestAuthorization()
                }
            } label: {
                Label("Grant Permissions", systemImage: "lock.open")
                    .fontWeight(.medium)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Spacer()
        }
    }

    // MARK: - Language Selector Bar

    private var languageSelectorBar: some View {
        HStack {
            // Source language
            Menu {
                ForEach(SupportedLanguage.allCases) { language in
                    Button {
                        viewModel.sourceLanguage = language
                    } label: {
                        HStack {
                            Text("\(language.flagEmoji) \(language.displayName)")
                            if language == viewModel.sourceLanguage {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                languagePill(viewModel.sourceLanguage)
            }

            Spacer()

            // Swap button (only when single target)
            if viewModel.targetLanguages.count == 1 {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.swapLanguages()
                    }
                } label: {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .background(.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
            } else {
                Image(systemName: "arrow.right")
                    .font(.callout)
                    .foregroundStyle(.tertiary)
                    .padding(8)
            }

            Spacer()

            // Target languages button
            Button {
                showLanguagePicker = true
            } label: {
                targetLanguagesPill
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private var targetLanguagesPill: some View {
        HStack(spacing: 4) {
            let targets = viewModel.orderedTargetLanguages
            if targets.count == 1, let lang = targets.first {
                Text(lang.flagEmoji)
                Text(lang.displayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
            } else {
                // Show flags for all selected
                Text(targets.map(\.flagEmoji).joined(separator: ""))
                Text("\(targets.count) languages")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            Image(systemName: "chevron.down")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.secondary.opacity(0.1))
        .clipShape(Capsule())
    }

    private func languagePill(_ language: SupportedLanguage) -> some View {
        HStack(spacing: 4) {
            Text(language.flagEmoji)
            Text(language.displayName)
                .font(.subheadline)
                .fontWeight(.medium)
            Image(systemName: "chevron.down")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.secondary.opacity(0.1))
        .clipShape(Capsule())
    }

    // MARK: - Target Language Picker Sheet

    private var targetLanguagePickerSheet: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(SupportedLanguage.allCases) { language in
                        if language != viewModel.sourceLanguage {
                            Button {
                                viewModel.toggleTargetLanguage(language)
                            } label: {
                                HStack {
                                    Text(language.flagEmoji)
                                    Text(language.displayName)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    if viewModel.targetLanguages.contains(language) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(Color.accentColor)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Select one or more target languages")
                } footer: {
                    Text("Translations will run in parallel for all selected languages.")
                }

                Section("Audio Playback") {
                    Button {
                        viewModel.setAudioMode(.off)
                    } label: {
                        HStack {
                            Label("Off", systemImage: "speaker.slash")
                                .foregroundStyle(.primary)
                            Spacer()
                            if viewModel.audioPlaybackMode == .off {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }

                    ForEach(viewModel.orderedTargetLanguages) { language in
                        Button {
                            viewModel.setAudioMode(.single(language))
                        } label: {
                            HStack {
                                Label("\(language.flagEmoji) \(language.displayName) only", systemImage: "speaker.wave.2")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if case .single(let selected) = viewModel.audioPlaybackMode, selected == language {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }

                    if viewModel.targetLanguages.count > 1 {
                        Button {
                            viewModel.setAudioMode(.all)
                        } label: {
                            HStack {
                                Label("All languages", systemImage: "speaker.wave.3")
                                    .foregroundStyle(.primary)
                                Spacer()
                                if viewModel.audioPlaybackMode == .all {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Target Languages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        showLanguagePicker = false
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Transcription Panel

    private var transcriptionPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Transcription")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                Text(viewModel.sourceLanguage.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.transcriptionSegments) { segment in
                            if viewModel.sourceLanguage.isJapanese {
                                TappableJapaneseTextView(
                                    words: segment.words,
                                    showFurigana: viewModel.showFurigana,
                                    onWordTap: { word in
                                        Task {
                                            await viewModel.lookupWord(word, in: viewModel.sourceLanguage)
                                        }
                                    }
                                )
                            } else {
                                Text(segment.text)
                                    .font(.body)
                            }
                        }

                        if !viewModel.currentPartialText.isEmpty {
                            Text(viewModel.currentPartialText)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .id("partial")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .onChange(of: viewModel.currentPartialText) {
                    withAnimation {
                        proxy.scrollTo("partial", anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.transcriptionSegments.count) {
                    withAnimation {
                        proxy.scrollTo("partial", anchor: .bottom)
                    }
                }
            }

            if viewModel.transcriptionSegments.isEmpty && viewModel.currentPartialText.isEmpty && viewModel.mode == .idle {
                emptyStateLabel("Tap the microphone to start transcribing")
            }
        }
    }

    // MARK: - Translation Panels

    private var translationPanels: some View {
        let targets = viewModel.orderedTargetLanguages

        return Group {
            if targets.isEmpty {
                emptyStateLabel("Select at least one target language")
            } else if targets.count == 1, let language = targets.first {
                // Single language — full panel
                singleTranslationPanel(for: language)
            } else {
                // Multiple languages — tabbed or stacked
                ScrollView(.vertical) {
                    LazyVStack(spacing: 0) {
                        ForEach(targets) { language in
                            VStack(spacing: 0) {
                                multiTranslationPanel(for: language)
                                if language != targets.last {
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private func singleTranslationPanel(for language: SupportedLanguage) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            translationPanelHeader(for: language)

            ScrollViewReader { proxy in
                ScrollView {
                    translationContent(for: language)
                }
                .onChange(of: viewModel.translationsByLanguage[language]?.count) {
                    if let last = viewModel.translationsByLanguage[language]?.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            if (viewModel.translationsByLanguage[language] ?? []).isEmpty && !viewModel.isTranslating && viewModel.mode == .idle {
                emptyStateLabel("Translations will appear here")
            }
        }
    }

    private func multiTranslationPanel(for language: SupportedLanguage) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            translationPanelHeader(for: language)

            let segments = viewModel.translationsByLanguage[language] ?? []
            if segments.isEmpty && !viewModel.isTranslating {
                Text("Waiting for speech...")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .padding(.horizontal)
                    .padding(.vertical, 8)
            } else {
                translationContent(for: language)
                    .padding(.bottom, 8)
            }
        }
    }

    private func translationPanelHeader(for language: SupportedLanguage) -> some View {
        HStack {
            Text("\(language.flagEmoji) \(language.displayName)")
                .font(.caption)
                .fontWeight(.medium)

            Spacer()

            if viewModel.isTranslating {
                ProgressView()
                    .scaleEffect(0.7)
            }

            // Speaker button for this language
            Button {
                if viewModel.isSpeakingLanguage == language && viewModel.isSpeaking {
                    viewModel.stopSpeaking()
                } else {
                    viewModel.speakLatestTranslation(for: language)
                }
            } label: {
                Image(systemName: viewModel.isSpeakingLanguage == language && viewModel.isSpeaking
                      ? "speaker.wave.3.fill" : "speaker.wave.2")
                    .font(.caption)
                    .foregroundStyle(viewModel.isSpeakingLanguage == language && viewModel.isSpeaking
                                     ? Color.accentColor : .secondary)
            }
            .disabled((viewModel.translationsByLanguage[language] ?? []).isEmpty)

            // Audio auto-play indicator
            if case .single(let selected) = viewModel.audioPlaybackMode, selected == language {
                Image(systemName: "autostartstop")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
            } else if viewModel.audioPlaybackMode == .all {
                Image(systemName: "autostartstop")
                    .font(.caption2)
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private func translationContent(for language: SupportedLanguage) -> some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            ForEach(viewModel.translationsByLanguage[language] ?? []) { segment in
                if language.isJapanese {
                    TappableJapaneseTextView(
                        words: segment.words,
                        showFurigana: viewModel.showFurigana,
                        onWordTap: { word in
                            Task {
                                await viewModel.lookupWord(word, in: language)
                            }
                        }
                    )
                } else {
                    TappableJapaneseTextView(
                        words: segment.words,
                        showFurigana: false,
                        onWordTap: { word in
                            Task {
                                await viewModel.lookupWord(word, in: language)
                            }
                        }
                    )
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }

    // MARK: - Manual Input Bar

    private var manualInputBar: some View {
        HStack(spacing: 8) {
            TextField("Type to translate...", text: $manualInputText)
                .textFieldStyle(.roundedBorder)
                .font(.subheadline)
                .focused($isManualInputFocused)
                .submitLabel(.send)
                .onSubmit {
                    sendManualInput()
                }

            Button {
                sendManualInput()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(manualInputText.trimmingCharacters(in: .whitespaces).isEmpty ? .secondary : Color.accentColor)
            }
            .disabled(manualInputText.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }

    private func sendManualInput() {
        let text = manualInputText
        manualInputText = ""
        Task {
            await viewModel.submitText(text)
        }
    }

    // MARK: - Control Bar

    private var controlBar: some View {
        HStack(spacing: 20) {
            // Furigana toggle
            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    viewModel.showFurigana.toggle()
                }
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: "character.ja")
                        .font(.title3)
                        .foregroundStyle(viewModel.showFurigana ? Color.accentColor : .secondary)
                    Text("Furigana")
                        .font(.system(size: 9))
                        .foregroundStyle(viewModel.showFurigana ? Color.accentColor : .secondary)
                }
            }

            Spacer()

            // Waveform
            if viewModel.mode == .listening {
                WaveformView(audioLevel: viewModel.audioLevel, barCount: 5)
                    .frame(width: 60, height: 30)
                    .transition(.opacity)
            }

            // Mic button
            Button {
                Task {
                    await viewModel.toggleListening()
                }
            } label: {
                Image(systemName: viewModel.mode == .listening ? "stop.circle.fill" : "mic.circle.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(viewModel.mode == .listening ? .red : Color.accentColor)
                    .symbolEffect(.pulse, isActive: viewModel.mode == .listening)
            }

            Spacer()

            // Audio mode indicator
            Button {
                showLanguagePicker = true
            } label: {
                VStack(spacing: 2) {
                    Image(systemName: audioModeIcon)
                        .font(.title3)
                        .foregroundStyle(viewModel.audioPlaybackMode != .off ? Color.accentColor : .secondary)
                    Text("Audio")
                        .font(.system(size: 9))
                        .foregroundStyle(viewModel.audioPlaybackMode != .off ? Color.accentColor : .secondary)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private var audioModeIcon: String {
        switch viewModel.audioPlaybackMode {
        case .off: return "speaker.slash"
        case .single: return "speaker.wave.2"
        case .all: return "speaker.wave.3"
        }
    }

    // MARK: - Helpers

    private func emptyStateLabel(_ text: String) -> some View {
        Text(text)
            .font(.subheadline)
            .foregroundStyle(.tertiary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
    }
}

#Preview {
    LiveTranslationView()
        .modelContainer(for: [
            Media.self,
            VocabularyItem.self,
            KanjiItem.self,
            GrammarPoint.self,
            UserProgress.self,
            LLMConfiguration.self
        ], inMemory: true)
}
