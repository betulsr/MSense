import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msense/services/mock_prediction_service.dart';
import 'package:msense/services/prediction_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('MockPredictionService Example Tests', () {
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
    
    test('MockPredictionService can simulate connection issues', () async {
      // Arrange
      bool? capturedConnectionStatus;
      mockService.onConnectionStatusChanged = (isConnected) {
        capturedConnectionStatus = isConnected;
      };
      
      // Act - simulate connection failure
      mockService.simulateConnectionStatusChange(false);
      
      // Assert
      expect(capturedConnectionStatus, false);
      
      // Act - try to get predictions, should throw
      expect(() => mockService.getCurrentPredictions(), throwsException);
    });
  });
}
