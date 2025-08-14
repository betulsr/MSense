//
//  FatigueForecastView.swift
//  MSense
//
//  Created by AI Assistant on 2025-08-08.
//

import SwiftUI

struct FatigueForecastView: View {
    let predictions: [Double]
    let isLoading: Bool
    let nextMinutes: [Int]
    let historicalData: [FatigueDataPoint]
    @Binding var selectedTimeRange: TimeRange
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Time Range Selector
            timeRangeSelector
            
            // Chart
            if isLoading {
                loadingView
            } else {
                chartView
            }
        }
        .padding()
        .background(themeManager.cardColor)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    @ViewBuilder
    private var timeRangeSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Range:")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(themeManager.textColor)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TimeRange.allCases, id: \.rawValue) { range in
                        Button(action: {
                            selectedTimeRange = range
                        }) {
                            Text(range.rawValue)
                                .font(.system(size: 14, weight: selectedTimeRange == range ? .bold : .medium))
                                .foregroundColor(selectedTimeRange == range ? .white : themeManager.textColor)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(selectedTimeRange == range ? themeManager.primaryColor : Color.clear)
                                )
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
    
    @ViewBuilder
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: themeManager.primaryColor))
                .scaleEffect(1.2)
            
            Text("Loading predictions...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(themeManager.textColor.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ViewBuilder
    private var chartView: some View {
        // Simple SwiftUI-based chart that works on all iOS versions
        simpleChartView
    }
    
    @ViewBuilder
    private var simpleChartView: some View {
        VStack(spacing: 12) {
            // Chart Title
            HStack {
                Text("Fatigue Level")
                    .font(.caption)
                    .foregroundColor(themeManager.textColor.opacity(0.7))
                Spacer()
                Text("Time")
                    .font(.caption)
                    .foregroundColor(themeManager.textColor.opacity(0.7))
            }
            
            // Simple line chart using SwiftUI
            GeometryReader { geometry in
                ZStack {
                    // Background grid
                    Path { path in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        
                        // Horizontal grid lines
                        for i in 0...10 {
                            let y = height - (CGFloat(i) * height / 10)
                            path.move(to: CGPoint(x: 0, y: y))
                            path.addLine(to: CGPoint(x: width, y: y))
                        }
                        
                        // Vertical grid lines
                        for i in 0...4 {
                            let x = CGFloat(i) * width / 4
                            path.move(to: CGPoint(x: x, y: 0))
                            path.addLine(to: CGPoint(x: x, y: height))
                        }
                    }
                    .stroke(themeManager.textColor.opacity(0.1), lineWidth: 0.5)
                    
                    // Data line
                    if selectedTimeRange == .future {
                        // Future predictions line
                        futureDataLine(geometry: geometry)
                    } else {
                        // Historical data line
                        historicalDataLine(geometry: geometry)
                    }
                }
            }
            .frame(height: 200)
            
            // X-axis labels
            HStack {
                if selectedTimeRange == .future {
                    ForEach(["Now", "+15m", "+30m", "+45m", "+60m"], id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .foregroundColor(themeManager.textColor.opacity(0.7))
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    // Show time labels for historical data
                    HStack {
                        Text(getHistoricalStartLabel())
                        Spacer()
                        Text("Now")
                    }
                    .font(.caption2)
                    .foregroundColor(themeManager.textColor.opacity(0.7))
                }
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var fallbackChartView: some View {
        VStack {
            Text("Chart view requires iOS 16+")
                .font(.headline)
                .foregroundColor(themeManager.textColor)
            
            if selectedTimeRange == .future && !predictions.isEmpty {
                VStack(spacing: 8) {
                    Text("Future Predictions:")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    
                    HStack {
                        ForEach(Array(zip(nextMinutes.prefix(predictions.count), predictions)), id: \.0) { minute, prediction in
                            VStack {
                                Text("+\(minute)m")
                                    .font(.caption)
                                Text(String(format: "%.1f", prediction))
                                    .font(.headline)
                                    .fontWeight(.bold)
                            }
                        }
                    }
                }
            } else {
                Text("Historical data: \(historicalData.count) points")
                    .font(.subheadline)
            }
        }
        .frame(height: 280)
        .frame(maxWidth: .infinity)
        .background(themeManager.surfaceColor.opacity(0.3))
        .cornerRadius(12)
    }
    
    // MARK: - Chart Drawing Methods
    
    @ViewBuilder
    private func futureDataLine(geometry: GeometryProxy) -> some View {
        let futureValues = ensureFivePredictions()
        let width = geometry.size.width
        let height = geometry.size.height
        
        Path { path in
            for (index, value) in futureValues.enumerated() {
                let x = CGFloat(index) * width / 4
                let y = height - (CGFloat(value) * height / 10)
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(themeManager.primaryColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
        
        // Data points
        ForEach(Array(futureValues.enumerated()), id: \.offset) { index, value in
            Circle()
                .fill(themeManager.secondaryColor)
                .frame(width: 8, height: 8)
                .position(
                    x: CGFloat(index) * width / 4,
                    y: height - (CGFloat(value) * height / 10)
                )
        }
    }
    
    @ViewBuilder
    private func historicalDataLine(geometry: GeometryProxy) -> some View {
        let filteredData = getFilteredHistoricalData()
        let width = geometry.size.width
        let height = geometry.size.height
        
        if !filteredData.isEmpty {
            Path { path in
                for (index, dataPoint) in filteredData.enumerated() {
                    let x = CGFloat(index) * width / CGFloat(max(1, filteredData.count - 1))
                    let y = height - (CGFloat(dataPoint.value) * height / 10)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(themeManager.primaryColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
            
            // Data points
            ForEach(Array(filteredData.enumerated()), id: \.element.id) { index, dataPoint in
                Circle()
                    .fill(themeManager.secondaryColor)
                    .frame(width: 6, height: 6)
                    .position(
                        x: CGFloat(index) * width / CGFloat(max(1, filteredData.count - 1)),
                        y: height - (CGFloat(dataPoint.value) * height / 10)
                    )
            }
        }
    }
    
    private func getHistoricalStartLabel() -> String {
        switch selectedTimeRange {
        case .lastHour:
            return "-1h"
        case .lastTwoHours:
            return "-2h"
        case .lastFiveHours:
            return "-5h"
        case .lastDay:
            return "-24h"
        default:
            return ""
        }
    }
    
    // MARK: - Helper Methods
    
    private func ensureFivePredictions() -> [Double] {
        var futureValues = Array(predictions.prefix(5))
        
        // Ensure we have exactly 5 values
        while futureValues.count < 5 {
            if let lastValue = futureValues.last {
                futureValues.append(lastValue)
            } else {
                futureValues.append(5.0) // Default value
            }
        }
        
        return futureValues
    }
    
    private func getFilteredHistoricalData() -> [FatigueDataPoint] {
        let cutoffTime = Date().addingTimeInterval(-selectedTimeRange.duration)
        let filtered = historicalData
            .filter { $0.timestamp > cutoffTime }
            .sorted { $0.timestamp < $1.timestamp } // Oldest first for chart
        
        return filtered
    }
    

}

#Preview {
    let samplePredictions = [5.0, 6.0, 7.0, 8.0]
    let sampleHistoricalData = (0..<24).map { index in
        FatigueDataPoint(
            timestamp: Date().addingTimeInterval(TimeInterval(-index * 3600)),
            value: 5.0 + Double(index % 5)
        )
    }
    
    return FatigueForecastView(
        predictions: samplePredictions,
        isLoading: false,
        nextMinutes: [15, 30, 45, 60],
        historicalData: sampleHistoricalData,
        selectedTimeRange: .constant(.lastHour)
    )
    .environmentObject(ThemeManager())
}

