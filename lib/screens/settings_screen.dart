import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _darkMode;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  void _toggleDarkMode(bool? value) async {
    if (value == null) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _darkMode = value;
    });
    prefs.setBool('dark_mode', value);
    // Call the function passed from MyApp
    final parentState = ModalRoute.of(context)?.settings.arguments as Function(bool)?;

    if (parentState != null) {
      parentState(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: const Text('Dark Mode'),
            trailing: Switch(
              value: _darkMode,
              onChanged: _toggleDarkMode,
              activeColor: Colors.teal,
            ),
          ),
          const Divider(),
          // Add more settings options here if needed
        ],
      ),
    );
  }
}