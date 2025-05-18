import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:basic_utils/basic_utils.dart';
import '../services/encryption_service.dart';
import '../services/innocent_encoding_service.dart';
import '../widgets/custom_text_field.dart';
import 'decrypt_message_screen.dart';

class EncryptMessageScreen extends StatefulWidget {
  const EncryptMessageScreen({Key? key}) : super(key: key);

  @override
  State<EncryptMessageScreen> createState() => _EncryptMessageScreenState();
}

class _EncryptMessageScreenState extends State<EncryptMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _aesKeyController = TextEditingController();
  final TextEditingController _aesIvController = TextEditingController();
  final TextEditingController _chachaKeyController = TextEditingController();
  final TextEditingController _chachaNonceController = TextEditingController();
  final TextEditingController _rsaPublicKeyController = TextEditingController();
  final TextEditingController _rsaPrivateKeyController = TextEditingController();

  String? _encryptedMessage;
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
    _rsaPublicKeyController.dispose();
    _rsaPrivateKeyController.dispose();
    super.dispose();
  }

  void _generateAesKeyAndIv() {
    final key = EncryptionService.generateAesKey();
    final iv = EncryptionService.generateHybridKeys()['aesIv']!;
    setState(() {
      _aesKeyController.text = key;
      _aesIvController.text = iv;
    });
  }

  void _generateChaCha20KeyAndNonce() {
    setState(() {
      _chachaKeyController.text = EncryptionService.generateChachaKey();
      _chachaNonceController.text = EncryptionService.generateChachaNonce();
    });
  }

  Future<void> _generateRSAKeys() async {
    setState(() => _isLoading = true);
    try {
      final keyPair = await EncryptionService.generateRsaKeyPair();
      final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPemPkcs1(keyPair.publicKey);
      final privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(keyPair.privateKey);
      setState(() {
        _rsaPublicKeyController.text = publicKeyPem;
        _rsaPrivateKeyController.text = privateKeyPem;
      });
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _clearKeys() {
    _aesKeyController.clear();
    _aesIvController.clear();
    _chachaKeyController.clear();
    _chachaNonceController.clear();
    _rsaPublicKeyController.clear();
    _rsaPrivateKeyController.clear();
  }

  Future<void> _encryptMessage() async {
    final message = _messageController.text.trim();
    final aesKey = _aesKeyController.text.trim();
    final aesIv = _aesIvController.text.trim();
    final chachaKey = _chachaKeyController.text.trim();
    final chachaNonce = _chachaNonceController.text.trim();
    final rsaPublicKeyPem = _rsaPublicKeyController.text.trim();
    String result;

    setState(() {
      _isLoading = true;
      _encryptedMessage = null;
      _copied = false;
      _errorMessage = null;
      _showSuccess = false;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    try {
      if (message.isEmpty) {
        result = 'Please enter a message to encrypt.';
      } else if (_selectedEncryptionType == 'AES') {
        if (aesKey.isEmpty || aesIv.isEmpty) {
          result = 'Please generate or enter AES key and IV.';
        } else {
          result = EncryptionService.encryptAes(message, aesKey, ivBase64: aesIv);
        }
      } else if (_selectedEncryptionType == 'RSA') {
        if (rsaPublicKeyPem.isEmpty) {
          result = 'Please generate or enter RSA public key.';
        } else {
          RSAPublicKey? publicKey;
          try {
            publicKey = CryptoUtils.rsaPublicKeyFromPem(rsaPublicKeyPem);
          } catch (_) {
            publicKey = null;
          }
          if (publicKey == null) {
            result = 'Invalid public key format.';
          } else {
            result = EncryptionService.encryptRsa(message, publicKey);
          }
        }
      } else if (_selectedEncryptionType == 'ChaCha20') {
        if (chachaKey.isEmpty || chachaNonce.isEmpty) {
          result = 'Please generate or enter ChaCha20 key and nonce.';
        } else {
          result = EncryptionService.encryptChacha20(message, chachaKey, chachaNonce);
        }
      } else if (_selectedEncryptionType == 'Hybrid') {
        if (aesKey.isEmpty || aesIv.isEmpty || chachaKey.isEmpty || chachaNonce.isEmpty) {
          result = 'Please generate or enter AES key, IV, ChaCha20 key and nonce for hybrid encryption.';
        } else {
          result = EncryptionService.hybridEncrypt(
            message,
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
      result = 'Encryption error: $e';
    }

    setState(() {
      _encryptedMessage = result;
      _isLoading = false;
      _showSuccess = !(result.startsWith('Encryption error:') || result.startsWith('Please'));
      _errorMessage =
      (result.startsWith('Encryption error:') || result.startsWith('Please')) ? result : null;
    });

    if (_showSuccess && _encryptedMessage != null) {
      await _askForDisguiseAndApply();
    }
  }

  Future<void> _askForDisguiseAndApply() async {
    String tempDisguiseType = _selectedDisguiseType;
    String? tempPassword = _disguisePassword;
    final passwordController = TextEditingController(text: tempPassword);

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text("Disguise Encrypted Message"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: tempDisguiseType,
                    onChanged: (v) {
                      if (v != null) setStateDialog(() => tempDisguiseType = v);
                    },
                    items: _disguiseTypes
                        .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                        .toList(),
                    decoration: const InputDecoration(labelText: "Disguise Type"),
                  ),
                  if (tempDisguiseType == 'Spam (with password)')
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: "Spam Password"),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedDisguiseType = tempDisguiseType;
                      _disguisePassword = passwordController.text;
                      _encryptedMessage = _applyDisguise(
                        _encryptedMessage!,
                        tempDisguiseType,
                        password: passwordController.text,
                      );
                    });
                    Navigator.of(ctx).pop();
                  },
                  child: const Text("Apply"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _applyDisguise(String message, String disguiseType, {String? password}) {
    switch (disguiseType) {
      case 'Spam':
        return InnocentEncodingService.encodeAsSpam(message);
      case 'Fake Spreadsheet':
        return InnocentEncodingService.encodeAsSpreadsheet(message);
      case 'Fake PGP':
        return InnocentEncodingService.encodeAsFakePGP(message);
      case 'Fake Russian':
        return InnocentEncodingService.encodeAsFakeRussian(message);
      case 'Space':
        return InnocentEncodingService.encodeAsSpace(message);
      default:
        return message;
    }
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

  int getCurrentStep() {
    if (_encryptedMessage != null) return 2;
    if (_aesKeyController.text.isNotEmpty ||
        _chachaKeyController.text.isNotEmpty ||
        _rsaPublicKeyController.text.isNotEmpty) return 1;
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

    Color generateBtnColor = isDark ? Colors.white : Colors.black;
    Color generateBtnTextColor = isDark ? Colors.black : Colors.white;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Encrypt Message', style: TextStyle(color: Colors.black87)),
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
                              'Enter Message',
                              'Enter Keys',
                              'Encrypt & Copy',
                            ],
                          ),
                          const SizedBox(height: 18),
                          CustomTextField(
                            controller: _messageController,
                            hintText: 'Message to encrypt',
                            minLines: 2,
                            maxLines: 5,
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
                                  _encryptedMessage = null;
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
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _generateAesKeyAndIv,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: generateBtnColor,
                                    foregroundColor: generateBtnTextColor,
                                    minimumSize: const Size(80, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                    elevation: 0,
                                  ),
                                  child: const Text("Generate"),
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
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _generateChaCha20KeyAndNonce,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: generateBtnColor,
                                    foregroundColor: generateBtnTextColor,
                                    minimumSize: const Size(80, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                    elevation: 0,
                                  ),
                                  child: const Text("Generate"),
                                ),
                              ],
                            ),
                          ],
                          if (isRSA) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  "Public Key (PEM):",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                              ],
                            ),
                            CustomTextField(
                              controller: _rsaPublicKeyController,
                              hintText: 'Paste your RSA Public Key here (PEM format)',
                              isPassword: false,
                              minLines: 3,
                              maxLines: 8,
                            ),
                            const SizedBox(height: 8),
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
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _generateRSAKeys,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: generateBtnColor,
                                    foregroundColor: generateBtnTextColor,
                                    minimumSize: const Size(80, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                    elevation: 0,
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: generateBtnTextColor),
                                  )
                                      : const Text("Generate"),
                                ),
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
                          if (_showSuccess && _encryptedMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: MaterialBanner(
                                backgroundColor: Colors.green.shade100,
                                content: Text(
                                  'Message encrypted successfully!',
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
                              onPressed: _isLoading ? null : _encryptMessage,
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
                                'Encrypt Message',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                          ),
                          if (_encryptedMessage != null) ...[
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
                                          Icon(Icons.lock, color: isDark ? Colors.white : Colors.black87),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Encrypted Message',
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
                                      _encryptedMessage!,
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
                              icon: Icon(Icons.lock_open, size: 18, color: isDark ? Colors.white : Colors.black87),
                              label: Text("Go to Decrypt", style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                              style: TextButton.styleFrom(
                                foregroundColor: isDark ? Colors.white : Colors.black87,
                              ),
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => const DecryptMessageScreen(),
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