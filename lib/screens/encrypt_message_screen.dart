import 'package:flutter/material.dart';
import '../services/encryption_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'package:pointycastle/asymmetric/api.dart';

class EncryptMessageScreen extends StatefulWidget {
  @override
  _EncryptMessageScreenState createState() => _EncryptMessageScreenState();
}

class _EncryptMessageScreenState extends State<EncryptMessageScreen> {
  final _messageController = TextEditingController();
  final _keyController = TextEditingController();
  String? _encryptedMessage;

  String selectedEncryptionType = 'AES'; // Default
  RSAPublicKey? _publicKey; // Make it nullable to handle initialization

  @override
  void initState() {
    super.initState();
    // Generate RSA keys for testing (you can later load real ones)
    final keyPair = EncryptionService.generateRSAKeyPair();
    setState(() {
      _publicKey = keyPair['publicKey']; // Initialize the public key
    });
  }

  void _encryptMessage() {
    final message = _messageController.text;
    final key = _keyController.text;

    if (message.isEmpty) {
      setState(() {
        _encryptedMessage = 'Please enter a message.';
      });
      return;
    }

    if (_publicKey == null) {
      setState(() {
        _encryptedMessage = 'RSA Public Key is not ready.';
      });
      return;
    }

    String result;

    switch (selectedEncryptionType) {
      case 'AES':
        if (key.isEmpty) {
          result = 'Please enter an AES key.';
        } else {
          result = EncryptionService.encryptAES(message, key);
        }
        break;
      case 'RSA':
        result = EncryptionService.encryptRSA(message, _publicKey!); // Use the public key
        break;
      case 'Hybrid':
        result = EncryptionService.hybridEncrypt(message, _publicKey!); // Use the public key
        break;
      default:
        result = 'Unknown encryption type.';
    }

    setState(() {
      _encryptedMessage = result;
    });
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
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              DropdownButton<String>(
                value: selectedEncryptionType,
                items: ['AES', 'RSA', 'Hybrid']
                    .map((type) => DropdownMenuItem(
                  value: type,
                  child: Text(type),
                ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedEncryptionType = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              CustomTextField(
                controller: _messageController,
                hintText: 'Enter your message',
              ),
              if (selectedEncryptionType == 'AES') ...[
                SizedBox(height: 16),
                CustomTextField(
                  controller: _keyController,
                  hintText: 'Enter your AES key',
                ),
              ],
              SizedBox(height: 16),
              CustomButton(
                text: 'Encrypt',
                onPressed: _encryptMessage,
              ),
              SizedBox(height: 16),
              if (_encryptedMessage != null)
                SelectableText(
                  'Encrypted Message:\n$_encryptedMessage',
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
