import 'package:flutter/material.dart';
import '../services/encryption_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class EncryptMessageScreen extends StatefulWidget {
  @override
  _EncryptMessageScreenState createState() => _EncryptMessageScreenState();
}

class _EncryptMessageScreenState extends State<EncryptMessageScreen> {
  final _messageController = TextEditingController();
  final _keyController = TextEditingController();
  String? _encryptedMessage;

  void _encryptMessage() {
    final message = _messageController.text;
    final key = _keyController.text;

    if (message.isNotEmpty && key.isNotEmpty) {
      final encryptedMessage = EncryptionService.encryptMessage(message, key);
      setState(() {
        _encryptedMessage = encryptedMessage;
      });
    } else {
      setState(() {
        _encryptedMessage = 'Please enter both a message and a key.';
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
        title: Text('Encrypt Message'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            CustomTextField(
              controller: _messageController,
              hintText: 'Enter your message',
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _keyController,
              hintText: 'Enter your key',
            ),
            SizedBox(height: 16),
            CustomButton(
              text: 'Encrypt',
              onPressed: _encryptMessage,
            ),
            SizedBox(height: 16),
            if (_encryptedMessage != null)
              Text(
                'Encrypted Message: $_encryptedMessage',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}