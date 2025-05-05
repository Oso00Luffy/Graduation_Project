import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/encryption_service.dart';
import '../widgets/custom_text_field.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:basic_utils/basic_utils.dart';
import 'dart:convert';

class DecryptMessageScreen extends StatefulWidget {
  const DecryptMessageScreen({Key? key}) : super(key: key);

  @override
  State<DecryptMessageScreen> createState() => _DecryptMessageScreenState();
}

class _DecryptMessageScreenState extends State<DecryptMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _aesKeyController = TextEditingController();
  final TextEditingController _aesIvController = TextEditingController();
  final TextEditingController _chachaKeyController = TextEditingController();
  final TextEditingController _nonceController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  String? _decryptedMessage;
  bool _isLoading = false;
  bool _copied = false;

  final List<String> _encryptionTypes = ['AES', 'RSA', 'Hybrid', 'ChaCha20'];
  late String _selectedEncryptionType;

  @override
  void initState() {
    super.initState();
    _selectedEncryptionType = _encryptionTypes[0];
  }

  @override
  void dispose() {
    _messageController.dispose();
    _aesKeyController.dispose();
    _aesIvController.dispose();
    _chachaKeyController.dispose();
    _nonceController.dispose();
    _publicKeyController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  bool _isValidBase64(String key, int requiredBytes) {
    try {
      final bytes = base64.decode(key);
      return bytes.length == requiredBytes;
    } catch (_) {
      return false;
    }
  }

  Future<void> _decryptMessage() async {
    final encrypted = _messageController.text.trim();
    final aesKey = _aesKeyController.text.trim();
    final aesIV = _aesIvController.text.trim();
    final chaChaKey = _chachaKeyController.text.trim();
    final nonce = _nonceController.text.trim();
    final privateKeyPem = _privateKeyController.text.trim();
    String result;

    setState(() {
      _isLoading = true;
      _decryptedMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      if (encrypted.isEmpty) {
        result = 'Please enter the encrypted message.';
      } else if (_selectedEncryptionType == 'AES') {
        if (aesKey.isEmpty || aesIV.isEmpty) {
          result = 'Please enter AES key (base64, 44 chars) and IV (base64, 24 chars).';
        } else if (!_isValidBase64(aesKey, 32) || !_isValidBase64(aesIV, 16)) {
          result = 'AES key must be base64 (44 chars, 32 bytes) and IV must be base64 (24 chars, 16 bytes).';
        } else {
          result = EncryptionService.decryptAES(encrypted, aesKey);
        }
      } else if (_selectedEncryptionType == 'RSA') {
        if (privateKeyPem.isEmpty) {
          result = 'No private key provided (required for decryption).';
        } else {
          RSAPrivateKey? privateKey;
          try {
            privateKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
          } catch (e) {
            privateKey = null;
          }
          if (privateKey == null) {
            result = 'Invalid private key format.';
          } else {
            result = EncryptionService.decryptRSA(encrypted, privateKey);
          }
        }
      } else if (_selectedEncryptionType == 'Hybrid') {
        if (aesKey.isEmpty || chaChaKey.isEmpty) {
          result = 'Please enter both AES key and ChaCha20 key (base64, 44 chars each).';
        } else if (!_isValidBase64(aesKey, 32) || !_isValidBase64(chaChaKey, 32)) {
          result = 'Hybrid requires AES and ChaCha20 keys (44 chars, 32 bytes each).';
        } else {
          result = EncryptionService.hybridDecrypt(encrypted, aesKey, chaChaKey);
        }
      } else if (_selectedEncryptionType == 'ChaCha20') {
        if (chaChaKey.isEmpty) {
          result = 'Please enter the ChaCha20 key (base64, 44 chars).';
        } else if (!_isValidBase64(chaChaKey, 32)) {
          result = 'ChaCha20 key must be base64 (44 chars, 32 bytes).';
        } else {
          try {
            result = EncryptionService.decryptChaCha20(encrypted, chaChaKey);
          } catch (e) {
            result = 'ChaCha20 decryption failed: $e';
          }
        }
      } else {
        result = 'Unknown encryption type.';
      }
    } catch (e) {
      result = 'Decryption error: $e';
    }

    setState(() {
      _decryptedMessage = result;
      _isLoading = false;
      _copied = false;
    });
  }

  void _copyToClipboard() async {
    if (_decryptedMessage != null) {
      await Clipboard.setData(ClipboardData(text: _decryptedMessage!));
      setState(() {
        _copied = true;
      });
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() => _copied = false);
      });
    }
  }

  void _copyPublicKeyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _publicKeyController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Public key copied to clipboard')),
    );
  }

  void _copyPrivateKeyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _privateKeyController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Private key copied to clipboard')),
    );
  }

  void _navigateBack(BuildContext context) {
    Navigator.of(context).pop();
  }

  void _goToEncryptScreen(BuildContext context) {
    Navigator.of(context).pushNamed('/encrypt-message');
  }

  @override
  Widget build(BuildContext context) {
    final isAES = _selectedEncryptionType == 'AES';
    final isRSA = _selectedEncryptionType == 'RSA';
    final isHybrid = _selectedEncryptionType == 'Hybrid';
    final isChaCha20 = _selectedEncryptionType == 'ChaCha20';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Card(
              elevation: 12,
              margin: const EdgeInsets.symmetric(horizontal: 18, vertical: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 30),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Top Navigation Row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 26),
                          tooltip: 'Back',
                          onPressed: () => _navigateBack(context),
                        ),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          icon: const Icon(Icons.lock, size: 18),
                          label: const Text("Go to Encrypt"),
                          onPressed: () => _goToEncryptScreen(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Decrypt Message',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Encryption Method',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      value: _selectedEncryptionType,
                      isExpanded: true,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedEncryptionType = value;
                            _decryptedMessage = null;
                            _aesKeyController.clear();
                            _aesIvController.clear();
                            _chachaKeyController.clear();
                            _nonceController.clear();
                            _publicKeyController.clear();
                            _privateKeyController.clear();
                          });
                        }
                      },
                      items: _encryptionTypes
                          .map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      ))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    CustomTextField(
                      controller: _messageController,
                      hintText: 'Encrypted message (JSON string)',
                      minLines: 2,
                      maxLines: 6,
                      isPassword: false,
                    ),
                    if (isAES) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _aesKeyController,
                              hintText: 'AES key (base64, 44 chars)',
                              isPassword: false,
                              minLines: 1,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              controller: _aesIvController,
                              hintText: 'AES IV (base64, 24 chars)',
                              isPassword: false,
                              minLines: 1,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isChaCha20) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _chachaKeyController,
                              hintText: 'ChaCha20 key (base64, 44 chars)',
                              isPassword: false,
                              minLines: 1,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isHybrid) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _aesKeyController,
                              hintText: 'AES key (base64, 44 chars)',
                              isPassword: false,
                              minLines: 1,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              controller: _chachaKeyController,
                              hintText: 'ChaCha20 key (base64, 44 chars)',
                              isPassword: false,
                              minLines: 1,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isRSA) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            "Private Key (PEM):",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: _copyPrivateKeyToClipboard,
                            tooltip: 'Copy private key',
                          ),
                        ],
                      ),
                      CustomTextField(
                        controller: _privateKeyController,
                        hintText: 'Paste your RSA Private Key here (PEM format)',
                        isPassword: false,
                        minLines: 3,
                        maxLines: 8,
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.lock_open),
                        label: const Text(
                          'Decrypt',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _isLoading ? null : _decryptMessage,
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 18),
                      const CircularProgressIndicator(),
                    ],
                    if (_decryptedMessage != null) ...[
                      const SizedBox(height: 24),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Decrypted Message:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              _decryptedMessage!,
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.copy, size: 18),
                                label: Text(_copied ? 'Copied!' : 'Copy'),
                                onPressed: _copyToClipboard,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _copied ? Colors.green : Theme.of(context).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}