//
//  TokenLoader.swift
//  FitFam
//
//  JSON-based design token loading system
//  Loads tokens from DesignTokens.json and provides type-safe access
//

import Foundation
import SwiftUI
import UIKit

// MARK: - Token Data Models

struct TokenData: Codable {
    let colors: ColorTokenData
    let typography: TypographyTokenData
    let spacing: SpacingTokenData
    let borderRadius: [String: Double]
    let shadows: [String: ShadowTokenData]
    let animation: AnimationTokenData
    let accessibility: AccessibilityTokenData
    let breakpoints: [String: Double]
}

struct ColorTokenData: Codable {
    let brand: BrandColorData
    let semantic: SemanticColorData
    let neutral: NeutralColorData
}

struct BrandColorData: Codable {
    let primary: ColorVariant
    let primaryVariant: ColorVariant
    let secondary: ColorVariant
}

struct SemanticColorData: Codable {
    let success: ColorVariant
    let warning: ColorVariant
    let error: ColorVariant
    let info: ColorVariant
}

struct NeutralColorData: Codable {
    let background: BackgroundColorData
    let surface: SurfaceColorData
    let border: BorderColorData
    let text: TextColorData
}

struct BackgroundColorData: Codable {
    let primary: ColorVariant
    let secondary: ColorVariant
    let tertiary: ColorVariant
}

struct SurfaceColorData: Codable {
    let elevated: ColorVariant
    let pressed: ColorVariant
}

struct BorderColorData: Codable {
    let primary: ColorVariant
    let secondary: ColorVariant
}

struct TextColorData: Codable {
    let primary: ColorVariant
    let secondary: ColorVariant
    let tertiary: ColorVariant
    let disabled: ColorVariant
}

struct ColorVariant: Codable {
    let light: String
    let dark: String
}

struct TypographyTokenData: Codable {
    let fontFamilies: FontFamilyData
    let fontSizes: [String: Double]
    let fontWeights: [String: Int]
    let lineHeights: [String: Double]
}

struct FontFamilyData: Codable {
    let primary: String
    let secondary: String
    let monospace: String
}

struct SpacingTokenData: Codable {
    let scale: String
    let values: [String: Double]
}

struct ShadowTokenData: Codable {
    let x: Double
    let y: Double
    let blur: Double
    let spread: Double
    let color: String
}

struct AnimationTokenData: Codable {
    let duration: [String: Double]
    let easing: [String: [Double]]
}

struct AccessibilityTokenData: Codable {
    let minimumTapTarget: Double
    let recommendedTapTarget: Double
    let largeTapTarget: Double
}

// MARK: - Token Loader

class TokenLoader {
    static let shared = TokenLoader()
    private var tokenData: TokenData?
    
    private init() {
        loadTokens()
    }
    
    private func loadTokens() {
        guard let url = Bundle.main.url(forResource: "DesignTokens", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let tokens = try? JSONDecoder().decode(TokenData.self, from: data) else {
            fatalError("Failed to load DesignTokens.json. Ensure the file exists in the bundle.")
        }
        
        self.tokenData = tokens
        print("✅ Design tokens loaded successfully")
    }
    
    func getTokens() -> TokenData {
        guard let tokens = tokenData else {
            fatalError("Design tokens not loaded")
        }
        return tokens
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    init(hex: String) {
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
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// Note: UIColor(hex:) extension is now defined in DesignTokens.swift