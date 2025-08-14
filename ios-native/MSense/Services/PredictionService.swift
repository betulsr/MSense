//
//  PredictionService.swift
//  MSense
//
//  Created by AI Assistant on 2025-08-08.
//

import Foundation
import Combine

class PredictionService: ObservableObject {
    @Published var predictions: [Double] = []
    @Published var nextMinutes: [Int] = [15, 30, 45, 60]
    @Published var historicalData: [FatigueDataPoint] = []
    @Published var isConnected: Bool = false
    @Published var isLoading: Bool = true
    
    private let baseURL = "http://localhost:5001" // Local prediction service
    private var pollingTimer: Timer?
    private let session = URLSession.shared
    
    init() {
        loadHistoricalData()
    }
    
    deinit {
        stopPolling()
    }
    
    // MARK: - Public Methods
    
    func startPolling() {
        isConnected = false
        getCurrentPredictions()
        
        // Poll every 15 minutes (900 seconds) to match server update interval
        pollingTimer = Timer.scheduledTimer(withTimeInterval: 900, repeats: true) { [weak self] _ in
            self?.getCurrentPredictions()
        }
    }
    
    func stopPolling() {
        pollingTimer?.invalidate()
        pollingTimer = nil
        isConnected = false
    }
    
    func getCurrentPredictions() {
        guard let url = URL(string: "\(baseURL)/current-predictions") else {
            print("Invalid URL")
            isConnected = false
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 10
        
        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.handlePredictionResponse(data: data, response: response, error: error)
            }
        }.resume()
    }
    
    func getHistoricalData(timeRange: TimeRange) -> [FatigueDataPoint] {
        if timeRange == .future {
            return historicalData
        }
        
        let cutoffTime = Date().addingTimeInterval(-timeRange.duration)
        return historicalData.filter { $0.timestamp > cutoffTime }
    }
    
    // MARK: - Private Methods
    
    private func handlePredictionResponse(data: Data?, response: URLResponse?, error: Error?) {
        isLoading = false
        
        if let error = error {
            print("Error fetching predictions: \(error)")
            isConnected = false
            return
        }
        
        guard let data = data else {
            print("No data received")
            isConnected = false
            return
        }
        
        do {
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            guard let status = json?["status"] as? String,
                  status == "success",
                  let predictionsArray = json?["predictions"] as? [Any] else {
                print("Invalid response format")
                isConnected = false
                return
            }
            
            // Convert predictions to doubles
            let newPredictions = predictionsArray.compactMap { prediction -> Double? in
                if let doubleValue = prediction as? Double {
                    return doubleValue
                } else if let intValue = prediction as? Int {
                    return Double(intValue)
                }
                return nil
            }
            
            let newNextMinutes = json?["next_minutes"] as? [Int] ?? [15, 30, 45, 60]
            
            self.predictions = newPredictions
            self.nextMinutes = newNextMinutes
            self.isConnected = true
            
            // Store current fatigue level in historical data (only if this is new data)
            if let currentFatigue = newPredictions.first {
                // Only add if this is different from the last data point (avoid duplicates on refresh)
                if historicalData.isEmpty || abs(historicalData.first!.value - currentFatigue) > 0.1 {
                    addHistoricalDataPoint(value: currentFatigue)
                }
            }
            
            // Check for notification triggers
            NotificationService.shared.checkForNotificationTriggers(
                predictions: newPredictions,
                nextMinutes: newNextMinutes
            )
            
            print("Received predictions: \(newPredictions) for minutes: \(newNextMinutes)")
            
        } catch {
            print("Error parsing JSON: \(error)")
            isConnected = false
        }
    }
    
    private func addHistoricalDataPoint(value: Double) {
        let dataPoint = FatigueDataPoint(timestamp: Date(), value: value)
        
        // Insert at beginning (newest first)
        historicalData.insert(dataPoint, at: 0)
        
        // Limit to 96 data points (24 hours at 15-minute intervals)
        if historicalData.count > 96 {
            historicalData = Array(historicalData.prefix(96))
        }
        
        saveHistoricalData()
        
        print("Added historical data point: \(value) at \(dataPoint.timestamp)")
    }
    
    private func loadHistoricalData() {
        guard let data = UserDefaults.standard.data(forKey: "historical_fatigue_data") else {
            print("No historical data found in UserDefaults")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            historicalData = try decoder.decode([FatigueDataPoint].self, from: data)
            
            // Sort by timestamp (newest first)
            historicalData.sort { $0.timestamp > $1.timestamp }
            
            print("Loaded \(historicalData.count) historical data points")
            
        } catch {
            print("Error loading historical data: \(error)")
        }
    }
    
    private func saveHistoricalData() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(historicalData)
            UserDefaults.standard.set(data, forKey: "historical_fatigue_data")
        } catch {
            print("Error saving historical data: \(error)")
        }
    }
}

// MARK: - Mock Implementation for Testing
extension PredictionService {
    func useMockData() {
        predictions = [5.0, 6.0, 7.0, 8.0]
        nextMinutes = [15, 30, 45, 60]
        isConnected = true
        isLoading = false
        
        // Generate mock historical data
        let now = Date()
        historicalData = (0..<24).map { index in
            FatigueDataPoint(
                timestamp: now.addingTimeInterval(TimeInterval(-index * 3600)), // Every hour for 24 hours
                value: 5.0 + Double(index % 5) // Values between 5-9
            )
        }
        
        saveHistoricalData()
    }
}
