//
//  SettingsView.swift
//  MSense
//
//  Created by AI Assistant on 2025-08-08.
//

import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var notificationService: NotificationService
    @State private var notificationsEnabled = true
    @State private var fatigueThreshold = 7.0
    @State private var dataCollectionConsent = true
    @State private var earlyNotificationsEnabled = false
    @State private var earlyNotificationTime = 30
    @State private var showingThresholdDialog = false
    @State private var isLoading = false
    
    private let earlyNotificationOptions = [15, 30, 60]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Notification Settings Section
                    settingsSection(title: "Notification Settings") {
                        VStack(spacing: 0) {
                            // Enable Notifications Toggle
                            SettingsRow(
                                icon: "bell.fill",
                                title: "Enable Notifications",
                                subtitle: notificationService.isAuthorized ? 
                                    "Receive alerts about your fatigue levels" : 
                                    "Tap to enable notifications in Settings"
                            ) {
                                if notificationService.isAuthorized {
                                    Toggle("", isOn: $notificationsEnabled)
                                        .tint(themeManager.primaryColor)
                                        .onChange(of: notificationsEnabled) { _, newValue in
                                            if !newValue {
                                                earlyNotificationsEnabled = false
                                            }
                                        }
                                } else {
                                    Button("Enable") {
                                        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                            UIApplication.shared.open(settingsUrl)
                                        }
                                    }
                                    .foregroundColor(themeManager.primaryColor)
                                }
                            }
                            
                            Divider()
                                .padding(.leading, 40)
                            
                            // Fatigue Threshold Setting
                            SettingsRow(
                                icon: "slider.horizontal.3",
                                title: "Fatigue Threshold",
                                subtitle: "Notify when fatigue level exceeds \(String(format: "%.1f", fatigueThreshold))"
                            ) {
                                Button(action: {
                                    showingThresholdDialog = true
                                }) {
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(themeManager.textColor.opacity(0.6))
                                }
                                .disabled(!notificationsEnabled)
                            }
                            
                            Divider()
                                .padding(.leading, 40)
                            
                            // Early Notifications Toggle
                            SettingsRow(
                                icon: "clock.badge",
                                title: "Early Notifications",
                                subtitle: "Get notified before reaching your threshold"
                            ) {
                                Toggle("", isOn: $earlyNotificationsEnabled)
                                    .tint(themeManager.primaryColor)
                                    .disabled(!notificationsEnabled || !notificationService.isAuthorized)
                            }
                            
                            // Early Notification Time Selection
                            if earlyNotificationsEnabled && notificationsEnabled && notificationService.isAuthorized {
                                VStack(spacing: 8) {
                                    Divider()
                                        .padding(.leading, 40)
                                    
                                    HStack {
                                        Text("Notify me before reaching threshold:")
                                            .font(.subheadline)
                                            .foregroundColor(themeManager.textColor)
                                        Spacer()
                                    }
                                    .padding(.horizontal)
                                    .padding(.top, 8)
                                    
                                    HStack(spacing: 12) {
                                        ForEach(earlyNotificationOptions, id: \.self) { option in
                                            Button(action: {
                                                earlyNotificationTime = option
                                            }) {
                                                Text("\(option) min")
                                                    .font(.subheadline)
                                                    .fontWeight(earlyNotificationTime == option ? .bold : .medium)
                                                    .foregroundColor(earlyNotificationTime == option ? .white : themeManager.textColor)
                                                    .padding(.horizontal, 16)
                                                    .padding(.vertical, 8)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .fill(earlyNotificationTime == option ? themeManager.primaryColor : Color.clear)
                                                            .overlay(
                                                                RoundedRectangle(cornerRadius: 16)
                                                                    .stroke(themeManager.primaryColor, lineWidth: 1)
                                                            )
                                                    )
                                            }
                                        }
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                                }
                            }
                        }
                    }
                    
                    // App Settings Section
                    settingsSection(title: "App Settings") {
                        VStack(spacing: 0) {
                            // Dark Mode Toggle
                            SettingsRow(
                                icon: themeManager.isDarkMode ? "moon.fill" : "sun.max.fill",
                                title: "Dark Mode",
                                subtitle: "Enable dark theme for the app"
                            ) {
                                Toggle("", isOn: Binding(
                                    get: { themeManager.isDarkMode },
                                    set: { _ in themeManager.toggleTheme() }
                                ))
                                .tint(themeManager.primaryColor)
                            }
                            
                            Divider()
                                .padding(.leading, 40)
                            
                            // Data Collection Consent
                            SettingsRow(
                                icon: "chart.bar.fill",
                                title: "Data Collection Consent",
                                subtitle: "Allow anonymous usage data collection to improve the app"
                            ) {
                                Toggle("", isOn: $dataCollectionConsent)
                                    .tint(themeManager.primaryColor)
                            }
                        }
                    }
                    
                    // Save Button
                    Button(action: saveSettings) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Save Settings")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(themeManager.primaryColor)
                    .cornerRadius(12)
                    .disabled(isLoading)
                    .padding(.horizontal)
                    
                    // Reset Button
                    Button("Reset to Defaults") {
                        resetToDefaults()
                    }
                    .foregroundColor(themeManager.primaryColor)
                    .padding(.bottom)
                    
                    // Version Info
                    Text("MSense v1.0.0")
                        .font(.caption)
                        .foregroundColor(themeManager.textColor.opacity(0.6))
                        .padding(.bottom)
                }
            }
            .navigationTitle("Settings")
            .background(themeManager.backgroundColor)
            .onAppear {
                loadSettings()
                notificationService.checkAuthorizationStatus()
            }
            .alert("Set Fatigue Threshold", isPresented: $showingThresholdDialog) {
                // iOS 15+ Alert with TextField
                Button("Cancel") { }
                Button("Save") {
                    // The threshold is already bound to the slider in the alert content
                }
            } message: {
                VStack {
                    Text("You will be notified when your fatigue level exceeds this value (0-10):")
                    
                    Slider(value: $fatigueThreshold, in: 0...10, step: 0.5)
                    
                    Text(String(format: "%.1f", fatigueThreshold))
                        .font(.title2)
                        .fontWeight(.bold)
                }
            }
        }
    }
    
    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(themeManager.textColor)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                content()
            }
            .background(themeManager.cardColor)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            .padding(.horizontal)
        }
    }
    
    private func loadSettings() {
        let defaults = UserDefaults.standard
        notificationsEnabled = defaults.bool(forKey: "notifications_enabled")
        fatigueThreshold = defaults.double(forKey: "fatigue_threshold")
        dataCollectionConsent = defaults.bool(forKey: "data_collection_consent")
        earlyNotificationsEnabled = defaults.bool(forKey: "early_notifications_enabled")
        earlyNotificationTime = defaults.integer(forKey: "early_notification_time")
        
        // Set defaults if not previously saved
        if !defaults.bool(forKey: "settings_initialized") {
            notificationsEnabled = true
            fatigueThreshold = 7.0
            dataCollectionConsent = true
            earlyNotificationsEnabled = false
            earlyNotificationTime = 30
            defaults.set(true, forKey: "settings_initialized")
        }
    }
    
    private func saveSettings() {
        isLoading = true
        
        // Simulate save delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let defaults = UserDefaults.standard
            defaults.set(notificationsEnabled, forKey: "notifications_enabled")
            defaults.set(fatigueThreshold, forKey: "fatigue_threshold")
            defaults.set(dataCollectionConsent, forKey: "data_collection_consent")
            defaults.set(earlyNotificationsEnabled, forKey: "early_notifications_enabled")
            defaults.set(earlyNotificationTime, forKey: "early_notification_time")
            
            isLoading = false
            
            // Show success feedback (you could add a toast notification here)
            print("Settings saved successfully")
        }
    }
    
    private func resetToDefaults() {
        notificationsEnabled = true
        fatigueThreshold = 7.0
        dataCollectionConsent = true
        earlyNotificationsEnabled = false
        earlyNotificationTime = 30
        
        // Reset theme to light mode
        if themeManager.isDarkMode {
            themeManager.toggleTheme()
        }
    }
}

struct SettingsRow<Accessory: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    @ViewBuilder let accessory: () -> Accessory
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(themeManager.primaryColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(themeManager.textColor)
                
                Text(subtitle)
                    .font(.system(size: 14))
                    .foregroundColor(themeManager.textColor.opacity(0.7))
            }
            
            Spacer()
            
            accessory()
        }
        .padding()
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
