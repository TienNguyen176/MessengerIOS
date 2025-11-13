
import Foundation

class MessageModel: Codable {
    var messageId: String
    var senderId: String
    var text: String
    var typeMessage: String
    var mediaUrl: String?
    var createdAt: TimeInterval
    
    init(messageId: String,
         senderId: String,
         text: String,
         typeMessage: String,
         mediaUrl: String?,
         createdAt: TimeInterval) {
        self.messageId = messageId
        self.senderId = senderId
        self.text = text
        self.typeMessage = typeMessage
        self.mediaUrl = mediaUrl
        self.createdAt = createdAt
    }
    
    static func fromDict(_ msgId: String, _ dict: [String: Any]) -> MessageModel? {
        if let senderId = dict["sender_id"] as? String,
           let text = dict["text"] as? String,
           let typeMessage = dict["type_message"] as? String,
           let createdAt = dict["createdAt"] as? TimeInterval {
            
            let mediaUrl = dict["mediaUrl"] as? String
            
            return MessageModel(
                messageId: msgId,
                senderId: senderId,
                text: text,
                typeMessage: typeMessage,
                mediaUrl: mediaUrl,
                createdAt: createdAt
            )
        } else {
            return nil
        }
    }
}

extension MessageModel: CustomStringConvertible {
    var description: String {
        return "Message(\(senderId)): \(text)"
    }
}
