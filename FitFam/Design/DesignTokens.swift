//
//  DesignTokens.swift
//  FitFam
//
//  Centralized design token system with Light/Dark mode support
//  Production-ready, scalable design system implementation
//  Compatible with both SwiftUI and UIKit
//

import SwiftUI
import UIKit

/// Main design token interface providing type-safe access to all design tokens
/// Automatically adapts to Light/Dark mode and accessibility settings
public struct DesignTokens {
    
    // MARK: - Private Properties
    private static let loader = TokenLoader.shared
    private static let tokens = loader.getTokens()
    
    // MARK: - Color Tokens
    
    /// Brand color tokens for primary brand elements
    public struct BrandColors {
        /// Primary brand color - adapts to light/dark mode
        public static var primary: Color {
            Color.adaptive(
                light: tokens.colors.brand.primary.light,
                dark: tokens.colors.brand.primary.dark
            )
        }
        
        /// Primary brand color variant - slightly different shade
        public static var primaryVariant: Color {
            Color.adaptive(
                light: tokens.colors.brand.primaryVariant.light,
                dark: tokens.colors.brand.primaryVariant.dark
            )
        }
        
        /// Secondary brand color
        public static var secondary: Color {
            Color.adaptive(
                light: tokens.colors.brand.secondary.light,
                dark: tokens.colors.brand.secondary.dark
            )
        }
        
        // UIKit versions
        public static var primaryUIColor: UIColor {
            UIColor.adaptive(
                light: tokens.colors.brand.primary.light,
                dark: tokens.colors.brand.primary.dark
            )
        }
    }
    
    /// Semantic color tokens for status and feedback
    public struct SemanticColors {
        public static var success: Color {
            Color.adaptive(
                light: tokens.colors.semantic.success.light,
                dark: tokens.colors.semantic.success.dark
            )
        }
        
        public static var warning: Color {
            Color.adaptive(
                light: tokens.colors.semantic.warning.light,
                dark: tokens.colors.semantic.warning.dark
            )
        }
        
        public static var error: Color {
            Color.adaptive(
                light: tokens.colors.semantic.error.light,
                dark: tokens.colors.semantic.error.dark
            )
        }
        
        public static var info: Color {
            Color.adaptive(
                light: tokens.colors.semantic.info.light,
                dark: tokens.colors.semantic.info.dark
            )
        }
    }
    
    /// Background color tokens
    public struct BackgroundColors {
        public static var primary: Color {
            Color.adaptive(
                light: tokens.colors.neutral.background.primary.light,
                dark: tokens.colors.neutral.background.primary.dark
            )
        }
        
        public static var secondary: Color {
            Color.adaptive(
                light: tokens.colors.neutral.background.secondary.light,
                dark: tokens.colors.neutral.background.secondary.dark
            )
        }
        
        public static var tertiary: Color {
            Color.adaptive(
                light: tokens.colors.neutral.background.tertiary.light,
                dark: tokens.colors.neutral.background.tertiary.dark
            )
        }
    }
    
    /// Surface color tokens for elevated components
    public struct SurfaceColors {
        public static var elevated: Color {
            Color.adaptive(
                light: tokens.colors.neutral.surface.elevated.light,
                dark: tokens.colors.neutral.surface.elevated.dark
            )
        }
        
        public static var pressed: Color {
            Color.adaptive(
                light: tokens.colors.neutral.surface.pressed.light,
                dark: tokens.colors.neutral.surface.pressed.dark
            )
        }
    }
    
    /// Text color tokens
    public struct TextColors {
        public static var primary: Color {
            Color.adaptive(
                light: tokens.colors.neutral.text.primary.light,
                dark: tokens.colors.neutral.text.primary.dark
            )
        }
        
        public static var secondary: Color {
            Color.adaptive(
                light: tokens.colors.neutral.text.secondary.light,
                dark: tokens.colors.neutral.text.secondary.dark
            )
        }
        
        public static var tertiary: Color {
            Color.adaptive(
                light: tokens.colors.neutral.text.tertiary.light,
                dark: tokens.colors.neutral.text.tertiary.dark
            )
        }
        
        public static var disabled: Color {
            Color.adaptive(
                light: tokens.colors.neutral.text.disabled.light,
                dark: tokens.colors.neutral.text.disabled.dark
            )
        }
    }
    
    /// Border color tokens
    public struct BorderColors {
        public static var primary: Color {
            Color.adaptive(
                light: tokens.colors.neutral.border.primary.light,
                dark: tokens.colors.neutral.border.primary.dark
            )
        }
        
        public static var secondary: Color {
            Color.adaptive(
                light: tokens.colors.neutral.border.secondary.light,
                dark: tokens.colors.neutral.border.secondary.dark
            )
        }
    }
    
    // MARK: - Typography Tokens
    
    /// Typography tokens with accessibility support
    public struct Typography {
        
        /// Font families
        public struct FontFamily {
            public static let primary = tokens.typography.fontFamilies.primary
            public static let secondary = tokens.typography.fontFamilies.secondary
            public static let monospace = tokens.typography.fontFamilies.monospace
        }
        
        /// Font sizes that scale with accessibility settings
        public struct FontSize {
            public static var xs: CGFloat { scaledSize(tokens.typography.fontSizes["xs"] ?? 12) }
            public static var sm: CGFloat { scaledSize(tokens.typography.fontSizes["sm"] ?? 14) }
            public static var base: CGFloat { scaledSize(tokens.typography.fontSizes["base"] ?? 16) }
            public static var lg: CGFloat { scaledSize(tokens.typography.fontSizes["lg"] ?? 18) }
            public static var xl: CGFloat { scaledSize(tokens.typography.fontSizes["xl"] ?? 20) }
            public static var xl2: CGFloat { scaledSize(tokens.typography.fontSizes["2xl"] ?? 24) }
            public static var xl3: CGFloat { scaledSize(tokens.typography.fontSizes["3xl"] ?? 30) }
            public static var xl4: CGFloat { scaledSize(tokens.typography.fontSizes["4xl"] ?? 36) }
            public static var xl5: CGFloat { scaledSize(tokens.typography.fontSizes["5xl"] ?? 48) }
            public static var xl6: CGFloat { scaledSize(tokens.typography.fontSizes["6xl"] ?? 60) }
            
            private static func scaledSize(_ size: Double) -> CGFloat {
                let scaleFactor = UIFontMetrics.default.scaledValue(for: CGFloat(size))
                return scaleFactor
            }
        }
        
        /// Font weights
        public struct FontWeight {
            public static let light = Font.Weight.light
            public static let regular = Font.Weight.regular
            public static let medium = Font.Weight.medium
            public static let semibold = Font.Weight.semibold
            public static let bold = Font.Weight.bold
            public static let heavy = Font.Weight.heavy
        }
        
        /// Predefined font styles
        public struct Styles {
            public static var largeTitle: Font {
                Font.custom(FontFamily.primary, size: FontSize.xl5).weight(.bold)
            }
            
            public static var title1: Font {
                Font.custom(FontFamily.primary, size: FontSize.xl4).weight(.bold)
            }
            
            public static var title2: Font {
                Font.custom(FontFamily.primary, size: FontSize.xl3).weight(.bold)
            }
            
            public static var title3: Font {
                Font.custom(FontFamily.primary, size: FontSize.xl2).weight(.semibold)
            }
            
            public static var headline: Font {
                Font.custom(FontFamily.primary, size: FontSize.xl).weight(.semibold)
            }
            
            public static var body: Font {
                Font.custom(FontFamily.secondary, size: FontSize.base).weight(.regular)
            }
            
            public static var bodyMedium: Font {
                Font.custom(FontFamily.secondary, size: FontSize.base).weight(.medium)
            }
            
            public static var callout: Font {
                Font.custom(FontFamily.secondary, size: FontSize.base).weight(.regular)
            }
            
            public static var subheadline: Font {
                Font.custom(FontFamily.secondary, size: FontSize.sm).weight(.regular)
            }
            
            public static var footnote: Font {
                Font.custom(FontFamily.secondary, size: FontSize.xs).weight(.regular)
            }
            
            public static var caption1: Font {
                Font.custom(FontFamily.secondary, size: FontSize.xs).weight(.regular)
            }
            
            public static var caption2: Font {
                Font.custom(FontFamily.secondary, size: FontSize.xs).weight(.regular)
            }
        }
    }
    
    // MARK: - Spacing Tokens
    
    /// Spacing tokens for consistent layout
    public struct Spacing {
        public static let none: CGFloat = 0
        public static let xs: CGFloat = CGFloat(tokens.spacing.values["xs"] ?? 4)
        public static let sm: CGFloat = CGFloat(tokens.spacing.values["sm"] ?? 8)
        public static let md: CGFloat = CGFloat(tokens.spacing.values["md"] ?? 16)
        public static let lg: CGFloat = CGFloat(tokens.spacing.values["lg"] ?? 24)
        public static let xl: CGFloat = CGFloat(tokens.spacing.values["xl"] ?? 32)
        public static let xl2: CGFloat = CGFloat(tokens.spacing.values["2xl"] ?? 40)
        public static let xl3: CGFloat = CGFloat(tokens.spacing.values["3xl"] ?? 48)
        public static let xl4: CGFloat = CGFloat(tokens.spacing.values["4xl"] ?? 64)
        public static let xl5: CGFloat = CGFloat(tokens.spacing.values["5xl"] ?? 80)
        public static let xl6: CGFloat = CGFloat(tokens.spacing.values["6xl"] ?? 96)
    }
    
    // MARK: - Border Radius Tokens
    
    /// Border radius tokens for consistent corner styling
    public struct BorderRadius {
        public static let none: CGFloat = CGFloat(tokens.borderRadius["none"] ?? 0)
        public static let xs: CGFloat = CGFloat(tokens.borderRadius["xs"] ?? 2)
        public static let sm: CGFloat = CGFloat(tokens.borderRadius["sm"] ?? 4)
        public static let md: CGFloat = CGFloat(tokens.borderRadius["md"] ?? 8)
        public static let lg: CGFloat = CGFloat(tokens.borderRadius["lg"] ?? 12)
        public static let xl: CGFloat = CGFloat(tokens.borderRadius["xl"] ?? 16)
        public static let xl2: CGFloat = CGFloat(tokens.borderRadius["2xl"] ?? 20)
        public static let xl3: CGFloat = CGFloat(tokens.borderRadius["3xl"] ?? 24)
        public static let full: CGFloat = CGFloat(tokens.borderRadius["full"] ?? 9999)
    }
    
    // MARK: - Shadow Tokens
    
    /// Shadow tokens for depth and elevation
    public struct Shadows {
        public static let none = Shadow(color: .clear, radius: 0, x: 0, y: 0)
        
        public static let sm = Shadow(
            color: .black.opacity(0.1),
            radius: CGFloat(tokens.shadows["sm"]?.blur ?? 2),
            x: CGFloat(tokens.shadows["sm"]?.x ?? 0),
            y: CGFloat(tokens.shadows["sm"]?.y ?? 1)
        )
        
        public static let md = Shadow(
            color: .black.opacity(0.1),
            radius: CGFloat(tokens.shadows["md"]?.blur ?? 6),
            x: CGFloat(tokens.shadows["md"]?.x ?? 0),
            y: CGFloat(tokens.shadows["md"]?.y ?? 4)
        )
        
        public static let lg = Shadow(
            color: .black.opacity(0.1),
            radius: CGFloat(tokens.shadows["lg"]?.blur ?? 15),
            x: CGFloat(tokens.shadows["lg"]?.x ?? 0),
            y: CGFloat(tokens.shadows["lg"]?.y ?? 10)
        )
        
        public static let xl = Shadow(
            color: .black.opacity(0.25),
            radius: CGFloat(tokens.shadows["xl"]?.blur ?? 25),
            x: CGFloat(tokens.shadows["xl"]?.x ?? 0),
            y: CGFloat(tokens.shadows["xl"]?.y ?? 20)
        )
    }
    
    // MARK: - Animation Tokens
    
    /// Animation tokens for consistent motion
    public struct Animation {
        public static let instant = SwiftUI.Animation.linear(duration: tokens.animation.duration["instant"] ?? 0)
        public static let fast = SwiftUI.Animation.easeInOut(duration: (tokens.animation.duration["fast"] ?? 150) / 1000)
        public static let normal = SwiftUI.Animation.easeInOut(duration: (tokens.animation.duration["normal"] ?? 300) / 1000)
        public static let slow = SwiftUI.Animation.easeInOut(duration: (tokens.animation.duration["slow"] ?? 500) / 1000)
        public static let slower = SwiftUI.Animation.easeInOut(duration: (tokens.animation.duration["slower"] ?? 750) / 1000)
        
        public static let spring = SwiftUI.Animation.spring(
            response: 0.5,
            dampingFraction: 0.75,
            blendDuration: 0
        )
        
        public static let bouncy = SwiftUI.Animation.spring(
            response: 0.3,
            dampingFraction: 0.6,
            blendDuration: 0
        )
    }
    
    // MARK: - Accessibility Tokens
    
    /// Accessibility tokens for inclusive design
    public struct Accessibility {
        public static let minimumTapTarget = CGFloat(tokens.accessibility.minimumTapTarget)
        public static let recommendedTapTarget = CGFloat(tokens.accessibility.recommendedTapTarget)
        public static let largeTapTarget = CGFloat(tokens.accessibility.largeTapTarget)
    }
    
    // MARK: - Breakpoint Tokens
    
    /// Responsive breakpoint tokens
    public struct Breakpoints {
        public static let mobile = CGFloat(tokens.breakpoints["mobile"] ?? 375)
        public static let tablet = CGFloat(tokens.breakpoints["tablet"] ?? 768)
        public static let desktop = CGFloat(tokens.breakpoints["desktop"] ?? 1024)
        public static let large = CGFloat(tokens.breakpoints["large"] ?? 1440)
    }
}

// MARK: - Shadow Helper Struct

public struct Shadow {
    public let color: Color
    public let radius: CGFloat
    public let x: CGFloat
    public let y: CGFloat
    
    public init(color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
        self.color = color
        self.radius = radius
        self.x = x
        self.y = y
    }
}

// MARK: - Color Extensions for Adaptive Colors

extension Color {
    /// Creates a color that adapts to light/dark mode
    static func adaptive(light: String, dark: String) -> Color {
        Color(UIColor.adaptive(light: light, dark: dark))
    }
}

extension UIColor {
    /// Creates a UIColor that adapts to light/dark mode
    static func adaptive(light: String, dark: String) -> UIColor {
        UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return UIColor(hex: dark)
            case .light, .unspecified:
                return UIColor(hex: light)
            @unknown default:
                return UIColor(hex: light)
            }
        }
    }
    
    /// Convenience initializer for hex colors
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            alpha: Double(a) / 255
        )
    }
}

// MARK: - View Extensions for Easy Token Usage

extension View {
    /// Apply background using design tokens
    public func tokenBackground(_ color: Color = DesignTokens.BackgroundColors.primary) -> some View {
        self.background(color)
    }
    
    /// Apply surface styling with elevation
    public func tokenSurface(
        backgroundColor: Color = DesignTokens.SurfaceColors.elevated,
        cornerRadius: CGFloat = DesignTokens.BorderRadius.md,
        shadow: Shadow = DesignTokens.Shadows.sm
    ) -> some View {
        self
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .shadow(
                color: shadow.color,
                radius: shadow.radius,
                x: shadow.x,
                y: shadow.y
            )
    }
    
    /// Apply primary button styling
    public func tokenPrimaryButton(
        isPressed: Bool = false,
        isDisabled: Bool = false
    ) -> some View {
        self
            .frame(minHeight: DesignTokens.Accessibility.recommendedTapTarget)
            .background(
                isDisabled ? DesignTokens.TextColors.disabled :
                isPressed ? DesignTokens.BrandColors.primaryVariant : DesignTokens.BrandColors.primary
            )
            .foregroundColor(DesignTokens.TextColors.primary)
            .cornerRadius(DesignTokens.BorderRadius.md)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isDisabled ? 0.6 : 1.0)
            .animation(DesignTokens.Animation.fast, value: isPressed)
            .animation(DesignTokens.Animation.fast, value: isDisabled)
    }
    
    /// Apply secondary button styling
    public func tokenSecondaryButton(
        isPressed: Bool = false,
        isDisabled: Bool = false
    ) -> some View {
        self
            .frame(minHeight: DesignTokens.Accessibility.recommendedTapTarget)
            .background(
                isPressed ? DesignTokens.SurfaceColors.pressed : DesignTokens.SurfaceColors.elevated
            )
            .foregroundColor(
                isDisabled ? DesignTokens.TextColors.disabled : DesignTokens.TextColors.primary
            )
            .cornerRadius(DesignTokens.BorderRadius.md)
            .overlay(
                RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                    .stroke(DesignTokens.BorderColors.primary, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .opacity(isDisabled ? 0.6 : 1.0)
            .animation(DesignTokens.Animation.fast, value: isPressed)
            .animation(DesignTokens.Animation.fast, value: isDisabled)
    }
}