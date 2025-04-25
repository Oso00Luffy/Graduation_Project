import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'screens/settings_screen.dart';
import 'screens/intro_screen.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCB5lcD3jindwA1H4_Bao6ED5ZuMSxN4bo",
        authDomain: "sccapp-c3165.firebaseapp.com",
        projectId: "sccapp-c3165",
        storageBucket: "sccapp-c3165.appspot.com",
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

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeProvider() {
    _loadTheme();
  }

  void _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _isDarkMode = (prefs.getBool('isDarkMode') ?? false);
    notifyListeners();
  }

  void toggleTheme(bool value) async {
    _isDarkMode = value;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', value);
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  final ThemeProvider themeProvider = ThemeProvider();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeProvider,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SCC App',
          theme: themeProvider.isDarkMode ? ThemeData.dark() : ThemeData.light(),
          home: AuthGate(
            isDarkMode: themeProvider.isDarkMode,
            toggleTheme: themeProvider.toggleTheme,
          ),
          routes: {
            '/settings': (context) => SettingsScreen(
              isDarkMode: themeProvider.isDarkMode,
              toggleTheme: themeProvider.toggleTheme,
            ),
            '/intro': (context) => IntroScreen(),
          },
        );
      },
    );
  }
}