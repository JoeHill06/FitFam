//
//  Post.swift
//  FitFam
//
//  Created by Claude on 10/08/2025.
//  
//  Data model for workout posts and social content in the fitness feed.
//  Supports various post types including workouts, achievements, check-ins, and progress updates.
//

import Foundation
import FirebaseFirestore

/// Main data model for social fitness posts
/// Represents workout posts, achievements, check-ins, and other social content
struct Post: Identifiable, Codable {
    // MARK: - Core Properties
    @DocumentID var id: String?
    let userID: String              // Firebase user ID of post creator
    let username: String            // Display username
    let userAvatarURL: String?      // Profile picture URL
    
    // MARK: - Post Content
    let postType: PostType          // Type of post (workout, achievement, etc.)
    let content: String?            // Optional text content/caption
    let workoutData: WorkoutData?   // Workout-specific data if applicable
    let mediaURL: String?           // Photo/video URL
    let location: Location?         // Check-in location data
    let timestamp: Date             // When the post was created
    
    // MARK: - Social Engagement
    var cheerCount: Int             // Number of cheers/likes
    var commentCount: Int           // Number of comments
    var isCheerByCurrentUser: Bool = false  // Has current user cheered this post
    
    init(userID: String, username: String, userAvatarURL: String?, postType: PostType, content: String? = nil, workoutData: WorkoutData? = nil, mediaURL: String? = nil, location: Location? = nil) {
        self.userID = userID
        self.username = username
        self.userAvatarURL = userAvatarURL
        self.postType = postType
        self.content = content
        self.workoutData = workoutData
        self.mediaURL = mediaURL
        self.location = location
        self.timestamp = Date()
        self.cheerCount = 0
        self.commentCount = 0
    }
}

// MARK: - PostType Enum

/// Different types of posts supported in the social feed
enum PostType: String, Codable, CaseIterable {
    case workout = "workout"
    case achievement = "achievement"
    case checkIn = "checkIn"
    case progress = "progress"
    case motivation = "motivation"
    case challenge = "challenge"
    
    var displayName: String {
        switch self {
        case .workout: return "Workout"
        case .achievement: return "Achievement"
        case .checkIn: return "Check-in"
        case .progress: return "Progress"
        case .motivation: return "Motivation"
        case .challenge: return "Challenge"
        }
    }
    
    var icon: String {
        switch self {
        case .workout: return "💪"
        case .achievement: return "🏆"
        case .checkIn: return "📍"
        case .progress: return "📈"
        case .motivation: return "🔥"
        case .challenge: return "🎯"
        }
    }
    
    var color: String {
        switch self {
        case .workout: return "blue"
        case .achievement: return "yellow"
        case .checkIn: return "green"
        case .progress: return "purple"
        case .motivation: return "orange"
        case .challenge: return "red"
        }
    }
}

struct WorkoutData: Codable {
    let activityType: ActivityType
    let duration: TimeInterval?
    let distance: Double?
    let calories: Int?
    let intensity: Int?
    
    var formattedDuration: String {
        guard let duration = duration else { return "" }
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var formattedDistance: String {
        guard let distance = distance else { return "" }
        return String(format: "%.1f km", distance)
    }
    
    var formattedCalories: String {
        guard let calories = calories else { return "" }
        return "\(calories) cal"
    }
}

enum ActivityType: String, Codable, CaseIterable {
    case running = "running"
    case cycling = "cycling"
    case swimming = "swimming"
    case gym = "gym"
    case yoga = "yoga"
    case hiking = "hiking"
    case walking = "walking"
    case basketball = "basketball"
    case soccer = "soccer"
    case tennis = "tennis"
    case other = "other"
    
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .gym: return "Gym"
        case .yoga: return "Yoga"
        case .hiking: return "Hiking"
        case .walking: return "Walking"
        case .basketball: return "Basketball"
        case .soccer: return "Soccer"
        case .tennis: return "Tennis"
        case .other: return "Other"
        }
    }
    
    var icon: String {
        switch self {
        case .running: return "🏃‍♂️"
        case .cycling: return "🚴‍♀️"
        case .swimming: return "🏊‍♂️"
        case .gym: return "🏋️‍♀️"
        case .yoga: return "🧘‍♀️"
        case .hiking: return "🥾"
        case .walking: return "🚶‍♂️"
        case .basketball: return "⛹️‍♂️"
        case .soccer: return "⚽"
        case .tennis: return "🎾"
        case .other: return "💪"
        }
    }
}

struct Location: Codable {
    let latitude: Double
    let longitude: Double
    let name: String?
    let address: String?
}

extension Post {
    var timeAgo: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }
    
    static let mockPosts: [Post] = [
        Post(
            userID: "user1",
            username: "sarah_runs",
            userAvatarURL: nil,
            postType: .workout,
            content: "Morning run to start the day right! 🌅",
            workoutData: WorkoutData(
                activityType: .running,
                duration: 1800,
                distance: 5.2,
                calories: 350,
                intensity: 7
            ),
            location: Location(latitude: 37.7749, longitude: -122.4194, name: "Golden Gate Park", address: "San Francisco, CA")
        ),
        Post(
            userID: "user2",
            username: "gym_warrior",
            userAvatarURL: nil,
            postType: .achievement,
            content: "New PR! 💪 Finally hit my goal of benching my body weight!"
        ),
        Post(
            userID: "user3",
            username: "yoga_zen",
            userAvatarURL: nil,
            postType: .workout,
            content: "Peaceful evening yoga session 🧘‍♀️",
            workoutData: WorkoutData(
                activityType: .yoga,
                duration: 3600,
                distance: nil,
                calories: 200,
                intensity: 4
            )
        )
    ]
}