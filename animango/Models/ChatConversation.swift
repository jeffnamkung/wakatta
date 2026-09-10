import Foundation
import SwiftData

@Model
final class ChatConversation {
    @Attribute(.unique) var id: String
    var title: String
    var mediaContextID: String?
    var createdAt: Date
    var lastMessageAt: Date

    init(
        id: String = UUID().uuidString,
        title: String = "New Conversation",
        mediaContextID: String? = nil,
        createdAt: Date = .now,
        lastMessageAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.mediaContextID = mediaContextID
        self.createdAt = createdAt
        self.lastMessageAt = lastMessageAt
    }
}

@Model
final class ChatMessageData {
    var id: String
    var conversationId: String
    var role: String
    var content: String
    var timestamp: Date

    init(
        id: String = UUID().uuidString,
        conversationId: String,
        role: String,
        content: String,
        timestamp: Date = .now
    ) {
        self.id = id
        self.conversationId = conversationId
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}
