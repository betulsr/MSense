import 'package:flutter_test/flutter_test.dart';
import 'package:msense/services/prediction_service.dart';
import 'package:msense/services/mock_prediction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late MockPredictionService mockService;
  
  setUp(() {
    // Set up SharedPreferences for testing
    SharedPreferences.setMockInitialValues({});
    
    // Create a fresh mock service for each test
    mockService = MockPredictionService();
  });
  
  group('MockPredictionService', () {
    test('getCurrentPredictions should call onPredictionsUpdated callback', () async {
      // Arrange
      List<double>? capturedPredictions;
      List<int>? capturedNextMinutes;
      
      mockService.onPredictionsUpdated = (predictions, nextMinutes) {
        capturedPredictions = predictions;
        capturedNextMinutes = nextMinutes;
      };
      
      // Act
      await mockService.getCurrentPredictions();
      
      // Assert
      expect(capturedPredictions, isNotNull);
      expect(capturedPredictions!.length, 4);
      expect(capturedNextMinutes, isNotNull);
      expect(capturedNextMinutes!.length, 4);
      expect(mockService.getCurrentPredictionsCalls, 1);
    });
    
    test('startPolling should set wasPollingStarted flag', () async {
      // Act
      await mockService.startPolling();
      
      // Assert
      expect(mockService.wasPollingStarted, true);
      
      // Cleanup
      mockService.stopPolling();
    });
    
    test('stopPolling should set wasPollingStoped flag', () async {
      // Arrange
      await mockService.startPolling();
      
      // Act
      mockService.stopPolling();
      
      // Assert
      expect(mockService.wasPollingStoped, true);
    });
    
    test('simulateConnectionStatusChange should call onConnectionStatusChanged callback', () {
      // Arrange
      bool? capturedStatus;
      mockService.onConnectionStatusChanged = (isConnected) {
        capturedStatus = isConnected;
      };
      
      // Act
      mockService.simulateConnectionStatusChange(false);
      
      // Assert
      expect(capturedStatus, false);
    });
    
    test('setMockPredictions should update mock predictions', () async {
      // Arrange
      List<double>? capturedPredictions;
      mockService.onPredictionsUpdated = (predictions, nextMinutes) {
        capturedPredictions = predictions;
      };
      
      // Act
      mockService.setMockPredictions([1.0, 2.0, 3.0], [10, 20, 30]);
      await mockService.getCurrentPredictions();
      
      // Assert
      expect(capturedPredictions, [1.0, 2.0, 3.0]);
    });
    
    test('historical data should be initialized', () async {
      // Wait for initialization to complete
      await Future.delayed(Duration(milliseconds: 500));
      
      // Act
      final historicalData = mockService.getHistoricalData();
      
      // Assert
      expect(historicalData, isNotEmpty);
    });
    
    test('clearHistoricalData should empty historical data', () async {
      // Wait for initialization to complete
      await Future.delayed(Duration(milliseconds: 500));
      
      // Act
      await mockService.clearHistoricalData();
      
      // Wait for the operation to complete
      await Future.delayed(Duration(milliseconds: 500));
      
      final historicalData = mockService.getHistoricalData();
      
      // Assert
      expect(historicalData, isEmpty);
    });
  });
}
