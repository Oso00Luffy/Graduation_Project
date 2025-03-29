import 'package:flutter/material.dart';
import 'encrypt_decrypt_message_screen.dart';
import 'encrypt_decrypt_image_screen.dart';
import 'file_sender_screen.dart';
import 'secure_chat_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Encryption Services App'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EncryptDecryptMessageScreen()),
                );
              },
              child: Text('Encrypt/Decrypt Messages'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EncryptDecryptImageScreen()),
                );
              },
              child: Text('Encrypt/Decrypt Images'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => FileSenderScreen()),
                );
              },
              child: Text('File Sender'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SecureChatScreen()),
                );
              },
              child: Text('Secure Chat'),
            ),
          ],
        ),
      ),
    );
  }
}