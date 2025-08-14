import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:msense/screens/home_screen.dart';
import 'package:msense/services/mock_prediction_service.dart';
import 'package:msense/services/prediction_service.dart';
import 'package:msense/widgets/fatigue_forecast_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A very simple test widget that directly uses the FatigueForecastWidget
/// This avoids all the complexity of the real app structure
class MinimalTestApp extends StatelessWidget {
  const MinimalTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mockPredictions = [7.0, 8.0, 9.0, 10.0];
    final mockNextMinutes = [15, 30, 45, 60];
    final mockHistoricalData = [
      FatigueDataPoint(
        timestamp: DateTime.now().subtract(Duration(hours: 1)),
        value: 6.0,
      ),
      FatigueDataPoint(
        timestamp: DateTime.now().subtract(Duration(minutes: 30)),
        value: 7.0,
      ),
    ];
    
    return MaterialApp(
      title: 'Minimal Test',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Scaffold(
        appBar: AppBar(title: Text('Test App')),
        body: FatigueForecastWidget(
          predictions: mockPredictions,
          isLoading: false,
          nextMinutes: mockNextMinutes,
          historicalData: mockHistoricalData,
          onTimeRangeChanged: (_) {},
        ),
      ),
    );
  }
}

void main() {
  // This is required to make the integration test work
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('MSense App Integration Tests', () {
    setUp(() async {
      // Set up SharedPreferences with empty initial values
      SharedPreferences.setMockInitialValues({});
    });
    
    testWidgets('Minimal widget test', (WidgetTester tester) async {
      // Build our minimal test app
      await tester.pumpWidget(const MinimalTestApp());
      
      // Wait for the app to settle
      await tester.pumpAndSettle();
      
      // Verify the FatigueForecastWidget is displayed
      expect(find.byType(FatigueForecastWidget), findsOneWidget);
      
      // Verify the app bar title is displayed
      expect(find.text('Test App'), findsOneWidget);
      
      // Verify the time range selector is displayed (this should be part of the widget)
      expect(find.text('Time Range:'), findsOneWidget);
      
      // Find and tap on the "Past 2h" time range option if it exists
      final past2hFinder = find.text('Past 2h');
      if (past2hFinder.evaluate().isNotEmpty) {
        await tester.tap(past2hFinder);
        await tester.pumpAndSettle();
        
        // Verify the widget is still there after the tap
        expect(find.byType(FatigueForecastWidget), findsOneWidget);
      }
    });
  });
}
