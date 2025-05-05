import 'package:flutter/material.dart';
import 'screens/encrypt_message_screen.dart';
import 'screens/decrypt_message_screen.dart';
import 'screens/encrypt_image_screen.dart';
import 'screens/decrypt_image_screen.dart';
import 'screens/file_sender_screen.dart';
import 'screens/chat_room_screen.dart';

// Only screens that are navigated to with Navigator.pushNamed should be here!
final Map<String, WidgetBuilder> routes = {
  '/encrypt-message': (context) => EncryptMessageScreen(),
  '/decrypt-message': (context) => DecryptMessageScreen(),
  '/encrypt-image': (context) => EncryptImageScreen(),
  '/decrypt-image': (context) => DecryptImageScreen(),
  '/file-sender': (context) => FileSenderScreen(),
  '/chat-rooms': (context) => const ChatRoomScreen(),
};