import 'package:flutter/material.dart';
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
              Text(
                'Decrypted Message: $_decryptedMessage',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}