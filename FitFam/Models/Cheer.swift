//
//  Cheer.swift
//  FitFam
//
//  Created by Claude on 10/08/2025.
//  
//  Data model for "cheers" (likes/reactions) on workout posts.
//  Represents positive engagement and encouragement in the fitness community.
//

import Foundation
import FirebaseFirestore

/// Positive reaction/like on a fitness post
struct Cheer: Identifiable, Codable {
    // MARK: - Core Properties
    @DocumentID var id: String?
    let postID: String              // ID of the post being cheered
    let userID: String              // Firebase ID of user giving cheer
    let username: String            // Display username of cheering user
    let timestamp: Date             // When the cheer was given
    
    init(postID: String, userID: String, username: String) {
        self.postID = postID
        self.userID = userID
        self.username = username
        self.timestamp = Date()
    }
}

extension Cheer {
    static let mockCheers: [Cheer] = [
        Cheer(postID: "post1", userID: "user2", username: "mike_lifts"),
        Cheer(postID: "post1", userID: "user3", username: "emma_fitness"),
        Cheer(postID: "post1", userID: "user4", username: "runner_joe")
    ]
}