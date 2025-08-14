import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'device_screen.dart';
import 'settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  _MainNavigationState createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  
  static final List<Widget> _screens = [
    HomeScreen(),
    DeviceScreen(),
    SettingsScreen(),
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    // Base color: #d1c8e4 (soft lavender)
    const deepPurple = Color(0xFF7E6F9B);  // Darker shade for primary actions
    const paleLavender = Color(0xFFE8E3F3); // Lighter shade for highlights
    
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? theme.colorScheme.surface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: isDarkMode 
                  ? theme.colorScheme.onSurface.withOpacity(0.2) 
                  : deepPurple.withOpacity(0.3),
              width: 1.0,
            ),
          ),
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.watch_rounded),
              label: 'Device',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: 'Settings',
            ),
          ],
          currentIndex: _selectedIndex,
          backgroundColor: Colors.transparent,
          elevation: 0,
          selectedItemColor: isDarkMode ? theme.colorScheme.primary : deepPurple,
          unselectedItemColor: isDarkMode 
              ? theme.colorScheme.onSurface.withOpacity(0.6) 
              : Colors.grey,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
