import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/settings_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/auth_gate.dart'; // <--- Add this import

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCB5lcD3jindwA1H4_Bao6ED5ZuMSxN4bo",
        authDomain: "sccapp-c3165.firebaseapp.com",
        projectId: "sccapp-c3165",
        storageBucket: "sccapp-c3165.firebasestorage.app",
        messagingSenderId: "76800991751",
        appId: "1:76800991751:web:eb9a35d5e2c3f9c3a380a2",
        measurementId: "G-CEGQ06WT91",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
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
      debugShowCheckedModeBanner: false,
      title: 'SCC - Secure - Chat - Crypt',
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      home: AuthGate(isDarkMode: _isDarkMode, toggleTheme: _toggleTheme),
      routes: {
        '/settings': (context) => SettingsScreen(isDarkMode: _isDarkMode, toggleTheme: _toggleTheme),
        '/intro': (context) => IntroScreen(),
      },
    );
  }
}