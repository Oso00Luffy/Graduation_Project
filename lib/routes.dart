import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'screens/encrypt_decrypt_message_screen.dart';
import 'screens/encrypt_decrypt_image_screen.dart';
import 'screens/file_sender_screen.dart';
import 'screens/secure_chat_screen.dart';
import 'screens/settings_screen.dart';

final Map<String, WidgetBuilder> appRoutes = {
  '/': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
    print("HomeScreen args: $args");
    return HomeScreen(
      isDarkMode: args['isDarkMode'] ?? false,
      toggleTheme: args['toggleTheme'] ?? (bool value) {},
    );
  },
  '/encrypt-decrypt-message': (context) => EncryptDecryptMessageScreen(),
  '/encrypt-decrypt-image': (context) => EncryptDecryptImageScreen(),
  '/file-sender': (context) => FileSenderScreen(),
  '/secure-chat': (context) => SecureChatScreen(),
  '/settings': (context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>? ?? {};
    print("SettingsScreen args: $args");
    return SettingsScreen(
      isDarkMode: args['isDarkMode'] ?? false,
      toggleTheme: args['toggleTheme'] ?? (bool value) {},
    );
  },
};