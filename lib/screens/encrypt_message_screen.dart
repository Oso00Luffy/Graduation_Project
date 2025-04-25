import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/encryption_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:basic_utils/basic_utils.dart';

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
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _nonceController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();
  String? _encryptedMessage;
  bool _isLoading = false;
  bool _copied = false;
  bool _publicKeyVisible = false;

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
    _keyController.dispose();
    _nonceController.dispose();
    _publicKeyController.dispose();
    super.dispose();
  }

  Future<void> _encryptMessage() async {
    final message = _messageController.text.trim();
    final key = _keyController.text.trim();
    final nonce = _nonceController.text.trim();
    final publicKeyPem = _publicKeyController.text.trim();
    String result;

    setState(() {
      _isLoading = true;
      _encryptedMessage = null;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    if (message.isEmpty) {
      result = 'Please enter a message to encrypt.';
    } else if (_selectedEncryptionType == 'AES') {
      if (key.isEmpty) {
        result = 'Please enter the AES key.';
      } else {
        result = EncryptionService.encryptAES(message, key);
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
          result = EncryptionService.hybridEncrypt(message, publicKey);
        }
      }
    } else if (_selectedEncryptionType == 'ChaCha20') {
      if (key.isEmpty || nonce.isEmpty) {
        result = 'Please enter both the ChaCha20 key (32 chars) and nonce (8 chars).';
      } else if (key.length != 32 || nonce.length != 8) {
        result = 'ChaCha20 requires a 32-character key and an 8-character nonce.';
      } else {
        try {
          result = EncryptionService.encryptChaCha20(message, key, nonce);
        } catch (e) {
          result = 'ChaCha20 encryption failed: $e';
        }
      }
    } else {
      result = 'Unknown encryption type.';
    }

    setState(() {
      _encryptedMessage = result;
      _isLoading = false;
      _copied = false;
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

  void _copyPublicKeyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _publicKeyController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Public key copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAES = _selectedEncryptionType == 'AES';
    final isRSA = _selectedEncryptionType == 'RSA';
    final isHybrid = _selectedEncryptionType == 'Hybrid';
    final isChaCha20 = _selectedEncryptionType == 'ChaCha20';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8), // Subtle background
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 8,
              margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Encrypt Message',
                      style: TextStyle(
                        fontSize: 26,
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
                            _keyController.clear();
                            _nonceController.clear();
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
                    ),
                    if (isAES) ...[
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _keyController,
                        hintText: 'Enter your AES key',
                        isPassword: true,
                      ),
                    ],
                    if (isChaCha20) ...[
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _keyController,
                        hintText: 'ChaCha20 key (32 chars)',
                        isPassword: true,
                        minLines: 1,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 8),
                      CustomTextField(
                        controller: _nonceController,
                        hintText: 'Nonce (8 chars)',
                        isPassword: false,
                        minLines: 1,
                        maxLines: 1,
                      ),
                    ],
                    if (isRSA || isHybrid) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            "Public Key (PEM):",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: Icon(_publicKeyVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: () {
                              setState(() {
                                _publicKeyVisible = !_publicKeyVisible;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.copy),
                            onPressed: _copyPublicKeyToClipboard,
                            tooltip: 'Copy public key',
                          ),
                        ],
                      ),
                      TextField(
                        controller: _publicKeyController,
                        minLines: 3,
                        maxLines: 8,
                        obscureText: false,
                        decoration: InputDecoration(
                          hintText: 'Paste your RSA Public Key here (PEM format)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
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