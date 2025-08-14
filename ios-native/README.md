# MSense iOS Native App

Native iOS application built with SwiftUI for optimal performance and platform integration.

## 🚀 Getting Started

### Prerequisites
- Xcode 14.0+
- iOS 15.0+ (iOS 16.0+ recommended for Charts)
- macOS for development

### Installation
1. Open `MSense.xcodeproj` in Xcode
2. Select your target device/simulator
3. Build and run (⌘R)

## 📱 Features

- **Native iOS Performance** with SwiftUI
- **Native Charts** using iOS 16+ Charts framework
- **Haptic Feedback** for enhanced user experience
- **iOS Notifications** with proper permission handling
- **UserDefaults Integration** for data persistence
- **Dark Mode Support** with automatic switching

## 🏗️ Architecture

```
MSense/
├── MSenseApp.swift          # App entry point
├── ContentView.swift        # Main content wrapper
├── Models/
│   └── FatigueDataPoint.swift # Data models
├── Services/
│   ├── PredictionService.swift  # API communication
│   ├── ThemeManager.swift       # Theme management
│   └── NotificationService.swift # Push notifications
└── Views/
    ├── MainTabView.swift        # Tab navigation
    ├── HomeView.swift           # Dashboard
    ├── DeviceView.swift         # Device control
    ├── SettingsView.swift       # Preferences
    └── FatigueForecastView.swift # Chart visualization
```

## 🎨 Design System

- **SwiftUI Native Components** for iOS feel
- **Material Design Inspired** color scheme
- **SF Symbols** for consistent iconography
- **Native Animations** with SwiftUI transitions
- **Adaptive Typography** with Dynamic Type support

## 🔧 Configuration

### API Endpoint
Update the base URL in `Services/PredictionService.swift`:
```swift
private let baseURL = "http://localhost:5001"
```

### Bundle Identifier
Update in Xcode project settings:
- Target → General → Bundle Identifier
- Currently: `com.msense.app`

## 📊 Charts Implementation

The app uses two chart implementations:

### iOS 16+ (Native Charts Framework)
```swift
import Charts

Chart {
    ForEach(dataPoints) { point in
        LineMark(x: .value("Time", point.time), 
                y: .value("Fatigue", point.value))
    }
}
```

### iOS 15 Fallback (Custom SwiftUI)
Custom implementation using `Path` and `GeometryReader` for compatibility.

## 🔔 Notifications

### Setup
1. Enable Push Notifications capability in Xcode
2. Configure notification permissions in `NotificationService.swift`
3. Test with device (notifications don't work in simulator)

### Types
- **Threshold Alerts**: When fatigue exceeds user-defined limit
- **Early Warnings**: Predictive notifications before reaching threshold

## 🧪 Testing

### Unit Tests
```bash
⌘U in Xcode
```

### UI Tests  
```bash
Select MSenseUITests scheme and run
```

## 📦 Dependencies

**Native iOS Only** - No external dependencies!
- SwiftUI (UI Framework)
- Charts (iOS 16+ visualization)
- UserNotifications (Push notifications)
- Foundation (Core functionality)

## 🚀 Deployment

### Development
1. Connect iPhone via USB
2. Select device in Xcode
3. Build and run (⌘R)

### App Store
1. Archive build (Product → Archive)
2. Distribute via App Store Connect
3. Follow Apple review guidelines

### TestFlight
1. Archive and upload to App Store Connect
2. Add internal/external testers
3. Distribute beta builds

## ⚙️ Requirements

- **iOS 15.0+** (minimum supported version)
- **iOS 16.0+** (recommended for full Chart functionality)
- **iPhone/iPad** compatible
- **Network connection** for API communication

## 🎯 Performance

- **Native compilation** for optimal speed
- **Efficient memory usage** with ARC
- **Smooth 60fps animations** with SwiftUI
- **Background processing** for data updates
- **Minimal battery impact** with efficient polling
