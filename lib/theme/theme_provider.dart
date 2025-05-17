import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String? _customThemeName;

  ThemeMode get themeMode => _themeMode;
  String? get customThemeName => _customThemeName;

  /// Returns the current ThemeData based on the selected theme
  ThemeData get themeData {
    // Gold & Purple
    if (_customThemeName == 'Gold & Purple') {
      return ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFFDB913),
        scaffoldBackgroundColor: const Color(0xFF2E003E),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFDB913),
          foregroundColor: Color(0xFF2E003E),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFDB913),
          secondary: Color(0xFF2E003E),
          background: Color(0xFF2E003E),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFFDB913),
          foregroundColor: Color(0xFF2E003E),
        ),
      );
    }
    // Pink & Blue-Gray
    if (_customThemeName == 'Pink & Blue-Gray') {
      return ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFFE91E63),
        scaffoldBackgroundColor: const Color(0xFF223A50),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFE91E63),
          foregroundColor: Color(0xFF223A50),
        ),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE91E63),
          secondary: Color(0xFF223A50),
          background: Color(0xFF223A50),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFE91E63),
          foregroundColor: Color(0xFF223A50),
        ),
      );
    }
    // AMOLED
    if (_customThemeName == 'AMOLED') {
      return ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        colorScheme: const ColorScheme.dark(
          primary: Colors.black,
          secondary: Colors.white,
          background: Colors.black,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
      );
    }
    // Blue
    if (_customThemeName == 'Blue') {
      return ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.blue.shade50,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        colorScheme: ColorScheme.light(
          primary: Colors.blue,
          secondary: Colors.blue.shade700,
          background: Colors.blue.shade50,
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
      );
    }
    // Sepia
    if (_customThemeName == 'Sepia') {
      return ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF704214),
        scaffoldBackgroundColor: const Color(0xFFF5ECD2),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF704214),
          foregroundColor: Color(0xFFF5ECD2),
        ),
        colorScheme: const ColorScheme.light(
          primary: Color(0xFF704214),
          secondary: Color(0xFFAC8A5B),
          background: Color(0xFFF5ECD2),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF704214),
          foregroundColor: Color(0xFFF5ECD2),
        ),
      );
    }
    // System/Light/Dark fallback
    return ThemeData(
      brightness: _themeMode == ThemeMode.dark
          ? Brightness.dark
          : Brightness.light,
    );
  }

  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('selected_theme') ?? 'System Default';
    switch (theme) {
      case 'Light':
        _themeMode = ThemeMode.light;
        _customThemeName = null;
        break;
      case 'Dark':
        _themeMode = ThemeMode.dark;
        _customThemeName = null;
        break;
      case 'AMOLED':
      case 'Blue':
      case 'Sepia':
      case 'Gold & Purple': // <-- Added
      case 'Pink & Blue-Gray': // <-- Added
        _themeMode = ThemeMode.light; // fallback to light, but custom theme used
        _customThemeName = theme;
        break;
      default:
        _themeMode = ThemeMode.system;
        _customThemeName = null;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    _customThemeName = null;
    final prefs = await SharedPreferences.getInstance();
    String theme;
    switch (themeMode) {
      case ThemeMode.light:
        theme = 'Light';
        break;
      case ThemeMode.dark:
        theme = 'Dark';
        break;
      default:
        theme = 'System Default';
    }
    await prefs.setString('selected_theme', theme);
    notifyListeners();
  }

  Future<void> setCustomTheme(String themeName) async {
    _customThemeName = themeName;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', themeName);
    notifyListeners();
  }
}