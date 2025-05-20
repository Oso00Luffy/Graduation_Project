import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

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
    {'name': 'Gold & Purple', 'themeMode': null},
    {'name': 'Pink & Blue-Gray', 'themeMode': null},
    {'name': 'System Default', 'themeMode': ThemeMode.system},
  ];

  // Migrated settings from ProfileScreen
  int _autoLogoutMinutes = 30;
  bool _notifications = true;
  bool _biometrics = false;
  bool _twoFactorEnabled = false;

  @override
  void initState() {
    super.initState();
    _selectedTheme = 'System Default';
    _loadThemePreference();
    _loadAuthSettings(); // Load migrated settings
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getString('selected_theme') ?? 'System Default';
      _autoLogoutMinutes = prefs.getInt('auto_logout_minutes') ?? 30;
      _notifications = prefs.getBool('notifications_enabled') ?? true;
      _biometrics = prefs.getBool('biometrics_enabled') ?? false;
    });
  }

  Future<void> _saveThemePreference(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_theme', theme);
  }

  Future<void> _saveAutoLogoutMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('auto_logout_minutes', minutes);
  }

  Future<void> _saveNotificationPref(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<void> _saveBiometricsPref(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometrics_enabled', enabled);
  }

  void _onThemeChanged(String? newTheme) {
    if (newTheme == null) return;
    setState(() {
      _selectedTheme = newTheme;
    });
    _saveThemePreference(newTheme);
    _applyTheme(newTheme);
  }

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

  Future<void> _loadAuthSettings() async {
    // Simulate async loading for 2FA, etc.
    await Future.delayed(const Duration(milliseconds: 200));
    setState(() {
      _twoFactorEnabled = false; // Replace with your real 2FA status
    });
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: "Graduation Project",
      applicationVersion: "1.0.0",
      applicationLegalese: "© 2025 Your Name",
      children: [
        const SizedBox(height: 10),
        const Text("A secure image and message encryption app for graduation project."),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Appearance',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
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
          const SizedBox(height: 24),
          const Divider(),
          const Text(
            'Security',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            value: _twoFactorEnabled,
            title: const Text('Two-Factor Authentication'),
            onChanged: (val) async {
              // Replace with actual logic for enabling/disabling 2FA
              setState(() => _twoFactorEnabled = val);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('2FA ${val ? "enabled" : "disabled"} (mocked)')),
              );
            },
            secondary: Icon(
              _twoFactorEnabled ? Icons.verified_user : Icons.security,
              color: _twoFactorEnabled ? Colors.green : Colors.teal[600],
            ),
          ),
          SwitchListTile(
            value: _biometrics,
            title: const Text('Biometric Authentication'),
            onChanged: (v) {
              setState(() => _biometrics = v);
              _saveBiometricsPref(v);
              // TODO: Add biometrics logic
            },
            secondary: const Icon(Icons.fingerprint),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const Text(
            'Session',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ListTile(
            title: const Text("Logout after inactivity (minutes)"),
            trailing: DropdownButton<int>(
              value: _autoLogoutMinutes,
              items: [5, 10, 15, 30, 60, 120]
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.toString())))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _autoLogoutMinutes = v);
                _saveAutoLogoutMinutes(v ?? 30);
              },
            ),
            leading: const Icon(Icons.timer),
          ),
          SwitchListTile(
            value: _notifications,
            title: const Text('Enable Notifications'),
            onChanged: (v) {
              setState(() => _notifications = v);
              _saveNotificationPref(v);
              // TODO: Add notification logic
            },
            secondary: const Icon(Icons.notifications_active),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const Text(
            'Legal & Info',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text("About"),
            onTap: _showAboutDialog,
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text("Privacy Policy"),
            onTap: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Privacy Policy"),
                  content: const Text(
                    "Your data is encrypted and stays on your device. We do not collect or share any user data.",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Close"),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          if (user != null)
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text("Log Out"),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, '/');
                }
              },
            ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              "Version 1.0.0",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}