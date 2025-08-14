import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceScreen extends StatefulWidget {
  const DeviceScreen({Key? key}) : super(key: key);

  @override
  _DeviceScreenState createState() => _DeviceScreenState();
}

class _DeviceScreenState extends State<DeviceScreen> {
  bool _isDeviceRunning = false;
  bool _isLoading = false;
  String _statusMessage = "Device is not running";
  DateTime? _deviceStartTime;
  Timer? _deviceStatusTimer;

  @override
  void initState() {
    super.initState();
    _loadDeviceStatus();
  }

  @override
  void dispose() {
    _deviceStatusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDeviceStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final startTimeMillis = prefs.getInt('device_start_time');
      
      if (startTimeMillis != null) {
        final startTime = DateTime.fromMillisecondsSinceEpoch(startTimeMillis);
        final now = DateTime.now();
        final difference = now.difference(startTime);
        
        // Device stays "on" for at least 3 hours
        if (difference.inHours < 3) {
          setState(() {
            _isDeviceRunning = true;
            _deviceStartTime = startTime;
            _statusMessage = "Device is running";
            _startDeviceTimer();
          });
        } else {
          // Reset device status after 3 hours
          await prefs.remove('device_start_time');
        }
      }
    } catch (e) {
      print('Error loading device status: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startDeviceTimer() {
    _deviceStatusTimer?.cancel();
    _deviceStatusTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_deviceStartTime != null) {
        final now = DateTime.now();
        final difference = now.difference(_deviceStartTime!);
        
        // Update UI with remaining time
        setState(() {
          if (difference.inHours >= 3) {
            _isDeviceRunning = false;
            _deviceStartTime = null;
            _statusMessage = "Device is not running";
            timer.cancel();
            _saveDeviceStatus(null);
          } else {
            final remainingMinutes = (3 * 60) - difference.inMinutes;
            _statusMessage = "Device is running\nRemaining time: ${_formatRemainingTime(remainingMinutes)}";
          }
        });
      }
    });
  }

  String _formatRemainingTime(int remainingMinutes) {
    final hours = remainingMinutes ~/ 60;
    final minutes = remainingMinutes % 60;
    return "${hours}h ${minutes}m";
  }

  Future<void> _saveDeviceStatus(DateTime? startTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (startTime != null) {
        await prefs.setInt('device_start_time', startTime.millisecondsSinceEpoch);
      } else {
        await prefs.remove('device_start_time');
      }
    } catch (e) {
      print('Error saving device status: $e');
    }
  }

  Future<void> _startDevice() async {
    setState(() {
      _isLoading = true;
      _statusMessage = "Starting device...";
    });

    try {
      final response = await http.get(
        Uri.parse('https://hwqdmdeo755wruijpc4kk6ap2u0xaqrq.lambda-url.us-east-2.on.aws/'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final startTime = DateTime.now();
        await _saveDeviceStatus(startTime);
        
        setState(() {
          _isDeviceRunning = true;
          _deviceStartTime = startTime;
          _statusMessage = "Device started successfully!";
          _startDeviceTimer();
        });
      } else {
        setState(() {
          _statusMessage = "Failed to start device: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = "Error connecting to device: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Base color: #d1c8e4 (soft lavender)
    const deepPurple = Color(0xFF7E6F9B);  // Darker shade for primary actions
    const paleLavender = Color(0xFFE8E3F3); // Lighter shade for highlights
    const textDark = Color(0xFF2D2640);     // Deep purple for text

    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Control'),
        backgroundColor: deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: paleLavender,
                  boxShadow: [
                    BoxShadow(
                      color: _isDeviceRunning 
                          ? Colors.green.withOpacity(0.3) 
                          : Colors.grey.withOpacity(0.2),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(
                  _isDeviceRunning ? Icons.check_circle : Icons.watch,
                  size: 70,
                  color: _isDeviceRunning ? Colors.green : deepPurple,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_isLoading)
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(deepPurple),
                )
              else
                ElevatedButton.icon(
                  onPressed: _isDeviceRunning ? null : _startDevice,
                  icon: const Icon(Icons.power_settings_new),
                  label: Text(_isDeviceRunning ? 'Device Running' : 'Start Device'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: deepPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    textStyle: const TextStyle(fontSize: 18),
                    disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              Text(
                _isDeviceRunning 
                    ? 'Device is actively collecting data from your wearable sensors.'
                    : 'Starting the device will begin data collection\nfrom your wearable sensors.',
                style: TextStyle(
                  fontSize: 14,
                  color: textDark.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
