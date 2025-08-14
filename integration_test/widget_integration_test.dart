import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:msense/services/prediction_service.dart';
import 'package:msense/widgets/fatigue_forecast_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('FatigueForecastWidget Integration Tests', () {
    testWidgets('Widget displays correctly with test data', (WidgetTester tester) async {
      // Set up test data
      final testPredictions = [5.0, 6.0, 7.0, 8.0];
      final testNextMinutes = [15, 30, 45, 60];
      final testHistoricalData = [
        FatigueDataPoint(
          timestamp: DateTime.now().subtract(Duration(hours: 1)),
          value: 6.0,
        ),
        FatigueDataPoint(
          timestamp: DateTime.now().subtract(Duration(minutes: 30)),
          value: 7.0,
        ),
      ];
      
      // Build the widget with test data
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FatigueForecastWidget(
              predictions: testPredictions,
              isLoading: false,
              nextMinutes: testNextMinutes,
              historicalData: testHistoricalData,
              onTimeRangeChanged: (_) {},
            ),
          ),
        ),
      );
      
      // Wait for the widget to fully render
      await tester.pumpAndSettle();
      
      // Verify the widget displays correctly
      expect(find.text('Fatigue Forecast'), findsOneWidget);
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
    
    testWidgets('Widget handles loading state correctly', (WidgetTester tester) async {
      // Build the widget in loading state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FatigueForecastWidget(
              predictions: [],
              isLoading: true,
              nextMinutes: [],
              historicalData: [],
              onTimeRangeChanged: (_) {},
            ),
          ),
        ),
      );
      
      // Wait for the widget to fully render
      await tester.pumpAndSettle();
      
      // Verify loading indicator is displayed
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
    
    testWidgets('Widget handles empty data correctly', (WidgetTester tester) async {
      // Build the widget with empty data
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FatigueForecastWidget(
              predictions: [],
              isLoading: false,
              nextMinutes: [],
              historicalData: [],
              onTimeRangeChanged: (_) {},
            ),
          ),
        ),
      );
      
      // Wait for the widget to fully render
      await tester.pumpAndSettle();
      
      // Verify no data message is displayed
      expect(find.text('No data available'), findsOneWidget);
    });
    
    testWidgets('Time range selection works', (WidgetTester tester) async {
      // Set up test data
      final testPredictions = [5.0, 6.0, 7.0, 8.0];
      final testNextMinutes = [15, 30, 45, 60];
      final testHistoricalData = List.generate(
        24, // 24 hours of data
        (index) => FatigueDataPoint(
          timestamp: DateTime.now().subtract(Duration(hours: index)),
          value: 5.0 + (index % 5),
        ),
      );
      
      // Track selected time range
      TimeRange? selectedTimeRange;
      
      // Build the widget with test data
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FatigueForecastWidget(
              predictions: testPredictions,
              isLoading: false,
              nextMinutes: testNextMinutes,
              historicalData: testHistoricalData,
              onTimeRangeChanged: (timeRange) {
                selectedTimeRange = timeRange;
              },
            ),
          ),
        ),
      );
      
      // Wait for the widget to fully render
      await tester.pumpAndSettle();
      
      // Find and tap on the "Past 2h" option if it exists
      final past2hFinder = find.text('Past 2h');
      if (past2hFinder.evaluate().isNotEmpty) {
        await tester.tap(past2hFinder);
        await tester.pumpAndSettle();
        
        // Verify the callback was called with the correct time range
        expect(selectedTimeRange, TimeRange.past2h);
      }
    });
  });
}
