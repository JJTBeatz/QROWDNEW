import SwiftUI

// MARK: - QROWD Dark Nightclub Theme
struct QROWDTheme {
    
    // MARK: - Colors
    static let backgroundColor = Color(hex: "#0B0B0E")
    static let primaryText = Color.white
    static let secondaryText = Color(hex: "#CCCCCC")
    static let placeholderText = Color(hex: "#E0E0E0")
    static let accentColor = Color(hex: "#BE6CFF")
    static let borderColor = Color(hex: "#1A1A1A")
    static let cardBackground = Color(hex: "#1A1A1A")
    
    // MARK: - Gradients
    static let primaryGradient = LinearGradient(
        colors: [Color(hex: "#E35AFF"), Color(hex: "#A35CFE"), Color(hex: "#577CFF")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let buttonGradient = LinearGradient(
        colors: [Color(hex: "#E35AFF"), Color(hex: "#577CFF")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [Color(hex: "#1A1A1A").opacity(0.6), Color(hex: "#2A2A2A").opacity(0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // MARK: - Shadows & Glows
    static let cardShadow = Color(hex: "#BE6CFF").opacity(0.3)
    static let buttonGlow = Color(hex: "#E35AFF").opacity(0.6)
    
    // MARK: - Typography
    static let titleFont = Font.custom("SF Pro Display", size: 28).weight(.bold)
    static let headlineFont = Font.custom("SF Pro Display", size: 22).weight(.semibold)
    static let bodyFont = Font.custom("Inter", size: 16).weight(.medium)
    static let captionFont = Font.custom("Inter", size: 14).weight(.regular)
    
    // MARK: - Layout
    static let cornerRadius: CGFloat = 20
    static let buttonHeight: CGFloat = 56
    static let cardPadding: CGFloat = 20
    static let sectionSpacing: CGFloat = 24
}

// MARK: - Color Extension
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