import SwiftUI
import SwiftData

struct ChatConversationListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ChatConversation.lastMessageAt, order: .reverse)
    private var conversations: [ChatConversation]

    @Query(filter: #Predicate<Media> { $0.isInLibrary == true })
    private var libraryMedia: [Media]

    @State private var navigateToNewChat = false
    @State private var newChatMediaID: String? = nil

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button {
                        newChatMediaID = nil
                        navigateToNewChat = true
                    } label: {
                        Label("New Conversation", systemImage: "plus.bubble")
                            .fontWeight(.semibold)
                    }

                    if !libraryMedia.isEmpty {
                        Menu {
                            ForEach(libraryMedia, id: \.externalID) { media in
                                Button {
                                    newChatMediaID = media.externalID
                                    navigateToNewChat = true
                                } label: {
                                    Label(media.title, systemImage: media.mediaType.iconName)
                                }
                            }
                        } label: {
                            Label("Chat About a Show...", systemImage: "tv")
                        }
                    }
                }

                if !conversations.isEmpty {
                    Section("Recent Conversations") {
                        ForEach(conversations) { convo in
                            NavigationLink(value: convo) {
                                ConversationRow(conversation: convo)
                            }
                        }
                        .onDelete { indexSet in
                            for i in indexSet {
                                deleteConversation(conversations[i])
                            }
                        }
                    }
                }
            }
            .navigationTitle("Chat")
            .navigationDestination(for: ChatConversation.self) { convo in
                ChatView(existingConversation: convo)
            }
            .navigationDestination(isPresented: $navigateToNewChat) {
                ChatView(mediaContextID: newChatMediaID)
            }
        }
    }

    private func deleteConversation(_ conversation: ChatConversation) {
        let convoID = conversation.id
        let predicate = #Predicate<ChatMessageData> { $0.conversationId == convoID }
        if let messages = try? modelContext.fetch(FetchDescriptor(predicate: predicate)) {
            for message in messages {
                modelContext.delete(message)
            }
        }
        modelContext.delete(conversation)
        try? modelContext.save()
    }
}

private struct ConversationRow: View {
    let conversation: ChatConversation

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conversation.title)
                .font(.body)
                .fontWeight(.medium)
                .lineLimit(1)
            Text(conversation.lastMessageAt, style: .relative)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
