import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/login_screen.dart'; // NEW: import the login screen

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // NEW: initialize Firebase
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
      title: 'SCC App',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      routes: {
        '/': (context) => LoginScreen(), // NEW: Start with LoginScreen
        '/home': (context) => HomeScreen(isDarkMode: _isDarkMode, toggleTheme: _toggleTheme),
        '/settings': (context) => SettingsScreen(isDarkMode: _isDarkMode, toggleTheme: _toggleTheme),
        '/intro': (context) => IntroScreen(),
      },
      initialRoute: '/',
    );
  }
}