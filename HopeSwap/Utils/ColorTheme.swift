import SwiftUI

extension Color {
    // Hex initializer
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
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // Hyundai Hope on Wheels Brand Colors - Bright & Optimistic Palette
    
    // Primary Colors
    static let hopeOrange = Color(hex: "FF6B35")       // Warm Orange - Hope & Optimism
    static let hopeBlue = Color(hex: "4285F4")         // Bright Blue - Trust & Stability
    static let hopeGreen = Color(hex: "34C759")        // Leaf Green - Recovery & Growth
    static let hopePink = Color(hex: "FF375F")         // Heart Pink - Love & Care
    
    // Secondary Colors
    static let hopePurple = Color(hex: "9B59B6")       // Purple - Children & Imagination
    static let hopeYellow = Color(hex: "FFCC00")       // Sunny Yellow - Joy & Energy
    static let hopeTeal = Color(hex: "00BFA5")         // Teal - Medical & Healing
    
    // Accent Colors (for dark mode)
    static let hopeAccentOrange = Color(hex: "FF8A65") // Lighter orange for dark backgrounds
    static let hopeAccentBlue = Color(hex: "64B5F6")   // Lighter blue for dark backgrounds
    static let hopeAccentGreen = Color(hex: "66BB6A")  // Lighter green for dark backgrounds
    
    // Dark Mode Background Colors
    static let hopeDarkBg = Color(hex: "0A1929")       // Main dark background
    static let hopeDarkSecondary = Color(hex: "1C2B3B") // Secondary dark background
    static let hopeDarkTertiary = Color(hex: "243447")  // Tertiary dark background
    
    // Text Colors
    static let hopeTextPrimary = Color.white
    static let hopeTextSecondary = Color(hex: "B8BCC8")
    
    // Semantic Colors
    static let hopeSuccess = Color(hex: "34C759")      // Success/Complete
    static let hopeWarning = Color(hex: "FFCC00")      // Warning/Attention
    static let hopeError = Color(hex: "FF375F")        // Error/Alert
}