import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  final Function(bool) toggleTheme;
  final int selectedIndex;
  final Function(int) onTabChanged;

  const AuthGate({
    super.key,
    required this.toggleTheme,
    required this.selectedIndex,
    required this.onTabChanged,
  });

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
          return const LoginScreen();
        }

        // Add a fallback widget to handle cases where no conditions are met
        return const Scaffold(
          body: Center(
            child: Text("No user data available."),
          ),
        );
      },
    );
  }
}