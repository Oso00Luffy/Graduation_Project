import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static const Color aquaBlue = Color(0xFF1ECBE1);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;
  int selectedIndex = 0;

  void toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
    });
  }

  void onTabChanged(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Future<void> _saveDarkModePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('dark_mode', value);
  }

  Future<void> _loadDarkModePreference() async {
    final prefs = await SharedPreferences.getInstance();
    bool savedMode = prefs.getBool('dark_mode') ?? false;
    setState(() {
      isDarkMode = savedMode;
    });
  }

  @override
  void initState() {
    super.initState();
    _loadDarkModePreference();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData baseTheme = ThemeData.light();
    final ThemeData lightTheme = baseTheme.copyWith(
      primaryColor: MyApp.aquaBlue,
      colorScheme: baseTheme.colorScheme.copyWith(
        primary: MyApp.aquaBlue,
        secondary: MyApp.aquaBlue,
      ),
      scaffoldBackgroundColor: const Color(0xFFE0FBFD),
      appBarTheme: AppBarTheme(
        backgroundColor: MyApp.aquaBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MyApp.aquaBlue,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyApp.aquaBlue, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyApp.aquaBlue, width: 2.0),
        ),
        labelStyle: TextStyle(color: MyApp.aquaBlue),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MyApp.aquaBlue,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MyApp.aquaBlue,
      ),
    );

    final ThemeData darkTheme = ThemeData.dark().copyWith(
      primaryColor: MyApp.aquaBlue,
      colorScheme: ThemeData.dark().colorScheme.copyWith(
        primary: MyApp.aquaBlue,
        secondary: MyApp.aquaBlue,
      ),
      scaffoldBackgroundColor: const Color(0xFF191C1D),
      appBarTheme: AppBarTheme(
        backgroundColor: MyApp.aquaBlue,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MyApp.aquaBlue,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyApp.aquaBlue, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: MyApp.aquaBlue, width: 2.0),
        ),
        labelStyle: TextStyle(color: MyApp.aquaBlue),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MyApp.aquaBlue,
        foregroundColor: Colors.white,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MyApp.aquaBlue,
      ),
    );

    return MaterialApp(
      title: 'Crypto App',
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          if (snapshot.hasData) {
            return HomeWrapper(
              isDarkMode: isDarkMode,
              toggleTheme: toggleTheme,
            );
          } else {
            return const LoginScreen();
          }
        },
      ),
    );
  }
}

class HomeWrapper extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;

  const HomeWrapper({
    Key? key,
    required this.isDarkMode,
    required this.toggleTheme,
  }) : super(key: key);

  @override
  State<HomeWrapper> createState() => _HomeWrapperState();
}

class _HomeWrapperState extends State<HomeWrapper> {
  int selectedIndex = 0;

  void onTabChanged(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HomeScreen(
      isDarkMode: widget.isDarkMode,
      toggleTheme: widget.toggleTheme,
      selectedIndex: selectedIndex,
      onTabChanged: onTabChanged,
    );
  }
}