//
//  NotificationService.swift
//  MSense
//
//  Created by AI Assistant on 2025-08-08.
//

import Foundation
import UserNotifications
import UIKit

class NotificationService: ObservableObject {
    static let shared = NotificationService()
    
    @Published var isAuthorized = false
    
    private init() {
        checkAuthorizationStatus()
    }
    
    // MARK: - Public Methods
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if let error = error {
                    print("Notification permission error: \(error)")
                }
            }
        }
    }
    
    func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func scheduleThresholdNotification(currentFatigue: Double, threshold: Double) {
        guard isAuthorized else { return }
        guard currentFatigue >= threshold else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "High Fatigue Alert"
        content.body = "Your current fatigue level (\(String(format: "%.1f", currentFatigue))) has exceeded your threshold (\(String(format: "%.1f", threshold)))."
        content.sound = .default
        content.badge = 1
        
        // Create identifier to prevent duplicate notifications
        let identifier = "fatigue-threshold-\(Int(Date().timeIntervalSince1970))"
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling threshold notification: \(error)")
            } else {
                print("Scheduled threshold notification for fatigue level: \(currentFatigue)")
            }
        }
    }
    
    func scheduleEarlyWarningNotification(predictedFatigue: Double, threshold: Double, minutesAhead: Int) {
        guard isAuthorized else { return }
        guard predictedFatigue >= threshold else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Fatigue Warning"
        content.body = "Your fatigue level is predicted to reach \(String(format: "%.1f", predictedFatigue)) in \(minutesAhead) minutes, which exceeds your threshold."
        content.sound = .default
        content.badge = 1
        
        // Create identifier to prevent duplicate notifications
        let identifier = "fatigue-warning-\(minutesAhead)min-\(Int(Date().timeIntervalSince1970))"
        
        // Trigger immediately
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling early warning notification: \(error)")
            } else {
                print("Scheduled early warning notification for predicted fatigue: \(predictedFatigue)")
            }
        }
    }
    
    func checkForNotificationTriggers(predictions: [Double], nextMinutes: [Int]) {
        let defaults = UserDefaults.standard
        
        guard defaults.bool(forKey: "notifications_enabled") else { return }
        
        let threshold = defaults.double(forKey: "fatigue_threshold")
        let earlyNotificationsEnabled = defaults.bool(forKey: "early_notifications_enabled")
        let earlyNotificationTime = defaults.integer(forKey: "early_notification_time")
        
        // Check current fatigue level
        if let currentFatigue = predictions.first {
            scheduleThresholdNotification(currentFatigue: currentFatigue, threshold: threshold)
        }
        
        // Check early warning notifications
        if earlyNotificationsEnabled {
            for (index, prediction) in predictions.enumerated() {
                if index < nextMinutes.count {
                    let minutesAhead = nextMinutes[index]
                    if minutesAhead == earlyNotificationTime {
                        scheduleEarlyWarningNotification(
                            predictedFatigue: prediction,
                            threshold: threshold,
                            minutesAhead: minutesAhead
                        )
                        break // Only schedule one early warning
                    }
                }
            }
        }
    }
    
    func clearAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        // Reset badge count
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
    
    func clearBadge() {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = 0
        }
    }
}
