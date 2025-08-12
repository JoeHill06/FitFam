import SwiftUI

struct StatsView: View {
    @State private var currentStreak = 5
    @State private var longestStreak = 12
    @State private var totalWorkouts = 47
    @State private var weeklyGoal = 4
    @State private var currentWeekWorkouts = 2
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Streak
                    VStack(spacing: 8) {
                        Text("🔥")
                            .font(.system(size: 40))
                        Text("\(currentStreak)")
                            .font(.system(size: 48, weight: .bold))
                            .foregroundColor(DesignTokens.BrandColors.primary)
                        Text("Day Streak")
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // Weekly Progress
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("This Week")
                                .font(.headline)
                                .fontWeight(.bold)
                            Spacer()
                            Text("\(currentWeekWorkouts)/\(weeklyGoal)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(DesignTokens.BrandColors.primary)
                        }
                        
                        // Progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Rectangle()
                                    .frame(height: 8)
                                    .foregroundColor(Color(.systemGray5))
                                    .cornerRadius(4)
                                
                                Rectangle()
                                    .frame(width: geometry.size.width * min(Double(currentWeekWorkouts) / Double(weeklyGoal), 1.0), height: 8)
                                    .foregroundColor(DesignTokens.BrandColors.primary)
                                    .cornerRadius(4)
                            }
                        }
                        .frame(height: 8)
                        
                        // Weekly calendar view
                        HStack(spacing: 8) {
                            ForEach(0..<7, id: \.self) { day in
                                VStack(spacing: 4) {
                                    Text(dayLetter(for: day))
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .foregroundColor(.secondary)
                                    
                                    Circle()
                                        .frame(width: 24, height: 24)
                                        .foregroundColor(day < currentWeekWorkouts ? DesignTokens.SemanticColors.success : DesignTokens.BorderColors.secondary)
                                        .overlay(
                                            Group {
                                                if day < currentWeekWorkouts {
                                                    Image(systemName: "checkmark")
                                                        .font(.caption2)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        )
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    // Stats Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        StatCard(title: "Total Workouts", value: "\(totalWorkouts)", icon: "💪", color: DesignTokens.BrandColors.primary)
                        StatCard(title: "Longest Streak", value: "\(longestStreak) days", icon: "🏆", color: DesignTokens.SemanticColors.warning)
                        StatCard(title: "This Month", value: "14 workouts", icon: "📅", color: DesignTokens.SemanticColors.success)
                        StatCard(title: "Calories Burned", value: "8,240 cal", icon: "🔥", color: DesignTokens.BrandColors.primaryVariant)
                    }
                    
                    // Achievement Gallery
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Achievements")
                            .font(.headline)
                            .fontWeight(.bold)
                        
                        VStack(spacing: 12) {
                            AchievementRow(icon: "🏃‍♂️", title: "Speed Demon", description: "Ran 5K in under 25 minutes", isUnlocked: true)
                            AchievementRow(icon: "💪", title: "Consistency King", description: "7 day workout streak", isUnlocked: true)
                            AchievementRow(icon: "🎯", title: "Goal Getter", description: "Hit monthly workout goal", isUnlocked: false)
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Stats & Streaks")
        }
    }
    
    private func dayLetter(for index: Int) -> String {
        let days = ["S", "M", "T", "W", "T", "F", "S"]
        return days[index]
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(icon)
                .font(.system(size: 24))
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

struct AchievementRow: View {
    let icon: String
    let title: String
    let description: String
    let isUnlocked: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Text(icon)
                .font(.system(size: 24))
                .opacity(isUnlocked ? 1.0 : 0.3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(isUnlocked ? .primary : .secondary)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if isUnlocked {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(DesignTokens.SemanticColors.success)
            } else {
                Image(systemName: "lock.circle.fill")
                    .foregroundColor(DesignTokens.TextColors.secondary)
            }
        }
        .padding(8)
        .background(Color(.systemGray6).opacity(isUnlocked ? 1.0 : 0.5))
        .cornerRadius(8)
    }
}

#Preview {
    StatsView()
}