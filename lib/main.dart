import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/firebase_options.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return HomeScreen(
              isDarkMode: isDarkMode,
              toggleTheme: toggleTheme,
              selectedIndex: selectedIndex,
              onTabChanged: onTabChanged,
            );
          }
          // ...put your login screen here...
          return const Scaffold(
            body: Center(child: Text('Not signed in!')),
          );
        },
      ),
    );
  }
}