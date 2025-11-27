import Foundation

struct UserModel: Codable {
    let userId: String
    let userName: String
    let email: String
    let avatarUrl: String
    let bio: String
    let genderId: String?
    let dob: String
    let chatIds: [String: Bool]?
    let friends: [String: Bool]?
    let blockedUsers: [String: Bool]?
    let allowMessagesFrom: String
    let status: StatusModel
    let friendRequests: FriendRequestModel?
    
    // init rút gọn chỉ dùng trong chat list
    init(userId: String, userName: String, avatarUrl: String?, statusId: String?) {
        self.userId = userId
        self.userName = userName
        self.avatarUrl = avatarUrl ?? ""
        self.email = ""
        self.bio = ""
        self.genderId = ""
        self.dob = ""
        self.chatIds = nil
        self.friends = nil
        self.blockedUsers = nil
        self.allowMessagesFrom = "type_03"
        self.status = StatusModel(statusId: statusId ?? "status_02", lastSeen: 0)
        self.friendRequests = FriendRequestModel(sentRequests: nil, receivedRequests: nil)
    }
}

struct StatusModel: Codable {
    let statusId: String?
    let lastSeen: Int64?
}

struct FriendRequestModel: Codable {
    let sentRequests: [String: SentRequest]?
    let receivedRequests: [String: ReceivedRequest]?
}

struct SentRequest: Codable {
    let sentAt: TimeInterval?
    let statusId: String?
}

struct ReceivedRequest: Codable {
    let sentBy: String?
    let sentAt: TimeInterval?
    let statusId: String?
}
