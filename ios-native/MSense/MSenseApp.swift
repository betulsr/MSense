//
//  MSenseApp.swift
//  MSense
//
//  Created by AI Assistant on 2025-08-08.
//

import SwiftUI
import UIKit

@main
struct MSenseApp: App {
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var predictionService = PredictionService()
    @StateObject private var notificationService = NotificationService.shared
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(themeManager)
                .environmentObject(predictionService)
                .environmentObject(notificationService)
                .onAppear {
                    themeManager.loadThemePreference()
                    notificationService.requestPermission()
                    predictionService.startPolling()
                }
                .onDisappear {
                    predictionService.stopPolling()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    // Clear badge when app becomes active
                    notificationService.clearBadge()
                }
        }
    }
}
