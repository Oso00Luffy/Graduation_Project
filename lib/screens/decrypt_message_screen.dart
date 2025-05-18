import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:basic_utils/basic_utils.dart';
import '../services/encryption_service.dart';
import '../services/innocent_encoding_service.dart';
import '../widgets/custom_text_field.dart';
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
  final TextEditingController _rsaPrivateKeyController = TextEditingController();

  String? _decryptedMessage;
  bool _isLoading = false;
  bool _copied = false;
  String? _errorMessage;
  bool _showSuccess = false;

  final List<String> _encryptionTypes = [
    'AES',
    'RSA',
    'ChaCha20',
    'Hybrid',
  ];
  late String _selectedEncryptionType;

  final List<String> _disguiseTypes = [
    'None',
    'Spam',
    'Fake Spreadsheet',
    'Fake PGP',
    'Fake Russian',
    'Space'
  ];
  String _selectedDisguiseType = 'None';
  String? _disguisePassword = '';

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
    _rsaPrivateKeyController.dispose();
    super.dispose();
  }

  void _clearKeys() {
    _aesKeyController.clear();
    _aesIvController.clear();
    _chachaKeyController.clear();
    _chachaNonceController.clear();
    _rsaPrivateKeyController.clear();
  }

  Future<void> _decryptMessage() async {
    setState(() {
      _isLoading = true;
      _decryptedMessage = null;
      _copied = false;
      _errorMessage = null;
      _showSuccess = false;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    String disguised = _messageController.text.trim();
    String extracted = disguised;

    // Extract the ciphertext from the disguise if needed
    if (_selectedDisguiseType != 'None') {
      extracted = _extractDisguised(disguised, _selectedDisguiseType, password: _disguisePassword);
      if (extracted.isEmpty) {
        setState(() {
          _decryptedMessage = null;
          _isLoading = false;
          _errorMessage = "Could not extract encrypted message from disguise.";
          _showSuccess = false;
        });
        return;
      }
    }

    final aesKey = _aesKeyController.text.trim();
    final aesIv = _aesIvController.text.trim();
    final chachaKey = _chachaKeyController.text.trim();
    final chachaNonce = _chachaNonceController.text.trim();
    final rsaPrivateKeyPem = _rsaPrivateKeyController.text.trim();
    String result;
    final encrypted = extracted;

    try {
      if (encrypted.isEmpty) {
        result = 'Please enter the encrypted message.';
      } else if (_selectedEncryptionType == 'AES') {
        if (aesKey.isEmpty) {
          result = 'Please enter AES key.';
        } else {
          result = EncryptionService.decryptAes(encrypted, aesKey);
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
        if (aesKey.isEmpty || aesIv.isEmpty || chachaKey.isEmpty || chachaNonce.isEmpty) {
          result = 'Please enter AES key, IV, ChaCha20 key and nonce for hybrid decryption.';
        } else {
          result = EncryptionService.hybridDecrypt(
            encrypted,
            aesKey,
            chachaKey,
            ivBase64: aesIv,
            nonceBase64: chachaNonce,
          );
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
      _showSuccess = !(result.startsWith('Decryption error:') || result.startsWith('Please'));
      _errorMessage =
      (result.startsWith('Decryption error:') || result.startsWith('Please')) ? result : null;
    });
  }

  String _extractDisguised(String disguised, String disguiseType, {String? password}) {
    switch (disguiseType) {
      case 'Spam':
        return InnocentEncodingService.decodeFromSpam(disguised) ?? '';
      case 'Fake Spreadsheet':
        return InnocentEncodingService.decodeFromSpreadsheet(disguised) ?? '';
      case 'Fake PGP':
        return InnocentEncodingService.decodeFromFakePGP(disguised) ?? '';
      case 'Fake Russian':
        return InnocentEncodingService.decodeFromFakeRussian(disguised) ?? '';
      case 'Space':
        return InnocentEncodingService.decodeFromSpace(disguised) ?? '';
      default:
        return disguised;
    }
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

  int getCurrentStep() {
    if (_decryptedMessage != null) return 2;
    if (_aesKeyController.text.isNotEmpty ||
        _chachaKeyController.text.isNotEmpty ||
        _rsaPrivateKeyController.text.isNotEmpty) return 1;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = Colors.orange;

    final isAES = _selectedEncryptionType == 'AES';
    final isRSA = _selectedEncryptionType == 'RSA';
    final isChaCha20 = _selectedEncryptionType == 'ChaCha20';
    final isHybrid = _selectedEncryptionType == 'Hybrid';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Decrypt Message', style: TextStyle(color: Colors.black87)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6a82fb), Color(0xFFfc5c7d)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    color: isDark ? Colors.grey[900]!.withOpacity(0.92) : Colors.white.withOpacity(0.92),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20),
                      child: Column(
                        children: [
                          StepperWidget(
                            currentStep: getCurrentStep(),
                            steps: const [
                              'Enter Ciphertext',
                              'Enter Keys',
                              'Decrypt & Copy',
                            ],
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            controller: _messageController,
                            hintText: 'Encrypted message (base64 or JSON or disguised)',
                            minLines: 2,
                            maxLines: 6,
                          ),
                          const SizedBox(height: 18),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'Encryption Method',
                              labelStyle: TextStyle(color: isDark ? Colors.white : Colors.black87),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor, width: 2),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor, width: 2),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: borderColor, width: 2),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            dropdownColor: isDark ? Colors.grey[900] : Colors.white,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w500),
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
                              child: Text(type, style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                            ))
                                .toList(),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            value: _selectedDisguiseType,
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedDisguiseType = v);
                            },
                            items: _disguiseTypes
                                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                                .toList(),
                            decoration: const InputDecoration(
                              labelText: 'Disguise Type',
                            ),
                          ),
                          if (_selectedDisguiseType == 'Spam (with password)')
                            TextField(
                              decoration: const InputDecoration(labelText: "Spam Password"),
                              onChanged: (v) => _disguisePassword = v,
                            ),
                          if (isAES || isHybrid) ...[
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
                          if (isChaCha20 || isHybrid) ...[
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
                          if (isRSA) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  "Private Key (PEM):",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
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
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: MaterialBanner(
                                backgroundColor: Colors.red.shade100,
                                content: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[800], fontSize: 15),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => setState(() => _errorMessage = null),
                                    child: const Text('Dismiss'),
                                  ),
                                ],
                              ),
                            ),
                          if (_showSuccess && _decryptedMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: MaterialBanner(
                                backgroundColor: Colors.green.shade100,
                                content: Text(
                                  'Message decrypted successfully!',
                                  style: TextStyle(color: Colors.green[900], fontSize: 15),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => setState(() => _showSuccess = false),
                                    child: const Text('Dismiss'),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            width: double.infinity,
                            height: 52,
                            margin: const EdgeInsets.only(top: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: const LinearGradient(
                                colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isLoading ? null : _decryptMessage,
                              child: _isLoading
                                  ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : const Text(
                                'Decrypt Message',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                          if (_decryptedMessage != null) ...[
                            const SizedBox(height: 20),
                            Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                              color: isDark ? Colors.grey[900] : Colors.white,
                              shadowColor: const Color(0x336a82fb),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey[850] : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                      child: Row(
                                        children: [
                                          Icon(Icons.lock_open, color: isDark ? Colors.white : Colors.black87),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Decrypted Message',
                                            style: TextStyle(
                                              color: isDark ? Colors.white : Colors.black87,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    SelectableText(
                                      _decryptedMessage!,
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: ElevatedButton.icon(
                                        icon: Icon(Icons.copy, size: 18, color: isDark ? Colors.white : Colors.black87),
                                        label: Text(_copied ? 'Copied!' : 'Copy', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                                          foregroundColor: isDark ? Colors.white : Colors.black87,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 18, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                        onPressed: _copyToClipboard,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: TextButton.icon(
                              icon: Icon(Icons.lock, size: 18, color: isDark ? Colors.white : Colors.black87),
                              label: Text("Go to Encrypt", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                              style: TextButton.styleFrom(
                                foregroundColor: isDark ? Colors.white : Colors.black87,
                              ),
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const EncryptMessageScreen(),
                              )),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StepperWidget extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const StepperWidget({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == currentStep;
        return Expanded(
          child: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: isActive
                      ? const LinearGradient(
                    colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: isActive ? null : (isDark ? Colors.grey[800] : Colors.grey[200]),
                  boxShadow: [
                    if (isActive)
                      const BoxShadow(
                        color: Color(0x3343e97b),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: Offset(0, 3),
                      ),
                  ],
                ),
                width: 42,
                height: 42,
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      color: isActive ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                steps[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isActive
                      ? (isDark ? Colors.white : Colors.black87)
                      : Colors.grey[600],
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}