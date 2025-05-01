import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  final Function(bool) toggleTheme;
  final int selectedIndex;
  final Function(int) onTabChanged;

  const AuthGate({
    Key? key,
    required this.toggleTheme,
    required this.selectedIndex,
    required this.onTabChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

    if (snapshot.hasData) {
    return HomeWrapper(
    isDarkMode: true, // Get from state
    toggleTheme: (value) {}, // Get from state
    );
    } else {
    return const LoginScreen();
    }
      },
    );
  }
  }