import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system; // Default to system theme

  ThemeMode get themeMode => _themeMode;

  // Load theme preference from SharedPreferences
  Future<void> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = prefs.getString('selected_theme') ?? 'System Default';

    switch (theme) {
      case 'Light':
        _themeMode = ThemeMode.light;
        break;
      case 'Dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  // Save theme preference to SharedPreferences
  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
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
    notifyListeners(); // Notify listeners to rebuild widgets with the new theme
  }
}