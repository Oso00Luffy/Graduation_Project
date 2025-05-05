import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _selectedTheme; // Current selected theme
  final List<Map<String, dynamic>> _availableThemes = [
    {'name': 'Light', 'themeMode': ThemeMode.light},
    {'name': 'Dark', 'themeMode': ThemeMode.dark},
    {'name': 'AMOLED', 'themeMode': null},
    {'name': 'Blue', 'themeMode': null},
    {'name': 'Sepia', 'themeMode': null},
    {'name': 'System Default', 'themeMode': ThemeMode.system},
  ];

  @override
  void initState() {
    super.initState();
    _selectedTheme = 'System Default';
    _loadThemePreference();
  }

  // Load saved user theme preference
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getString('selected_theme') ?? 'System Default';
    });
  }

  // Save the selected theme to SharedPreferences
  Future<void> _saveThemePreference(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', theme);
  }

  // Handle theme change
  void _onThemeChanged(String? newTheme) {
    if (newTheme == null) return;
    setState(() {
      _selectedTheme = newTheme;
    });
    _saveThemePreference(newTheme);

    // Apply the theme globally (via ThemeProvider)
    _applyTheme(newTheme);
  }

  // Apply the selected theme globally
  void _applyTheme(String theme) {
    final selectedTheme = _availableThemes.firstWhere(
          (item) => item['name'] == theme,
      orElse: () => _availableThemes[5], // Default to 'System Default'
    );

    if (selectedTheme['themeMode'] != null) {
      context.read<ThemeProvider>().setThemeMode(selectedTheme['themeMode']);
    } else {
      context.read<ThemeProvider>().setCustomTheme(theme);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Theme',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            DropdownButton<String>(
              value: _selectedTheme,
              icon: const Icon(Icons.arrow_downward),
              elevation: 16,
              style: const TextStyle(color: Colors.teal),
              underline: Container(
                height: 2,
                color: Colors.teal,
              ),
              onChanged: _onThemeChanged,
              items: _availableThemes.map<DropdownMenuItem<String>>((theme) {
                return DropdownMenuItem<String>(
                  value: theme['name'],
                  child: Text(theme['name']),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            const Divider(),
            const Text(
              'Other Settings',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            // Add other settings here
          ],
        ),
      ),
    );
  }
}