import SwiftUI
import SwiftData

struct ChatSetupWizardView: View {
    var onComplete: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var step: SetupStep = .pickProvider
    @State private var selectedProvider: LLMProvider = .anthropic
    @State private var apiKey: String = ""
    @State private var selectedModel: String = "claude-sonnet-4-20250514"
    @State private var isTesting = false
    @State private var testError: String?
    @State private var showKey = false

    private enum SetupStep {
        case pickProvider
        case enterKey
        case success
    }

    var body: some View {
        VStack(spacing: 0) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(stepIndex >= index ? Color.accentColor : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.top, 20)
            .padding(.bottom, 12)

            switch step {
            case .pickProvider:
                providerPickerStep
            case .enterKey:
                apiKeyStep
            case .success:
                successStep
            }
        }
    }

    private var stepIndex: Int {
        switch step {
        case .pickProvider: 0
        case .enterKey: 1
        case .success: 2
        }
    }

    // MARK: - Step 1: Pick Provider

    private var providerPickerStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(Color.accentColor)

            VStack(spacing: 8) {
                Text("Set Up Your AI Tutor")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Pick which AI will power Manga-chan.\nYou'll need a free API key.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                providerButton(
                    provider: .anthropic,
                    subtitle: "Best for Japanese tutoring"
                )
                providerButton(
                    provider: .openAI,
                    subtitle: "GPT-4o and GPT-4.1"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                selectedModel = selectedProvider.defaultModel
                step = .enterKey
            } label: {
                Text("Next")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    private func providerButton(provider: LLMProvider, subtitle: String) -> some View {
        Button {
            selectedProvider = provider
            selectedModel = provider.defaultModel
        } label: {
            HStack(spacing: 14) {
                Image(systemName: provider.iconName)
                    .font(.title3)
                    .frame(width: 32)

                VStack(alignment: .leading, spacing: 2) {
                    Text(provider.displayName)
                        .fontWeight(.medium)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if selectedProvider == provider {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.accentColor)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(selectedProvider == provider
                          ? Color.accentColor.opacity(0.1)
                          : Color(.secondarySystemGroupedBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(selectedProvider == provider ? Color.accentColor : .clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Step 2: Enter API Key

    private var apiKeyStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("Get Your API Key")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("Follow these steps — it only takes a minute.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 12)

                // Step-by-step instructions
                VStack(alignment: .leading, spacing: 16) {
                    instructionRow(number: 1, text: "Tap the button below to open \(selectedProvider == .anthropic ? "Anthropic Console" : "OpenAI Platform") in Safari")
                    instructionRow(number: 2, text: "Create a free account (or sign in)")
                    instructionRow(number: 3, text: selectedProvider == .anthropic
                                   ? "Go to **API Keys** → **Create Key**"
                                   : "Go to **API keys** → **Create new secret key**")
                    instructionRow(number: 4, text: "Copy the key and paste it below")
                }
                .padding(.horizontal, 24)

                // Open console button
                Button {
                    openConsole()
                } label: {
                    Label(
                        selectedProvider == .anthropic
                            ? "Open Anthropic Console"
                            : "Open OpenAI Platform",
                        systemImage: "safari"
                    )
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.horizontal, 24)

                // API key input
                VStack(alignment: .leading, spacing: 8) {
                    Text("Paste your API key")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    HStack {
                        if showKey {
                            TextField("sk-...", text: $apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-...", text: $apiKey)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                        }

                        Button {
                            showKey.toggle()
                        } label: {
                            Image(systemName: showKey ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                    if let error = testError {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                    }
                }
                .padding(.horizontal, 24)

                // Model picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Model")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Picker("Model", selection: $selectedModel) {
                        ForEach(selectedProvider.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal, 24)

                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        step = .pickProvider
                        testError = nil
                    } label: {
                        Text("Back")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    Button {
                        Task { await verifyAndSave() }
                    } label: {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .tint(.white)
                            }
                            Text(isTesting ? "Verifying..." : "Verify & Save")
                        }
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isTesting)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }

    private func instructionRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(Color.accentColor)
                .clipShape(Circle())

            Text(.init(text))
                .font(.subheadline)
        }
    }

    // MARK: - Step 3: Success

    private var successStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green)

            VStack(spacing: 8) {
                Text("You're All Set!")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("Manga-chan is ready to teach you Japanese.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                onComplete()
            } label: {
                Text("Start Learning")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }

    // MARK: - Actions

    private func openConsole() {
        let urlString = selectedProvider == .anthropic
            ? "https://console.anthropic.com/settings/keys"
            : "https://platform.openai.com/api-keys"
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }

    private func verifyAndSave() async {
        isTesting = true
        testError = nil

        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)

        let provider: any LLMServiceProvider
        switch selectedProvider {
        case .anthropic:
            provider = AnthropicProvider(apiKey: trimmedKey, model: selectedModel)
        case .openAI:
            provider = OpenAIProvider(apiKey: trimmedKey, model: selectedModel)
        case .apple:
            isTesting = false
            return
        }

        do {
            let response = try await provider.chat(messages: [
                LLMMessage(role: .system, content: "You are a test assistant. Respond with only: OK"),
                LLMMessage(role: .user, content: "Test")
            ])

            if response.isEmpty {
                testError = "Received empty response. Check your key."
                isTesting = false
                return
            }

            // Save configuration
            let configs = (try? modelContext.fetch(FetchDescriptor<LLMConfiguration>())) ?? []
            if let existing = configs.first {
                existing.provider = selectedProvider
                existing.apiKey = trimmedKey
                existing.selectedModel = selectedModel
            } else {
                let config = LLMConfiguration(
                    provider: selectedProvider,
                    apiKey: trimmedKey,
                    selectedModel: selectedModel
                )
                modelContext.insert(config)
            }
            try? modelContext.save()

            isTesting = false
            step = .success
        } catch let error as LLMServiceError {
            testError = error.localizedDescription
            isTesting = false
        } catch {
            testError = error.localizedDescription
            isTesting = false
        }
    }
}
