# MSense Flutter App

Cross-platform Flutter application for fatigue prediction and monitoring.

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK
- iOS Simulator / Android Emulator

### Installation
```bash
flutter pub get
flutter run
```

## 📱 Features

- **Real-time fatigue monitoring** with beautiful charts
- **Cross-platform compatibility** (iOS, Android, Web)
- **Material Design 3** with custom purple theme
- **Dark/Light mode** with system preference sync
- **Push notifications** for fatigue alerts
- **Historical data visualization** with multiple time ranges

## 🏗️ Architecture

```
lib/
├── main.dart                 # App entry point
├── screens/
│   ├── home_screen.dart     # Main dashboard
│   ├── device_screen.dart   # Sensor control
│   ├── settings_screen.dart # App preferences
│   └── main_navigation.dart # Tab navigation
├── services/
│   ├── prediction_service.dart # API communication
│   └── mock_prediction_service.dart # Testing
├── widgets/
│   └── fatigue_forecast_widget.dart # Chart component
└── theme/
    └── app_theme.dart       # Theme configuration
```

## 🎨 Design System

- **Primary Color**: Deep Purple (#7E6F9B)
- **Accent Color**: Pale Lavender (#E8E3F3)  
- **Typography**: Material Design 3
- **Charts**: FL Chart with custom styling
- **Animations**: Smooth transitions and micro-interactions

## 🔧 Configuration

### API Endpoint
Update the base URL in `lib/services/prediction_service.dart`:
```dart
static const String baseUrl = 'http://your-api-endpoint:5000';
```

### Notifications
Configure push notifications in:
- `android/app/src/main/AndroidManifest.xml`
- `ios/Runner/Info.plist`

## 🧪 Testing

```bash
# Unit tests
flutter test

# Integration tests  
flutter test integration_test/
```

## 📦 Dependencies

- **http**: API communication
- **fl_chart**: Data visualization
- **shared_preferences**: Local storage
- **provider**: State management
- **google_fonts**: Typography

## 🚀 Deployment

### Android
```bash
flutter build apk --release
```

### iOS
```bash
flutter build ios --release
```

### Web
```bash
flutter build web
```
