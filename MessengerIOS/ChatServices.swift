import Foundation
import FirebaseDatabase

final class ChatService {
    
    static let shared = ChatService()
    private let ref = Database.database(
        url: "https://messengerios-b2aa7-default-rtdb.asia-southeast1.firebasedatabase.app"
    ).reference()
    
    private init() {}
    
    // MARK: - Fetch chats by type
    func fetchChats(for userId: String, type: String, completion: @escaping ([ChatModel]) -> Void) {
        ref.child("users").child(userId).child("chat_ids").observeSingleEvent(of: .value) { snapshot in
            guard let chatIdsDict = snapshot.value as? [String: Bool] else {
                completion([])
                return
            }
            
            var chats: [ChatModel] = []
            let group = DispatchGroup()
            
            for chatId in chatIdsDict.keys {
                group.enter()
                self.ref.child("chats").child(chatId).observeSingleEvent(of: .value) { chatSnap in
                    defer { group.leave() }
                    
                    guard let chatData = chatSnap.value as? [String: Any],
                          let typeId = chatData["type_id"] as? String,
                          typeId == type,
                          let updatedAt = chatData["updatedAt"] as? TimeInterval,
                          let lastMessage = chatData["lastMessage"] as? String else {
                        return
                    }
                    
                    let userIds = (chatData["users"] as? [String: Bool])?.map { $0.key } ?? []
                    let chat = ChatModel(chatId: chatId,
                                         typeId: typeId,
                                         lastMessage: lastMessage,
                                         updatedAt: updatedAt,
                                         userIds: userIds)
                    chats.append(chat)
                }
            }
            
            group.notify(queue: .main) {
                completion(chats)
            }
        }
    }
    
    // MARK: - Fetch private chats
    func fetchPrivateChats(for userId: String, completion: @escaping ([ChatModel]) -> Void) {
        fetchChats(for: userId, type: "type_05", completion: completion)
    }
    
    // MARK: - Fetch group chats
    func fetchGroupChats(for userId: String, completion: @escaping ([ChatModel]) -> Void) {
        fetchChats(for: userId, type: "type_06", completion: completion)
    }
    
    // MARK: - Create private chat
    func createPrivateChat(currentUserId: String,
                           otherUserId: String,
                           firstMessage: String,
                           completion: @escaping (String?) -> Void) {
        
        let newChatRef = ref.child("chats").childByAutoId()
        guard let chatId = newChatRef.key else {
            completion(nil)
            return
        }
        
        let timestamp = Date().timeIntervalSince1970
        
        let chatData: [String: Any] = [
            "type_id": "type_05",
            "users": [currentUserId: true, otherUserId: true],
            "lastMessage": firstMessage,
            "updatedAt": timestamp
        ]
        
        newChatRef.setValue(chatData) { error, _ in
            if let error = error {
                print("Error creating private chat:", error)
                completion(nil)
                return
            }
            
            // update users
            let updates: [String: Any] = [
                "/users/\(currentUserId)/chat_ids/\(chatId)": true,
                "/users/\(otherUserId)/chat_ids/\(chatId)": true
            ]
            self.ref.updateChildValues(updates)
            completion(chatId)
        }
    }
    
    // MARK: - Create group chat
    func createGroupChat(ownerId: String,
                         groupName: String,
                         memberIds: [String],
                         completion: @escaping (String?) -> Void) {
        
        let newChatRef = ref.child("chats").childByAutoId()
        guard let chatId = newChatRef.key else {
            completion(nil)
            return
        }
        
        var roles: [String: [String: Bool]] = [
            "owners": [ownerId: true],
            "admins": [:],
            "members": [:]
        ]
        
        for memberId in memberIds where memberId != ownerId {
            roles["members"]?[memberId] = true
        }
        
        let chatData: [String: Any] = [
            "type_id": "type_06",
            "updatedAt": Date().timeIntervalSince1970,
            "lastMessage": "",
            "groupInfo": [
                "group_name": groupName,
                "avatarGroupUrl": "",
                "groupDescription": "",
                "ownerId": ownerId,
                "roles": roles,
                "pendingMembers": [:],
                "settings": [
                    "onlyAdminCanChat": false,
                    "requireApprovalToJoin": false
                ]
            ]
        ]
        
        newChatRef.setValue(chatData) { error, _ in
            if let error = error {
                print("Error creating group chat:", error)
                completion(nil)
                return
            }
            
            var updates: [String: Any] = [:]
            for memberId in memberIds + [ownerId] {
                updates["/users/\(memberId)/chat_ids/\(chatId)"] = true
            }
            self.ref.updateChildValues(updates)
            completion(chatId)
        }
    }
}
