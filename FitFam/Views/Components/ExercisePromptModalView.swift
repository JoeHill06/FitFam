//
//  ExercisePromptModalView.swift
//  FitFam
//
//  Created by Claude on 13/08/2025.
//

import SwiftUI

/// Modal that prompts users if they are exercising when entering the app
/// Shown once per cold app launch after authentication is confirmed
struct ExercisePromptModalView: View {
    // MARK: - Properties
    let onSelection: (ExercisePromptResponse) -> Void
    
    @State private var isVisible = false
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Background overlay with blur effect
            DesignTokens.BackgroundColors.primary.opacity(0.95)
                .ignoresSafeArea()
                .onTapGesture {
                    // Allow dismissal by tapping background (fallback to "No")
                    dismissWithSelection(.no)
                }
            
            // Main modal content
            modalContent
                .scaleEffect(isVisible ? 1.0 : 0.8)
                .opacity(isVisible ? 1.0 : 0.0)
                .onAppear {
                    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                        isVisible = true
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Modal Content
    
    private var modalContent: some View {
        VStack(spacing: DesignTokens.Spacing.xl) {
            // Header section
            headerSection
            
            // Question section  
            questionSection
            
            // Action buttons
            actionButtons
        }
        .padding(DesignTokens.Spacing.xl)
        .tokenSurface(
            backgroundColor: DesignTokens.BackgroundColors.secondary,
            cornerRadius: DesignTokens.BorderRadius.xl2,
            shadow: DesignTokens.Shadows.xl
        )
        .padding(.horizontal, DesignTokens.Spacing.lg)
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Animated emoji with subtle bounce
            Text("🏋️")
                .font(.system(size: 64))
                .scaleEffect(isVisible ? 1.0 : 0.5)
                .animation(.spring(response: 0.8, dampingFraction: 0.6).delay(0.1), value: isVisible)
            
            Text("Welcome to Fit Fam!")
                .font(DesignTokens.Typography.Styles.title1)
                .foregroundColor(DesignTokens.TextColors.primary)
                .multilineTextAlignment(.center)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(.easeOut(duration: 0.6).delay(0.2), value: isVisible)
        }
    }
    
    // MARK: - Question Section
    
    private var questionSection: some View {
        Text("Are you working out?")
            .font(DesignTokens.Typography.Styles.title3)
            .foregroundColor(DesignTokens.TextColors.secondary)
            .multilineTextAlignment(.center)
            .opacity(isVisible ? 1.0 : 0.0)
            .animation(.easeOut(duration: 0.6).delay(0.3), value: isVisible)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // Primary action - YES
            PrimaryButton("Yes") {
                dismissWithSelection(.yes)
            }
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : 20)
            .animation(.easeOut(duration: 0.5).delay(0.4), value: isVisible)
            .accessibilityLabel("Yes, I am working out")
            .accessibilityHint("Navigates to camera for workout check-in")
            
            // Secondary actions
            HStack(spacing: DesignTokens.Spacing.md) {
                // NO Button
                SecondaryButton("No") {
                    dismissWithSelection(.no)
                }
                .accessibilityLabel("No, I am not working out")
                .accessibilityHint("Returns to home feed")
                
                // REST DAY Button  
                SecondaryButton("Rest Day") {
                    dismissWithSelection(.restDay)
                }
                .accessibilityLabel("Today is a rest day")
                .accessibilityHint("Opens camera for rest day documentation")
            }
            .opacity(isVisible ? 1.0 : 0.0)
            .offset(y: isVisible ? 0 : 30)
            .animation(.easeOut(duration: 0.5).delay(0.5), value: isVisible)
        }
    }
    
    // MARK: - Helper Methods
    
    private func dismissWithSelection(_ response: ExercisePromptResponse) {
        // Haptic feedback based on selection
        switch response {
        case .yes:
            HapticManager.success()
        case .restDay:
            HapticManager.mediumTap()
        case .no:
            HapticManager.lightTap()
        }
        
        // Animate out then call completion
        withAnimation(.easeIn(duration: 0.25)) {
            isVisible = false
        }
        
        // Slight delay before calling onSelection for smooth animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            onSelection(response)
        }
    }
}

// MARK: - Exercise Prompt Response

/// Response types for the exercise prompt modal
enum ExercisePromptResponse {
    case yes
    case no
    case restDay
}

// MARK: - Preview

#Preview {
    ExercisePromptModalView { response in
        print("Selected: \(response)")
    }
}