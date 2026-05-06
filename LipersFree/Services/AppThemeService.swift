//
//  AppThemeService.swift
//  LipersFree
//

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6: (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default: (r, g, b) = (1, 1, 0)
        }
        self.init(red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255)
    }
}

enum AppThemeService {
    static let screenBackground = Color(hex: "141824")
    static let detailBackground = Color(hex: "0C0F1A")
    static let accent = Color(hex: "9B5CF6")
    static let accentLight = Color(hex: "C084FC")
    static let surface = Color.white.opacity(0.07)
    static let premiumGold = Color(hex: "F59E0B")
    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.55)
    static let destructive = Color(hex: "EF4444")
}
