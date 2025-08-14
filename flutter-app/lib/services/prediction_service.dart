import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class FatigueDataPoint {
  final DateTime timestamp;
  final double value;

  FatigueDataPoint({required this.timestamp, required this.value});

  Map<String, dynamic> toJson() => {
    'timestamp': timestamp.toIso8601String(),
    'value': value,
  };

  factory FatigueDataPoint.fromJson(Map<String, dynamic> json) {
    return FatigueDataPoint(
      timestamp: DateTime.parse(json['timestamp']),
      value: json['value'],
    );
  }
}

class PredictionService {
  // Singleton instance for global access
  static PredictionService instance = PredictionService();
  
  static const String baseUrl = 'http://10.0.2.2:5000';  // Special Android emulator localhost
  final _client = http.Client();
  Timer? _pollingTimer;
  bool _isPolling = false;
  
  // Historical data storage
  List<FatigueDataPoint> _historicalData = [];
  
  // Callbacks
  Function(List<double>, List<int>)? onPredictionsUpdated;
  Function(bool)? onConnectionStatusChanged;
  Function(List<FatigueDataPoint>)? onHistoricalDataUpdated;

  PredictionService() {
    _loadHistoricalData();
  }

  Future<void> _loadHistoricalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = prefs.getString('historical_fatigue_data');
      
      if (jsonData != null) {
        final List<dynamic> decoded = json.decode(jsonData);
        _historicalData = decoded
            .map((item) => FatigueDataPoint.fromJson(item))
            .toList();
        
        // Sort by timestamp (newest first)
        _historicalData.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        
        // Print all historical data for debugging
        print('=== LOADED HISTORICAL DATA ===');
        print('Total data points: ${_historicalData.length}');
        for (var i = 0; i < _historicalData.length; i++) {
          print('[$i] ${_historicalData[i].timestamp} - Value: ${_historicalData[i].value}');
        }
        print('==============================');
        
        // Notify listeners
        onHistoricalDataUpdated?.call(_historicalData);
      } else {
        print('=== NO HISTORICAL DATA FOUND IN SHARED PREFERENCES ===');
      }
    } catch (e) {
      print('Error loading historical data: $e');
    }
  }

  Future<void> _saveHistoricalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonData = json.encode(_historicalData.map((dp) => dp.toJson()).toList());
      await prefs.setString('historical_fatigue_data', jsonData);
    } catch (e) {
      print('Error saving historical data: $e');
    }
  }

  List<FatigueDataPoint> getHistoricalData({Duration? timeRange}) {
    if (timeRange == null) {
      return List.from(_historicalData);
    }
    
    final cutoffTime = DateTime.now().subtract(timeRange);
    return _historicalData
        .where((dataPoint) => dataPoint.timestamp.isAfter(cutoffTime))
        .toList();
  }

  Future<void> startPolling() async {
    if (_isPolling) return;
    _isPolling = true;
    onConnectionStatusChanged?.call(false);  // Start with disconnected state
    
    // Get initial predictions
    await getCurrentPredictions();
    
    // Start polling every 15 minutes (900 seconds) to match the server update interval
    _pollingTimer = Timer.periodic(const Duration(seconds: 900), (_) {
      getCurrentPredictions();
    });
  }

  Future<void> getCurrentPredictions() async {
    try {
      print('Fetching predictions from $baseUrl/current-predictions');
      final response = await _client.get(
        Uri.parse('$baseUrl/current-predictions'),
        headers: {
          'Accept': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
      ).timeout(const Duration(seconds: 10)); // Add timeout
      
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'success' && data['predictions'] != null) {
          // Convert integers to doubles if needed
          final predictions = data['predictions'].map<double>((pred) => 
            pred is int ? pred.toDouble() : (pred is double ? pred : 0.0)
          ).toList();
          
          final nextMinutes = List<int>.from(data['next_minutes'] ?? [15, 30, 45, 60]);
          print('Received predictions: $predictions for minutes: $nextMinutes');
          
          // Store the current fatigue level in historical data
          if (predictions.isNotEmpty) {
            final currentFatigue = predictions[0];
            _addHistoricalDataPoint(currentFatigue);
          }
          
          onPredictionsUpdated?.call(predictions, nextMinutes);
          onConnectionStatusChanged?.call(true);
        } else {
          print('Invalid response format: $data');
          onConnectionStatusChanged?.call(false);
        }
      } else {
        print('Error response: ${response.statusCode}');
        onConnectionStatusChanged?.call(false);
      }
    } catch (e) {
      print('Error fetching predictions: $e');
      onConnectionStatusChanged?.call(false);
    }
  }

  void _addHistoricalDataPoint(double value) {
    final now = DateTime.now();
    final dataPoint = FatigueDataPoint(timestamp: now, value: value);
    
    print('=== ADDING NEW HISTORICAL DATA POINT ===');
    print('Timestamp: $now - Value: $value');
    
    // Add to the beginning of the list (newest first)
    _historicalData.insert(0, dataPoint);
    
    // Limit the size of historical data (keep last 24 hours = 96 data points at 15-minute intervals)
    if (_historicalData.length > 96) {
      _historicalData = _historicalData.sublist(0, 96);
    }
    
    print('Total historical data points after adding: ${_historicalData.length}');
    
    // Save to SharedPreferences
    _saveHistoricalData();
    
    // Notify listeners
    onHistoricalDataUpdated?.call(_historicalData);
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
    onConnectionStatusChanged?.call(false);
  }
}
