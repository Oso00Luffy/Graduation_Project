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
  String selectedEncryptionType = 'AES'; // Default encryption type

  void _decryptMessage() {
    final encryptedMessage = _messageController.text;
    final key = _keyController.text;

    if (encryptedMessage.isNotEmpty && key.isNotEmpty) {
      String decryptedMessage;

      if (selectedEncryptionType == 'AES') {
        decryptedMessage = EncryptionService.decryptAES(encryptedMessage, key);
      } else if (selectedEncryptionType == 'RSA') {
        decryptedMessage = EncryptionService.decryptRSA(encryptedMessage, EncryptionService.privateKey);
      } else if (selectedEncryptionType == 'ChaCha20') {
        decryptedMessage = EncryptionService.decryptChaCha20(encryptedMessage, key);
      } else if (selectedEncryptionType == 'ECC') {
        decryptedMessage = EncryptionService.decryptECC(encryptedMessage, key);
      } else {
        decryptedMessage = 'Unknown encryption type selected.';
      }

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
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // Dropdown to select encryption type
              DropdownButton<String>(
                value: selectedEncryptionType,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedEncryptionType = newValue!;
                  });
                },
                items: <String>['AES', 'RSA', 'ChaCha20', 'ECC']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              // Input field for encrypted message
              CustomTextField(
                controller: _messageController,
                hintText: 'Enter the encrypted message',
              ),
              SizedBox(height: 16),

              // Input field for key
              CustomTextField(
                controller: _keyController,
                hintText: 'Enter the key',
              ),
              SizedBox(height: 16),

              // Button to trigger decryption
              CustomButton(
                text: 'Decrypt',
                onPressed: _decryptMessage,
              ),
              SizedBox(height: 16),

              // Display decrypted message
              if (_decryptedMessage != null)
                SelectableText(
                  'Decrypted Message:\n$_decryptedMessage',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
