import SwiftUI

/// Psychological reward system for streak achievements
/// Uses escalating celebrations to maintain user motivation and engagement
struct StreakCelebrationView: View {
    let streakCount: Int
    let isVisible: Bool
    let onComplete: () -> Void
    
    @State private var scale: CGFloat = 0.1
    @State private var opacity: Double = 0
    @State private var rotation: Double = 0
    @State private var fireworksOffset: CGFloat = 0
    
    var body: some View {
        if isVisible {
            ZStack {
                // Semi-transparent background
                Color.black.opacity(0.4)
                    .opacity(opacity)
                    .ignoresSafeArea()
                
                VStack(spacing: 20) {
                    // Celebration icon with escalating rewards
                    celebrationIcon
                        .scaleEffect(scale)
                        .rotationEffect(.degrees(rotation))
                    
                    // Streak count display
                    Text("\(streakCount)")
                        .font(.system(size: 72, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        .scaleEffect(scale)
                    
                    Text(streakMessage)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 1)
                        .opacity(opacity)
                    
                    // Psychological reward escalation
                    if streakCount >= 7 {
                        Text("You're on fire! 🔥")
                            .font(.headline)
                            .foregroundColor(.orange)
                            .opacity(opacity)
                    }
                    
                    if streakCount >= 30 {
                        Text("LEGENDARY STREAK! 👑")
                            .font(.headline)
                            .foregroundColor(.yellow)
                            .opacity(opacity)
                    }
                }
                
                // Fireworks/celebration particles
                if streakCount >= 5 {
                    fireworksEffect
                }
            }
            .onAppear {
                triggerCelebration()
            }
        }
    }
    
    private var celebrationIcon: some View {
        ZStack {
            // Background circle
            Circle()
                .fill(celebrationColor.gradient)
                .frame(width: 120, height: 120)
                .shadow(color: celebrationColor.opacity(0.5), radius: 10, x: 0, y: 5)
            
            // Icon based on streak milestone
            Image(systemName: streakIcon)
                .font(.system(size: 40, weight: .bold))
                .foregroundColor(.white)
        }
    }
    
    private var fireworksEffect: some View {
        ForEach(0..<min(streakCount / 5, 8), id: \.self) { index in
            Circle()
                .fill(randomColor.opacity(0.8))
                .frame(width: 8, height: 8)
                .offset(
                    x: cos(Double(index) * .pi / 4) * fireworksOffset,
                    y: sin(Double(index) * .pi / 4) * fireworksOffset
                )
                .animation(.easeOut(duration: 1.5).delay(Double(index) * 0.1), value: fireworksOffset)
        }
    }
    
    // MARK: - Psychological Reward Escalation
    
    private var celebrationColor: Color {
        switch streakCount {
        case 1...3: return .green
        case 4...6: return .blue
        case 7...13: return .orange
        case 14...29: return .purple
        case 30...99: return .pink
        default: return .yellow // Legendary
        }
    }
    
    private var streakIcon: String {
        switch streakCount {
        case 1: return "flame"
        case 2...3: return "flame.fill"
        case 4...6: return "bolt.fill"
        case 7...13: return "star.fill"
        case 14...29: return "crown.fill"
        case 30...99: return "diamond.fill"
        default: return "trophy.fill"
        }
    }
    
    private var streakMessage: String {
        switch streakCount {
        case 1: return "First day complete!\nGreat start! 🌟"
        case 2: return "Two days strong!\nMomentum building! ⚡"
        case 3: return "Three day streak!\nYou're getting the hang of it! 💪"
        case 4...6: return "\(streakCount) day streak!\nConsistency is key! 🔥"
        case 7: return "One week streak!\nThis is becoming a habit! 🎯"
        case 14: return "Two week streak!\nYou're unstoppable! 🚀"
        case 30: return "30 day streak!\nLegendary commitment! 👑"
        case 50: return "50 day streak!\nYou're an inspiration! 💎"
        case 100: return "100 DAYS!\nAbsolute legend! 🏆"
        default:
            if streakCount > 100 {
                return "\(streakCount) days!\nBeyond legendary! 🌟"
            } else {
                return "\(streakCount) day streak!\nKeep it going! 🔥"
            }
        }
    }
    
    private var randomColor: Color {
        let colors: [Color] = [.red, .blue, .green, .orange, .purple, .pink, .yellow]
        return colors.randomElement() ?? .blue
    }
    
    // MARK: - Animation Logic
    
    private func triggerCelebration() {
        // Immediate feedback
        HapticManager.shared.streakMilestone(streakCount: streakCount)
        SoundManager.shared.streakMilestone(streak: streakCount)
        
        // Entry animation
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            scale = 1.0
            opacity = 1.0
        }
        
        // Rotation for special milestones
        if streakCount >= 7 {
            withAnimation(.easeInOut(duration: 0.8).delay(0.3)) {
                rotation = 360
            }
        }
        
        // Fireworks animation
        if streakCount >= 5 {
            withAnimation(.easeOut(duration: 1.5).delay(0.5)) {
                fireworksOffset = 100
            }
        }
        
        // Auto-dismiss after psychological satisfaction period
        let dismissDelay = min(3.0 + Double(streakCount) * 0.1, 6.0)
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDelay) {
            dismissCelebration()
        }
    }
    
    private func dismissCelebration() {
        withAnimation(.easeInOut(duration: 0.5)) {
            scale = 0.1
            opacity = 0
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onComplete()
        }
    }
}

// MARK: - Streak Manager

class StreakManager: ObservableObject {
    @Published var showCelebration = false
    @Published var currentStreak = 0
    
    func celebrateStreak(_ count: Int) {
        currentStreak = count
        showCelebration = true
    }
    
    func dismissCelebration() {
        showCelebration = false
    }
}

// MARK: - Preview
#Preview {
    ZStack {
        Color.gray.ignoresSafeArea()
        
        StreakCelebrationView(
            streakCount: 7,
            isVisible: true,
            onComplete: {}
        )
    }
}