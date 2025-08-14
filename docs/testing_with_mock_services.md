# Testing with Mock Services in MSense

This document provides guidelines and examples for testing the MSense app using mock services, particularly the `MockPredictionService`.

## Overview

The MSense app relies on external services to provide fatigue predictions. When testing, we need to simulate these services to ensure our tests are:

- Fast and reliable
- Independent of network conditions
- Deterministic with predictable outcomes
- Able to simulate edge cases and error conditions

## MockPredictionService

The `MockPredictionService` class provides a drop-in replacement for the real `PredictionService` during testing. It implements the same interface but returns predefined test data instead of making actual network requests.

### Key Features

- Provides realistic test data for predictions and historical fatigue levels
- Can simulate connection issues and error conditions
- Tracks method calls for verification in tests
- Allows customization of test data
- Works with SharedPreferences for persistent storage testing

## Usage Examples

### Unit Testing

```dart
import 'package:flutter_test/flutter_test.dart';
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
  
  test('Service provides predictions', () async {
    // Arrange
    List<double>? capturedPredictions;
    
    mockService.onPredictionsUpdated = (predictions, nextMinutes) {
      capturedPredictions = predictions;
    };
    
    // Act
    await mockService.getCurrentPredictions();
    
    // Assert
    expect(capturedPredictions, isNotNull);
    expect(capturedPredictions!.length, 4);
    expect(mockService.getCurrentPredictionsCalls, 1);
  });
  
  test('Service can simulate connection issues', () async {
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
}
```

### Widget Testing

When testing widgets that depend on the `PredictionService`, you can either:

1. Pass mock data directly to the widget:

```dart
testWidgets('FatigueForecastWidget displays data correctly', (WidgetTester tester) async {
  // Arrange - prepare test data
  final mockService = MockPredictionService();
  final testPredictions = [7.0, 8.0, 9.0, 10.0];
  final testNextMinutes = [15, 30, 45, 60];
  final historicalData = mockService.getHistoricalData();
  
  // Build widget with test data
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FatigueForecastWidget(
          predictions: testPredictions,
          isLoading: false,
          nextMinutes: testNextMinutes,
          historicalData: historicalData,
          onTimeRangeChanged: (_) {},
        ),
      ),
    ),
  );
  
  // Assert
  expect(find.text('Fatigue Forecast'), findsOneWidget);
});
```

2. Replace the global instance for integration testing:

```dart
testWidgets('App uses mock service', (WidgetTester tester) async {
  // Replace the global instance with our mock
  final mockService = MockPredictionService();
  PredictionService.instance = mockService;
  
  // Build the app
  await tester.pumpWidget(MyApp());
  
  // Verify the mock service was used
  expect(mockService.wasPollingStarted, true);
});
```

## Integration Testing

For integration tests, you can replace the real service with the mock:

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  testWidgets('Full app flow with mock service', (WidgetTester tester) async {
    // Replace the global instance with our mock
    final mockService = MockPredictionService();
    PredictionService.instance = mockService;
    
    // Run the app
    app.main();
    await tester.pumpAndSettle();
    
    // Test app functionality
    expect(find.text('Fatigue Forecast'), findsOneWidget);
    
    // Verify the mock service was used
    expect(mockService.wasPollingStarted, true);
  });
}
```

## Customizing Mock Data

The `MockPredictionService` provides methods to customize the test data:

```dart
// Set custom predictions
mockService.setMockPredictions([1.0, 2.0, 3.0], [10, 20, 30]);

// Simulate connection status changes
mockService.simulateConnectionStatusChange(false);

// Clear historical data
await mockService.clearHistoricalData();
```

## Best Practices

1. **Create a fresh mock for each test**: This ensures tests don't interfere with each other.
2. **Set up SharedPreferences**: Use `SharedPreferences.setMockInitialValues({})` before creating the mock service.
3. **Verify method calls**: Check that methods like `getCurrentPredictions()` were called the expected number of times.
4. **Test error handling**: Use `simulateConnectionStatusChange(false)` to test how your app handles connection issues.
5. **Customize test data**: Use `setMockPredictions()` to test how your app handles different prediction values.

## Conclusion

Using the `MockPredictionService` allows for comprehensive testing of the MSense app without relying on external services. This approach makes tests faster, more reliable, and able to cover a wider range of scenarios, including error conditions that would be difficult to reproduce with real services.
