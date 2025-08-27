import Foundation
import FirebaseFirestore

struct Message: Identifiable, Codable, Equatable {
    let id: String
    let conversationId: String
    let senderId: String
    let receiverId: String
    let text: String
    let timestamp: Date
    let isRead: Bool
    
    init(id: String = UUID().uuidString,
         conversationId: String,
         senderId: String,
         receiverId: String,
         text: String,
         timestamp: Date = Date(),
         isRead: Bool = false) {
        self.id = id
        self.conversationId = conversationId
        self.senderId = senderId
        self.receiverId = receiverId
        self.text = text
        self.timestamp = timestamp
        self.isRead = isRead
    }
    
    var dictionary: [String: Any] {
        return [
            "id": id,
            "conversationId": conversationId,
            "senderId": senderId,
            "receiverId": receiverId,
            "text": text,
            "timestamp": Timestamp(date: timestamp),
            "isRead": isRead
        ]
    }
}

struct Conversation: Identifiable, Codable {
    let id: String
    let participants: [String] // User IDs
    let itemId: String? // Optional reference to the item being discussed
    let lastMessage: String
    let lastMessageTimestamp: Date
    let unreadCount: Int
    
    init(id: String = UUID().uuidString,
         participants: [String],
         itemId: String? = nil,
         lastMessage: String = "",
         lastMessageTimestamp: Date = Date(),
         unreadCount: Int = 0) {
        self.id = id
        self.participants = participants
        self.itemId = itemId
        self.lastMessage = lastMessage
        self.lastMessageTimestamp = lastMessageTimestamp
        self.unreadCount = unreadCount
    }
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "id": id,
            "participants": participants,
            "lastMessage": lastMessage,
            "lastMessageTimestamp": Timestamp(date: lastMessageTimestamp),
            "unreadCount": unreadCount
        ]
        if let itemId = itemId {
            dict["itemId"] = itemId
        }
        return dict
    }
}