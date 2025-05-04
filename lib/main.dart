import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:graduation_project/screens/firebase_options.dart';
import 'theme_provider.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Prevent duplicate initialization (especially for web hot restart)
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider()..loadThemePreference(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const Color aquaBlue = Color(0xFF1ECBE1); // Define Aqua Blue color

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      title: 'Crypto App',
      theme: ThemeData.light().copyWith(
        primaryColor: aquaBlue,
        scaffoldBackgroundColor: const Color(0xFFE0FBFD),
        appBarTheme: const AppBarTheme(
          backgroundColor: aquaBlue,
          foregroundColor: Colors.white,
        ),
        colorScheme: ThemeData.light().colorScheme.copyWith(
          primary: aquaBlue,
          secondary: aquaBlue,
        ),
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: aquaBlue,
        scaffoldBackgroundColor: const Color(0xFF121212),
        appBarTheme: const AppBarTheme(
          backgroundColor: aquaBlue,
          foregroundColor: Colors.white,
        ),
        colorScheme: ThemeData.dark().colorScheme.copyWith(
          primary: aquaBlue,
          secondary: aquaBlue,
        ),
      ),
      themeMode: themeProvider.themeMode, // Dynamically switch theme
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasData) {
          return const HomeScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}