import Foundation
import FirebaseDatabase

class MessageService {
    
    static let shared = MessageService()
    private let ref = Database.database(url: "https://messengerios-b2aa7-default-rtdb.asia-southeast1.firebasedatabase.app").reference()
    
    private init() {}
    
    // MARK: - Fetch messages for a chat
    func fetchMessages(for chatId: String, completion: @escaping ([MessageModel]) -> Void) {
        ref.child("messages").child(chatId).observeSingleEvent(of: .value) { snapshot in
            guard let dict = snapshot.value as? [String: [String: Any]] else {
                completion([])
                return
            }
            
            var messages: [MessageModel] = []
            for (msgId, msgData) in dict {
                if let message = MessageModel.fromDict(msgId, msgData) {
                    messages.append(message)
                }
            }
            
            // sort by createdAt ascending
            messages.sort { $0.createdAt < $1.createdAt }
            completion(messages)
        }
    }
    
    // MARK: - Send message
    func sendMessage(chatId: String, senderId: String, text: String, typeMessage: String = "type_07", mediaUrl: String? = nil, completion: (() -> Void)? = nil) {
        let msgRef = ref.child("messages").child(chatId).childByAutoId()
        let msgId = msgRef.key ?? UUID().uuidString
        let messageData: [String: Any] = [
            "sender_id": senderId,
            "text": text,
            "type_message": typeMessage,
            "mediaUrl": mediaUrl ?? NSNull(),
            "createdAt": Date().timeIntervalSince1970
        ]
        msgRef.setValue(messageData) { error, _ in
            if let error = error {
                print("Error sending message: \(error)")
            }
            completion?()
            
            // Update lastMessage & updatedAt in chat
            self.ref.child("chats").child(chatId).updateChildValues([
                "lastMessage": text,
                "updatedAt": Date().timeIntervalSince1970
            ])
        }
    }
    
    // MARK: - Listen for new messages (Realtime)
    func observeMessages(chatId: String, newMessageHandler: @escaping (MessageModel) -> Void) -> DatabaseHandle {
        return ref.child("messages").child(chatId).observe(.childAdded) { snapshot in
            guard let msgData = snapshot.value as? [String: Any],
                  let message = MessageModel.fromDict(snapshot.key, msgData) else { return }
            newMessageHandler(message)
        }
    }
    
    func removeObserver(chatId: String, handle: DatabaseHandle) {
        ref.child("messages").child(chatId).removeObserver(withHandle: handle)
    }
}
