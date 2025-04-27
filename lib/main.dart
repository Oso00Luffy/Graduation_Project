import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'routes.dart'; // <<== THIS IMPORTS YOUR ROUTES MAP
import 'screens/firebase_options.dart';
import 'screens/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

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

  static const Color aquaBlue = Color(0xFF1ECBE1);

  @override
  Widget build(BuildContext context) {
    final ThemeData baseTheme = isDarkMode ? ThemeData.dark() : ThemeData.light();
    return MaterialApp(
      title: 'Crypto App',
      theme: baseTheme.copyWith(
        primaryColor: aquaBlue,
        colorScheme: baseTheme.colorScheme.copyWith(
          primary: aquaBlue,
          secondary: aquaBlue,
        ),
        scaffoldBackgroundColor: isDarkMode ? const Color(0xFF181A20) : const Color(0xFFE0FBFD),
        appBarTheme: AppBarTheme(
          backgroundColor: aquaBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: aquaBlue,
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
            borderSide: BorderSide(color: aquaBlue, width: 1.2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: aquaBlue, width: 2.0),
          ),
          labelStyle: TextStyle(color: aquaBlue),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: aquaBlue,
          foregroundColor: Colors.white,
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: aquaBlue,
        ),
      ),
      debugShowCheckedModeBanner: false,
      // <<<<< USE YOUR ROUTES MAP HERE!
      routes: routes,
      initialRoute: '/', // Optional: sets the starting route
      onGenerateRoute: null, // You can remove this if you aren't using it
    );
  }
}