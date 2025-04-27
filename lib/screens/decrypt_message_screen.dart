import 'package:flutter/material.dart';
import '../services/decryption_service.dart'; // Import the decryption service

class DecryptionUI extends StatefulWidget {
  @override
  _DecryptionUIState createState() => _DecryptionUIState();
}

class _DecryptionUIState extends State<DecryptionUI> {
  final TextEditingController _encryptedMessageController = TextEditingController();
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  String _decryptedMessage = '';

  String _selectedAlgorithm = 'AES';

  void _decrypt() {
    final encryptedMessage = _encryptedMessageController.text;
    final key = _keyController.text;
    final privateKeyPem = _privateKeyController.text;

    if (encryptedMessage.isEmpty || key.isEmpty) {
      _showError('Please enter both the encrypted message and the key.');
      return;
    }

    try {
      String decryptedMessage = '';
      switch (_selectedAlgorithm) {
        case 'AES':
          decryptedMessage = DecryptionService.decryptAES(encryptedMessage, key);
          break;
        case 'RSA':
          if (privateKeyPem.isEmpty) {
            _showError('Please enter the private key for RSA decryption.');
            return;
          }
          final privateKey = DecryptionService.parsePrivateKey(privateKeyPem);
          decryptedMessage = DecryptionService.decryptRSA(encryptedMessage, privateKey);
          break;
        case 'ChaCha20':
          decryptedMessage = DecryptionService.decryptChaCha20(encryptedMessage, key);
          break;
        case 'Hybrid':
          if (privateKeyPem.isEmpty) {
            _showError('Please enter both AES and ChaCha20 keys for Hybrid decryption.');
            return;
          }
          final chaChaKey = privateKeyPem;
          decryptedMessage = DecryptionService.hybridDecrypt(encryptedMessage, key, chaChaKey);
          break;
        default:
          _showError('Invalid algorithm selected.');
          return;
      }

      setState(() {
        _decryptedMessage = decryptedMessage;
      });
    } catch (e) {
      _showError('Decryption failed: $e');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textFieldDecoration = InputDecoration(
      labelStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Decryption'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _selectedAlgorithm,
                decoration: textFieldDecoration.copyWith(
                  labelText: 'Select Algorithm',
                ),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedAlgorithm = newValue!;
                  });
                },
                items: ['AES', 'RSA', 'ChaCha20', 'Hybrid']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value, style: TextStyle(fontSize: 16)),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              TextField(
                controller: _encryptedMessageController,
                decoration: textFieldDecoration.copyWith(
                  labelText: 'Encrypted Message',
                ),
                maxLines: 3,
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 16),

              TextField(
                controller: _keyController,
                decoration: textFieldDecoration.copyWith(
                  labelText: _selectedAlgorithm == 'Hybrid' ? 'AES Key' : 'Key',
                ),
                style: TextStyle(fontSize: 16, color: Colors.black),
              ),
              SizedBox(height: 16),

              if (_selectedAlgorithm == 'RSA' || _selectedAlgorithm == 'Hybrid')
                TextField(
                  controller: _privateKeyController,
                  decoration: textFieldDecoration.copyWith(
                    labelText: _selectedAlgorithm == 'RSA'
                        ? 'Private Key (RSA)'
                        : 'ChaCha20 Key (for Hybrid)',
                  ),
                  maxLines: 5,
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Colors.blue,
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _decrypt,
                child: Text('Decrypt'),
              ),
              SizedBox(height: 24),

              if (_decryptedMessage.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Decrypted Message:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SelectableText(
                        _decryptedMessage,
                        style: TextStyle(color: Colors.green, fontSize: 16),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
