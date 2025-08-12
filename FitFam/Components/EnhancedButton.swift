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
                        .progressViewStyle(CircularProgressViewStyle(tint: DesignTokens.TextColors.primary))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(DesignTokens.Typography.Styles.bodyMedium)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: DesignTokens.Accessibility.recommendedTapTarget)
            .background(
                Group {
                    if isDisabled {
                        DesignTokens.SurfaceColors.elevated
                    } else if isPressed {
                        DesignTokens.BrandColors.primaryVariant
                    } else {
                        DesignTokens.BrandColors.primary
                    }
                }
            )
            .foregroundColor(
                isDisabled ? DesignTokens.TextColors.tertiary : DesignTokens.TextColors.primary
            )
            .cornerRadius(DesignTokens.BorderRadius.md)
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .opacity(isDisabled ? 0.6 : (isPressed ? 0.9 : 1.0))
            .shadow(
                color: isPressed ? DesignTokens.BrandColors.primary.opacity(0.1) : DesignTokens.BrandColors.primary.opacity(0.4),
                radius: isPressed ? 2 : 8,
                x: 0,
                y: isPressed ? 1 : 4
            )
        }
        .disabled(isDisabled || isLoading)
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.6, blendDuration: 0), value: isPressed)
        .animation(DesignTokens.Animation.fast, value: isDisabled)
        .animation(DesignTokens.Animation.fast, value: isLoading)
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
                .font(DesignTokens.Typography.Styles.bodyMedium)
                .frame(maxWidth: .infinity)
                .frame(minHeight: DesignTokens.Accessibility.recommendedTapTarget)
                .background(
                    isPressed ? DesignTokens.SurfaceColors.pressed : DesignTokens.SurfaceColors.elevated
                )
                .foregroundColor(
                    isDisabled ? DesignTokens.TextColors.tertiary : DesignTokens.TextColors.primary
                )
                .cornerRadius(DesignTokens.BorderRadius.md)
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                        .stroke(
                            isPressed ? DesignTokens.BrandColors.primary : (isDisabled ? DesignTokens.BorderColors.primary.opacity(0.5) : DesignTokens.BorderColors.primary),
                            lineWidth: isPressed ? 2 : 1
                        )
                )
                .scaleEffect(isPressed ? 0.97 : 1.0)
                .opacity(isDisabled ? 0.6 : (isPressed ? 0.95 : 1.0))
                .shadow(
                    color: isPressed ? DesignTokens.BorderColors.primary.opacity(0.2) : .clear,
                    radius: isPressed ? 4 : 0,
                    x: 0,
                    y: isPressed ? 2 : 0
                )
        }
        .disabled(isDisabled)
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .animation(DesignTokens.Animation.fast, value: isPressed)
        .animation(DesignTokens.Animation.fast, value: isDisabled)
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
                .font(DesignTokens.Typography.Styles.bodyMedium)
                .frame(maxWidth: .infinity)
                .frame(height: DesignTokens.Accessibility.recommendedTapTarget)
                .background(
                    isPressed ? DesignTokens.SemanticColors.error.opacity(0.9) : DesignTokens.SemanticColors.error
                )
                .foregroundColor(DesignTokens.TextColors.primary)
                .cornerRadius(DesignTokens.BorderRadius.md)
                .scaleEffect(isPressed ? 0.98 : 1.0)
                .opacity(isDisabled ? 0.6 : 1.0)
                .shadow(
                    color: isPressed ? .clear : DesignTokens.SemanticColors.error.opacity(0.3),
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
        .animation(DesignTokens.Animation.fast, value: isPressed)
        .animation(DesignTokens.Animation.fast, value: isDisabled)
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
        color: Color = DesignTokens.BrandColors.primary,
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
                .font(DesignTokens.Typography.Styles.bodyMedium)
                .foregroundColor(isPressed ? color.opacity(0.7) : color)
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.7, blendDuration: 0), value: isPressed)
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