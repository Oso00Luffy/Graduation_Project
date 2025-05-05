import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'screens/firebase_options.dart';
import 'theme/theme_provider.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cross-platform safe Firebase initialization
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_V3_SITE_KEY'), // Replace with your actual key!
    );
  } else {
    await Firebase.initializeApp(
      name: 'SCC_App',
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
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
  const MyApp({super.key});

  static const Color aquaBlue = Color(0xFF1ECBE1);

  ThemeData _getCustomTheme(String? name) {
    switch (name) {
      case 'AMOLED':
        return ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          cardColor: const Color(0xFF121212),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
            titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            elevation: 0,
          ),
        );
      case 'Blue':
        return ThemeData.dark().copyWith(
          scaffoldBackgroundColor: const Color(0xFF0A2540),
          cardColor: const Color(0xFF133B5C),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Color(0xFFB3E5FC)),
            titleLarge: TextStyle(color: Color(0xFFB3E5FC), fontWeight: FontWeight.bold),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF133B5C),
            foregroundColor: Color(0xFFB3E5FC),
            elevation: 0,
          ),
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF2196F3),
            secondary: Color(0xFF03A9F4),
          ).copyWith(background: const Color(0xFF0A2540)),
        );
      case 'Sepia':
        return ThemeData.light().copyWith(
          scaffoldBackgroundColor: const Color(0xFFF5E9DA),
          cardColor: const Color(0xFFD2B48C),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Color(0xFF5B4636)),
            titleLarge: TextStyle(color: Color(0xFF5B4636), fontWeight: FontWeight.bold),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFD2B48C),
            foregroundColor: Color(0xFF5B4636),
            elevation: 0,
          ),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF8B6F43),
            secondary: Color(0xFFC9B18B),
          ).copyWith(background: const Color(0xFFF5E9DA)),
        );
      default:
        return ThemeData.light();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    final ThemeData betterDarkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF181A20),
      canvasColor: const Color(0xFF1A1A1A),
      cardColor: const Color(0xFF232323),
      dialogBackgroundColor: const Color(0xFF232323),
      primaryColor: aquaBlue,
      colorScheme: ColorScheme.dark(
        primary: aquaBlue,
        secondary: aquaBlue,
        surface: const Color(0xFF232323),
        background: const Color(0xFF181A20),
        error: const Color(0xFFcf6679),
        onPrimary: const Color(0xFF181A20),
        onSecondary: const Color(0xFF181A20),
        onSurface: const Color(0xFFE0E0E0),
        onBackground: const Color(0xFFE0E0E0),
        onError: const Color(0xFF232323),
        brightness: Brightness.dark,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFE0E0E0)),
        bodyMedium: TextStyle(color: Color(0xFFB0B0B0)),
        titleLarge: TextStyle(color: Color(0xFFFFFFFF), fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: Color(0xFFE0E0E0)),
        labelLarge: TextStyle(color: Color(0xFF1ECBE1)),
      ),
      dividerColor: const Color(0xFF333333),
      iconTheme: const IconThemeData(color: Color(0xFFB0B0B0)),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A1A1A),
        foregroundColor: Color(0xFFE0E0E0),
        elevation: 0,
        titleTextStyle: TextStyle(color: Color(0xFFE0E0E0), fontSize: 20, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF232323),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        hintStyle: const TextStyle(color: Color(0xFF888888)),
        labelStyle: const TextStyle(color: Color(0xFFB0B0B0)),
      ),
    );

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
      darkTheme: betterDarkTheme,
      themeMode: (themeProvider.customThemeName != null)
          ? ThemeMode.light // Use base light for custom themes
          : themeProvider.themeMode,
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      builder: (context, child) {
        return themeProvider.customThemeName != null
            ? Theme(
          data: _getCustomTheme(themeProvider.customThemeName),
          child: child!,
        )
            : child!;
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

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