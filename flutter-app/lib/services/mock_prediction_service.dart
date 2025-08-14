import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'prediction_service.dart';

/// A mock implementation of the PredictionService for testing purposes.
/// 
/// This class simulates the behavior of the real PredictionService without making
/// actual network requests. It provides predictable test data and can simulate
/// various scenarios like connection errors or data updates.
/// 
/// Usage:
/// ```dart
/// // Replace the real service with the mock in your tests
/// PredictionService.instance = MockPredictionService();
/// 
/// // Or inject it directly into widgets that need it
/// FatigueForecastWidget(
///   predictionService: MockPredictionService(),
///   ...
/// )
/// ```
class MockPredictionService implements PredictionService {
  // Callbacks from PredictionService interface
  @override
  Function(List<double>, List<int>)? onPredictionsUpdated;
  
  @override
  Function(bool)? onConnectionStatusChanged;
  
  @override
  Function(List<FatigueDataPoint>)? onHistoricalDataUpdated;
  
  // Mock data
  List<FatigueDataPoint> _historicalData = [];
  List<double> _mockPredictions = [5.0, 6.0, 7.0, 8.0];
  List<int> _mockNextMinutes = [15, 30, 45, 60];
  bool _isConnected = true;
  Timer? _pollingTimer;
  bool _isPolling = false;
  
  // For testing purposes - these properties help verify the service behavior
  bool wasPollingStarted = false;
  bool wasPollingStoped = false;
  int getCurrentPredictionsCalls = 0;
  
  /// Creates a new MockPredictionService with default test data.
  MockPredictionService() {
    _initializeHistoricalData();
  }
  
  /// Initialize mock historical data with realistic test values.
  Future<void> _initializeHistoricalData() async {
    final now = DateTime.now();
    
    // Create mock historical data points for the past 24 hours
    _historicalData = List.generate(
      24, // 24 hours of data
      (index) => FatigueDataPoint(
        timestamp: now.subtract(Duration(hours: index)),
        value: 5.0 + (index % 5), // Values between 5-9
      ),
    );
    
    // Sort by timestamp (newest first)
    _historicalData.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Save to SharedPreferences for testing
    await _saveHistoricalData();
    
    // Notify listeners
    onHistoricalDataUpdated?.call(_historicalData);
  }
  
  /// Save historical data to SharedPreferences.
  Future<void> _saveHistoricalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = jsonEncode(_historicalData.map((dp) => dp.toJson()).toList());
      await prefs.setString('historical_fatigue_data', jsonData);
    } catch (e) {
      print('Mock - Error saving historical data: $e');
    }
  }
  
  @override
  Future<void> getCurrentPredictions() async {
    getCurrentPredictionsCalls++;
    
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Simulate successful prediction
    if (_isConnected) {
      // Notify listeners with mock predictions
      onPredictionsUpdated?.call(_mockPredictions, _mockNextMinutes);
      onConnectionStatusChanged?.call(true);
      
      // Add current prediction to historical data
      _addHistoricalDataPoint(_mockPredictions[0]);
      
      return;
    }
    
    // Simulate connection error
    onConnectionStatusChanged?.call(false);
    throw Exception('Mock connection error');
  }
  
  /// Add a new historical data point.
  void _addHistoricalDataPoint(double value) {
    final now = DateTime.now();
    final dataPoint = FatigueDataPoint(timestamp: now, value: value);
    
    // Add to the beginning of the list (newest first)
    _historicalData.insert(0, dataPoint);
    
    // Limit the size of historical data (keep last 24 hours = 96 data points at 15-minute intervals)
    if (_historicalData.length > 96) {
      _historicalData = _historicalData.sublist(0, 96);
    }
    
    // Save to SharedPreferences
    _saveHistoricalData();
    
    // Notify listeners
    onHistoricalDataUpdated?.call(_historicalData);
  }
  
  @override
  List<FatigueDataPoint> getHistoricalData({Duration? timeRange}) {
    if (timeRange == null) {
      return List.from(_historicalData);
    }
    
    final cutoffTime = DateTime.now().subtract(timeRange);
    return _historicalData
        .where((dataPoint) => dataPoint.timestamp.isAfter(cutoffTime))
        .toList();
  }
  
  @override
  Future<void> startPolling() async {
    if (_isPolling) return;
    _isPolling = true;
    wasPollingStarted = true;
    
    // Cancel any existing timer
    _pollingTimer?.cancel();
    
    // Start polling every 15 minutes
    _pollingTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      getCurrentPredictions();
    });
    
    // Get predictions immediately
    await getCurrentPredictions();
  }
  
  @override
  void stopPolling() {
    wasPollingStoped = true;
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    onConnectionStatusChanged?.call(false);
  }
  
  /// Simulate connection status change.
  /// 
  /// This method allows tests to simulate connection issues.
  void simulateConnectionStatusChange(bool isConnected) {
    _isConnected = isConnected;
    onConnectionStatusChanged?.call(isConnected);
  }
  
  /// Set mock predictions for testing.
  /// 
  /// This method allows tests to provide specific prediction values.
  void setMockPredictions(List<double> predictions, List<int> nextMinutes) {
    _mockPredictions = predictions;
    _mockNextMinutes = nextMinutes;
  }
  
  /// Clear historical data.
  /// 
  /// This method allows tests to start with a clean slate.
  Future<void> clearHistoricalData() async {
    _historicalData = [];
    await _saveHistoricalData();
    onHistoricalDataUpdated?.call(_historicalData);
  }
}
