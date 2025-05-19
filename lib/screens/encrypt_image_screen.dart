import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart'; // For Clipboard
import '../services/image_encryption_service.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/web_download_helper.dart' if (dart.library.html) '../utils/web_download_helper_web.dart';

enum ImageEncryptionMethod { visualCrypto, aesRsa }

class ImageEncryptionScreen extends StatefulWidget {
  @override
  _ImageEncryptionScreenState createState() => _ImageEncryptionScreenState();
}

class _ImageEncryptionScreenState extends State<ImageEncryptionScreen> {
  // Method
  ImageEncryptionMethod _method = ImageEncryptionMethod.visualCrypto;

  // --- Visual Crypto State ---
  Uint8List? _plainImageBytes;
  Uint8List? _keyImageBytes;
  Uint8List? _encryptedImageBytes;
  Uint8List? _decryptedImageBytes;

  // --- AES+RSA State ---
  Uint8List? _aesRsaPlainImageBytes;
  Uint8List? _aesRsaEncryptedImageBytes;
  Uint8List? _aesRsaEncryptedAesKeyBytes;
  String? _aesRsaEncryptedAesKeyText;
  String? _aesRsaPrivateKeyPem;
  String? _aesRsaPublicKeyPem;
  Uint8List? _aesRsaDecryptedImageBytes;
  String? _aesRsaEncryptedImageText; // For Base64 text field

  final ImagePicker _picker = ImagePicker();
  String? _errorMessage;
  bool _isEncrypting = false;
  bool _isDecrypting = false;
  bool _showSuccess = false;

  static const int MAX_IMAGE_SIZE = 20 * 1024 * 1024;

  void _resetOutputs() {
    _plainImageBytes = null;
    _keyImageBytes = null;
    _encryptedImageBytes = null;
    _decryptedImageBytes = null;
    _aesRsaPlainImageBytes = null;
    _aesRsaEncryptedImageBytes = null;
    _aesRsaEncryptedAesKeyBytes = null;
    _aesRsaEncryptedAesKeyText = null;
    _aesRsaPrivateKeyPem = null;
    _aesRsaPublicKeyPem = null;
    _aesRsaDecryptedImageBytes = null;
    _aesRsaEncryptedImageText = null;
    _errorMessage = null;
    _showSuccess = false;
    _isEncrypting = false;
    _isDecrypting = false;
  }

  Future<void> _pickImage(String purpose, Function(Uint8List) onImageSelected) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        final bytes = await pickedFile.readAsBytes();

        if (bytes.length > MAX_IMAGE_SIZE) {
          setState(() {
            _errorMessage = '$purpose image is too large. Please pick an image under 20 MB.';
          });
          return;
        }

        setState(() {
          _errorMessage = null;
        });

        onImageSelected(bytes);
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to read $purpose image: $e';
        });
      }
    }
  }

  // --------- Visual Crypto Handlers ---------
  Future<void> _encryptImageVisualCrypto() async {
    if (_plainImageBytes == null || _keyImageBytes == null) {
      setState(() {
        _errorMessage = 'Please select both plain and key images.';
      });
      return;
    }

    setState(() {
      _isEncrypting = true;
      _errorMessage = null;
      _showSuccess = false;
      _encryptedImageBytes = null;
      _decryptedImageBytes = null;
    });

    try {
      final encryptedBytes = await compute(
        _performEncryptionVisualCrypto,
        EncryptionParams(_plainImageBytes!, _keyImageBytes!),
      );

      setState(() {
        _encryptedImageBytes = encryptedBytes;
        _isEncrypting = false;
        _showSuccess = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image encrypted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Encryption failed: $e';
        _isEncrypting = false;
        _showSuccess = false;
      });
    }
  }

  static Uint8List _performEncryptionVisualCrypto(EncryptionParams params) {
    return ImageEncryptionService.encryptImageWithKey(
      params.plainImageBytes,
      params.keyImageBytes,
    );
  }

  Future<void> _decryptImageVisualCrypto() async {
    if (_encryptedImageBytes == null || _keyImageBytes == null) {
      setState(() {
        _errorMessage = 'Please select an encrypted image and key image for decryption.';
      });
      return;
    }

    setState(() {
      _isDecrypting = true;
      _errorMessage = null;
      _showSuccess = false;
      _decryptedImageBytes = null;
    });

    try {
      final decryptedBytes = await compute(
        _performDecryptionVisualCrypto,
        EncryptionParams(_encryptedImageBytes!, _keyImageBytes!),
      );

      setState(() {
        _decryptedImageBytes = decryptedBytes;
        _isDecrypting = false;
        _showSuccess = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image decrypted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Decryption failed: $e';
        _isDecrypting = false;
        _showSuccess = false;
      });
    }
  }

  static Uint8List _performDecryptionVisualCrypto(EncryptionParams params) {
    return ImageEncryptionService.decryptImageWithKey(
      params.plainImageBytes,
      params.keyImageBytes,
    );
  }

  // --------- AES+RSA Handlers ---------
  Future<void> _encryptImageAESRSA() async {
    if (_aesRsaPlainImageBytes == null) {
      setState(() {
        _errorMessage = 'Please select a plain image.';
      });
      return;
    }

    setState(() {
      _isEncrypting = true;
      _errorMessage = null;
      _showSuccess = false;
      _aesRsaEncryptedImageBytes = null;
      _aesRsaDecryptedImageBytes = null;
      _aesRsaEncryptedAesKeyBytes = null;
      _aesRsaPrivateKeyPem = null;
      _aesRsaPublicKeyPem = null;
      _aesRsaEncryptedAesKeyText = null;
      _aesRsaEncryptedImageText = null;
    });

    try {
      final result = await ImageEncryptionService.encryptImageWithAESRSA(_aesRsaPlainImageBytes!);
      setState(() {
        _aesRsaEncryptedImageBytes = result['encryptedImage'];
        _aesRsaEncryptedImageText = base64Encode(result['encryptedImage']);
        _aesRsaEncryptedAesKeyBytes = result['encryptedAesKey'];
        _aesRsaEncryptedAesKeyText = base64Encode(result['encryptedAesKey']);
        _aesRsaPrivateKeyPem = result['privateKeyPem'];
        _aesRsaPublicKeyPem = result['publicKeyPem'];
        _isEncrypting = false;
        _showSuccess = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image encrypted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'AES+RSA Encryption failed: $e';
        _isEncrypting = false;
        _showSuccess = false;
      });
    }
  }

  Future<void> _decryptImageAESRSA() async {
    if ((_aesRsaEncryptedImageText == null || _aesRsaEncryptedImageText!.isEmpty) ||
        (_aesRsaEncryptedAesKeyText == null || _aesRsaEncryptedAesKeyText!.isEmpty) ||
        (_aesRsaPrivateKeyPem == null || _aesRsaPrivateKeyPem!.isEmpty)) {
      setState(() {
        _errorMessage = 'For decryption, provide Base64 encrypted image, encrypted AES key, and private key PEM.';
      });
      return;
    }

    setState(() {
      _isDecrypting = true;
      _errorMessage = null;
      _showSuccess = false;
      _aesRsaDecryptedImageBytes = null;
    });

    try {
      Uint8List encryptedImage;
      Uint8List encryptedAesKey;
      try {
        encryptedImage = base64Decode(_aesRsaEncryptedImageText!);
      } catch (e) {
        setState(() {
          _errorMessage = 'Invalid Base64 for encrypted image: $e';
          _isDecrypting = false;
        });
        return;
      }
      try {
        encryptedAesKey = base64Decode(_aesRsaEncryptedAesKeyText!);
      } catch (e) {
        setState(() {
          _errorMessage = 'Invalid Base64 for AES key: $e';
          _isDecrypting = false;
        });
        return;
      }

      final decryptedBytes = await ImageEncryptionService.decryptImageWithAESRSA(
        encryptedImage,
        encryptedAesKey,
        _aesRsaPrivateKeyPem!,
      );

      setState(() {
        _aesRsaDecryptedImageBytes = decryptedBytes;
        _isDecrypting = false;
        _showSuccess = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image decrypted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'AES+RSA Decryption failed: $e';
        _isDecrypting = false;
        _showSuccess = false;
      });
    }
  }

  // --------- Download Helper ---------
  Future<void> _downloadImage(Uint8List? bytes, String filename) async {
    if (bytes == null) return;

    if (kIsWeb) {
      await saveImageWeb(bytes, filename);
    } else {
      final result = await ImageGallerySaverPlus.saveImage(
        bytes,
        quality: 100,
        name: filename,
      );
      bool success = result['isSuccess'] ?? false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Image saved to gallery!' : 'Failed to save image.'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  // --------- UI ---------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Image Encryption'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6a82fb), Color(0xFFfc5c7d)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: SingleChildScrollView(
                  child: Card(
                    elevation: 12,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    color: Colors.white.withOpacity(0.92),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20),
                      child: Column(
                        children: [
                          // --- Method Switcher ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text("Method:", style: TextStyle(fontWeight: FontWeight.bold)),
                              SizedBox(width: 12),
                              DropdownButton<ImageEncryptionMethod>(
                                value: _method,
                                items: [
                                  DropdownMenuItem(
                                    value: ImageEncryptionMethod.visualCrypto,
                                    child: Text("Visual Cryptography"),
                                  ),
                                  DropdownMenuItem(
                                    value: ImageEncryptionMethod.aesRsa,
                                    child: Text("AES + RSA"),
                                  ),
                                ],
                                onChanged: (val) {
                                  setState(() {
                                    _method = val!;
                                    _resetOutputs();
                                  });
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 18),
                          if (_method == ImageEncryptionMethod.visualCrypto)
                            _buildVisualCryptoUI()
                          else
                            _buildAESRSAUI(),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              child: MaterialBanner(
                                backgroundColor: Colors.red.shade100,
                                content: Text(
                                  _errorMessage!,
                                  style: TextStyle(color: Colors.red[800], fontSize: 15),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => setState(() => _errorMessage = null),
                                    child: Text('Dismiss'),
                                  ),
                                ],
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

  Widget _buildVisualCryptoUI() {
    return Column(
      children: [
        StepperWidget(
          currentStep: _decryptedImageBytes != null
              ? 3
              : _encryptedImageBytes != null
              ? 2
              : _keyImageBytes != null
              ? 1
              : 0,
          steps: [
            'Select Plain Image',
            'Select Key Image',
            'Encrypt Image',
            'Decrypt Image',
          ],
        ),
        SizedBox(height: 18),
        _buildImageCard(
          title: 'Plain Image',
          imageBytes: _plainImageBytes,
          onPick: () => _pickImage('Plain', (bytes) {
            setState(() => _plainImageBytes = bytes);
          }),
          icon: Icons.image_outlined,
          pickLabel: 'Select Plain Image',
        ),
        SizedBox(height: 16),
        _buildImageCard(
          title: 'Key Image',
          imageBytes: _keyImageBytes,
          onPick: () => _pickImage('Key', (bytes) {
            setState(() => _keyImageBytes = bytes);
          }),
          icon: Icons.vpn_key_outlined,
          pickLabel: 'Select Key Image',
        ),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: _isEncrypting
                    ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Icon(Icons.lock, color: Colors.white),
                label: Text(
                  _isEncrypting ? 'Encrypting...' : 'Encrypt Image',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF43e97b),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isEncrypting ? null : _encryptImageVisualCrypto,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: _isDecrypting
                    ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Icon(Icons.lock_open, color: Colors.white),
                label: Text(
                  _isDecrypting ? 'Decrypting...' : 'Decrypt Image',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF38f9d7),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isDecrypting ? null : _decryptImageVisualCrypto,
              ),
            ),
          ],
        ),
        if (_encryptedImageBytes != null) ...[
          SizedBox(height: 20),
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            color: Colors.white,
            shadowColor: Color(0x336a82fb),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6a82fb), Color(0xFFfc5c7d)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Encrypted Image',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Image.memory(
                    _encryptedImageBytes!,
                    fit: BoxFit.contain,
                    filterQuality: ui.FilterQuality.medium,
                    height: 220,
                  ),
                  SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.download, color: Colors.white),
                      label: Text(
                        'Download Encrypted',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _downloadImage(_encryptedImageBytes, "encrypted_image"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_decryptedImageBytes != null) ...[
          SizedBox(height: 20),
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            color: Colors.white,
            shadowColor: Color(0x336a82fb),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.lock_open, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Decrypted Image',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Image.memory(
                    _decryptedImageBytes!,
                    fit: BoxFit.contain,
                    filterQuality: ui.FilterQuality.medium,
                    height: 220,
                  ),
                  SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.download, color: Colors.white),
                      label: Text(
                        'Download Decrypted',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _downloadImage(_decryptedImageBytes, "decrypted_image"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAESRSAUI() {
    TextEditingController encryptedImageController = TextEditingController(text: _aesRsaEncryptedImageText ?? "");
    TextEditingController encryptedAesKeyController = TextEditingController(text: _aesRsaEncryptedAesKeyText ?? "");
    TextEditingController privateKeyController = TextEditingController(text: _aesRsaPrivateKeyPem ?? "");
    TextEditingController publicKeyController = TextEditingController(text: _aesRsaPublicKeyPem ?? "");

    return Column(
      children: [
        StepperWidget(
          currentStep: _aesRsaDecryptedImageBytes != null
              ? 3
              : _aesRsaEncryptedImageBytes != null
              ? 2
              : _aesRsaPlainImageBytes != null
              ? 1
              : 0,
          steps: [
            'Select Plain Image',
            'Encrypt Image (AES+RSA)',
            'Decrypt Image',
          ],
        ),
        SizedBox(height: 18),
        _buildImageCard(
          title: 'Plain Image',
          imageBytes: _aesRsaPlainImageBytes,
          onPick: () => _pickImage('Plain', (bytes) {
            setState(() => _aesRsaPlainImageBytes = bytes);
          }),
          icon: Icons.image_outlined,
          pickLabel: 'Select Plain Image',
        ),
        SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: _isEncrypting
                    ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Icon(Icons.lock, color: Colors.white),
                label: Text(
                  _isEncrypting ? 'Encrypting...' : 'Encrypt Image',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF43e97b),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isEncrypting ? null : _encryptImageAESRSA,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: _isDecrypting
                    ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : Icon(Icons.lock_open, color: Colors.white),
                label: Text(
                  _isDecrypting ? 'Decrypting...' : 'Decrypt Image',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF38f9d7),
                  padding: EdgeInsets.symmetric(vertical: 16),
                  textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: _isDecrypting ? null : _decryptImageAESRSA,
              ),
            ),
          ],
        ),
        if (_aesRsaEncryptedImageBytes != null || _aesRsaEncryptedImageText != null) ...[
          SizedBox(height: 20),
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            color: Colors.white,
            shadowColor: Color(0x336a82fb),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF6a82fb), Color(0xFFfc5c7d)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.lock, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Encrypted Image (Base64)',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: encryptedImageController,
                          minLines: 2,
                          maxLines: 8,
                          readOnly: false,
                          onChanged: (val) => _aesRsaEncryptedImageText = val,
                          decoration: InputDecoration(
                            labelText: "Encrypted Image (Base64)",
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.blue),
                        tooltip: "Copy to clipboard",
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: encryptedImageController.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Encrypted image (Base64) copied!')),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.paste, color: Colors.green),
                        tooltip: "Paste from clipboard",
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data != null) setState(() => _aesRsaEncryptedImageText = data.text ?? "");
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: encryptedAesKeyController,
                          minLines: 2,
                          maxLines: 6,
                          readOnly: false,
                          onChanged: (val) => _aesRsaEncryptedAesKeyText = val,
                          decoration: InputDecoration(
                            labelText: "Encrypted AES Key (Base64)",
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.blue),
                        tooltip: "Copy AES Key",
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: encryptedAesKeyController.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Encrypted AES key (Base64) copied!')),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.paste, color: Colors.green),
                        tooltip: "Paste AES Key",
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data != null) setState(() => _aesRsaEncryptedAesKeyText = data.text ?? "");
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: privateKeyController,
                          minLines: 2,
                          maxLines: 8,
                          readOnly: false,
                          onChanged: (val) => _aesRsaPrivateKeyPem = val,
                          decoration: InputDecoration(
                            labelText: "RSA Private Key (PEM)",
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11, color: Colors.red),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.blue),
                        tooltip: "Copy Private Key",
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: privateKeyController.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('RSA Private Key copied!')),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.paste, color: Colors.green),
                        tooltip: "Paste Private Key",
                        onPressed: () async {
                          final data = await Clipboard.getData('text/plain');
                          if (data != null) setState(() => _aesRsaPrivateKeyPem = data.text ?? "");
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: publicKeyController,
                          minLines: 2,
                          maxLines: 8,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: "RSA Public Key (PEM)",
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(fontFamily: 'monospace', fontSize: 11),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.copy, color: Colors.blue),
                        tooltip: "Copy Public Key",
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: publicKeyController.text));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('RSA Public Key copied!')),
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.download, color: Colors.white),
                      label: Text(
                        'Download Encrypted',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _downloadImage(_aesRsaEncryptedImageBytes, "aesrsa_encrypted_image"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_aesRsaDecryptedImageBytes != null) ...[
          SizedBox(height: 20),
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            margin: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
            color: Colors.white,
            shadowColor: Color(0x336a82fb),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.lock_open, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Decrypted Image',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Image.memory(
                    _aesRsaDecryptedImageBytes!,
                    fit: BoxFit.contain,
                    filterQuality: ui.FilterQuality.medium,
                    height: 220,
                  ),
                  SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.download, color: Colors.white),
                      label: Text(
                        'Download Decrypted',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 28),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => _downloadImage(_aesRsaDecryptedImageBytes, "aesrsa_decrypted_image"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildImageCard({
    required String title,
    required Uint8List? imageBytes,
    required VoidCallback onPick,
    required IconData icon,
    required String pickLabel,
  }) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.white,
      shadowColor: Color(0x336a82fb),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF6a82fb), Color(0xFFfc5c7d)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),
            _buildImagePreview(imageBytes),
            SizedBox(height: 10),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: OutlinedButton.icon(
                icon: Icon(Icons.upload_file_rounded, color: Colors.white),
                label: Text(
                  pickLabel,
                  style: TextStyle(color: Colors.white),
                ),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: onPick,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(Uint8List? imageBytes) {
    if (imageBytes == null) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.photo, color: Colors.grey[300], size: 40),
              SizedBox(height: 6),
              Text(
                'No image selected',
                style: TextStyle(color: Colors.grey[400], fontSize: 15),
              ),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        imageBytes,
        height: 120,
        fit: BoxFit.contain,
        filterQuality: ui.FilterQuality.medium,
      ),
    );
  }
}

class EncryptionParams {
  final Uint8List plainImageBytes;
  final Uint8List keyImageBytes;

  EncryptionParams(this.plainImageBytes, this.keyImageBytes);
}

/// A beautiful stepper indicator for process steps
class StepperWidget extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const StepperWidget({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
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
                      ? LinearGradient(
                    colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: isActive ? null : Colors.grey[200],
                  boxShadow: [
                    if (isActive)
                      BoxShadow(
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
                      color: isActive ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 6),
              Text(
                steps[index],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  color: isActive ? Color(0xFF43e97b) : Colors.grey[600],
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