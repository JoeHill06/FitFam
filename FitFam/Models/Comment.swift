//
//  Comment.swift
//  FitFam
//
//  Created by Claude on 10/08/2025.
//  
//  Data model for comments on workout posts and social content.
//  Enables user interaction and discussion on fitness activities.
//

import Foundation
import FirebaseFirestore

/// User comment on a fitness post
struct Comment: Identifiable, Codable {
    // MARK: - Core Properties
    @DocumentID var id: String?
    let postID: String              // ID of the post being commented on
    let userID: String              // Firebase ID of commenting user
    let username: String            // Display username of commenter
    let userAvatarURL: String?      // Commenter's profile picture
    let content: String             // Comment text content
    let timestamp: Date             // When comment was posted
    
    init(postID: String, userID: String, username: String, userAvatarURL: String?, content: String) {
        self.postID = postID
        self.userID = userID
        self.username = username
        self.userAvatarURL = userAvatarURL
        self.content = content
        self.timestamp = Date()
    }
}

extension Comment {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    static let mockComments: [Comment] = [
        Comment(
            postID: "post1",
            userID: "user2",
            username: "mike_lifts",
            userAvatarURL: nil,
            content: "Great job! Keep it up! 💪"
        ),
        Comment(
            postID: "post1",
            userID: "user3",
            username: "emma_fitness",
            userAvatarURL: nil,
            content: "That's awesome! What's your next goal?"
        )
    ]
}