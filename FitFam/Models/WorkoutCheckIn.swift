import Foundation
import FirebaseFirestore
import CoreLocation

struct WorkoutCheckIn: Identifiable, Codable {
    @DocumentID var id: String?
    let userID: String
    let username: String
    let userAvatarURL: String?
    let timestamp: Date
    let type: CheckInType
    var caption: String?
    let mediaItems: [MediaItem]
    let location: CheckInLocation?
    let visibility: Visibility
    var reactions: [String: [String]] = [:]  // [emoji: [userIDs]]
    var commentCount: Int = 0
    let streakDay: Int
    
    enum CheckInType: String, Codable, CaseIterable {
        case workout = "workout"
        case restDay = "rest_day"
        case activeRecovery = "active_recovery"
        
        var displayName: String {
            switch self {
            case .workout: return "Workout"
            case .restDay: return "Rest Day"
            case .activeRecovery: return "Active Recovery"
            }
        }
        
        var emoji: String {
            switch self {
            case .workout: return "💪"
            case .restDay: return "😴"
            case .activeRecovery: return "🚶"
            }
        }
    }
    
    enum Visibility: String, Codable {
        case friends = "friends"
        case group = "group"
        case `private` = "private"
    }
}

struct MediaItem: Identifiable, Codable {
    var id = UUID().uuidString
    let type: MediaType
    let frontCameraURL: String?
    let backCameraURL: String?
    let thumbnailURL: String?
    let duration: TimeInterval?
    let uploadedAt: Date
    
    enum MediaType: String, Codable {
        case photo = "photo"
        case video = "video"
    }
    
    var hasMultiCamera: Bool {
        return frontCameraURL != nil && backCameraURL != nil
    }
}

struct CheckInLocation: Codable {
    let latitude: Double
    let longitude: Double
    let placeName: String?
    let city: String?
    let country: String?
    
    init(coordinate: CLLocationCoordinate2D, placeName: String? = nil, city: String? = nil, country: String? = nil) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.placeName = placeName
        self.city = city
        self.country = country
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension WorkoutCheckIn {
    static let mockCheckIn = WorkoutCheckIn(
        userID: "mock-user-id",
        username: "testuser",
        userAvatarURL: nil,
        timestamp: Date(),
        type: .workout,
        caption: "Morning gym session! 💪",
        mediaItems: [],
        location: nil,
        visibility: .friends,
        streakDay: 5
    )
    
    var totalReactionCount: Int {
        reactions.values.reduce(0) { $0 + $1.count }
    }
    
    func userReactions(for userID: String) -> [String] {
        reactions.compactMap { emoji, userIDs in
            userIDs.contains(userID) ? emoji : nil
        }
    }
}
