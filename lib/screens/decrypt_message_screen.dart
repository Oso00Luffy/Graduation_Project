import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/encryption_service.dart';
import '../widgets/custom_text_field.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:basic_utils/basic_utils.dart';

import 'encrypt_message_screen.dart';

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
  final TextEditingController _chachaNonceController = TextEditingController();
  final TextEditingController _rsaPublicKeyController = TextEditingController();
  final TextEditingController _rsaPrivateKeyController = TextEditingController();

  String? _decryptedMessage;
  bool _isLoading = false;
  bool _copied = false;

  final List<String> _encryptionTypes = [
    'AES',
    'RSA',
    'ChaCha20',
    'Hybrid',
    'Double Encryption'
  ];
  late String _selectedEncryptionType;

  // For double decryption
  String _firstAlgo = 'AES';
  String _secondAlgo = 'RSA';

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
    _chachaNonceController.dispose();
    _rsaPublicKeyController.dispose();
    _rsaPrivateKeyController.dispose();
    super.dispose();
  }

  void _clearKeys() {
    _aesKeyController.clear();
    _aesIvController.clear();
    _chachaKeyController.clear();
    _chachaNonceController.clear();
    _rsaPublicKeyController.clear();
    _rsaPrivateKeyController.clear();
  }

  Future<void> _decryptMessage() async {
    final encrypted = _messageController.text.trim();
    final aesKey = _aesKeyController.text.trim();
    final aesIv = _aesIvController.text.trim();
    final chachaKey = _chachaKeyController.text.trim();
    final chachaNonce = _chachaNonceController.text.trim();
    final rsaPrivateKeyPem = _rsaPrivateKeyController.text.trim();

    String result;

    setState(() {
      _isLoading = true;
      _decryptedMessage = null;
      _copied = false;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      if (encrypted.isEmpty) {
        result = 'Please enter the encrypted message.';
      } else if (_selectedEncryptionType == 'AES') {
        if (aesKey.isEmpty || aesIv.isEmpty) {
          result = 'Please enter AES key and IV.';
        } else {
          result = EncryptionService.decryptAes(encrypted, aesKey, aesIv);
        }
      } else if (_selectedEncryptionType == 'RSA') {
        if (rsaPrivateKeyPem.isEmpty) {
          result = 'Please enter your RSA private key.';
        } else {
          RSAPrivateKey? privateKey;
          try {
            privateKey = CryptoUtils.rsaPrivateKeyFromPem(rsaPrivateKeyPem);
          } catch (_) {
            privateKey = null;
          }
          if (privateKey == null) {
            result = 'Invalid private key format.';
          } else {
            result = EncryptionService.decryptRsa(encrypted, privateKey);
          }
        }
      } else if (_selectedEncryptionType == 'ChaCha20') {
        if (chachaKey.isEmpty || chachaNonce.isEmpty) {
          result = 'Please enter ChaCha20 key and nonce.';
        } else {
          result = EncryptionService.decryptChacha20(encrypted, chachaKey, chachaNonce);
        }
      } else if (_selectedEncryptionType == 'Hybrid') {
        if (rsaPrivateKeyPem.isEmpty) {
          result = 'Please enter RSA private key for hybrid decryption.';
        } else {
          RSAPrivateKey? privateKey;
          try {
            privateKey = CryptoUtils.rsaPrivateKeyFromPem(rsaPrivateKeyPem);
          } catch (_) {
            privateKey = null;
          }
          if (privateKey == null) {
            result = 'Invalid private key format.';
          } else {
            result = EncryptionService.hybridDecrypt(encrypted, privateKey);
          }
        }
      } else if (_selectedEncryptionType == 'Double Encryption') {
        RSAPrivateKey? rsaPrivate;
        try {
          rsaPrivate = CryptoUtils.rsaPrivateKeyFromPem(rsaPrivateKeyPem);
        } catch (_) {
          rsaPrivate = null;
        }
        final params = {
          'aesKey': aesKey,
          'aesIv': aesIv,
          'chachaKey': chachaKey,
          'chachaNonce': chachaNonce,
          'rsaPrivateKey': rsaPrivate,
        };
        result = EncryptionService.doubleDecrypt(
          ciphertext: encrypted,
          first: _firstAlgo,
          second: _secondAlgo,
          params: params,
        );
      } else {
        result = 'Unknown encryption type.';
      }
    } catch (e) {
      result = 'Decryption error: $e';
    }

    setState(() {
      _decryptedMessage = result;
      _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final isAES = _selectedEncryptionType == 'AES';
    final isRSA = _selectedEncryptionType == 'RSA';
    final isChaCha20 = _selectedEncryptionType == 'ChaCha20';
    final isHybrid = _selectedEncryptionType == 'Hybrid';
    final isDouble = _selectedEncryptionType == 'Double Encryption';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
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
                    // Top navigation
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, size: 26),
                          tooltip: 'Back',
                          onPressed: () => Navigator.of(context).pop(),
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
                          onPressed: () =>
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => EncryptMessageScreen(),
                              )),
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
                            _clearKeys();
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
                    if (isDouble) ...[
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'First Algorithm',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              value: _firstAlgo,
                              onChanged: (v) {
                                if (v != null) setState(() => _firstAlgo = v);
                              },
                              items: ['AES', 'RSA', 'ChaCha20', 'Hybrid']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Second Algorithm',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              value: _secondAlgo,
                              onChanged: (v) {
                                if (v != null) setState(() => _secondAlgo = v);
                              },
                              items: ['AES', 'RSA', 'ChaCha20', 'Hybrid']
                                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    CustomTextField(
                      controller: _messageController,
                      hintText: 'Encrypted message (base64 or JSON)',
                      minLines: 2,
                      maxLines: 6,
                      isPassword: false,
                    ),
                    if (isAES || isDouble) ...[
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
                    if (isChaCha20 || isDouble) ...[
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              controller: _chachaNonceController,
                              hintText: 'ChaCha20 nonce (base64, 16 chars)',
                              isPassword: false,
                              minLines: 1,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (isRSA || isHybrid || isDouble) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            "Private Key (PEM):",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                        ],
                      ),
                      CustomTextField(
                        controller: _rsaPrivateKeyController,
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
                                  backgroundColor: _copied
                                      ? Colors.green
                                      : Theme.of(context).colorScheme.primary,
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