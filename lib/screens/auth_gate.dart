import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) toggleTheme;

  const AuthGate({required this.isDarkMode, required this.toggleTheme, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // User is signed in
          return HomeScreen(isDarkMode: isDarkMode, toggleTheme: toggleTheme);
        } else {
          // Not signed in
          return LoginScreen();
        }
      },
    );
  }
}