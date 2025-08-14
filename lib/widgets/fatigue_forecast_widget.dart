import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/prediction_service.dart';

enum TimeRange {
  future,
  lastHour,
  lastTwoHours,
  lastFiveHours,
  lastDay
}

extension TimeRangeExtension on TimeRange {
  String get label {
    switch (this) {
      case TimeRange.future:
        return 'Future';
      case TimeRange.lastHour:
        return 'Past 1h';
      case TimeRange.lastTwoHours:
        return 'Past 2h';
      case TimeRange.lastFiveHours:
        return 'Past 5h';
      case TimeRange.lastDay:
        return 'Past 24h';
    }
  }
  
  Duration get duration {
    switch (this) {
      case TimeRange.future:
        return Duration.zero;
      case TimeRange.lastHour:
        return const Duration(hours: 1);
      case TimeRange.lastTwoHours:
        return const Duration(hours: 2);
      case TimeRange.lastFiveHours:
        return const Duration(hours: 5);
      case TimeRange.lastDay:
        return const Duration(hours: 24);
    }
  }
}

class FatigueForecastWidget extends StatefulWidget {
  final List<double>? predictions;
  final bool isLoading;
  final List<int> nextMinutes;
  final List<FatigueDataPoint>? historicalData;
  final Function(TimeRange)? onTimeRangeChanged;

  const FatigueForecastWidget({
    Key? key,
    required this.predictions,
    required this.isLoading,
    this.nextMinutes = const [15, 30, 45, 60],
    this.historicalData,
    this.onTimeRangeChanged,
  }) : super(key: key);

  @override
  State<FatigueForecastWidget> createState() => _FatigueForecastWidgetState();
}

class _FatigueForecastWidgetState extends State<FatigueForecastWidget> {
  TimeRange _selectedTimeRange = TimeRange.lastHour;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Colors that adapt to theme
    final primaryColor = theme.colorScheme.primary;
    final accentColor = isDarkMode 
        ? theme.colorScheme.primary.withOpacity(0.7) 
        : const Color(0xFF9B8BB5);
    
    if (widget.isLoading || widget.predictions == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 9,
              color: primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'Loading predictions...',
              style: TextStyle(
                color: theme.colorScheme.onBackground.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Range:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
          ),
        ),
        const SizedBox(height: 8),
        _buildTimeRangeSelector(theme),
        const SizedBox(height: 16),
        AspectRatio(
          aspectRatio: 1.5,
          child: _buildChart(theme, isDarkMode, primaryColor, accentColor),
        ),
      ],
    );
  }
  
  Widget _buildTimeRangeSelector(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: TimeRange.values.map((range) {
              final isSelected = _selectedTimeRange == range;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTimeRange = range;
                    });
                    widget.onTimeRangeChanged?.call(range);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      range.label,
                      style: TextStyle(
                        color: isSelected 
                            ? theme.colorScheme.onPrimary 
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildChart(ThemeData theme, bool isDarkMode, Color primaryColor, Color accentColor) {
    final gridColor = theme.colorScheme.onSurface.withOpacity(0.2);
    final labelColor = theme.colorScheme.onSurface.withOpacity(0.8);

    // Determine if we're showing only future predictions
    final showFutureOnly = _selectedTimeRange == TimeRange.future;
    
    // Create spots for the chart
    final spots = <FlSpot>[];
    
    // Track the index where "Now" is located
    int nowIndex = 0;
    
    if (showFutureOnly) {
      // For future only view, we want to show exactly 5 points (Now, +15m, +30m, +45m, +60m)
      if (widget.predictions != null && widget.predictions!.isNotEmpty) {
        // Always show all 5 points for future view
        final pointCount = 5;
        
        // Make sure we have enough predictions
        List<double> futureValues = List.from(widget.predictions!);
        
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
    } else if (widget.historicalData != null && widget.historicalData!.isNotEmpty) {
      // Historical view - filter data based on selected time range
      final filteredData = widget.historicalData!
          .where((dataPoint) => 
              dataPoint.timestamp.isAfter(
                  DateTime.now().subtract(_selectedTimeRange.duration)
              )
          )
          .toList();
      
      // Sort by timestamp (oldest first for the chart)
      filteredData.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      // Create spots from historical data
      for (int i = 0; i < filteredData.length; i++) {
        spots.add(FlSpot(i.toDouble(), filteredData[i].value));
      }
      
      // Remember where "Now" will be - at the end of historical data
      nowIndex = spots.length - 1;
      
      // For past views, we don't show future predictions
    } else {
      // No historical data available, show current value only
      if (widget.predictions != null && widget.predictions!.isNotEmpty) {
        // Just show the current value (first prediction)
        spots.add(FlSpot(0, widget.predictions![0]));
        nowIndex = 0;
      }
    }
    
    // If no spots, show a message
    if (spots.isEmpty) {
      return Center(
        child: Text(
          'No data available for the selected time range',
          style: TextStyle(
            color: theme.colorScheme.onBackground,
            fontSize: 16,
          ),
        ),
      );
    }

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: spots.length - 1.0,
        minY: 0,
        maxY: 10,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          drawHorizontalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: gridColor,
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            // Only draw grid lines at specific points
            if (showFutureOnly) {
              // For future only, show grid lines at every time point
              if (value.toInt() == value && value >= 0 && value < spots.length) {
                return FlLine(
                  color: value == 0 ? primaryColor.withOpacity(0.5) : gridColor,
                  strokeWidth: value == 0 ? 1.5 : 1,
                );
              }
            } else {
              // For historical view
              if (value == nowIndex.toDouble()) {
                // Highlight the "Now" line
                return FlLine(
                  color: primaryColor.withOpacity(0.5),
                  strokeWidth: 1.5,
                );
              } else if (value.toInt() == value && value >= 0 && value < spots.length) {
                // Show regular grid lines at regular intervals
                final interval = _selectedTimeRange == TimeRange.lastHour ? 2 : 
                                 _selectedTimeRange == TimeRange.lastTwoHours ? 4 : 
                                 _selectedTimeRange == TimeRange.lastFiveHours ? 8 : 12;
                
                if ((nowIndex - value).toInt() % interval == 0) {
                  return FlLine(
                    color: gridColor,
                    strokeWidth: 1,
                  );
                }
              }
            }
            return FlLine(
              color: Colors.transparent,
              strokeWidth: 0,
            );
          },
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            axisNameWidget: Text(
              'Time',
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            axisNameSize: 24,
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              reservedSize: 32,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                
                // Skip if out of range
                if (index < 0 || index >= spots.length) {
                  return const SizedBox.shrink();
                }
                
                // Future only view - simple fixed labels
                if (showFutureOnly) {
                  final labels = ['Now', '+15m', '+30m', '+45m', '+60m'];
                  if (index < labels.length) {
                    final isNow = index == 0;
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        labels[index],
                        style: TextStyle(
                          color: isNow ? primaryColor : labelColor,
                          fontSize: 12,
                          fontWeight: isNow ? FontWeight.bold : FontWeight.w500,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                } 
                // Historical view
                else {
                  // For historical view, "Now" is at the end
                  if (index == nowIndex) {
                    return SideTitleWidget(
                      axisSide: meta.axisSide,
                      child: Text(
                        'Now',
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }
                  
                  // Show past time markers at key intervals
                  if (index < nowIndex) {
                    // Calculate how many minutes ago this was
                    final minutesAgo = ((nowIndex - index) * 15);
                    
                    // For 1 hour view, show -30m
                    if (_selectedTimeRange == TimeRange.lastHour && minutesAgo == 30) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          '-30m',
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    
                    // For 2 hour view, show -1h
                    if (_selectedTimeRange == TimeRange.lastTwoHours && minutesAgo == 60) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          '-1h',
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    
                    // For 5 hour view, show -2h and -4h
                    if (_selectedTimeRange == TimeRange.lastFiveHours && 
                        (minutesAgo == 120 || minutesAgo == 240)) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          '-${minutesAgo ~/ 60}h',
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                    
                    // For 24 hour view, show -6h, -12h, -18h
                    if (_selectedTimeRange == TimeRange.lastDay && 
                        (minutesAgo == 360 || minutesAgo == 720 || minutesAgo == 1080)) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          '-${minutesAgo ~/ 60}h',
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      );
                    }
                  }
                }
                
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            axisNameWidget: Text(
              'Fatigue Level',
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            axisNameSize: 24,
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                // Only show integer values
                if (value != value.toInt()) {
                  return const SizedBox.shrink();
                }
                
                return SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(
                    value.toInt().toString(),
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              },
              reservedSize: 32,
            ),
          ),
          topTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: gridColor, width: 1),
            left: BorderSide(color: gridColor, width: 1),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: primaryColor,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 6,
                  color: accentColor,
                  strokeWidth: 2,
                  strokeColor: primaryColor,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: primaryColor.withOpacity(0.15),
            ),
          ),
        ],
      ),
    );
  }
}
