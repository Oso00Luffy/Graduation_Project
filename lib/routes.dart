import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/encrypt_message_screen.dart';
import 'screens/decrypt_message_screen.dart';
import 'screens/encrypt_image_screen.dart';
import 'screens/decrypt_image_screen.dart';
import 'screens/profile_screen.dart'; // Import ProfileScreen

final Map<String, WidgetBuilder> routes = {
  '/': (context) => HomeScreen(isDarkMode: false, toggleTheme: (value) {}),
  '/settings': (context) => SettingsScreen(isDarkMode: false, toggleTheme: (value) {}),
  '/encrypt-message': (context) => EncryptMessageScreen(),
  '/decrypt-message': (context) => DecryptMessageScreen(prefilledEncryptedText: '',),
  '/encrypt-image': (context) => EncryptImageScreen(),
  '/decrypt-image': (context) => DecryptImageScreen(),
  '/profile': (context) => ProfileScreen(), // Add ProfileScreen route
};