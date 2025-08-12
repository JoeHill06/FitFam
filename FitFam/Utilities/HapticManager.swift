//
//  HapticManager.swift
//  FitFam
//
//  Centralized haptic feedback system for enhanced user interactions.
//  Provides contextual tactile feedback based on interaction type and outcome.
//

import UIKit

/// Manages haptic feedback throughout the app for enhanced user experience
final class HapticManager {
    
    // MARK: - Singleton
    static let shared = HapticManager()
    private init() {}
    
    // MARK: - Haptic Generators
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    // MARK: - Public Interface
    
    /// Light tap feedback for subtle interactions (secondary buttons, toggles)
    static func lightTap() {
        shared.lightImpact.prepare()
        shared.lightImpact.impactOccurred()
    }
    
    /// Medium tap feedback for primary interactions (main buttons, confirmations)
    static func mediumTap() {
        shared.mediumImpact.prepare()
        shared.mediumImpact.impactOccurred()
    }
    
    /// Heavy tap feedback for significant actions (workout completion, major milestones)
    static func heavyTap() {
        shared.heavyImpact.prepare()
        shared.heavyImpact.impactOccurred()
    }
    
    /// Selection feedback for navigation and tab changes
    static func selection() {
        shared.selection.prepare()
        shared.selection.selectionChanged()
    }
    
    /// Success feedback for positive outcomes (goal achieved, workout saved)
    static func success() {
        shared.notification.prepare()
        shared.notification.notificationOccurred(.success)
    }
    
    /// Warning feedback for important alerts (data loss warning, network issues)
    static func warning() {
        shared.notification.prepare()
        shared.notification.notificationOccurred(.warning)
    }
    
    /// Error feedback for failures (login failed, network error)
    static func error() {
        shared.notification.prepare()
        shared.notification.notificationOccurred(.error)
    }
    
    // MARK: - Contextual Feedback Methods
    
    /// Workout-specific haptics
    static func workoutStarted() {
        mediumTap()
    }
    
    static func workoutCompleted() {
        heavyTap()
        // Add a small delay and another light tap for celebration effect
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            lightTap()
        }
    }
    
    static func goalAchieved() {
        success()
        // Triple celebration feedback
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            lightTap()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            lightTap()
        }
    }
    
    /// Social interaction haptics
    static func cheerGiven() {
        mediumTap()
    }
    
    static func messageReceived() {
        lightTap()
    }
    
    /// Navigation haptics
    static func tabChanged() {
        selection()
    }
    
    static func pageTransition() {
        lightTap()
    }
    
    /// Form interaction haptics
    static func fieldFocus() {
        selection()
    }
    
    static func validationError() {
        warning()
    }
    
    static func formSubmitted() {
        mediumTap()
    }
}

// MARK: - SwiftUI View Extension for Easy Usage

import SwiftUI

extension View {
    
    /// Adds light haptic feedback to any tap gesture
    func hapticTap(_ feedback: HapticFeedback = .light) -> some View {
        self.onTapGesture {
            switch feedback {
            case .light:
                HapticManager.lightTap()
            case .medium:
                HapticManager.mediumTap()
            case .heavy:
                HapticManager.heavyTap()
            case .selection:
                HapticManager.selection()
            }
        }
    }
    
    /// Adds haptic feedback on button press (using pressEvents modifier)
    func hapticPress(_ feedback: HapticFeedback = .light) -> some View {
        self.pressEvents(
            onPress: {
                switch feedback {
                case .light:
                    HapticManager.lightTap()
                case .medium:
                    HapticManager.mediumTap()
                case .heavy:
                    HapticManager.heavyTap()
                case .selection:
                    HapticManager.selection()
                }
            },
            onRelease: { }
        )
    }
}

// MARK: - Haptic Feedback Types

enum HapticFeedback {
    case light
    case medium
    case heavy
    case selection
}