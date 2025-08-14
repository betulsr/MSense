import 'package:flutter_test/flutter_test.dart';
import 'package:msense/services/prediction_service.dart';
import 'package:fl_chart/fl_chart.dart';

// Helper class to simulate the chart data processing logic from FatigueForecastWidget
class ChartDataProcessor {
  // Process future predictions data
  static List<FlSpot> processFuturePredictions(List<double>? predictions) {
    final spots = <FlSpot>[];
    
    if (predictions != null && predictions.isNotEmpty) {
      // Always show all 5 points for future view
      final pointCount = 5;
      
      // Make sure we have enough predictions
      List<double> futureValues = List.from(predictions);
      
      // If we don't have enough predictions, duplicate the last one
      while (futureValues.length < pointCount) {
        if (futureValues.isNotEmpty) {
          futureValues.add(futureValues.last);
        } else {
          futureValues.add(5.0); // Default value if no predictions
        }
      }
      
      // Create spots for all 5 time points
      for (int i = 0; i < pointCount; i++) {
        spots.add(FlSpot(i.toDouble(), futureValues[i]));
      }
    } else {
      // If no predictions, create default spots
      for (int i = 0; i < 5; i++) {
        spots.add(FlSpot(i.toDouble(), 5.0));
      }
    }
    
    return spots;
  }
  
  // Get the index where "Now" is located in historical view
  static int getNowIndex(List<FlSpot> spots) {
    return spots.isEmpty ? 0 : spots.length - 1;
  }
  
  // Process fallback data (when there's no historical data)
  static List<FlSpot> processFallbackData(List<double>? predictions) {
    final spots = <FlSpot>[];
    
    if (predictions != null && predictions.isNotEmpty) {
      // Just show the current value (first prediction)
      spots.add(FlSpot(0, predictions[0]));
    }
    
    return spots;
  }
}

void main() {
  group('ChartDataProcessor - Future Predictions', () {
    test('processes normal predictions correctly', () {
      // Arrange
      final predictions = [5.0, 6.0, 7.0, 8.0, 9.0];
      
      // Act
      final spots = ChartDataProcessor.processFuturePredictions(predictions);
      
      // Assert
      expect(spots.length, 5);
      expect(spots[0].x, 0);
      expect(spots[0].y, 5.0);
      expect(spots[4].x, 4);
      expect(spots[4].y, 9.0);
    });
    
    test('handles fewer predictions by duplicating last value', () {
      // Arrange
      final predictions = [5.0, 6.0, 7.0]; // Only 3 predictions
      
      // Act
      final spots = ChartDataProcessor.processFuturePredictions(predictions);
      
      // Assert
      expect(spots.length, 5);
      expect(spots[0].y, 5.0);
      expect(spots[1].y, 6.0);
      expect(spots[2].y, 7.0);
      expect(spots[3].y, 7.0); // Duplicated last value
      expect(spots[4].y, 7.0); // Duplicated last value
    });
    
    test('handles empty predictions with default values', () {
      // Arrange
      final predictions = <double>[];
      
      // Act
      final spots = ChartDataProcessor.processFuturePredictions(predictions);
      
      // Assert
      expect(spots.length, 5);
      for (int i = 0; i < 5; i++) {
        expect(spots[i].x, i.toDouble());
        expect(spots[i].y, 5.0); // Default value
      }
    });
    
    test('handles null predictions with default values', () {
      // Act
      final spots = ChartDataProcessor.processFuturePredictions(null);
      
      // Assert
      expect(spots.length, 5);
      for (int i = 0; i < 5; i++) {
        expect(spots[i].x, i.toDouble());
        expect(spots[i].y, 5.0); // Default value
      }
    });
    
    test('handles more predictions than needed', () {
      // Arrange
      final predictions = [5.0, 6.0, 7.0, 8.0, 9.0, 10.0, 11.0]; // 7 predictions
      
      // Act
      final spots = ChartDataProcessor.processFuturePredictions(predictions);
      
      // Assert
      expect(spots.length, 5); // Should still use only 5
      expect(spots[0].y, 5.0);
      expect(spots[4].y, 9.0);
    });
  });
  
  group('ChartDataProcessor - Now Index', () {
    test('returns last index for non-empty spots', () {
      // Arrange
      final spots = [
        FlSpot(0, 5.0),
        FlSpot(1, 6.0),
        FlSpot(2, 7.0),
      ];
      
      // Act
      final nowIndex = ChartDataProcessor.getNowIndex(spots);
      
      // Assert
      expect(nowIndex, 2); // Last index
    });
    
    test('returns 0 for empty spots', () {
      // Act
      final nowIndex = ChartDataProcessor.getNowIndex([]);
      
      // Assert
      expect(nowIndex, 0);
    });
  });
  
  group('ChartDataProcessor - Fallback Data', () {
    test('creates spot with first prediction', () {
      // Arrange
      final predictions = [5.0, 6.0, 7.0];
      
      // Act
      final spots = ChartDataProcessor.processFallbackData(predictions);
      
      // Assert
      expect(spots.length, 1);
      expect(spots[0].x, 0);
      expect(spots[0].y, 5.0);
    });
    
    test('handles empty predictions', () {
      // Act
      final spots = ChartDataProcessor.processFallbackData([]);
      
      // Assert
      expect(spots.length, 0);
    });
    
    test('handles null predictions', () {
      // Act
      final spots = ChartDataProcessor.processFallbackData(null);
      
      // Assert
      expect(spots.length, 0);
    });
  });
}
