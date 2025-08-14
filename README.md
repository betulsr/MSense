# MSense - Fatigue Prediction for MS Patients

A comprehensive fatigue prediction system for Multiple Sclerosis patients, featuring Flutter cross-platform, native iOS, and ML backend implementations.

## 🏗️ Project Structure

- **[flutter-app/](./flutter-app/)** - Cross-platform Flutter application
- **[ios-native/](./ios-native/)** - Native iOS application built with SwiftUI  
- **[prediction-service/](./prediction-service/)** - Python backend with ML models and AWS integration

## 🚀 Quick Start

### Flutter App
```bash
cd flutter-app
flutter pub get
flutter run
```

### iOS Native App
1. Open `ios-native/MSense.xcodeproj` in Xcode
2. Build and run (⌘R)

### Prediction Service
```bash
cd prediction-service
pip3 install -r requirements.txt
cp .env.template .env
# Edit .env with your AWS credentials
python3 prediction_service.py
```

## 📱 Features

- **Real-time fatigue monitoring** (0-10 scale)
- **ML-powered predictions** (15, 30, 45, 60 minutes ahead)
- **Wearable device integration** via AWS Lambda
- **Historical data visualization** with interactive charts
- **Push notifications** for threshold alerts
- **Dark/Light theme support**

## 🎯 Platform Comparison

| Feature | Flutter App | iOS Native |
|---------|-------------|------------|
| **Platform Support** | iOS, Android, Web | iOS Only |
| **Performance** | Good | Excellent |
| **Native Feel** | Good | Perfect |
| **Development Speed** | Fast | Medium |
| **Code Sharing** | High | None |
| **Platform APIs** | Limited | Full Access |

## 🏛️ Architecture

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Mobile Apps   │────│ Prediction API   │────│   AWS Cloud     │
│                 │    │                  │    │                 │
│ • Flutter       │    │ • Flask Server   │    │ • DynamoDB      │
│ • iOS Native    │    │ • ML Models      │    │ • Lambda        │
│ • SwiftUI       │    │ • LSTM/PyTorch   │    │ • IoT Sensors   │
└─────────────────┘    └──────────────────┘    └─────────────────┘
```

## 📊 ML Pipeline

1. **Data Collection** - Wearable sensors (heart rate, HRV, temperature, steps, sleep)
2. **Data Processing** - AWS Lambda preprocessing pipeline  
3. **Feature Engineering** - Scaling and windowing for LSTM input
4. **Prediction** - PyTorch LSTM model for fatigue forecasting
5. **API Serving** - Flask REST API with real-time predictions

## 🔧 Technical Stack

### Frontend
- **Flutter**: Dart, Material Design, FL Chart
- **iOS Native**: SwiftUI, UIKit, Charts Framework

### Backend  
- **API**: Python Flask with CORS
- **ML**: PyTorch, scikit-learn, NumPy, Pandas
- **Cloud**: AWS (DynamoDB, Lambda, IoT Core)

### DevOps
- **Version Control**: Git, GitHub
- **CI/CD**: GitHub Actions (planned)
- **Testing**: Unit tests, Integration tests

## 🏥 Medical Context

MSense addresses fatigue management for Multiple Sclerosis patients by:
- Providing **early warning systems** for fatigue episodes
- Enabling **proactive symptom management**
- Supporting **clinical decision making** with data insights
- Improving **quality of life** through personalized monitoring

## 📈 Project Status

- ✅ **Flutter App**: Complete with full feature set
- ✅ **iOS Native App**: Complete with native SwiftUI implementation  
- ✅ **ML Backend**: Complete with trained models and AWS integration
- 🔄 **Data Pipeline**: Sensor integration in progress
- 📋 **Testing**: Comprehensive test suite planned

## 🎓 Academic Context

**Course**: BME 461 4B Capstone Project  
**Focus**: Mobile Health Applications for Chronic Disease Management  
**Domain**: Machine Learning, iOS Development, Cloud Computing

---

*Built with ❤️ for MS patients and healthcare innovation*
