//
//  User.swift
//  FitFam
//
//  Created by Claude on 10/08/2025.
//  
//  Core user data model with authentication, profile, and fitness tracking information.
//  Integrates with Firebase Authentication and Firestore for user management.
//

import Foundation
import FirebaseFirestore

/// Core user profile and fitness tracking data
struct User: Identifiable, Codable {
    // MARK: - Identity
    @DocumentID var id: String?
    let firebaseUID: String         // Firebase Authentication ID
    let email: String               // User's email address
    
    // MARK: - Profile Information
    var username: String            // Unique username for social features
    var displayName: String         // Display name shown in app
    var avatarURL: String?          // Profile picture URL
    
    // MARK: - Account Status
    var createdAt: Date            // When account was created
    var lastActiveAt: Date         // Last app usage timestamp
    var isOnboarded: Bool          // Has completed onboarding flow
    
    // MARK: - Social Connections
    var friendGroupIDs: [String]   // Groups user belongs to
    
    // MARK: - Fitness Tracking
    var currentStreak: Int         // Current consecutive workout days
    var longestStreak: Int         // Longest streak achieved
    var totalWorkouts: Int         // Total workouts completed
    
    // MARK: - Privacy & Settings
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