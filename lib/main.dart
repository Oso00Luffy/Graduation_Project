import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Import the routes configuration
import 'screens/home_screen.dart'; // Import HomeScreen
import 'screens/settings_screen.dart'; // Import SettingsScreen
import 'screens/intro_screen.dart'; // Import IntroScreen

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
    print("Theme loaded: Dark Mode = $_isDarkMode");
  }

  _toggleTheme(bool value) {
    setState(() {
      _isDarkMode = value;
      SharedPreferences.getInstance().then((prefs) {
        prefs.setBool('isDarkMode', value);
      });
      print("Theme toggled: Dark Mode = $_isDarkMode");
    });
  }

  @override
  Widget build(BuildContext context) {
    print("Building MaterialApp with Dark Mode = $_isDarkMode");
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SCC - Secure - Chat - Crypt',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      routes: {
        '/': (context) => IntroScreen(),
        '/home': (context) => HomeScreen(isDarkMode: _isDarkMode, toggleTheme: _toggleTheme),
        '/settings': (context) => SettingsScreen(isDarkMode: _isDarkMode, toggleTheme: _toggleTheme),
      },
      initialRoute: '/',
    );
  }
}