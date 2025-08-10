import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let firebaseUID: String
    let email: String
    var username: String
    var displayName: String
    var avatarURL: String?
    var createdAt: Date
    var lastActiveAt: Date
    var isOnboarded: Bool
    var friendGroupIDs: [String]
    var currentStreak: Int
    var longestStreak: Int
    var totalWorkouts: Int
    var privacySettings: PrivacySettings
    
    init(firebaseUID: String, email: String, username: String, displayName: String) {
        self.firebaseUID = firebaseUID
        self.email = email
        self.username = username
        self.displayName = displayName
        self.avatarURL = nil
        self.createdAt = Date()
        self.lastActiveAt = Date()
        self.isOnboarded = false
        self.friendGroupIDs = []
        self.currentStreak = 0
        self.longestStreak = 0
        self.totalWorkouts = 0
        self.privacySettings = PrivacySettings()
    }
}

struct PrivacySettings: Codable {
    var isProfilePublic: Bool = false
    var allowsLocationSharing: Bool = true
    var allowsNotifications: Bool = true
    var blockedUserIDs: [String] = []
}

extension User {
    static let mockUser = User(
        firebaseUID: "mock-uid",
        email: "test@example.com",
        username: "testuser",
        displayName: "Test User"
    )
}