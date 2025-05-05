import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  String? _customThemeName; // Store custom theme name

  ThemeMode get themeMode => _themeMode;
  String? get customThemeName => _customThemeName;

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
        _themeMode = ThemeMode.light; // fallback, app will use custom theme
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