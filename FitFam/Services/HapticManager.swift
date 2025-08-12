import UIKit
import CoreHaptics

/// Manages haptic feedback throughout the app for enhanced user engagement
/// Uses psychological principles to create satisfying, contextual tactile responses
class HapticManager {
    static let shared = HapticManager()
    
    private var engine: CHHapticEngine?
    private var supportsHaptics = false
    
    private init() {
        setupHapticEngine()
    }
    
    private func setupHapticEngine() {
        // Check if device supports haptics
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            return
        }
        
        supportsHaptics = true
        
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }
    
    // MARK: - Basic Haptic Patterns
    
    /// Light tap - for gentle interactions (like/unlike, small buttons)
    func lightTap() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
    
    /// Medium impact - for standard interactions (button taps, selections)
    func mediumImpact() {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }
    
    /// Heavy impact - for significant actions (completion, achievements)
    func heavyImpact() {
        let impact = UIImpactFeedbackGenerator(style: .heavy)
        impact.impactOccurred()
    }
    
    /// Success haptic - for positive completions
    func success() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
    }
    
    /// Error haptic - for failures or mistakes
    func error() {
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.error)
    }
    
    /// Selection feedback - for picker wheels, tab switches
    func selection() {
        let selection = UISelectionFeedbackGenerator()
        selection.selectionChanged()
    }
    
    // MARK: - Custom Haptic Patterns
    
    /// Celebration pattern - for achievements, streaks, milestones
    func celebration() {
        guard supportsHaptics, let engine = engine else {
            // Fallback to basic success haptic
            success()
            return
        }
        
        // Custom celebration pattern: Quick burst + pause + stronger burst
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
        
        let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.1)
        let event3 = CHHapticEvent(eventType: .hapticTransient, parameters: [
            CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0), sharpness
        ], relativeTime: 0.3)
        
        do {
            let pattern = try CHHapticPattern(events: [event1, event2, event3], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            print("Failed to play celebration haptic: \(error)")
            success() // Fallback
        }
    }
    
    /// Streak milestone - special pattern for streak achievements
    func streakMilestone(streakCount: Int) {
        guard supportsHaptics, let engine = engine else {
            celebration()
            return
        }
        
        // Intensity increases with streak count (psychological reward escalation)
        let baseIntensity: Float = min(0.5 + Float(streakCount) * 0.1, 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
        
        var events: [CHHapticEvent] = []
        
        // Build pattern based on streak count
        let pulseCount = min(streakCount / 5 + 1, 4) // Max 4 pulses
        
        for i in 0..<pulseCount {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: baseIntensity)
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: Double(i) * 0.15)
            events.append(event)
        }
        
        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            celebration()
        }
    }
    
    /// Photo capture - satisfying camera shutter feel
    func photoCapture() {
        guard supportsHaptics, let engine = engine else {
            heavyImpact()
            return
        }
        
        // Sharp, quick burst mimicking mechanical camera shutter
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.9)
        
        let event = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
        
        do {
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: 0)
        } catch {
            heavyImpact()
        }
    }
    
    /// Pull-to-refresh complete
    func refreshComplete() {
        // Satisfying "snap back" feeling
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred(intensity: 0.7)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let light = UIImpactFeedbackGenerator(style: .light)
            light.impactOccurred(intensity: 0.5)
        }
    }
    
    /// Social interaction (cheer, comment)
    func socialInteraction() {
        // Gentle but satisfying feedback for social actions
        lightTap()
    }
    
    /// Button press with psychological satisfaction
    func buttonPress() {
        // Quick, crisp feedback that feels responsive
        mediumImpact()
    }
    
    /// Navigation transition
    func navigationTransition() {
        selection()
    }
}

// MARK: - Convenience Extensions

extension UIButton {
    /// Add haptic feedback to button tap
    func addHapticFeedback() {
        self.addTarget(self, action: #selector(handleButtonHapticTap), for: .touchUpInside)
    }
    
    @objc private func handleButtonHapticTap() {
        HapticManager.shared.buttonPress()
    }
}

extension UIView {
    /// Add haptic feedback to gesture recognizers
    func addHapticToTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleViewHapticTap))
        self.addGestureRecognizer(tapGesture)
    }
    
    @objc private func handleViewHapticTap() {
        HapticManager.shared.lightTap()
    }
}