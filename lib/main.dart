import 'package:flutter/material.dart';
import 'screens/main_navigation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load dark mode preference
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('dark_mode_enabled') ?? false;
  
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(isDarkMode),
      child: const MSenseApp(),
    ),
  );
}

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode;
  
  ThemeProvider(this._isDarkMode);
  
  bool get isDarkMode => _isDarkMode;
  
  void toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    
    // Save preference
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode_enabled', _isDarkMode);
    
    notifyListeners();
  }
}

class MSenseApp extends StatelessWidget {
  const MSenseApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    // Base color: #d1c8e4 (soft lavender)
    const baseColor = Colors.white;
    const darkBaseColor = Color(0xFF121212);
    
    // Creating a monochromatic/complementary palette
    const deepPurple = Color(0xFF7E6F9B);  // Darker shade for primary actions
    const paleLavender = Color(0xFFE8E3F3); // Lighter shade for highlights
    const textDark = Color(0xFF2D2640);     // Deep purple for text
    const accentPurple = Color(0xFF9B8BB5); // Medium shade for accents
    
    // Dark theme colors
    const darkPurple = Color(0xFF9B8BB5); // Brighter purple for dark mode
    const darkPaleLavender = Color(0xFF2A2A2A);
    const textLight = Color(0xFFE0E0E0);

    final lightTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: baseColor,
      colorScheme: ColorScheme.light(
        primary: deepPurple,
        secondary: accentPurple,
        surface: paleLavender,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: deepPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepPurple,
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: textDark,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textDark,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: textDark,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textDark,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: textDark,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textDark,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textDark.withOpacity(0.9),
        ),
        bodyMedium: TextStyle(
          color: textDark.withOpacity(0.9),
        ),
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    
    final darkTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBaseColor,
      colorScheme: ColorScheme.dark(
        primary: darkPurple,
        secondary: accentPurple,
        surface: darkPaleLavender,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textLight,
        background: darkBaseColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: darkPurple,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPurple,
          foregroundColor: Colors.white,
        ),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          color: textLight,
          fontWeight: FontWeight.bold,
        ),
        displayMedium: TextStyle(
          color: textLight,
          fontWeight: FontWeight.bold,
        ),
        displaySmall: TextStyle(
          color: textLight,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: textLight,
          fontWeight: FontWeight.bold,
        ),
        headlineSmall: TextStyle(
          color: textLight,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: textLight,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: textLight.withOpacity(0.9),
        ),
        bodyMedium: TextStyle(
          color: textLight.withOpacity(0.9),
        ),
      ),
      cardTheme: CardTheme(
        color: const Color(0xFF2F2F2F), // slightly lighter background color for better contrast
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    return MaterialApp(
      title: 'MSense',
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const MainNavigation(),
    );
  }
}
