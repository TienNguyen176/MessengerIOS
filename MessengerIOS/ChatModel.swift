import Foundation

// MARK: - Group info
struct ChatGroupInfo: Codable {
    var groupName: String
    var avatarGroupUrl: String
    var groupDescription: String
    var ownerId: String
    var roles: ChatGroupRoles
    var pendingMembers: [String: ChatPendingMember]
    var settings: ChatGroupSettings

    struct ChatGroupRoles: Codable {
        var owners: [String: Bool]
        var admins: [String: Bool]
        var members: [String: Bool]
    }

    struct ChatPendingMember: Codable {
        var addedBy: String
        var approvedBy: String?
        var addedAt: TimeInterval
        var approvedAt: TimeInterval?
        var statusId: String
    }

    struct ChatGroupSettings: Codable {
        var onlyAdminCanChat: Bool
        var requireApprovalToJoin: Bool
    }

    static func fromDict(_ dict: [String: Any]) -> ChatGroupInfo? {
        guard
            let groupName = dict["group_name"] as? String,
            let avatarGroupUrl = dict["avatarGroupUrl"] as? String,
            let groupDescription = dict["groupDescription"] as? String,
            let ownerId = dict["ownerId"] as? String,
            let rolesDict = dict["roles"] as? [String: Any],
            let settingsDict = dict["settings"] as? [String: Any]
        else { return nil }

        let owners = rolesDict["owners"] as? [String: Bool] ?? [:]
        let admins = rolesDict["admins"] as? [String: Bool] ?? [:]
        let members = rolesDict["members"] as? [String: Bool] ?? [:]
        let roles = ChatGroupRoles(owners: owners, admins: admins, members: members)

        var pendingMembers: [String: ChatPendingMember] = [:]
        if let pendingDict = dict["pendingMembers"] as? [String: [String: Any]] {
            for (key, value) in pendingDict {
                if let addedBy = value["addedBy"] as? String,
                   let addedAt = value["addedAt"] as? TimeInterval,
                   let statusId = value["status_id"] as? String {
                    let approvedBy = value["approvedBy"] as? String
                    let approvedAt = value["approvedAt"] as? TimeInterval
                    let pending = ChatPendingMember(addedBy: addedBy, approvedBy: approvedBy, addedAt: addedAt, approvedAt: approvedAt, statusId: statusId)
                    pendingMembers[key] = pending
                }
            }
        }

        let onlyAdminCanChat = settingsDict["onlyAdminCanChat"] as? Bool ?? false
        let requireApprovalToJoin = settingsDict["requireApprovalToJoin"] as? Bool ?? false
        let settings = ChatGroupSettings(onlyAdminCanChat: onlyAdminCanChat, requireApprovalToJoin: requireApprovalToJoin)

        return ChatGroupInfo(groupName: groupName, avatarGroupUrl: avatarGroupUrl, groupDescription: groupDescription, ownerId: ownerId, roles: roles, pendingMembers: pendingMembers, settings: settings)
    }
}

// MARK: - Chat Model
class ChatModel: Codable {
    var chatId: String
    var typeId: String // type_05: private, type_06: group
    var lastMessage: String
    var updatedAt: TimeInterval
    var userIds: [String]

    // Group info, nil nếu chat private
    var groupInfo: ChatGroupInfo?

    init(chatId: String, typeId: String, lastMessage: String, updatedAt: TimeInterval, userIds: [String], groupInfo: ChatGroupInfo? = nil) {
        self.chatId = chatId
        self.typeId = typeId
        self.lastMessage = lastMessage
        self.updatedAt = updatedAt
        self.userIds = userIds
        self.groupInfo = groupInfo
    }

    // Decode từ dict Firebase
    static func fromDict(_ chatId: String, _ dict: [String: Any]) -> ChatModel? {
        guard
            let typeId = dict["type_id"] as? String,
            let updatedAt = dict["updatedAt"] as? TimeInterval
        else { return nil }

        let lastMessage = dict["lastMessage"] as? String ?? ""
        var userIds: [String] = []
        if let users = dict["users"] as? [String: Bool] {
            userIds = Array(users.keys)
        }

        var groupInfo: ChatGroupInfo? = nil
        if typeId == "type_06", let groupDict = dict["groupInfo"] as? [String: Any] {
            groupInfo = ChatGroupInfo.fromDict(groupDict)
        }

        return ChatModel(chatId: chatId, typeId: typeId, lastMessage: lastMessage, updatedAt: updatedAt, userIds: userIds, groupInfo: groupInfo)
    }
}

extension ChatModel: CustomStringConvertible {
    var description: String {
        if typeId == "type_06", let group = groupInfo {
            return "GroupChat(chatId: \(chatId), users: \(userIds), groupName: \(group.groupName), lastMessage: \(lastMessage))"
        } else {
            return "PrivateChat(chatId: \(chatId), users: \(userIds), lastMessage: \(lastMessage))"
        }
    }
}
