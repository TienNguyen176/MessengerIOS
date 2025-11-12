import Foundation

struct UserModel: Codable {
    let userId: String
    let userName: String
    let email: String
    let avatarUrl: String
    let bio: String
    let genderId: String
    let dob: String
    let chatIds: [String: Bool]?
    let friends: [String: Bool]?
    let blockedUsers: [String: Bool]?
    let allowMessagesFrom: String
    let status: StatusModel
    let friendRequests: FriendRequestModel
}

struct StatusModel: Codable {
    let statusId: String
    let lastSeen: Int64
}

struct FriendRequestModel: Codable {
    let sentRequests: [String: SentRequest]?
    let receivedRequests: [String: ReceivedRequest]?
}

struct SentRequest: Codable {
    let sentAt: Int64
    let statusId: String
}

struct ReceivedRequest: Codable {
    let sentBy: String
    let sentAt: Int64
    let statusId: String
}
