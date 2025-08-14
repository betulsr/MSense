import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../main.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  double _fatigueThreshold = 7.0;
  bool _isLoading = true;
  bool _dataCollectionConsent = true;
  bool _earlyNotificationsEnabled = false;
  int _earlyNotificationTime = 30; // Default to 30 minutes

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _fatigueThreshold = prefs.getDouble('fatigue_threshold') ?? 7.0;
        _dataCollectionConsent = prefs.getBool('data_collection_consent') ?? true;
        _earlyNotificationsEnabled = prefs.getBool('early_notifications_enabled') ?? false;
        _earlyNotificationTime = prefs.getInt('early_notification_time') ?? 30;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      await prefs.setBool('notifications_enabled', _notificationsEnabled);
      await prefs.setDouble('fatigue_threshold', _fatigueThreshold);
      await prefs.setBool('data_collection_consent', _dataCollectionConsent);
      await prefs.setBool('early_notifications_enabled', _earlyNotificationsEnabled);
      await prefs.setInt('early_notification_time', _earlyNotificationTime);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully')),
      );
    } catch (e) {
      print('Error saving settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notification Settings',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Enable Notifications'),
                              subtitle: const Text('Receive alerts about your fatigue levels'),
                              value: _notificationsEnabled,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (value) {
                                setState(() {
                                  _notificationsEnabled = value;
                                  // If notifications are disabled, also disable early notifications
                                  if (!value) {
                                    _earlyNotificationsEnabled = false;
                                  }
                                });
                              },
                            ),
                            const Divider(),
                            ListTile(
                              title: const Text('Fatigue Threshold'),
                              subtitle: Text('Notify when fatigue level exceeds ${_fatigueThreshold.toStringAsFixed(1)}'),
                              trailing: _notificationsEnabled 
                                  ? const Icon(Icons.chevron_right) 
                                  : null,
                              onTap: _notificationsEnabled 
                                  ? () => _showThresholdDialog() 
                                  : null,
                              textColor: _notificationsEnabled 
                                  ? null 
                                  : theme.disabledColor,
                            ),
                            const Divider(),
                            SwitchListTile(
                              title: const Text('Early Notifications'),
                              subtitle: const Text('Get notified before reaching your threshold'),
                              value: _earlyNotificationsEnabled && _notificationsEnabled,
                              activeColor: theme.colorScheme.primary,
                              onChanged: _notificationsEnabled 
                                  ? (value) {
                                      setState(() {
                                        _earlyNotificationsEnabled = value;
                                      });
                                    } 
                                  : null,
                            ),
                            if (_earlyNotificationsEnabled && _notificationsEnabled) ...[
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Notify me before reaching threshold:',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: RadioListTile<int>(
                                            title: const Text('15 min'),
                                            value: 15,
                                            groupValue: _earlyNotificationTime,
                                            onChanged: (value) {
                                              setState(() {
                                                _earlyNotificationTime = value!;
                                              });
                                            },
                                            activeColor: theme.colorScheme.primary,
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                          ),
                                        ),
                                        Expanded(
                                          child: RadioListTile<int>(
                                            title: const Text('30 min'),
                                            value: 30,
                                            groupValue: _earlyNotificationTime,
                                            onChanged: (value) {
                                              setState(() {
                                                _earlyNotificationTime = value!;
                                              });
                                            },
                                            activeColor: theme.colorScheme.primary,
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                          ),
                                        ),
                                        Expanded(
                                          child: RadioListTile<int>(
                                            title: const Text('60 min'),
                                            value: 60,
                                            groupValue: _earlyNotificationTime,
                                            onChanged: (value) {
                                              setState(() {
                                                _earlyNotificationTime = value!;
                                              });
                                            },
                                            activeColor: theme.colorScheme.primary,
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'App Settings',
                      style: theme.textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            SwitchListTile(
                              title: const Text('Dark Mode'),
                              subtitle: const Text('Enable dark theme for the app'),
                              value: themeProvider.isDarkMode,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (value) {
                                themeProvider.toggleTheme();
                              },
                            ),
                            const Divider(),
                            SwitchListTile(
                              title: const Text('Data Collection Consent'),
                              subtitle: const Text('Allow anonymous usage data collection to improve the app'),
                              value: _dataCollectionConsent,
                              activeColor: theme.colorScheme.primary,
                              onChanged: (value) {
                                setState(() {
                                  _dataCollectionConsent = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Save Settings'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          // Reset to defaults
                          setState(() {
                            _notificationsEnabled = true;
                            _fatigueThreshold = 7.0;
                            _dataCollectionConsent = true;
                            _earlyNotificationsEnabled = false;
                            _earlyNotificationTime = 30;
                          });
                          // Reset theme to light
                          if (themeProvider.isDarkMode) {
                            themeProvider.toggleTheme();
                          }
                        },
                        child: const Text('Reset to Defaults'),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        'MSense v1.0.0',
                        style: TextStyle(
                          color: theme.brightness == Brightness.dark 
                              ? Colors.grey[400] 
                              : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showThresholdDialog() {
    showDialog(
      context: context,
      builder: (context) {
        double tempThreshold = _fatigueThreshold;
        final theme = Theme.of(context);
        
        return AlertDialog(
          title: const Text('Set Fatigue Threshold'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You will be notified when your fatigue level exceeds this value (0-10):',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(
                builder: (context, setSliderState) {
                  return Column(
                    children: [
                      Slider(
                        value: tempThreshold,
                        min: 0,
                        max: 10,
                        divisions: 10,
                        label: tempThreshold.toStringAsFixed(1),
                        activeColor: theme.colorScheme.primary,
                        onChanged: (value) {
                          setSliderState(() {
                            tempThreshold = value;
                          });
                        },
                      ),
                      Text(
                        tempThreshold.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _fatigueThreshold = tempThreshold;
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
