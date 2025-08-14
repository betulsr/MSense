import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msense/widgets/fatigue_forecast_widget.dart';
import 'package:msense/services/prediction_service.dart';

void main() {
  // Helper function to create test data
  List<FatigueDataPoint> createHistoricalData() {
    final now = DateTime.now();
    return [
      // Create data points for the past 24 hours at 15-minute intervals
      for (int i = 96; i > 0; i--)
        FatigueDataPoint(
          timestamp: now.subtract(Duration(minutes: 15 * i)),
          value: (i % 10).toDouble(), // Values between 0-9 for testing
        ),
    ];
  }

  // Helper function to create a testable widget
  Widget createTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 600, // Fixed width to avoid layout issues
          height: 800, // Fixed height to avoid layout issues
          child: child,
        ),
      ),
    );
  }

  group('FatigueForecastWidget', () {
    testWidgets('displays loading indicator when isLoading is true',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestableWidget(
          FatigueForecastWidget(
            predictions: [5.0, 6.0, 7.0, 8.0],
            isLoading: true,
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading predictions...'), findsOneWidget);
    });

    testWidgets('displays loading indicator when predictions is null',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestableWidget(
          FatigueForecastWidget(
            predictions: null,
            isLoading: false,
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading predictions...'), findsOneWidget);
    });
    
    testWidgets('displays time range selector',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestableWidget(
          FatigueForecastWidget(
            predictions: [5.0, 6.0, 7.0, 8.0],
            isLoading: false,
          ),
        ),
      );
      
      // Pump a frame to ensure widget is built
      await tester.pump();

      // Assert - check for time range header
      expect(find.text('Time Range:'), findsOneWidget);
    });
    
    testWidgets('handles callback without errors',
        (WidgetTester tester) async {
      // Arrange
      bool callbackCalled = false;
      
      await tester.pumpWidget(
        createTestableWidget(
          FatigueForecastWidget(
            predictions: [5.0, 6.0, 7.0, 8.0],
            isLoading: false,
            onTimeRangeChanged: (timeRange) {
              callbackCalled = true;
            },
          ),
        ),
      );
      
      // Pump a frame to ensure widget is built
      await tester.pump();
      
      // This test just ensures the widget builds without errors when a callback is provided
      expect(find.text('Time Range:'), findsOneWidget);
    });
    
    testWidgets('handles empty historical data',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestableWidget(
          FatigueForecastWidget(
            predictions: [5.0, 6.0, 7.0, 8.0],
            isLoading: false,
            historicalData: [], // Empty historical data
          ),
        ),
      );
      
      // Pump a frame to ensure widget is built
      await tester.pump();
      
      // Assert - widget should build without errors
      expect(find.text('Time Range:'), findsOneWidget);
    });
    
    testWidgets('handles single prediction',
        (WidgetTester tester) async {
      // Arrange - test with fewer predictions
      await tester.pumpWidget(
        createTestableWidget(
          FatigueForecastWidget(
            predictions: [5.0], // Only one prediction
            isLoading: false,
          ),
        ),
      );
      
      // Pump a frame to ensure widget is built
      await tester.pump();
      
      // Assert - widget should build without errors
      expect(find.text('Time Range:'), findsOneWidget);
    });
    
    testWidgets('handles custom nextMinutes',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestableWidget(
          FatigueForecastWidget(
            predictions: [5.0, 6.0, 7.0],
            isLoading: false,
            nextMinutes: [10, 20, 30], // Custom next minutes
          ),
        ),
      );
      
      // Pump a frame to ensure widget is built
      await tester.pump();
      
      // Assert - widget should build without errors
      expect(find.text('Time Range:'), findsOneWidget);
    });
    
    testWidgets('builds with historical data',
        (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(
        createTestableWidget(
          FatigueForecastWidget(
            predictions: [5.0, 6.0, 7.0, 8.0],
            isLoading: false,
            historicalData: createHistoricalData(),
          ),
        ),
      );
      
      // Pump a frame to ensure widget is built
      await tester.pump();
      
      // Assert - widget should build without errors
      expect(find.text('Time Range:'), findsOneWidget);
    });
  });
}
