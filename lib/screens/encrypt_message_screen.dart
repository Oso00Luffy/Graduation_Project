import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/encryption_service.dart';
import '../widgets/custom_text_field.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:basic_utils/basic_utils.dart';
import 'dart:convert';

class EncryptMessageScreen extends StatefulWidget {
  final String? initialEncryptionType;
  final RSAPublicKey? rsaPublicKey;

  const EncryptMessageScreen({
    Key? key,
    this.initialEncryptionType,
    this.rsaPublicKey,
  }) : super(key: key);

  @override
  State<EncryptMessageScreen> createState() => _EncryptMessageScreenState();
}

class _EncryptMessageScreenState extends State<EncryptMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _aesKeyController = TextEditingController();
  final TextEditingController _aesIvController = TextEditingController();
  final TextEditingController _chachaKeyController = TextEditingController();
  final TextEditingController _chachaNonceController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  String? _encryptedMessage;
  bool _isLoading = false;
  bool _copied = false;

  final List<String> _encryptionTypes = ['AES', 'RSA', 'Hybrid', 'ChaCha20'];
  late String _selectedEncryptionType;

  @override
  void initState() {
    super.initState();
    _selectedEncryptionType = widget.initialEncryptionType ?? _encryptionTypes[0];
    if (widget.rsaPublicKey != null) {
      _publicKeyController.text =
          CryptoUtils.encodeRSAPublicKeyToPemPkcs1(widget.rsaPublicKey!);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _aesKeyController.dispose();
    _aesIvController.dispose();
    _chachaKeyController.dispose();
    _chachaNonceController.dispose();
    _publicKeyController.dispose();
    _privateKeyController.dispose();
    super.dispose();
  }

  void _generateAesKeyAndIv() {
    setState(() {
      _aesKeyController.text = EncryptionService.generateAESKey();
      _aesIvController.text = EncryptionService.generateIV();
    });
  }

  void _generateChaCha20KeyAndNonce() {
    setState(() {
      _chachaKeyController.text = EncryptionService.generateChaCha20Key();
      _chachaNonceController.text = EncryptionService.generateChaCha20Nonce();
    });
  }

  void _generateHybridKeys() {
    setState(() {
      _aesKeyController.text = EncryptionService.generateAESKey();
      _aesIvController.text = EncryptionService.generateIV();
      _chachaKeyController.text = EncryptionService.generateChaCha20Key();
      _chachaNonceController.text = EncryptionService.generateChaCha20Nonce();
    });
  }

  Future<void> _generateRSAKeys() async {
    setState(() => _isLoading = true);
    try {
      final keyPair = await EncryptionService.generateRSAKeyPair();
      final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPemPkcs1(keyPair.publicKey);
      final privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(keyPair.privateKey);
      setState(() {
        _publicKeyController.text = publicKeyPem;
        _privateKeyController.text = privateKeyPem;
      });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _encryptMessage() async {
    final message = _messageController.text.trim();
    final aesKey = _aesKeyController.text.trim();
    final aesIv = _aesIvController.text.trim();
    final chachaKey = _chachaKeyController.text.trim();
    final chachaNonce = _chachaNonceController.text.trim();
    final publicKeyPem = _publicKeyController.text.trim();
    String result;

    setState(() {
      _isLoading = true;
      _encryptedMessage = null;
      _copied = false;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      if (message.isEmpty) {
        result = 'Please enter a message to encrypt.';
      } else if (_selectedEncryptionType == 'AES') {
        if (aesKey.isEmpty || aesIv.isEmpty) {
          result = 'Please generate or enter AES key (32 chars) and IV (base64, 24 chars).';
        } else if (aesKey.length != 32) {
          result = 'AES key must be exactly 32 characters (not base64).';
        } else if (base64.decode(aesIv).length != 16) {
          result = 'AES IV must be base64 (24 chars, 16 bytes).';
        } else {
          result = EncryptionService.encryptAES(message, aesKey, ivBase64: aesIv);
        }
      } else if (_selectedEncryptionType == 'RSA') {
        if (publicKeyPem.isEmpty) {
          result = 'No public key provided (required for encryption).';
        } else {
          RSAPublicKey? publicKey;
          try {
            publicKey = CryptoUtils.rsaPublicKeyFromPem(publicKeyPem);
          } catch (e) {
            publicKey = null;
          }
          if (publicKey == null) {
            result = 'Invalid public key format.';
          } else {
            result = EncryptionService.encryptRSA(message, publicKey);
          }
        }
      } else if (_selectedEncryptionType == 'Hybrid') {
        if (aesKey.isEmpty || aesIv.isEmpty || chachaKey.isEmpty || chachaNonce.isEmpty) {
          result = 'Please generate or enter all keys and IV/nonce required for hybrid encryption.';
        } else if (aesKey.length != 32) {
          result = 'Hybrid requires AES key to be exactly 32 characters.';
        } else if (base64.decode(aesIv).length != 16) {
          result = 'Hybrid requires AES IV to be base64 (24 chars, 16 bytes).';
        } else if (base64.decode(chachaKey).length != 32) {
          result = 'Hybrid requires ChaCha20 key to be base64 (44 chars, 32 bytes).';
        } else if (base64.decode(chachaNonce).length != 8) {
          result = 'Hybrid requires ChaCha20 nonce to be base64 (12 chars, 8 bytes).';
        } else {
          result = EncryptionService.hybridEncrypt(message, aesKey, aesIv, chachaKey, chachaNonce);
        }
      } else if (_selectedEncryptionType == 'ChaCha20') {
        if (chachaKey.isEmpty || chachaNonce.isEmpty) {
          result = 'Please generate or enter ChaCha20 key (base64, 44 chars) and nonce (base64, 12 chars).';
        } else if (base64.decode(chachaKey).length != 32) {
          result = 'ChaCha20 key must be base64 (44 chars, 32 bytes).';
        } else if (base64.decode(chachaNonce).length != 8) {
          result = 'ChaCha20 nonce must be base64 (12 chars, 8 bytes).';
        } else {
          result = EncryptionService.encryptChaCha20(message, chachaKey, chachaNonce);
        }
      } else {
        result = 'Unknown encryption type.';
      }
    } catch (e) {
      result = 'Encryption error: $e';
    }

    setState(() {
      _encryptedMessage = result;
      _isLoading = false;
    });
  }

  void _copyToClipboard() async {
    if (_encryptedMessage != null) {
      await Clipboard.setData(ClipboardData(text: _encryptedMessage!));
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
    final isHybrid = _selectedEncryptionType == 'Hybrid';
    final isChaCha20 = _selectedEncryptionType == 'ChaCha20';

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
                    // Navigation
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
                          icon: const Icon(Icons.lock_open, size: 18),
                          label: const Text("Go to Decrypt"),
                          onPressed: () => Navigator.of(context).pushNamed('/decrypt-message'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Encrypt Message',
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
                            _encryptedMessage = null;
                            _aesKeyController.clear();
                            _aesIvController.clear();
                            _chachaKeyController.clear();
                            _chachaNonceController.clear();
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
                      hintText: 'Message to encrypt',
                      minLines: 2,
                      maxLines: 4,
                      isPassword: false,
                    ),
                    if (isAES) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: CustomTextField(
                              controller: _aesKeyController,
                              hintText: 'AES key (32 chars, not base64)',
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
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _generateAesKeyAndIv,
                            child: const Text("Generate"),
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
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              controller: _chachaNonceController,
                              hintText: 'ChaCha20 nonce (base64, 12 chars)',
                              isPassword: false,
                              minLines: 1,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _generateChaCha20KeyAndNonce,
                            child: const Text("Generate"),
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
                              hintText: 'AES key (32 chars, not base64)',
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
                      const SizedBox(height: 8),
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
                              hintText: 'ChaCha20 nonce (base64, 12 chars)',
                              isPassword: false,
                              minLines: 1,
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _generateHybridKeys,
                            child: const Text("Generate All"),
                          ),
                        ],
                      ),
                    ],
                    if (isRSA) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            "Public Key (PEM):",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                        ],
                      ),
                      CustomTextField(
                        controller: _publicKeyController,
                        hintText: 'Paste your RSA Public Key here (PEM format)',
                        isPassword: false,
                        minLines: 3,
                        maxLines: 8,
                      ),
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
                        controller: _privateKeyController,
                        hintText: 'Paste your RSA Private Key here (PEM format)',
                        isPassword: false,
                        minLines: 3,
                        maxLines: 8,
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _generateRSAKeys,
                        child: _isLoading
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : const Text("Generate RSA Keys"),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.lock_outline),
                        label: const Text(
                          'Encrypt',
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
                        onPressed: _isLoading ? null : _encryptMessage,
                      ),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 18),
                      const CircularProgressIndicator(),
                    ],
                    if (_encryptedMessage != null) ...[
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
                              'Encrypted Message:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            SelectableText(
                              _encryptedMessage!,
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