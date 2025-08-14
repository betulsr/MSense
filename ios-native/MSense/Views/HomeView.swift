//
//  HomeView.swift
//  MSense
//
//  Created by AI Assistant on 2025-08-08.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var predictionService: PredictionService
    @State private var selectedTimeRange: TimeRange = .lastHour
    @State private var isRefreshing = false
    @State private var lastRefreshTime: Date?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Fatigue Level Card
                    if let currentFatigue = predictionService.predictions.first {
                        currentFatigueCard(fatigue: currentFatigue)
                    }
                    
                    // Fatigue Trends Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Fatigue Trends")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(themeManager.textColor)
                            
                            Spacer()
                            
                            // Refresh button with loading indicator
                            Button(action: {
                                refreshPredictions()
                            }) {
                                HStack(spacing: 6) {
                                    if isRefreshing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.primaryColor))
                                            .scaleEffect(0.8)
                                    } else {
                                        Image(systemName: "arrow.clockwise")
                                            .foregroundColor(themeManager.primaryColor)
                                    }
                                    
                                    if let lastRefresh = lastRefreshTime {
                                        Text(timeAgoString(from: lastRefresh))
                                            .font(.caption2)
                                            .foregroundColor(themeManager.textColor.opacity(0.6))
                                    }
                                }
                            }
                            .disabled(isRefreshing)
                        }
                        
                        FatigueForecastView(
                            predictions: predictionService.predictions,
                            isLoading: predictionService.isLoading,
                            nextMinutes: predictionService.nextMinutes,
                            historicalData: predictionService.historicalData,
                            selectedTimeRange: $selectedTimeRange
                        )
                        .frame(height: 400)
                    }
                }
                .padding(.horizontal)
            }
            .navigationTitle("MSense")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Debug") {
                        printHistoricalData()
                    }
                    .foregroundColor(themeManager.primaryColor)
                }
            }
            .refreshable {
                await refreshPredictionsAsync()
            }
        }
        .background(themeManager.backgroundColor)
        .onAppear {
            // Try real service first, fallback to mock data after 10 seconds if no connection
            DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                if predictionService.predictions.isEmpty && !predictionService.isConnected {
                    predictionService.useMockData()
                }
            }
        }
    }
    
    @ViewBuilder
    private func currentFatigueCard(fatigue: Double) -> some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "clock")
                    .foregroundColor(themeManager.primaryColor)
                    .font(.system(size: 20))
                
                Text("Current Fatigue Level")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(themeManager.textColor)
                
                Spacer()
            }
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1f", fatigue))
                        .font(.system(size: 42, weight: .bold))
                        .foregroundColor(themeManager.textColor)
                    
                    Text("out of 9.0")
                        .font(.caption)
                        .foregroundColor(themeManager.textColor.opacity(0.7))
                }
                
                Spacer()
                
                // Fatigue Level Badge
                fatigueStatusBadge(for: fatigue)
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .scaleEffect(isRefreshing ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isRefreshing)
    }
    
    @ViewBuilder
    private func fatigueStatusBadge(for fatigue: Double) -> some View {
        let (color, text) = fatigueStatusInfo(for: fatigue)
        
        Text(text)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(color)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(color.opacity(themeManager.isDarkMode ? 0.2 : 0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(color.opacity(0.5), lineWidth: 1)
                    )
            )
    }
    
    private func fatigueStatusInfo(for fatigue: Double) -> (Color, String) {
        if fatigue < 3.0 {
            return (.green, "Low")
        } else if fatigue < 7.0 {
            return (.orange, "Moderate")
        } else {
            return (.red, "High")
        }
    }
    
    // MARK: - Refresh Functions
    
    private func refreshPredictions() {
        isRefreshing = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        predictionService.getCurrentPredictions()
        
        // Simulate minimum loading time for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isRefreshing = false
            lastRefreshTime = Date()
        }
    }
    
    private func refreshPredictionsAsync() async {
        isRefreshing = true
        
        // Add haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        predictionService.getCurrentPredictions()
        
        // Wait minimum time for better UX
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        isRefreshing = false
        lastRefreshTime = Date()
    }
    
    private func timeAgoString(from date: Date) -> String {
        let seconds = Int(Date().timeIntervalSince(date))
        
        if seconds < 60 {
            return "now"
        } else if seconds < 3600 {
            let minutes = seconds / 60
            return "\(minutes)m ago"
        } else {
            let hours = seconds / 3600
            return "\(hours)h ago"
        }
    }
    
    private func printHistoricalData() {
        print("=== HISTORICAL DATA DEBUG ===")
        print("Total data points: \(predictionService.historicalData.count)")
        
        if predictionService.historicalData.isEmpty {
            print("No historical data available!")
        } else {
            let pointsToPrint = min(10, predictionService.historicalData.count)
            print("Most recent \(pointsToPrint) data points:")
            
            for (index, point) in predictionService.historicalData.prefix(pointsToPrint).enumerated() {
                print("[\(index)] \(point.timestamp) - Value: \(point.value)")
            }
        }
        print("===========================")
    }
}

#Preview {
    HomeView()
        .environmentObject(ThemeManager())
        .environmentObject(PredictionService())
}
