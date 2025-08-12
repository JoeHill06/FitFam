//
//  DesignTokensUsageGuide.swift
//  FitFam
//
//  Complete usage guide and examples for the Design Token system
//  Copy-paste ready components and best practices
//

import SwiftUI

/*
 
 # FitFam Design Token System - Usage Guide
 
 ## Overview
 This design token system provides a centralized, scalable way to manage design decisions across the app.
 It supports Light/Dark mode, accessibility scaling, and is compatible with both SwiftUI and UIKit.
 
 ## Key Features
 - 🎨 **JSON-driven**: All tokens defined in DesignTokens.json for easy updates
 - 🌓 **Light/Dark Mode**: Automatic adaptation with semantic color naming
 - ♿ **Accessibility**: Font sizes scale with user preferences
 - 📱 **Cross-platform**: Works with both SwiftUI and UIKit
 - 🔧 **Type-safe**: Compile-time checking for all token usage
 - 📏 **Consistent**: Enforces design system rules across all components
 
 ## Token Categories
 
 ### Colors
 - `DesignTokens.BrandColors.*` - Primary brand colors
 - `DesignTokens.SemanticColors.*` - Status and feedback colors
 - `DesignTokens.BackgroundColors.*` - Background variants
 - `DesignTokens.SurfaceColors.*` - Elevated component backgrounds
 - `DesignTokens.TextColors.*` - Text color hierarchy
 - `DesignTokens.BorderColors.*` - Border and divider colors
 
 ### Typography
 - `DesignTokens.Typography.Styles.*` - Pre-configured font styles
 - `DesignTokens.Typography.FontSize.*` - Scalable font sizes
 - `DesignTokens.Typography.FontWeight.*` - Font weights
 
 ### Layout
 - `DesignTokens.Spacing.*` - Consistent spacing scale
 - `DesignTokens.BorderRadius.*` - Corner radius values
 - `DesignTokens.Accessibility.*` - Tap target sizes
 
 ### Motion
 - `DesignTokens.Animation.*` - Consistent animation timing
 - `DesignTokens.Shadows.*` - Elevation shadows
 
 ## Usage Examples
 
 */

// MARK: - Color Usage Examples

struct ColorExamplesView: View {
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            
            // Primary brand color usage
            Text("Primary Brand Color")
                .foregroundColor(DesignTokens.BrandColors.primary)
                .font(DesignTokens.Typography.Styles.headline)
            
            // Status colors for feedback
            HStack {
                Label("Success", systemImage: "checkmark.circle")
                    .foregroundColor(DesignTokens.SemanticColors.success)
                
                Label("Warning", systemImage: "exclamationmark.triangle")
                    .foregroundColor(DesignTokens.SemanticColors.warning)
                
                Label("Error", systemImage: "xmark.circle")
                    .foregroundColor(DesignTokens.SemanticColors.error)
            }
            
            // Text hierarchy
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.sm) {
                Text("Primary Text")
                    .foregroundColor(DesignTokens.TextColors.primary)
                    .font(DesignTokens.Typography.Styles.body)
                
                Text("Secondary Text")
                    .foregroundColor(DesignTokens.TextColors.secondary)
                    .font(DesignTokens.Typography.Styles.subheadline)
                
                Text("Tertiary Text")
                    .foregroundColor(DesignTokens.TextColors.tertiary)
                    .font(DesignTokens.Typography.Styles.caption1)
            }
        }
        .tokenBackground()
    }
}

// MARK: - Button Examples

/// Production-ready button components using design tokens
struct TokenButtonExamples: View {
    @State private var isPrimaryPressed = false
    @State private var isSecondaryPressed = false
    @State private var isDisabled = false
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            
            // Primary Button - Main actions
            Button("Primary Action") {
                // Action here
            }
            .tokenPrimaryButton(
                isPressed: isPrimaryPressed,
                isDisabled: isDisabled
            )
            .pressEvents(
                onPress: { isPrimaryPressed = true },
                onRelease: { isPrimaryPressed = false }
            )
            
            // Secondary Button - Secondary actions
            Button("Secondary Action") {
                // Action here
            }
            .tokenSecondaryButton(
                isPressed: isSecondaryPressed,
                isDisabled: isDisabled
            )
            .pressEvents(
                onPress: { isSecondaryPressed = true },
                onRelease: { isSecondaryPressed = false }
            )
            
            // Destructive Button Example
            Button("Delete Item") {
                // Destructive action
            }
            .tokenPrimaryButton(isDisabled: isDisabled)
            .background(DesignTokens.SemanticColors.error)
            
            // Toggle for testing disabled state
            Toggle("Disabled State", isOn: $isDisabled)
                .padding(.top, DesignTokens.Spacing.lg)
        }
        .padding(DesignTokens.Spacing.lg)
        .tokenBackground()
    }
}

// MARK: - Card/Surface Examples

struct TokenSurfaceExamples: View {
    var body: some View {
        ScrollView {
            VStack(spacing: DesignTokens.Spacing.lg) {
                
                // Basic elevated surface
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Basic Card")
                        .font(DesignTokens.Typography.Styles.headline)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    
                    Text("This is a basic elevated surface using design tokens.")
                        .font(DesignTokens.Typography.Styles.body)
                        .foregroundColor(DesignTokens.TextColors.secondary)
                }
                .padding(DesignTokens.Spacing.lg)
                .tokenSurface()
                
                // Highly elevated surface
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    Text("Elevated Card")
                        .font(DesignTokens.Typography.Styles.headline)
                        .foregroundColor(DesignTokens.TextColors.primary)
                    
                    Text("This card has more elevation with a larger shadow.")
                        .font(DesignTokens.Typography.Styles.body)
                        .foregroundColor(DesignTokens.TextColors.secondary)
                }
                .padding(DesignTokens.Spacing.lg)
                .tokenSurface(
                    backgroundColor: DesignTokens.SurfaceColors.elevated,
                    cornerRadius: DesignTokens.BorderRadius.xl,
                    shadow: DesignTokens.Shadows.lg
                )
                
                // Alert-style surface
                VStack(alignment: .leading, spacing: DesignTokens.Spacing.md) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(DesignTokens.SemanticColors.warning)
                        Text("Warning")
                            .font(DesignTokens.Typography.Styles.headline)
                            .foregroundColor(DesignTokens.TextColors.primary)
                    }
                    
                    Text("This is a warning message with semantic coloring.")
                        .font(DesignTokens.Typography.Styles.body)
                        .foregroundColor(DesignTokens.TextColors.secondary)
                }
                .padding(DesignTokens.Spacing.lg)
                .tokenSurface(
                    backgroundColor: DesignTokens.SemanticColors.warning.opacity(0.1),
                    cornerRadius: DesignTokens.BorderRadius.md,
                    shadow: DesignTokens.Shadows.sm
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                        .stroke(DesignTokens.SemanticColors.warning, lineWidth: 1)
                )
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .tokenBackground()
    }
}

// MARK: - Form Examples

struct TokenFormExamples: View {
    @State private var email = ""
    @State private var password = ""
    @State private var hasError = false
    
    var body: some View {
        VStack(spacing: DesignTokens.Spacing.lg) {
            
            // Email field with proper styling
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Email")
                    .font(DesignTokens.Typography.Styles.subheadline)
                    .foregroundColor(DesignTokens.TextColors.primary)
                
                TextField("Enter your email", text: $email)
                    .font(DesignTokens.Typography.Styles.body)
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.SurfaceColors.elevated)
                    .foregroundColor(DesignTokens.TextColors.primary)
                    .cornerRadius(DesignTokens.BorderRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                            .stroke(
                                hasError ? DesignTokens.SemanticColors.error : DesignTokens.BorderColors.primary,
                                lineWidth: 1
                            )
                    )
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                
                if hasError {
                    Text("Please enter a valid email address")
                        .font(DesignTokens.Typography.Styles.caption1)
                        .foregroundColor(DesignTokens.SemanticColors.error)
                }
            }
            
            // Password field
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.xs) {
                Text("Password")
                    .font(DesignTokens.Typography.Styles.subheadline)
                    .foregroundColor(DesignTokens.TextColors.primary)
                
                SecureField("Enter your password", text: $password)
                    .font(DesignTokens.Typography.Styles.body)
                    .padding(DesignTokens.Spacing.md)
                    .background(DesignTokens.SurfaceColors.elevated)
                    .foregroundColor(DesignTokens.TextColors.primary)
                    .cornerRadius(DesignTokens.BorderRadius.md)
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignTokens.BorderRadius.md)
                            .stroke(DesignTokens.BorderColors.primary, lineWidth: 1)
                    )
            }
            
            // Submit button
            Button("Sign In") {
                hasError = email.isEmpty
            }
            .tokenPrimaryButton(isDisabled: email.isEmpty && password.isEmpty)
            
            // Toggle for testing error state
            Toggle("Show Error State", isOn: $hasError)
                .padding(.top, DesignTokens.Spacing.lg)
        }
        .padding(DesignTokens.Spacing.lg)
        .tokenBackground()
    }
}

// MARK: - Typography Scale Example

struct TypographyScaleView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DesignTokens.Spacing.lg) {
                
                Group {
                    Text("Large Title")
                        .font(DesignTokens.Typography.Styles.largeTitle)
                    
                    Text("Title 1")
                        .font(DesignTokens.Typography.Styles.title1)
                    
                    Text("Title 2")
                        .font(DesignTokens.Typography.Styles.title2)
                    
                    Text("Title 3")
                        .font(DesignTokens.Typography.Styles.title3)
                    
                    Text("Headline")
                        .font(DesignTokens.Typography.Styles.headline)
                }
                .foregroundColor(DesignTokens.TextColors.primary)
                
                Group {
                    Text("Body - Regular weight for main content")
                        .font(DesignTokens.Typography.Styles.body)
                    
                    Text("Body Medium - For emphasized content")
                        .font(DesignTokens.Typography.Styles.bodyMedium)
                    
                    Text("Callout - For secondary information")
                        .font(DesignTokens.Typography.Styles.callout)
                    
                    Text("Subheadline - For labels and metadata")
                        .font(DesignTokens.Typography.Styles.subheadline)
                    
                    Text("Footnote - For disclaimers")
                        .font(DesignTokens.Typography.Styles.footnote)
                    
                    Text("Caption - For fine print")
                        .font(DesignTokens.Typography.Styles.caption1)
                }
                .foregroundColor(DesignTokens.TextColors.secondary)
            }
            .padding(DesignTokens.Spacing.lg)
        }
        .tokenBackground()
    }
}

// MARK: - Press Events Helper (for button interactions)
// Note: PressEventModifier is defined in EnhancedButton.swift to avoid redeclaration

/*
 
 ## Best Practices
 
 ### 1. Naming Conventions
 - Use semantic names: `DesignTokens.SemanticColors.success` not `DesignTokens.Colors.green`
 - Follow hierarchy: `DesignTokens.TextColors.primary` → `secondary` → `tertiary`
 - Be descriptive: `DesignTokens.Spacing.xl` not `DesignTokens.Spacing.big`
 
 ### 2. Color Usage
 ```swift
 // ✅ Good - Semantic usage
 .foregroundColor(DesignTokens.SemanticColors.error)
 
 // ❌ Avoid - Direct color values
 .foregroundColor(.red)
 ```
 
 ### 3. Typography
 ```swift
 // ✅ Good - Use predefined styles
 .font(DesignTokens.Typography.Styles.headline)
 
 // ❌ Avoid - Custom font definitions
 .font(.system(size: 18, weight: .semibold))
 ```
 
 ### 4. Spacing
 ```swift
 // ✅ Good - Use token spacing
 .padding(DesignTokens.Spacing.lg)
 
 // ❌ Avoid - Magic numbers
 .padding(24)
 ```
 
 ### 5. Accessibility
 ```swift
 // ✅ Good - Use accessibility tokens
 .frame(minHeight: DesignTokens.Accessibility.recommendedTapTarget)
 
 // ❌ Avoid - Fixed sizes
 .frame(height: 44)
 ```
 
 ## Updating Tokens
 
 1. **Modify DesignTokens.json** - All changes start here
 2. **Figma Sync** - Keep design file in sync with JSON values
 3. **Test across modes** - Verify light/dark mode appearance
 4. **Accessibility check** - Test with larger text sizes
 5. **Update documentation** - Keep this guide current
 
 ## Integration with Figma
 
 ### Export from Figma
 1. Use Figma tokens plugin to export design tokens
 2. Transform to DesignTokens.json format
 3. Import into project and test
 
 ### Figma Variable Naming
 ```
 Brand/Primary/Light    → colors.brand.primary.light
 Text/Primary/Dark      → colors.neutral.text.primary.dark
 Spacing/Large          → spacing.values.lg
 Corner/Medium          → borderRadius.md
 ```
 
 ## Performance Notes
 
 - Tokens are loaded once at app startup
 - Color adaptation happens at render time
 - Font scaling respects system accessibility settings
 - JSON parsing is cached for optimal performance
 
 */