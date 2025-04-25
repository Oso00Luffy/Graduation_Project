import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isDarkMode = false;

  void toggleTheme(bool value) {
    setState(() {
      isDarkMode = value;
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
          background: isDarkMode ? const Color(0xFF181A20) : const Color(0xFFE0FBFD),
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasData && snapshot.data != null) {
            return HomeScreen(
              isDarkMode: isDarkMode,
              toggleTheme: toggleTheme,
            );
          }
          return LoginScreen();
        },
      ),
    );
  }
}