import 'package:flutter/material.dart';
import '../services/prediction_service.dart';
import '../widgets/fatigue_forecast_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _predictionService = PredictionService();
  List<double>? _predictions;
  List<int> _nextMinutes = [15, 30, 45, 60];  // Default values
  List<FatigueDataPoint> _historicalData = [];
  bool _isLoading = true;
  TimeRange _selectedTimeRange = TimeRange.lastHour;

  @override
  void initState() {
    super.initState();
    _setupPredictionService();
  }

  void _setupPredictionService() {
    _predictionService.onPredictionsUpdated = (List<double> predictions, List<int> nextMinutes) {
      if (mounted) {
        setState(() {
          _predictions = predictions;
          _nextMinutes = nextMinutes;
          _isLoading = false;
        });
      }
    };

    _predictionService.onConnectionStatusChanged = (isConnected) {
      if (mounted) {
        setState(() {
          _isLoading = !isConnected;
        });
      }
    };
    
    _predictionService.onHistoricalDataUpdated = (List<FatigueDataPoint> historicalData) {
      if (mounted) {
        setState(() {
          _historicalData = historicalData;
        });
      }
    };

    _predictionService.startPolling();
  }

  @override
  void dispose() {
    _predictionService.stopPolling();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isLoading = true;
    });
    await _predictionService.getCurrentPredictions();
    setState(() {
      _isLoading = false;
    });
  }

  void _printHistoricalData() {
    print('=== HISTORICAL DATA DEBUG ===');
    print('Total data points: ${_historicalData.length}');
    
    if (_historicalData.isEmpty) {
      print('No historical data available!');
    } else {
      // Print the first 10 data points
      final pointsToPrint = _historicalData.length > 10 ? 10 : _historicalData.length;
      print('Most recent $pointsToPrint data points:');
      for (var i = 0; i < pointsToPrint; i++) {
        final point = _historicalData[i];
        print('[$i] ${point.timestamp} - Value: ${point.value}');
      }
      
      // Print time ranges
      print('\nTime ranges available:');
      final now = DateTime.now();
      
      // Last hour
      final lastHourCutoff = now.subtract(const Duration(hours: 1));
      final lastHourPoints = _historicalData.where((p) => p.timestamp.isAfter(lastHourCutoff)).length;
      print('Last Hour: $lastHourPoints data points');
      
      // Last 2 hours
      final last2HoursCutoff = now.subtract(const Duration(hours: 2));
      final last2HoursPoints = _historicalData.where((p) => p.timestamp.isAfter(last2HoursCutoff)).length;
      print('Last 2 Hours: $last2HoursPoints data points');
      
      // Last 5 hours
      final last5HoursCutoff = now.subtract(const Duration(hours: 5));
      final last5HoursPoints = _historicalData.where((p) => p.timestamp.isAfter(last5HoursCutoff)).length;
      print('Last 5 Hours: $last5HoursPoints data points');
      
      // Last 24 hours
      final last24HoursCutoff = now.subtract(const Duration(hours: 24));
      final last24HoursPoints = _historicalData.where((p) => p.timestamp.isAfter(last24HoursCutoff)).length;
      print('Last 24 Hours: $last24HoursPoints data points');
    }
    
    print('===========================');
  }

  @override
  Widget build(BuildContext context) {
    final currentFatigue = _predictions?.isNotEmpty == true ? _predictions![0] : null;
    
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80, 
        title: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Image.asset(
            'assets/logo.png',
            height: 100,
            fit: BoxFit.contain,
            alignment: Alignment.bottomLeft,
          ),
        ),
        centerTitle: true,
        actions: [
          // Debug button to print historical data
          IconButton(
            icon: const Icon(Icons.bug_report),
            iconSize: 28,
            onPressed: () {
              _printHistoricalData();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            iconSize: 28, 
            onPressed: () {
              setState(() {
                _isLoading = true;
              });
              _predictionService.getCurrentPredictions();
            },
          ),
          const SizedBox(width: 8), 
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (currentFatigue != null) ...[
                  const SizedBox(height: 20),
                  _buildCurrentFatigueCard(currentFatigue),
                  const SizedBox(height: 32),
                ],
                _buildForecastSection(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentFatigueCard(double fatigue) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Determine color based on fatigue level
    Color fatigueColor;
    String fatigueText;
    
    if (fatigue < 3.0) {
      fatigueColor = Colors.green;
      fatigueText = 'Low';
    } else if (fatigue < 7.0) {
      fatigueColor = Colors.orange;
      fatigueText = 'Moderate';
    } else {
      fatigueColor = Colors.red;
      fatigueText = 'High';
    }
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Current Fatigue Level',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fatigue.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'out of 9.0',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? fatigueColor.withOpacity(0.2) : fatigueColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: fatigueColor.withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    fatigueText,
                    style: TextStyle(
                      color: fatigueColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fatigue Trends',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 400, // Increased height to accommodate time range selector
          child: FatigueForecastWidget(
            predictions: _predictions,
            isLoading: _isLoading,
            nextMinutes: _nextMinutes,
            historicalData: _historicalData,
            onTimeRangeChanged: (TimeRange timeRange) {
              setState(() {
                _selectedTimeRange = timeRange;
              });
              
              // If we need to fetch more historical data based on the time range
              if (timeRange != TimeRange.future) {
                // If we need more historical data for 24-hour view, fetch it
                if (timeRange == TimeRange.lastDay && _historicalData.length < 96) {
                  // This is just a placeholder - in a real app, you might want to fetch more historical data
                  // from a server or local database when the user selects a longer time range
                  print('Need to fetch more historical data for 24-hour view');
                }
              }
            },
          ),
        ),
      ],
    );
  }
}
