//
//  MainTabView.swift
//  MSense
//
//  Created by AI Assistant on 2025-08-08.
//

import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
            
            DeviceView()
                .tabItem {
                    Image(systemName: "applewatch")
                    Text("Device")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(themeManager.primaryColor)
        .preferredColorScheme(themeManager.isDarkMode ? .dark : .light)
    }
}
