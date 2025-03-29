import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;

  const SettingsScreen({required this.isDarkMode, required this.toggleTheme});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Dark Mode'),
            trailing: Switch(
              value: widget.isDarkMode,
              onChanged: (value) {
                setState(() {
                  widget.toggleTheme(value);
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}