import SwiftUI
import SwiftData

struct LiveTranslationView: View {
    @State private var viewModel = LiveTranslationViewModel()
    @Environment(\.modelContext) private var modelContext

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

                    // Split: transcription + translation
                    GeometryReader { geo in
                        VStack(spacing: 0) {
                            transcriptionPanel
                                .frame(height: geo.size.height / 2)

                            Divider()

                            translationPanel
                                .frame(height: geo.size.height / 2)
                        }
                    }

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
                        .disabled(viewModel.transcriptionSegments.isEmpty && viewModel.translationSegments.isEmpty)
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

            Text("Live Translation uses your configured AI provider for translation. Set up Claude, ChatGPT, or Apple Intelligence in Settings.")
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

            Spacer()

            Menu {
                ForEach(SupportedLanguage.allCases) { language in
                    Button {
                        viewModel.targetLanguage = language
                    } label: {
                        HStack {
                            Text("\(language.flagEmoji) \(language.displayName)")
                            if language == viewModel.targetLanguage {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                languagePill(viewModel.targetLanguage)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
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

    // MARK: - Transcription Panel

    private var transcriptionPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
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
                                            await viewModel.lookupWord(word)
                                        }
                                    }
                                )
                            } else {
                                Text(segment.text)
                                    .font(.body)
                            }
                        }

                        // Partial text (live)
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

    // MARK: - Translation Panel

    private var translationPanel: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Translation")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if viewModel.isTranslating {
                    ProgressView()
                        .scaleEffect(0.7)
                }

                Text(viewModel.targetLanguage.displayName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.top, 8)
            .padding(.bottom, 4)

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.translationSegments) { segment in
                            if viewModel.targetLanguage.isJapanese {
                                TappableJapaneseTextView(
                                    words: segment.words,
                                    showFurigana: viewModel.showFurigana,
                                    onWordTap: { word in
                                        Task {
                                            await viewModel.lookupWord(word)
                                        }
                                    }
                                )
                            } else {
                                Text(segment.translatedText)
                                    .font(.body)
                                    .onTapGesture {
                                        // For non-Japanese, tap the whole segment
                                        // Split and find which word was tapped — simplified: just show first word
                                    }
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                                .id("translationBottom")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                .onChange(of: viewModel.translationSegments.count) {
                    if let last = viewModel.translationSegments.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            if viewModel.translationSegments.isEmpty && !viewModel.isTranslating && viewModel.mode == .idle {
                emptyStateLabel("Translations will appear here")
            }
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
                    Image(systemName: viewModel.showFurigana ? "character.ja" : "character.ja")
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

            // Placeholder for symmetry
            VStack(spacing: 2) {
                Image(systemName: "character.ja")
                    .font(.title3)
                Text("Furigana")
                    .font(.system(size: 9))
            }
            .hidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
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
