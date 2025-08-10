import Foundation
import FirebaseFirestore

struct FriendGroup: Identifiable, Codable {
    @DocumentID var id: String?
    let name: String
    let description: String?
    let createdBy: String
    let createdAt: Date
    var memberIDs: [String]
    var invitedMemberIDs: [String] = []
    let inviteCode: String
    var isPublic: Bool = false
    var maxMembers: Int = 50
    var settings: GroupSettings
    
    init(name: String, description: String?, createdBy: String) {
        self.name = name
        self.description = description
        self.createdBy = createdBy
        self.createdAt = Date()
        self.memberIDs = [createdBy]
        self.inviteCode = FriendGroup.generateInviteCode()
        self.settings = GroupSettings()
    }
    
    static func generateInviteCode() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<8).map { _ in characters.randomElement()! })
    }
}

struct GroupSettings: Codable {
    var allowsComments: Bool = true
    var allowsReactions: Bool = true
    var requiresApprovalForNewMembers: Bool = true
    var dailyRemindersEnabled: Bool = true
    var streakNotificationsEnabled: Bool = true
}

struct GroupInvite: Identifiable, Codable {
    @DocumentID var id: String?
    let groupID: String
    let groupName: String
    let invitedByUserID: String
    let invitedByUsername: String
    let inviteCode: String
    let createdAt: Date
    let expiresAt: Date
    var isUsed: Bool = false
    
    init(groupID: String, groupName: String, invitedByUserID: String, invitedByUsername: String, inviteCode: String) {
        self.groupID = groupID
        self.groupName = groupName
        self.invitedByUserID = invitedByUserID
        self.invitedByUsername = invitedByUsername
        self.inviteCode = inviteCode
        self.createdAt = Date()
        self.expiresAt = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    }
    
    var isExpired: Bool {
        Date() > expiresAt
    }
    
    var isValid: Bool {
        !isUsed && !isExpired
    }
}

extension FriendGroup {
    static let mockGroup = FriendGroup(
        name: "Gym Buddies",
        description: "Daily workout accountability group",
        createdBy: "mock-user-id"
    )
    
    var memberCount: Int {
        memberIDs.count
    }
    
    var isFull: Bool {
        memberIDs.count >= maxMembers
    }
    
    func isMember(_ userID: String) -> Bool {
        memberIDs.contains(userID)
    }
    
    func isCreator(_ userID: String) -> Bool {
        createdBy == userID
    }
}