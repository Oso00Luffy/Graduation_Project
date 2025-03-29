import 'package:flutter/material.dart';

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
                // Navigate to Encrypt/Decrypt Messages Screen
              },
              child: Text('Encrypt/Decrypt Messages'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to Encrypt/Decrypt Images Screen
              },
              child: Text('Encrypt/Decrypt Images'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to File Sender Screen
              },
              child: Text('File Sender'),
            ),
            ElevatedButton(
              onPressed: () {
                // Navigate to Secure Chat Screen
              },
              child: Text('Secure Chat'),
            ),
          ],
        ),
      ),
    );
  }
}