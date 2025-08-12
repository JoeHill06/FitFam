//
//  HapticManager.swift
//  FitFam
//
//  Centralized haptic feedback management with semantic methods
//

import UIKit

/// Manages haptic feedback with semantic methods for consistent user experience
final class HapticManager {
    static let shared = HapticManager()
    
    private init() {}
    
    // MARK: - Light Feedback (Button taps, selections)
    static func lightTap() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    // MARK: - Medium Feedback (Confirmations, toggles)
    static func mediumTap() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    // MARK: - Heavy Feedback (Important actions, deletions)
    static func heavyTap() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }
    
    // MARK: - Success Feedback (Completions, achievements)
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // MARK: - Warning Feedback (Cautions, alerts)
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }
    
    // MARK: - Error Feedback (Failures, errors)
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // MARK: - Selection Changed (List navigation, tab changes)
    static func selectionChanged() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - View Extension for Easy Access
extension View {
    func onTapHaptic(_ style: HapticStyle = .light, action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            switch style {
            case .light:
                HapticManager.lightTap()
            case .medium:
                HapticManager.mediumTap()
            case .heavy:
                HapticManager.heavyTap()
            case .success:
                HapticManager.success()
            case .warning:
                HapticManager.warning()
            case .error:
                HapticManager.error()
            case .selection:
                HapticManager.selectionChanged()
            }
            action()
        }
    }
}

enum HapticStyle {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
    case selection
}