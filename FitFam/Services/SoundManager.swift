import AVFoundation
import UIKit
import SwiftUI

/// Manages subtle sound effects for enhanced user engagement
/// Uses psychological audio cues to create satisfying, contextual feedback
class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    private var isEnabled = true
    
    private init() {
        setupAudioSession()
        preloadSounds()
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    private func preloadSounds() {
        // Pre-generate system sounds for immediate playback
        preloadSystemSound("camera_shutter", systemSound: 1108) // Camera shutter
        preloadSystemSound("notification", systemSound: 1315) // Gentle notification
        preloadSystemSound("success", systemSound: 1322) // Success chime
        preloadSystemSound("error", systemSound: 1073) // Error sound
        preloadSystemSound("click", systemSound: 1104) // Keyboard click
    }
    
    private func preloadSystemSound(_ key: String, systemSound: SystemSoundID) {
        // System sounds are handled differently - just store the ID
        // We'll create a simple mapping for psychological sound design
    }
    
    // MARK: - Sound Control
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
    }
    
    // MARK: - Contextual Sound Effects
    
    /// Camera capture sound - satisfying shutter click
    func cameraCapture() {
        guard isEnabled else { return }
        
        // Use system camera sound for authenticity
        AudioServicesPlaySystemSound(1108)
    }
    
    /// Success sound - gentle, rewarding chime
    func success() {
        guard isEnabled else { return }
        
        // Gentle success chime
        AudioServicesPlaySystemSound(1322)
    }
    
    /// Achievement sound - more pronounced success
    func achievement() {
        guard isEnabled else { return }
        
        // Double chime for achievements
        AudioServicesPlaySystemSound(1322)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            AudioServicesPlaySystemSound(1322)
        }
    }
    
    /// Streak milestone - escalating reward sound
    func streakMilestone(streak: Int) {
        guard isEnabled else { return }
        
        // More celebration sounds for higher streaks
        let celebrationCount = min(streak / 5 + 1, 3)
        
        for i in 0..<celebrationCount {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.15) {
                AudioServicesPlaySystemSound(1322)
            }
        }
    }
    
    /// Social interaction - gentle, friendly sound
    func socialInteraction() {
        guard isEnabled else { return }
        
        // Very subtle click for likes/comments
        AudioServicesPlaySystemSound(1104)
    }
    
    /// Button tap - crisp, responsive click
    func buttonTap() {
        guard isEnabled else { return }
        
        // Keyboard click sound for button responsiveness
        AudioServicesPlaySystemSound(1104)
    }
    
    /// Navigation sound - smooth transition
    func navigation() {
        guard isEnabled else { return }
        
        // Subtle whoosh for page transitions
        AudioServicesPlaySystemSound(1315)
    }
    
    /// Pull-to-refresh complete
    func refreshComplete() {
        guard isEnabled else { return }
        
        // Satisfying "snap" sound
        AudioServicesPlaySystemSound(1104)
    }
    
    /// Error feedback - non-harsh error indication
    func error() {
        guard isEnabled else { return }
        
        // Gentle error sound (not alarming)
        AudioServicesPlaySystemSound(1053)
    }
    
    /// Notification received
    func notification() {
        guard isEnabled else { return }
        
        AudioServicesPlaySystemSound(1315)
    }
    
    // MARK: - Advanced Audio Feedback
    
    /// Workout completion celebration
    func workoutComplete() {
        guard isEnabled else { return }
        
        // Triumphant sequence
        AudioServicesPlaySystemSound(1322) // Success
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            AudioServicesPlaySystemSound(1322)
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            AudioServicesPlaySystemSound(1322)
        }
    }
    
    /// Profile photo update
    func profilePhotoUpdated() {
        guard isEnabled else { return }
        
        // Camera shutter followed by success
        AudioServicesPlaySystemSound(1108)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            AudioServicesPlaySystemSound(1322)
        }
    }
    
    /// Friend added/social connection
    func socialConnection() {
        guard isEnabled else { return }
        
        // Friendly notification sound
        AudioServicesPlaySystemSound(1315)
    }
    
    // MARK: - Psychological Sound Design
    
    /// Play contextual sound based on user action psychology
    func contextualFeedback(for action: UserAction) {
        switch action {
        case .photoCapture:
            cameraCapture()
        case .socialLike:
            socialInteraction()
        case .achievement:
            achievement()
        case .streakMaintained(let count):
            streakMilestone(streak: count)
        case .profileUpdate:
            success()
        case .workoutComplete:
            workoutComplete()
        case .friendAdded:
            socialConnection()
        case .buttonPress:
            buttonTap()
        case .navigation:
            navigation()
        case .error:
            error()
        case .pullRefresh:
            refreshComplete()
        }
    }
}

// MARK: - User Action Types

enum UserAction {
    case photoCapture
    case socialLike
    case achievement
    case streakMaintained(Int)
    case profileUpdate
    case workoutComplete
    case friendAdded
    case buttonPress
    case navigation
    case error
    case pullRefresh
}

// MARK: - SwiftUI Integration

extension View {
    /// Add sound feedback to button interactions
    func soundFeedback(_ action: UserAction) -> some View {
        self.onTapGesture {
            SoundManager.shared.contextualFeedback(for: action)
        }
    }
    
    /// Add combined haptic + sound feedback
    func richFeedback(_ action: UserAction) -> some View {
        self.onTapGesture {
            // Combine haptic and sound for maximum psychological impact
            switch action {
            case .photoCapture:
                HapticManager.shared.photoCapture()
                SoundManager.shared.cameraCapture()
            case .socialLike:
                HapticManager.shared.socialInteraction()
                SoundManager.shared.socialInteraction()
            case .achievement:
                HapticManager.shared.celebration()
                SoundManager.shared.achievement()
            case .streakMaintained(let count):
                HapticManager.shared.streakMilestone(streakCount: count)
                SoundManager.shared.streakMilestone(streak: count)
            case .buttonPress:
                HapticManager.shared.buttonPress()
                SoundManager.shared.buttonTap()
            default:
                HapticManager.shared.lightTap()
                SoundManager.shared.contextualFeedback(for: action)
            }
        }
    }
}