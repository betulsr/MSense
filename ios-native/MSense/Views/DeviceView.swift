//
//  DeviceView.swift
//  MSense
//
//  Created by AI Assistant on 2025-08-08.
//

import SwiftUI

struct DeviceView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @State private var isDeviceRunning = false
    @State private var isLoading = false
    @State private var statusMessage = "Device is not running"
    @State private var deviceStartTime: Date?
    @State private var timer: Timer?
    
    private let deviceRunDuration: TimeInterval = 3 * 3600 // 3 hours
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Spacer()
                
                // Device Status Icon
                deviceStatusIcon
                
                // Status Message
                Text(statusMessage)
                    .font(.title3)
                    .fontWeight(.medium)
                    .foregroundColor(themeManager.textColor)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Control Button
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: themeManager.primaryColor))
                        .scaleEffect(1.2)
                } else {
                    Button(action: startDevice) {
                        HStack {
                            Image(systemName: "power")
                                .font(.title2)
                            Text(isDeviceRunning ? "Device Running" : "Start Device")
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(isDeviceRunning ? Color.gray : themeManager.primaryColor)
                        )
                    }
                    .disabled(isDeviceRunning)
                    .padding(.horizontal)
                }
                
                // Description Text
                Text(getDescriptionText())
                    .font(.subheadline)
                    .foregroundColor(themeManager.textColor.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
            }
            .navigationTitle("Device Control")
            .background(themeManager.backgroundColor)
            .onAppear {
                loadDeviceStatus()
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    @ViewBuilder
    private var deviceStatusIcon: some View {
        ZStack {
            Circle()
                .fill(themeManager.surfaceColor)
                .frame(width: 120, height: 120)
                .shadow(
                    color: isDeviceRunning ? .green.opacity(0.3) : .gray.opacity(0.2),
                    radius: 15,
                    x: 0,
                    y: 5
                )
            
            Image(systemName: isDeviceRunning ? "checkmark.circle.fill" : "applewatch")
                .font(.system(size: 70))
                .foregroundColor(isDeviceRunning ? .green : themeManager.primaryColor)
        }
    }
    
    private func loadDeviceStatus() {
        if let startTimeData = UserDefaults.standard.object(forKey: "device_start_time") as? Date {
            let now = Date()
            let difference = now.timeIntervalSince(startTimeData)
            
            // Device stays "on" for 3 hours
            if difference < deviceRunDuration {
                isDeviceRunning = true
                deviceStartTime = startTimeData
                updateStatusMessage()
                startDeviceTimer()
            } else {
                // Reset device status after 3 hours
                UserDefaults.standard.removeObject(forKey: "device_start_time")
                resetDeviceStatus()
            }
        }
    }
    
    private func startDevice() {
        isLoading = true
        statusMessage = "Starting device..."
        
        // Call the real AWS Lambda endpoint
        guard let url = URL(string: "https://hwqdmdeo755wruijpc4kk6ap2u0xaqrq.lambda-url.us-east-2.on.aws/") else {
            statusMessage = "Invalid endpoint URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    statusMessage = "Error starting device: \(error.localizedDescription)"
                    isLoading = false
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        // Success - device started
                        let startTime = Date()
                        UserDefaults.standard.set(startTime, forKey: "device_start_time")
                        
                        isDeviceRunning = true
                        deviceStartTime = startTime
                        isLoading = false
                        statusMessage = "Device started successfully!"
                        
                        // Add haptic feedback for success
                        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                        impactFeedback.impactOccurred()
                        
                        startDeviceTimer()
                    } else {
                        statusMessage = "Device start failed: HTTP \(httpResponse.statusCode)"
                        isLoading = false
                    }
                } else {
                    statusMessage = "Device start failed: Invalid response"
                    isLoading = false
                }
            }
        }.resume()
    }
    
    private func startDeviceTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { _ in
            updateStatusMessage()
            
            if let startTime = deviceStartTime {
                let now = Date()
                let difference = now.timeIntervalSince(startTime)
                
                if difference >= deviceRunDuration {
                    resetDeviceStatus()
                    timer?.invalidate()
                    UserDefaults.standard.removeObject(forKey: "device_start_time")
                }
            }
        }
    }
    
    private func updateStatusMessage() {
        guard let startTime = deviceStartTime else { return }
        
        let now = Date()
        let elapsed = now.timeIntervalSince(startTime)
        let remaining = deviceRunDuration - elapsed
        
        if remaining > 0 {
            let hours = Int(remaining / 3600)
            let minutes = Int((remaining.truncatingRemainder(dividingBy: 3600)) / 60)
            statusMessage = "Device is running\nRemaining time: \(hours)h \(minutes)m"
        } else {
            resetDeviceStatus()
        }
    }
    
    private func resetDeviceStatus() {
        isDeviceRunning = false
        deviceStartTime = nil
        statusMessage = "Device is not running"
        timer?.invalidate()
    }
    
    private func getDescriptionText() -> String {
        if isLoading {
            return "Connecting to your wearable device...\nThis may take a few moments."
        } else if isDeviceRunning {
            return "Device is actively collecting data from your wearable sensors.\nData will be processed for fatigue predictions."
        } else {
            return "Starting the device will begin data collection\nfrom your wearable sensors."
        }
    }
}

#Preview {
    DeviceView()
        .environmentObject(ThemeManager())
}
