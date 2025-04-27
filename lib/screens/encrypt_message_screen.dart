import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/encryption_service.dart';
import 'package:pointycastle/export.dart' as pc;

enum EncryptionType { AES, RSA, ChaCha20, Hybrid }

class EncryptionUI extends StatefulWidget {
  @override
  _EncryptionUIState createState() => _EncryptionUIState();
}

class _EncryptionUIState extends State<EncryptionUI> {
  EncryptionType _selectedEncryption = EncryptionType.AES;

  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _aesKeyController = TextEditingController();
  final TextEditingController _chaChaKeyController = TextEditingController();
  final TextEditingController _chaChaNonceController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();

  String _encryptedMessage = '';
  bool _isGeneratingKeys = false;

  void _encrypt() async {
    final message = _messageController.text;
    if (message.isEmpty) {
      _showError('Please enter a message.');
      return;
    }

    try {
      String encrypted = '';
      switch (_selectedEncryption) {
        case EncryptionType.AES:
          if (_aesKeyController.text.isEmpty) {
            _showError('Please generate or enter an AES key.');
            return;
          }
          encrypted = EncryptionService.encryptAES(message, _aesKeyController.text);
          break;
        case EncryptionType.RSA:
          if (_publicKeyController.text.isEmpty) {
            _showError('Please generate or enter an RSA public key.');
            return;
          }
          final publicKey = EncryptionService.parsePublicKeyFromPem(_publicKeyController.text);
          encrypted = EncryptionService.encryptRSA(message, publicKey);
          break;
        case EncryptionType.ChaCha20:
          if (_chaChaKeyController.text.isEmpty || _chaChaNonceController.text.isEmpty) {
            _showError('Please generate or enter a ChaCha20 key and nonce.');
            return;
          }
          encrypted = EncryptionService.encryptChaCha20(
              message, _chaChaKeyController.text, nonceBase64: _chaChaNonceController.text);
          break;
        case EncryptionType.Hybrid:
          if (_aesKeyController.text.isEmpty || _chaChaKeyController.text.isEmpty || _chaChaNonceController.text.isEmpty) {
            _showError('Please generate or enter AES and ChaCha20 keys and nonce.');
            return;
          }
          encrypted = EncryptionService.hybridEncrypt(
              message, _aesKeyController.text, _chaChaKeyController.text);
          break;
      }

      setState(() {
        _encryptedMessage = encrypted;
      });
    } catch (e) {
      _showError('Encryption failed: $e');
    }
  }

  void _generateAESKey() {
    final aesKey = EncryptionService.generateAESKey();
    setState(() {
      _aesKeyController.text = aesKey;
    });
  }

  void _generateChaCha20Key() {
    final chaChaKeys = EncryptionService.generateChaCha20Key();
    setState(() {
      _chaChaKeyController.text = chaChaKeys['key']!;
      _chaChaNonceController.text = chaChaKeys['nonce']!;
    });
  }

  void _generateRSAKeys() async {
    setState(() {
      _isGeneratingKeys = true;
    });

    try {
      final pair = await EncryptionService.generateRSAKeyPair();

      final publicKeyPem = EncryptionService.encodePublicKeyToPem(pair.publicKey);
      final privateKeyPem = EncryptionService.encodePrivateKeyToPem(pair.privateKey);

      setState(() {
        _publicKeyController.text = publicKeyPem;
        _privateKeyController.text = privateKeyPem;
      });
    } catch (e) {
      _showError('Failed to generate RSA keys: $e');
    } finally {
      setState(() {
        _isGeneratingKeys = false;
      });
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  ElevatedButton _buildGenerateKeyButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
    bool isDisabled = false,
  }) {
    return ElevatedButton.icon(
      onPressed: isDisabled ? null : onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDisabled ? Colors.grey : Colors.teal,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
        elevation: 4,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Encryption UI'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Select Encryption Type',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButton<EncryptionType>(
                        value: _selectedEncryption,
                        isExpanded: true,
                        items: EncryptionType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.toString().split('.').last),
                          );
                        }).toList(),
                        onChanged: (type) {
                          setState(() {
                            _selectedEncryption = type!;
                            _encryptedMessage = '';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Message to Encrypt',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Enter your message',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedEncryption == EncryptionType.AES || _selectedEncryption == EncryptionType.Hybrid)
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'AES Key',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _aesKeyController,
                          decoration: const InputDecoration(
                            labelText: 'AES Key (32 characters)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildGenerateKeyButton(
                          onPressed: _generateAESKey,
                          label: 'Generate AES Key',
                          icon: Icons.vpn_key,
                        ),
                      ],
                    ),
                  ),
                ),
              if (_selectedEncryption == EncryptionType.RSA)
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'RSA Keys',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _publicKeyController,
                          decoration: const InputDecoration(
                            labelText: 'Public Key (PEM)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _privateKeyController,
                          decoration: const InputDecoration(
                            labelText: 'Private Key (PEM)',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 8),
                        _buildGenerateKeyButton(
                          onPressed: _generateRSAKeys,
                          label: 'Generate RSA Keys',
                          icon: Icons.vpn_key,
                          isDisabled: _isGeneratingKeys,
                        ),
                      ],
                    ),
                  ),
                ),
              if (_selectedEncryption == EncryptionType.ChaCha20 || _selectedEncryption == EncryptionType.Hybrid)
                Card(
                  elevation: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ChaCha20 Keys',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _chaChaKeyController,
                          decoration: const InputDecoration(
                            labelText: 'ChaCha20 Key',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _chaChaNonceController,
                          decoration: const InputDecoration(
                            labelText: 'ChaCha20 Nonce',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildGenerateKeyButton(
                          onPressed: _generateChaCha20Key,
                          label: 'Generate ChaCha20 Keys',
                          icon: Icons.vpn_key,
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _encrypt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                  child: const Text(
                    'Encrypt Message',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              if (_encryptedMessage.isNotEmpty)
                Card(
                  elevation: 8,
                  color: Colors.white,
                  margin: const EdgeInsets.only(top: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Encrypted Message',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.deepPurple,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.deepPurple, width: 1.5),
                          ),
                          child: SelectableText(
                            _encryptedMessage,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: () async {
                            await Clipboard.setData(ClipboardData(text: _encryptedMessage));
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text(
                                  'Copied!',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.deepPurple,
                                  ),
                                ),
                                content: const Text(
                                  'The encrypted message has been copied to clipboard.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy, color: Colors.white),
                          label: const Text(
                            'Copy Message',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
