//
//  DesignTokens.swift
//  FitFam
//
//  Design system tokens for consistent theming across the app
//  Implements dark theme with vibrant red accent and accessible colors
//

import SwiftUI

/// Centralized design tokens for consistent theming
struct DesignTokens {
    // MARK: - Colors
    struct Colors {
        // Primary brand colors
        static let accent = Color(red: 0.95, green: 0.26, blue: 0.21) // Vibrant red #F34236
        static let accentLight = Color(red: 0.95, green: 0.26, blue: 0.21).opacity(0.8)
        static let accentDark = Color(red: 0.8, green: 0.15, blue: 0.1)
        
        // Background colors (dark theme optimized)
        static let backgroundPrimary = Color(red: 0.08, green: 0.08, blue: 0.08) // #141414
        static let backgroundSecondary = Color(red: 0.12, green: 0.12, blue: 0.12) // #1F1F1F
        static let backgroundTertiary = Color(red: 0.16, green: 0.16, blue: 0.16) // #292929
        
        // Surface colors
        static let surfaceElevated = Color(red: 0.2, green: 0.2, blue: 0.2) // #333333
        static let surfacePressed = Color(red: 0.24, green: 0.24, blue: 0.24) // #3D3D3D
        
        // Text colors
        static let textPrimary = Color.white
        static let textSecondary = Color.white.opacity(0.7)
        static let textTertiary = Color.white.opacity(0.5)
        static let textAccent = accent
        
        // Status colors
        static let success = Color(red: 0.2, green: 0.78, blue: 0.35) // #34C759
        static let warning = Color(red: 1.0, green: 0.58, blue: 0.0) // #FF9500
        static let error = Color(red: 0.95, green: 0.26, blue: 0.21) // Same as accent for consistency
        
        // Border and separator colors
        static let border = Color.white.opacity(0.12)
        static let separator = Color.white.opacity(0.08)
    }
    
    // MARK: - Typography
    struct Typography {
        static let largeTitle = Font.largeTitle.bold()
        static let title = Font.title.bold()
        static let title2 = Font.title2.bold()
        static let title3 = Font.title3.weight(.semibold)
        static let headline = Font.headline.weight(.semibold)
        static let body = Font.body
        static let bodyMedium = Font.body.weight(.medium)
        static let bodyBold = Font.body.bold()
        static let callout = Font.callout
        static let subheadline = Font.subheadline
        static let footnote = Font.footnote
        static let caption = Font.caption
    }
    
    // MARK: - Spacing
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
        static let xxxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    struct CornerRadius {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 100
    }
    
    // MARK: - Shadows
    struct Shadows {
        static let light = Color.black.opacity(0.05)
        static let medium = Color.black.opacity(0.1)
        static let heavy = Color.black.opacity(0.15)
        
        static let lightRadius: CGFloat = 2
        static let mediumRadius: CGFloat = 4
        static let heavyRadius: CGFloat = 8
    }
    
    // MARK: - Animation
    struct Animation {
        static let quick = SwiftUI.Animation.easeInOut(duration: 0.2)
        static let medium = SwiftUI.Animation.easeInOut(duration: 0.3)
        static let slow = SwiftUI.Animation.easeInOut(duration: 0.5)
        static let spring = SwiftUI.Animation.spring(response: 0.3, dampingFraction: 0.7)
    }
    
    // MARK: - Interaction Sizes (44pt minimum for accessibility)
    struct InteractionSize {
        static let minimum: CGFloat = 44
        static let comfortable: CGFloat = 48
        static let large: CGFloat = 56
    }
}

// MARK: - View Extensions for Easy Access
extension View {
    func primaryBackground() -> some View {
        self.background(DesignTokens.Colors.backgroundPrimary)
    }
    
    func secondaryBackground() -> some View {
        self.background(DesignTokens.Colors.backgroundSecondary)
    }
    
    func elevatedSurface() -> some View {
        self
            .background(DesignTokens.Colors.surfaceElevated)
            .cornerRadius(DesignTokens.CornerRadius.lg)
            .shadow(
                color: DesignTokens.Shadows.medium,
                radius: DesignTokens.Shadows.mediumRadius,
                x: 0, y: 2
            )
    }
    
    func primaryButton(isPressed: Bool = false) -> some View {
        self
            .frame(minHeight: DesignTokens.InteractionSize.comfortable)
            .background(
                isPressed ? DesignTokens.Colors.accentDark : DesignTokens.Colors.accent
            )
            .foregroundColor(DesignTokens.Colors.textPrimary)
            .cornerRadius(DesignTokens.CornerRadius.md)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(DesignTokens.Animation.quick, value: isPressed)
    }
    
    func secondaryButton(isPressed: Bool = false) -> some View {
        self
            .frame(minHeight: DesignTokens.InteractionSize.comfortable)
            .background(
                isPressed ? DesignTokens.Colors.surfacePressed : DesignTokens.Colors.surfaceElevated
            )
            .foregroundColor(DesignTokens.Colors.textPrimary)
            .cornerRadius(DesignTokens.CornerRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.CornerRadius.md)
                    .stroke(DesignTokens.Colors.border, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(DesignTokens.Animation.quick, value: isPressed)
    }
}