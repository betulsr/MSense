//
//  ThemeManager.swift
//  MSense
//
//  Created by AI Assistant on 2025-08-08.
//

import SwiftUI
import Foundation

class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool = false
    
    // MSense Color Palette - Based on soft lavender (#d1c8e4)
    struct Colors {
        // Light Theme Colors
        static let deepPurple = Color(red: 0.494, green: 0.435, blue: 0.608) // #7E6F9B
        static let paleLavender = Color(red: 0.910, green: 0.890, blue: 0.953) // #E8E3F3
        static let textDark = Color(red: 0.176, green: 0.149, blue: 0.251) // #2D2640
        static let accentPurple = Color(red: 0.608, green: 0.545, blue: 0.710) // #9B8BB5
        
        // Dark Theme Colors
        static let darkPurple = Color(red: 0.608, green: 0.545, blue: 0.710) // #9B8BB5
        static let darkPaleLavender = Color(red: 0.165, green: 0.165, blue: 0.165) // #2A2A2A
        static let textLight = Color(red: 0.878, green: 0.878, blue: 0.878) // #E0E0E0
        static let darkBaseColor = Color(red: 0.071, green: 0.071, blue: 0.071) // #121212
    }
    
    var primaryColor: Color {
        isDarkMode ? Colors.darkPurple : Colors.deepPurple
    }
    
    var secondaryColor: Color {
        Colors.accentPurple
    }
    
    var backgroundColor: Color {
        isDarkMode ? Colors.darkBaseColor : .white
    }
    
    var surfaceColor: Color {
        isDarkMode ? Colors.darkPaleLavender : Colors.paleLavender
    }
    
    var textColor: Color {
        isDarkMode ? Colors.textLight : Colors.textDark
    }
    
    var cardColor: Color {
        isDarkMode ? Color(red: 0.184, green: 0.184, blue: 0.184) : .white
    }
    
    func toggleTheme() {
        isDarkMode.toggle()
        saveThemePreference()
    }
    
    func loadThemePreference() {
        isDarkMode = UserDefaults.standard.bool(forKey: "dark_mode_enabled")
    }
    
    private func saveThemePreference() {
        UserDefaults.standard.set(isDarkMode, forKey: "dark_mode_enabled")
    }
}

// MARK: - Environment Key for Theme
struct ThemeEnvironmentKey: EnvironmentKey {
    static let defaultValue = ThemeManager()
}

extension EnvironmentValues {
    var theme: ThemeManager {
        get { self[ThemeEnvironmentKey.self] }
        set { self[ThemeEnvironmentKey.self] = newValue }
    }
}
