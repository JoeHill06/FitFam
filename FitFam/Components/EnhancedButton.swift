//
//  EnhancedButton.swift
//  FitFam
//
//  Enhanced button components with micro-interactions and haptic feedback
//

import SwiftUI

/// Primary action button with micro-interactions and haptic feedback
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let isLoading: Bool
    let isDisabled: Bool
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.isLoading = isLoading
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button(action: {
            HapticManager.mediumTap()
            action()
        }) {
            HStack(spacing: DesignTokens.Spacing.sm) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.Colors.textPrimary))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(DesignTokens.Typography.bodyMedium)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: DesignTokens.InteractionSize.comfortable)
            .background(
                Group {
                    if isDisabled {
                        DesignTokens.Colors.surfaceElevated
                    } else if isPressed {
                        DesignTokens.Colors.accentDark
                    } else {
                        DesignTokens.Colors.accent
                    }
                }
            )
            .foregroundColor(
                isDisabled ? DesignTokens.Colors.textTertiary : DesignTokens.Colors.textPrimary
            )
            .cornerRadius(DesignTokens.CornerRadius.md)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isDisabled ? 0.6 : 1.0)
            .shadow(
                color: isPressed ? .clear : DesignTokens.Colors.accent.opacity(0.3),
                radius: isPressed ? 0 : 4,
                x: 0,
                y: isPressed ? 0 : 2
            )
        }
        .disabled(isDisabled || isLoading)
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .animation(DesignTokens.Animation.quick, value: isPressed)
        .animation(DesignTokens.Animation.quick, value: isDisabled)
        .animation(DesignTokens.Animation.quick, value: isLoading)
    }
}

/// Secondary action button with subtle styling
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let isDisabled: Bool
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button(action: {
            HapticManager.lightTap()
            action()
        }) {
            Text(title)
                .font(DesignTokens.Typography.bodyMedium)
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.InteractionSize.comfortable)
                .background(
                    isPressed ? DesignTokens.Colors.surfacePressed : DesignTokens.Colors.surfaceElevated
                )
                .foregroundColor(
                    isDisabled ? DesignTokens.Colors.textTertiary : DesignTokens.Colors.textPrimary
                )
                .cornerRadius(DesignTokens.CornerRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                        .stroke(
                            isDisabled ? DesignTokens.Colors.border.opacity(0.5) : DesignTokens.Colors.border,
                            lineWidth: 1
                        )
                )
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .opacity(isDisabled ? 0.6 : 1.0)
        }
        .disabled(isDisabled)
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .animation(DesignTokens.Animation.quick, value: isPressed)
        .animation(DesignTokens.Animation.quick, value: isDisabled)
    }
}

/// Destructive button for dangerous actions (like sign out, delete)
struct DestructiveButton: View {
    let title: String
    let action: () -> Void
    let isDisabled: Bool
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        Button(action: {
            HapticManager.warning()
            action()
        }) {
            Text(title)
                .font(DesignTokens.Typography.bodyMedium)
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.InteractionSize.comfortable)
                .background(
                    isPressed ? DesignTokens.Colors.error.opacity(0.9) : DesignTokens.Colors.error
                )
                .foregroundColor(DesignTokens.Colors.textPrimary)
                .cornerRadius(DesignTokens.CornerRadius.md)
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .opacity(isDisabled ? 0.6 : 1.0)
                .shadow(
                    color: isPressed ? .clear : DesignTokens.Colors.error.opacity(0.3),
                    radius: isPressed ? 0 : 4,
                    x: 0,
                    y: isPressed ? 0 : 2
                )
        }
        .disabled(isDisabled)
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .animation(DesignTokens.Animation.quick, value: isPressed)
        .animation(DesignTokens.Animation.quick, value: isDisabled)
    }
}

/// Text button for subtle actions
struct TextButton: View {
    let title: String
    let action: () -> Void
    let color: Color
    
    @State private var isPressed = false
    
    init(
        _ title: String,
        color: Color = DesignTokens.Colors.accent,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.action = action
        self.color = color
    }
    
    var body: some View {
        Button(action: {
            HapticManager.lightTap()
            action()
        }) {
            Text(title)
                .font(DesignTokens.Typography.bodyMedium)
                .foregroundColor(isPressed ? color.opacity(0.7) : color)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .animation(DesignTokens.Animation.quick, value: isPressed)
    }
}

// MARK: - Press Events Modifier
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.modifier(PressEventModifier(onPress: onPress, onRelease: onRelease))
    }
}

struct PressEventModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onLongPressGesture(
                minimumDuration: 0,
                maximumDistance: .infinity,
                pressing: { pressing in
                    if pressing {
                        onPress()
                    } else {
                        onRelease()
                    }
                },
                perform: {}
            )
    }
}