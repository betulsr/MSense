import 'package:flutter_test/flutter_test.dart';
import 'package:msense/services/mock_prediction_service.dart';
import 'package:msense/services/prediction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Basic MockPredictionService Tests', () {
    late MockPredictionService mockService;
    
    setUp(() {
      // Set up SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
      
      // Create a fresh mock service for each test
      mockService = MockPredictionService();
    });
    
    test('MockPredictionService provides predictions', () async {
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
    
    test('MockPredictionService provides historical data', () {
      // Act
      final historicalData = mockService.getHistoricalData();
      
      // Assert
      expect(historicalData, isNotEmpty);
      expect(historicalData.first.timestamp, isNotNull);
      expect(historicalData.first.value, isNotNull);
    });
  });
}
