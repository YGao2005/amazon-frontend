//
//  RainforestTheme.swift
//  replate
//
//  Created by Yang Gao on 7/26/25.
//

import SwiftUI

// MARK: - Rainforest Theme Colors
extension Color {
    static let rainforest = RainforestColors()
}

struct RainforestColors {
    // Light Theme Colors
    let primaryBackground = Color(hex: "F7F7F2")      // Soft, warm off-white
    let primaryGreen = Color(hex: "2D572C")           // Deep forest green
    let secondaryGreen = Color(hex: "88A17D")         // Sage/moss green
    let primaryText = Color(hex: "333333")            // Dark charcoal
    let secondaryText = Color(hex: "6B7280")          // Muted grey
    let accent = Color(hex: "D4A373")                 // Warm earthy tan
    
    // Derived colors for UI elements
    let cardBackground = Color.white
    let borderColor = Color(hex: "6B7280").opacity(0.2)
    let shadowColor = Color.black.opacity(0.08)
}

// MARK: - Typography System
extension Font {
    static let rainforest = RainforestTypography()
}

struct RainforestTypography {
    // Headers
    let largeTitle = Font.custom("Poppins-Bold", size: 34)
    let title1 = Font.custom("Poppins-Bold", size: 28)
    let title2 = Font.custom("Poppins-Semibold", size: 22)
    let title3 = Font.custom("Poppins-Semibold", size: 20)
    
    // Body text
    let body = Font.custom("Poppins-Regular", size: 16)
    let bodyLarge = Font.custom("Poppins-Regular", size: 18)
    let bodyMedium = Font.custom("Poppins-Medium", size: 16)
    
    // Small text
    let caption = Font.custom("Poppins-Regular", size: 12)
    let footnote = Font.custom("Poppins-Regular", size: 13)
    
    // Buttons
    let buttonText = Font.custom("Poppins-Medium", size: 16)
    let buttonTextLarge = Font.custom("Poppins-Medium", size: 18)
}

// MARK: - Color Extension for Hex
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

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rainforest.buttonTextLarge)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.rainforest.primaryGreen)
                    .shadow(
                        color: Color.rainforest.shadowColor,
                        radius: 8,
                        x: 0,
                        y: 4
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rainforest.buttonText)
            .foregroundColor(Color.rainforest.primaryGreen)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.rainforest.secondaryGreen, lineWidth: 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.rainforest.primaryBackground)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CompactButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.rainforest.caption)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.rainforest.secondaryGreen)
                    .shadow(
                        color: Color.rainforest.shadowColor,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Card Style
struct RainforestCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.rainforest.cardBackground)
                    .shadow(
                        color: Color.rainforest.shadowColor,
                        radius: 12,
                        x: 0,
                        y: 4
                    )
            )
    }
}

// MARK: - Input Field Style
struct RainforestTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .font(.rainforest.body)
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.rainforest.primaryBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.rainforest.borderColor, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Tab Style
struct RainforestTabStyle: ViewModifier {
    let isSelected: Bool
    
    func body(content: Content) -> some View {
        content
            .font(.rainforest.bodyMedium)
            .foregroundColor(isSelected ? .white : Color.rainforest.primaryText)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? Color.rainforest.secondaryGreen : Color.rainforest.primaryBackground)
                    .shadow(
                        color: isSelected ? Color.rainforest.shadowColor : .clear,
                        radius: 4,
                        x: 0,
                        y: 2
                    )
            )
    }
}

// MARK: - View Extensions
extension View {
    func rainforestCard() -> some View {
        modifier(RainforestCardStyle())
    }
    
    func rainforestTab(isSelected: Bool) -> some View {
        modifier(RainforestTabStyle(isSelected: isSelected))
    }
    
    func primaryButtonStyle() -> some View {
        buttonStyle(PrimaryButtonStyle())
    }
    
    func secondaryButtonStyle() -> some View {
        buttonStyle(SecondaryButtonStyle())
    }
    
    func compactButtonStyle() -> some View {
        buttonStyle(CompactButtonStyle())
    }
    
    func rainforestTextField() -> some View {
        textFieldStyle(RainforestTextFieldStyle())
    }
}

// MARK: - Layout Constants
struct RainforestSpacing {
    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
}

// MARK: - Icon Style
struct RainforestIconStyle: ViewModifier {
    let size: CGFloat
    
    func body(content: Content) -> some View {
        content
            .font(.system(size: size, weight: .regular, design: .default))
            .foregroundColor(Color.rainforest.secondaryText)
    }
}

extension View {
    func rainforestIcon(size: CGFloat = 16) -> some View {
        modifier(RainforestIconStyle(size: size))
    }
} 