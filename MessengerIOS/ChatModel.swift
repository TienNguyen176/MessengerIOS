import Foundation

class ChatModel: Codable {
    var chatId: String
    var typeId: String
    var lastMessage: String
    var updatedAt: TimeInterval
    var userIds: [String]
    
    init(chatId: String,
         typeId: String,
         lastMessage: String,
         updatedAt: TimeInterval,
         userIds: [String]) {
        self.chatId = chatId
        self.typeId = typeId
        self.lastMessage = lastMessage
        self.updatedAt = updatedAt
        self.userIds = userIds
    }
    
    static func fromDict(_ chatId: String, _ dict: [String: Any]) -> ChatModel? {
        if let typeId = dict["type_id"] as? String,
           let updatedAt = dict["updatedAt"] as? TimeInterval,
           let users = dict["users"] as? [String: Bool] {
            
            let lastMessage = dict["lastMessage"] as? String ?? ""
            let userIds = Array(users.keys)
            
            return ChatModel(
                chatId: chatId,
                typeId: typeId,
                lastMessage: lastMessage,
                updatedAt: updatedAt,
                userIds: userIds
            )
        } else {
            return nil
        }
    }
}

extension ChatModel: CustomStringConvertible {
    var description: String {
        return "ChatModel(chatId: \(chatId), users: \(userIds), lastMessage: \(lastMessage))"
    }
}
