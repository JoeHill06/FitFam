import Foundation
import FirebaseFirestore

struct Streak: Identifiable, Codable {
    @DocumentID var id: String?
    let userID: String
    var currentStreak: Int
    var longestStreak: Int
    var lastCheckInDate: Date?
    var streakHistory: [StreakEntry]
    var achievements: [Achievement]
    
    init(userID: String) {
        self.userID = userID
        self.currentStreak = 0
        self.longestStreak = 0
        self.lastCheckInDate = nil
        self.streakHistory = []
        self.achievements = []
    }
    
    mutating func recordCheckIn(date: Date = Date(), type: WorkoutCheckIn.CheckInType) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        let lastCheckIn = lastCheckInDate.map { calendar.startOfDay(for: $0) }
        
        let entry = StreakEntry(date: today, type: type)
        
        if let lastDate = lastCheckIn {
            let daysDifference = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 0
            
            switch daysDifference {
            case 0:
                if let lastIndex = streakHistory.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: today) }) {
                    streakHistory[lastIndex] = entry
                }
                return
                
            case 1:
                if type == .workout || type == .activeRecovery {
                    currentStreak += 1
                } else {
                    currentStreak = max(0, currentStreak)
                }
                
            default:
                if type == .workout || type == .activeRecovery {
                    currentStreak = 1
                } else {
                    currentStreak = 0
                }
            }
        } else {
            if type == .workout || type == .activeRecovery {
                currentStreak = 1
            }
        }
        
        streakHistory.append(entry)
        lastCheckInDate = date
        
        if currentStreak > longestStreak {
            longestStreak = currentStreak
            checkForAchievements()
        }
    }
    
    private mutating func checkForAchievements() {
        let milestones = [7, 14, 30, 60, 90, 180, 365]
        
        for milestone in milestones {
            if currentStreak == milestone {
                let achievement = Achievement.streakMilestone(days: milestone)
                if !achievements.contains(where: { $0.id == achievement.id }) {
                    achievements.append(achievement)
                }
            }
        }
    }
    
    func streakStatus(for date: Date = Date()) -> StreakStatus {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: date)
        
        guard let lastCheckIn = lastCheckInDate else {
            return .notStarted
        }
        
        let lastDate = calendar.startOfDay(for: lastCheckIn)
        let daysDifference = calendar.dateComponents([.day], from: lastDate, to: today).day ?? 0
        
        switch daysDifference {
        case 0:
            return .completedToday
        case 1:
            return .canContinue
        case 2...:
            return .broken
        default:
            return .notStarted
        }
    }
}

struct StreakEntry: Codable {
    let date: Date
    let type: WorkoutCheckIn.CheckInType
    
    var isRestDay: Bool {
        type == .restDay
    }
}

enum StreakStatus {
    case notStarted
    case completedToday
    case canContinue
    case broken
    
    var message: String {
        switch self {
        case .notStarted:
            return "Ready to start your streak!"
        case .completedToday:
            return "Streak completed for today!"
        case .canContinue:
            return "Keep your streak alive!"
        case .broken:
            return "Time to restart your streak"
        }
    }
    
    var canCheckIn: Bool {
        switch self {
        case .notStarted, .canContinue:
            return true
        case .completedToday, .broken:
            return false
        }
    }
}

struct Achievement: Identifiable, Codable {
    let id: String
    let title: String
    let description: String
    let iconName: String
    let unlockedAt: Date
    let category: Category
    
    enum Category: String, Codable {
        case streak = "streak"
        case social = "social"
        case milestone = "milestone"
    }
    
    init(id: String, title: String, description: String, iconName: String, category: Category) {
        self.id = id
        self.title = title
        self.description = description
        self.iconName = iconName
        self.unlockedAt = Date()
        self.category = category
    }
    
    static func streakMilestone(days: Int) -> Achievement {
        return Achievement(
            id: "streak_\(days)",
            title: "\(days) Day Streak",
            description: "Completed \(days) days of consistent workouts",
            iconName: "flame.fill",
            category: .streak
        )
    }
}

extension Streak {
    static let mockStreak = Streak(userID: "mock-user-id")
}