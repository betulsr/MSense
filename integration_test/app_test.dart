import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:msense/screens/home_screen.dart';
import 'package:msense/services/prediction_service.dart';
import 'package:msense/widgets/fatigue_forecast_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test/mocks/mock_prediction_service.dart';

// A test app that uses the MockPredictionService
class TestApp extends StatelessWidget {
  final MockPredictionService mockService;
  
  const TestApp({Key? key, required this.mockService}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Replace the global instance with our mock
    PredictionService.instance = mockService;
    
    return MaterialApp(
      home: HomeScreen(),
    );
  }
}

// A simplified version of the app for widget testing
class SimpleTestApp extends StatelessWidget {
  const SimpleTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: FatigueForecastWidget(
          predictions: [5.0, 6.0, 7.0, 8.0],
          isLoading: false,
          nextMinutes: [15, 30, 45, 60],
          historicalData: [
            FatigueDataPoint(
              timestamp: DateTime.now().subtract(Duration(hours: 1)),
              value: 6.0,
            ),
            FatigueDataPoint(
              timestamp: DateTime.now().subtract(Duration(minutes: 30)),
              value: 7.0,
            ),
          ],
          onTimeRangeChanged: (timeRange) {
            // Do nothing in test
          },
        ),
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('MSense App Integration Tests', () {
    setUp(() async {
      // Set up fake SharedPreferences data
      SharedPreferences.setMockInitialValues({
        'historical_fatigue_data': jsonEncode([
          {
            'timestamp': DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
            'value': 6.0
          },
          {
            'timestamp': DateTime.now().subtract(Duration(minutes: 30)).toIso8601String(),
            'value': 7.0
          },
        ])
      });
    });
    
    testWidgets('FatigueForecastWidget displays correctly', (WidgetTester tester) async {
      // Use a simplified test app that directly uses the FatigueForecastWidget
      await tester.pumpWidget(const SimpleTestApp());
      
      // Wait for the app to fully load
      await tester.pumpAndSettle();
      
      // Verify the fatigue forecast widget is displayed
      expect(find.byType(FatigueForecastWidget), findsOneWidget);
      
      // Verify the time range selector is displayed
      expect(find.text('Time Range:'), findsOneWidget);
      
      // Verify at least one time range option is visible
      final timeRangeOptions = ['Past 1h', 'Past 2h', 'Past 5h', 'Past 24h', 'Future'];
      bool foundAtLeastOne = false;
      
      for (final option in timeRangeOptions) {
        final finder = find.text(option);
        if (finder.evaluate().isNotEmpty) {
          foundAtLeastOne = true;
          break;
        }
      }
      
      expect(foundAtLeastOne, true, reason: 'At least one time range option should be visible');
    });
    
    testWidgets('HomeScreen with MockPredictionService', (WidgetTester tester) async {
      // Create a mock prediction service
      final mockService = MockPredictionService();
      
      // Set up callbacks to track when predictions are updated
      bool predictionsUpdated = false;
      mockService.onPredictionsUpdated = (predictions, nextMinutes) {
        predictionsUpdated = true;
      };
      
      // Use the test app with the mock service
      await tester.pumpWidget(TestApp(mockService: mockService));
      
      // Wait for the app to fully load and predictions to be fetched
      await tester.pumpAndSettle(Duration(seconds: 1));
      
      // Verify the home screen is displayed
      expect(find.byType(HomeScreen), findsOneWidget);
      
      // Verify the fatigue forecast widget is displayed
      expect(find.byType(FatigueForecastWidget), findsOneWidget);
      
      // Verify that polling was started
      expect(mockService.wasPollingStarted, true);
      
      // Verify that predictions were requested
      expect(mockService.getCurrentPredictionsCalls > 0, true);
    });
  });
}
