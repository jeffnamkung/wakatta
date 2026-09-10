import Foundation
import SwiftData

struct ChatDisplayMessage: Identifiable {
    let id: String
    let role: LLMRole
    let content: String
    let timestamp: Date
}

@Observable @MainActor
final class ChatViewModel {

    // MARK: - State

    var messages: [ChatDisplayMessage] = []
    var inputText: String = ""
    var isLoading = false
    var errorMessage: String?
    var isConfigured = false
    var currentConversation: ChatConversation?

    // MARK: - Dependencies

    private let llmManager = LLMServiceManager()
    private var modelContext: ModelContext?

    // MARK: - Configuration

    func configure(
        modelContext: ModelContext,
        conversation: ChatConversation? = nil,
        mediaContextID: String? = nil
    ) {
        self.modelContext = modelContext
        llmManager.loadConfiguration(modelContext: modelContext)
        isConfigured = llmManager.isAvailable

        if let existing = conversation {
            currentConversation = existing
            loadMessages(for: existing, modelContext: modelContext)
        } else {
            let newConvo = ChatConversation(
                title: "New Conversation",
                mediaContextID: mediaContextID
            )
            modelContext.insert(newConvo)
            try? modelContext.save()
            currentConversation = newConvo

            appendAndPersist(
                role: "assistant",
                content: buildWelcomeMessage(mediaContextID: mediaContextID, modelContext: modelContext),
                conversation: newConvo,
                modelContext: modelContext
            )
        }
    }

    // MARK: - Sending Messages

    func sendMessage() async {
        guard let modelContext, let convo = currentConversation else { return }
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        // Auto-title from first user message
        if convo.title == "New Conversation" {
            convo.title = String(text.prefix(40))
            try? modelContext.save()
        }

        appendAndPersist(role: "user", content: text, conversation: convo, modelContext: modelContext)
        inputText = ""
        isLoading = true
        errorMessage = nil
        convo.lastMessageAt = .now

        // Build system prompt fresh each send
        let profile = ChatContextBuilder.buildFluencyProfile(
            modelContext: modelContext,
            mediaContextID: convo.mediaContextID
        )
        let systemPrompt = ChatContextBuilder.buildSystemPrompt(from: profile)

        var llmMessages: [LLMMessage] = [
            LLMMessage(role: .system, content: systemPrompt)
        ]

        // Include last 20 messages for context
        let history = messages.suffix(20)
        for msg in history {
            if msg.role == .user || msg.role == .assistant {
                llmMessages.append(LLMMessage(role: msg.role, content: msg.content))
            }
        }

        do {
            let response = try await llmManager.chat(messages: llmMessages)
            appendAndPersist(role: "assistant", content: response, conversation: convo, modelContext: modelContext)
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Persistence

    private func loadMessages(for conversation: ChatConversation, modelContext: ModelContext) {
        let convoID = conversation.id
        let predicate = #Predicate<ChatMessageData> { $0.conversationId == convoID }
        let descriptor = FetchDescriptor(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp)]
        )
        let stored = (try? modelContext.fetch(descriptor)) ?? []
        messages = stored.compactMap { msg in
            guard let role = LLMRole(rawValue: msg.role), role != .system else { return nil }
            return ChatDisplayMessage(
                id: msg.id,
                role: role,
                content: msg.content,
                timestamp: msg.timestamp
            )
        }
    }

    @discardableResult
    private func appendAndPersist(
        role: String,
        content: String,
        conversation: ChatConversation,
        modelContext: ModelContext
    ) -> ChatDisplayMessage? {
        let stored = ChatMessageData(
            conversationId: conversation.id,
            role: role,
            content: content
        )
        modelContext.insert(stored)
        try? modelContext.save()

        guard let llmRole = LLMRole(rawValue: role), llmRole != .system else { return nil }

        let display = ChatDisplayMessage(
            id: stored.id,
            role: llmRole,
            content: content,
            timestamp: stored.timestamp
        )
        messages.append(display)
        return display
    }

    // MARK: - Welcome Message

    private func buildWelcomeMessage(mediaContextID: String?, modelContext: ModelContext) -> String {
        let profile = ChatContextBuilder.buildFluencyProfile(
            modelContext: modelContext,
            mediaContextID: mediaContextID
        )

        // Build a lesson intro from the lesson plan
        let vocabPreview = profile.vocabToTeach.prefix(2)
        let hasLessonContent = !vocabPreview.isEmpty

        // Media-anchored conversation
        if let mediaID = mediaContextID {
            let predicate = #Predicate<Media> { $0.externalID == mediaID }
            if let media = (try? modelContext.fetch(FetchDescriptor(predicate: predicate)))?.first {
                let jpTitle = media.titleJapanese.map { " (\($0))" } ?? ""
                if hasLessonContent {
                    let firstWord = vocabPreview[vocabPreview.startIndex]
                    var msg = "こんにちは！ Manga-chan here! " +
                        "Today we're studying vocab from **\(media.title)**\(jpTitle).\n\n"
                    msg += "Let's start with: **\(firstWord.word)（\(firstWord.reading)）** — it means \"\(firstWord.meaning)\"."
                    if vocabPreview.count > 1 {
                        let second = vocabPreview[vocabPreview.index(after: vocabPreview.startIndex)]
                        msg += " We'll also cover **\(second.word)** and more."
                    }
                    msg += "\n\nCan you try using \(firstWord.word) in a sentence? Even a short one is great!"
                    return msg
                } else {
                    return "こんにちは！ Manga-chan here! " +
                        "Let's dive into **\(media.title)**\(jpTitle)! " +
                        "I've got some vocab and grammar from this show lined up — let's get started!"
                }
            }
        }

        // General conversation — tier-appropriate proactive lesson
        switch profile.tier {
        case .beginner:
            if hasLessonContent {
                let first = vocabPreview[vocabPreview.startIndex]
                return "こんにちは！ I'm Manga-chan, your Japanese tutor! " +
                    "Let's jump right into a lesson.\n\n" +
                    "First word: **\(first.word)（\(first.reading)）** — it means \"\(first.meaning)\". " +
                    "You'll hear this one a lot in anime!\n\n" +
                    "Try repeating it: \(first.word). Can you type it back to me?"
            }
            return "こんにちは！ I'm Manga-chan, your Japanese tutor! " +
                "Let's start learning! First — こんにちは (konnichiwa) means \"hello\". " +
                "You'll hear this in every anime ever. Try typing こんにちは back to me!"

        case .elementary:
            if hasLessonContent {
                let first = vocabPreview[vocabPreview.startIndex]
                return "こんにちは！ マンガちゃんです！ " +
                    "You know \(profile.totalKnownWords) words already — let's add more!\n\n" +
                    "Today's first word: **\(first.word)（\(first.reading)）** = \"\(first.meaning)\"\n\n" +
                    "\(first.word)を使って文を作ってみて！ [Try making a sentence with \(first.word)!]"
            }
            return "こんにちは！ マンガちゃんです！ " +
                "\(profile.totalKnownWords) words and counting — 頑張ってるね！[You're working hard!] " +
                "Let's add some more today. 準備はいい？ [Ready?]"

        case .intermediate:
            if hasLessonContent {
                let first = vocabPreview[vocabPreview.startIndex]
                return "こんにちは！今日もレッスンを始めよう！\n\n" +
                    "最初の単語（さいしょのたんご）: **\(first.word)（\(first.reading)）** — \(first.meaning)\n\n" +
                    "この言葉を使って何か言ってみて！"
            }
            return "こんにちは！マンガちゃんです。今日も勉強しよう！ " +
                "\(profile.totalKnownWords)語も知ってるから、もっと上を目指そう。 " +
                "準備はいい？始めるよ！"

        case .advanced:
            if hasLessonContent {
                let first = vocabPreview[vocabPreview.startIndex]
                return "こんにちは！今日のレッスンを始めよう。\n\n" +
                    "まずは：**\(first.word)（\(first.reading)）** — \(first.meaning)\n\n" +
                    "この言葉、どんな場面で使うと思う？例文を作ってみて！"
            }
            return "こんにちは！マンガちゃんだよ。\(profile.totalKnownWords)語以上覚えてるのはすごい！ " +
                "今日はさらに上のレベルを目指そう。始めるよ！"
        }
    }
}
