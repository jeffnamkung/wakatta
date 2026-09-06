import SwiftUI
import SwiftData

struct ChatTutorView: View {
    var grammarPoint: GrammarPoint?
    @State private var viewModel = ChatTutorViewModel()
    @Environment(\.modelContext) private var modelContext
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.isConfigured {
                unconfiguredView
            } else {
                chatMessages
                Divider()
                inputBar
            }
        }
        .navigationTitle(grammarPoint?.pattern ?? "Language Tutor")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            viewModel.configure(modelContext: modelContext, grammarPoint: grammarPoint)
        }
    }

    // MARK: - Unconfigured State

    private var unconfiguredView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "brain.head.profile")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("AI Tutor Not Configured")
                .font(.title3)
                .fontWeight(.semibold)

            Text("Set up an AI provider in Settings to use the language tutor. You can use Claude, ChatGPT, or Apple Intelligence.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            NavigationLink {
                SettingsView()
            } label: {
                Label("Go to Settings", systemImage: "gear")
                    .fontWeight(.semibold)
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
    }

    // MARK: - Chat Messages

    private var chatMessages: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        ChatBubble(message: message)
                            .id(message.id)
                    }

                    if viewModel.isLoading {
                        HStack {
                            TypingIndicator()
                            Spacer()
                        }
                        .padding(.horizontal)
                        .id("typing")
                    }

                    if let error = viewModel.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                withAnimation {
                    if viewModel.isLoading {
                        proxy.scrollTo("typing", anchor: .bottom)
                    } else if let last = viewModel.messages.last {
                        proxy.scrollTo(last.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Input Bar

    private var inputBar: some View {
        HStack(spacing: 12) {
            TextField("Ask about Japanese...", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused($isInputFocused)
                .onSubmit {
                    Task { await viewModel.sendMessage() }
                }

            Button {
                Task { await viewModel.sendMessage() }
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(
                        viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading
                        ? Color(.systemGray4)
                        : Color.accentColor
                    )
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

// MARK: - Chat Bubble

private struct ChatBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 48) }

            Text(LocalizedStringKey(message.content))
                .font(.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))

            if !isUser { Spacer(minLength: 48) }
        }
        .padding(.horizontal)
    }
}

// MARK: - Typing Indicator

private struct TypingIndicator: View {
    @State private var dotOffset: CGFloat = 0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color(.systemGray3))
                    .frame(width: 8, height: 8)
                    .offset(y: dotOffset)
                    .animation(
                        .easeInOut(duration: 0.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.15),
                        value: dotOffset
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemGray5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onAppear { dotOffset = -4 }
    }
}

#Preview {
    NavigationStack {
        ChatTutorView()
    }
    .modelContainer(for: [LLMConfiguration.self, GrammarPoint.self], inMemory: true)
}
