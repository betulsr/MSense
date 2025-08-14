//
//  FatigueDataPoint.swift
//  MSense
//
//  Created by AI Assistant on 2025-08-08.
//

import Foundation

struct FatigueDataPoint: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let value: Double
    
    enum CodingKeys: String, CodingKey {
        case timestamp, value
    }
    
    init(timestamp: Date = Date(), value: Double) {
        self.timestamp = timestamp
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let timestampString = try container.decode(String.self, forKey: .timestamp)
        
        let formatter = ISO8601DateFormatter()
        self.timestamp = formatter.date(from: timestampString) ?? Date()
        self.value = try container.decode(Double.self, forKey: .value)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        let formatter = ISO8601DateFormatter()
        try container.encode(formatter.string(from: timestamp), forKey: .timestamp)
        try container.encode(value, forKey: .value)
    }
}

// MARK: - TimeRange for chart filtering
enum TimeRange: String, CaseIterable {
    case future = "Future"
    case lastHour = "Past 1h"
    case lastTwoHours = "Past 2h"
    case lastFiveHours = "Past 5h"
    case lastDay = "Past 24h"
    
    var duration: TimeInterval {
        switch self {
        case .future:
            return 0
        case .lastHour:
            return 3600
        case .lastTwoHours:
            return 7200
        case .lastFiveHours:
            return 18000
        case .lastDay:
            return 86400
        }
    }
}
