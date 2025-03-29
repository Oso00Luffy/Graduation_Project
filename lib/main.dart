import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = (prefs.getBool('isDarkMode') ?? false);
    });
  }

  _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('isDarkMode', value);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SCC - Secure - Chat - Crypt',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: HomeScreen(isDarkMode: _isDarkMode, toggleTheme: _toggleTheme),
      routes: {
        '/settings': (context) => SettingsScreen(isDarkMode: _isDarkMode, toggleTheme: _toggleTheme),
      },
    );
  }
}