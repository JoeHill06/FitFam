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
    
    // MARK: - Body
    var body: some View {
        ZStack {
            // Dark background overlay
            DesignTokens.BackgroundColors.primary
                .ignoresSafeArea()
            
            VStack(spacing: DesignTokens.Spacing.xl2) {
                // Welcome section
                welcomeSection
                
                // Question section
                questionSection
                
                // Action buttons
                actionButtons
                
                Spacer()
            }
            .padding(.horizontal, DesignTokens.Spacing.lg)
            .padding(.top, DesignTokens.Spacing.xl4)
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Welcome Section
    
    private var welcomeSection: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            Text("🏋️")
                .font(DesignTokens.Typography.Styles.largeTitle)
            
            Text("Welcome to Fit Fam!")
                .font(DesignTokens.Typography.Styles.title1)
                .foregroundColor(DesignTokens.TextColors.primary)
                .multilineTextAlignment(.center)
        }
    }
    
    // MARK: - Question Section
    
    private var questionSection: some View {
        Text("Are you working out?")
            .font(DesignTokens.Typography.Styles.title2)
            .foregroundColor(DesignTokens.TextColors.primary)
            .multilineTextAlignment(.center)
            .padding(.top, DesignTokens.Spacing.xl)
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        VStack(spacing: DesignTokens.Spacing.md) {
            // YES Button
            ExercisePromptButton(
                title: "Yes",
                backgroundColor: DesignTokens.BrandColors.primary,
                textColor: DesignTokens.TextColors.primary
            ) {
                HapticManager.selection()
                onSelection(.yes)
            }
            
            // NO Button  
            ExercisePromptButton(
                title: "No",
                backgroundColor: DesignTokens.BrandColors.primary,
                textColor: DesignTokens.TextColors.primary
            ) {
                HapticManager.selection()
                onSelection(.no)
            }
            
            // REST DAY Button
            ExercisePromptButton(
                title: "Rest Day",
                backgroundColor: DesignTokens.BrandColors.primary,
                textColor: DesignTokens.TextColors.primary
            ) {
                HapticManager.selection()
                onSelection(.restDay)
            }
        }
        .padding(.horizontal, DesignTokens.Spacing.md)
    }
}

// MARK: - Exercise Prompt Button

/// Custom button component for exercise prompt actions
private struct ExercisePromptButton: View {
    let title: String
    let backgroundColor: Color
    let textColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                Spacer()
                Text(title)
                    .font(DesignTokens.Typography.Styles.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(textColor)
                Spacer()
            }
            .frame(height: DesignTokens.Accessibility.largeTapTarget)
            .background(backgroundColor)
            .cornerRadius(DesignTokens.BorderRadius.lg)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: DesignTokens.Shadows.md.color,
                radius: DesignTokens.Shadows.md.radius,
                x: DesignTokens.Shadows.md.x,
                y: DesignTokens.Shadows.md.y
            )
        }
        .buttonStyle(PlainButtonStyle())
        .onTapGesture {
            withAnimation(DesignTokens.Animation.fast) {
                isPressed = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(DesignTokens.Animation.fast) {
                    isPressed = false
                }
                action()
            }
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