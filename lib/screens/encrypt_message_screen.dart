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
  RSAPublicKey? _publicKey;
  bool _isLoading = false; // For loading indicator

  // New: track if key is being generated separately
  bool _isKeyGenerating = false;

  Future<void> _generateRSAKeysAsync() async {
    setState(() {
      _isKeyGenerating = true;
      _encryptedMessage = null;
    });
    await Future.delayed(const Duration(milliseconds: 100)); // Let UI update
    // Use a smaller key for web demo!
    final keyPair = await EncryptionService.generateRSAKeyPairAsync(bitLength: 512); // <-- 512 for demo
    setState(() {
      _publicKey = keyPair['publicKey'];
      _isKeyGenerating = false;
    });
  }

  Future<void> _encryptMessage() async {
    final message = _messageController.text;
    final key = _keyController.text;

    if (message.isEmpty) {
      setState(() {
        _encryptedMessage = 'Please enter a message.';
      });
      return;
    }

    if (selectedEncryptionType != 'AES' && _publicKey == null) {
      setState(() {
        _encryptedMessage = 'RSA Public Key is not ready. Please generate a key first.';
      });
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 100)); // Let spinner show

    String result;
    switch (selectedEncryptionType) {
      case 'AES':
        if (key.isEmpty) {
          result = 'Please enter an AES key.';
        } else {
          result = await EncryptionService.encryptAESAsync(message, key);
        }
        break;
      case 'RSA':
        result = await EncryptionService.encryptRSAAsync(message, _publicKey!);
        break;
      case 'Hybrid':
        result = await EncryptionService.hybridEncryptAsync(message, _publicKey!);
        break;
      default:
        result = 'Unknown encryption type.';
    }

    setState(() {
      _encryptedMessage = result;
      _isLoading = false;
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
        child: _isLoading || _isKeyGenerating
            ? Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(_isKeyGenerating ? "Generating RSA Key..." : "Encrypting...")
          ],
        ))
            : SingleChildScrollView(
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
              if (selectedEncryptionType != 'AES') ...[
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _publicKey == null
                            ? 'No RSA Key generated yet.'
                            : 'RSA Key ready (bit length: ${_publicKey!.modulus!.bitLength})',
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isKeyGenerating ? null : _generateRSAKeysAsync,
                      child: Text('Generate RSA Key'),
                    ),
                  ],
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