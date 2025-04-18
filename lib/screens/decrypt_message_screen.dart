import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import for Clipboard functionality
import '../services/encryption_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class DecryptMessageScreen extends StatefulWidget {
  @override
  _DecryptMessageScreenState createState() => _DecryptMessageScreenState();
}

class _DecryptMessageScreenState extends State<DecryptMessageScreen> {
  final _messageController = TextEditingController();
  final _keyController = TextEditingController();
  String? _decryptedMessage;

  void _decryptMessage() {
    final encryptedMessage = _messageController.text;
    final key = _keyController.text;

    if (encryptedMessage.isNotEmpty && key.isNotEmpty) {
      final decryptedMessage = EncryptionService.decryptMessage(encryptedMessage, key);
      setState(() {
        _decryptedMessage = decryptedMessage;
      });
    } else {
      setState(() {
        _decryptedMessage = 'Please enter both an encrypted message and a key.';
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  void _navigateToHome(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst); // Navigate back to Home
  }

  @override
  void dispose() {
    _messageController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Decrypt Message'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            CustomTextField(
              controller: _messageController,
              hintText: 'Enter the encrypted message',
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _keyController,
              hintText: 'Enter your key',
            ),
            SizedBox(height: 16),
            CustomButton(
              text: 'Decrypt',
              onPressed: _decryptMessage,
            ),
            SizedBox(height: 16),
            if (_decryptedMessage != null)
              Column(
                children: [
                  Text(
                    'Decrypted Message: $_decryptedMessage',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  CustomButton(
                    text: 'Copy to Clipboard',
                    onPressed: () => _copyToClipboard(_decryptedMessage!),
                  ),
                  SizedBox(height: 16),
                  CustomButton(
                    text: 'Go to Home',
                    onPressed: () => _navigateToHome(context),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}