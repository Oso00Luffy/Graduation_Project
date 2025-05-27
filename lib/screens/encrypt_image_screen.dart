import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/image_encryption_service.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/file_extension_utils.dart';
import '../utils/web_download_helper.dart' if (dart.library.html) '../utils/web_download_helper_web.dart';
import 'decrypt_image_screen.dart';
import '../models/image_encryption_method.dart';

class ImageEncryptionScreen extends StatefulWidget {
  @override
  _ImageEncryptionScreenState createState() => _ImageEncryptionScreenState();
}

class _ImageEncryptionScreenState extends State<ImageEncryptionScreen> {
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
  String? _aesRsaEncryptedImageText;

  final TextEditingController _encryptedImageController = TextEditingController();
  final TextEditingController _encryptedAesKeyController = TextEditingController();
  final TextEditingController _privateKeyController = TextEditingController();
  final TextEditingController _publicKeyController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  String? _errorMessage;
  bool _isEncrypting = false;
  bool _isDecrypting = false;
  bool _showSuccess = false;

  static const int MAX_IMAGE_SIZE = 20 * 1024 * 1024;

  @override
  void initState() {
    super.initState();
    _updateTextControllers();
  }

  @override
  void dispose() {
    _encryptedImageController.dispose();
    _encryptedAesKeyController.dispose();
    _privateKeyController.dispose();
    _publicKeyController.dispose();
    super.dispose();
  }

  void _updateTextControllers() {
    _encryptedImageController.text = _aesRsaEncryptedImageText ?? '';
    _encryptedAesKeyController.text = _aesRsaEncryptedAesKeyText ?? '';
    _privateKeyController.text = _aesRsaPrivateKeyPem ?? '';
    _publicKeyController.text = _aesRsaPublicKeyPem ?? '';
  }

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
    _updateTextControllers();
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
        _updateTextControllers();
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
    final encryptedImageText = _aesRsaEncryptedImageText ?? '';
    final encryptedAesKeyText = _aesRsaEncryptedAesKeyText ?? '';
    final privateKeyPemText = _aesRsaPrivateKeyPem ?? '';

    if (encryptedImageText.trim().isEmpty ||
        encryptedAesKeyText.trim().isEmpty ||
        privateKeyPemText.trim().isEmpty) {
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
        encryptedImage = base64Decode(encryptedImageText.trim());
      } catch (e) {
        setState(() {
          _errorMessage = 'Invalid Base64 for encrypted image: $e';
          _isDecrypting = false;
        });
        return;
      }
      try {
        encryptedAesKey = base64Decode(encryptedAesKeyText.trim());
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
        privateKeyPemText.trim(),
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

  void _goToDecrypt(BuildContext context) {
    if (_method == ImageEncryptionMethod.visualCrypto) {
      if (_encryptedImageBytes == null || _keyImageBytes == null) {
        setState(() {
          _errorMessage = 'You must encrypt an image and have a key image to proceed to decryption.';
        });
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DecryptImageScreen(
            initialEncryptedImage: _encryptedImageBytes,
            initialKeyImage: _keyImageBytes,
            method: ImageEncryptionMethod.visualCrypto,
          ),
        ),
      );
    } else {
      if (_aesRsaEncryptedImageBytes == null ||
          _aesRsaEncryptedAesKeyBytes == null ||
          _aesRsaPrivateKeyPem == null ||
          _aesRsaPrivateKeyPem!.isEmpty) {
        setState(() {
          _errorMessage = 'You must encrypt an image and copy the AES key and private key to proceed to decryption.';
        });
        return;
      }
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DecryptImageScreen(
            initialEncryptedImage: _aesRsaEncryptedImageBytes,
            initialEncryptedAesKey: _aesRsaEncryptedAesKeyBytes,
            initialPrivateKeyPem: _aesRsaPrivateKeyPem,
            method: ImageEncryptionMethod.aesRsa,
          ),
        ),
      );
    }
  }

  Future<void> _downloadImage(
      Uint8List? bytes,
      String filenameBase, {
        String? originalPathOrName,
      }) async {
    if (bytes == null) return;

    String ext = '';
    if (originalPathOrName != null && originalPathOrName.isNotEmpty) {
      ext = getFileExtension(originalPathOrName);
    }
    if (ext.isEmpty) {
      ext = guessImageExtension(bytes);
    }
    if (ext.isEmpty) {
      ext = '.jpg';
    }
    String filename = "$filenameBase$ext";

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
                          _buildMethodToggle(),
                          SizedBox(height: 20),
                          StepperWidget(
                            currentStep: _method == ImageEncryptionMethod.visualCrypto
                                ? (_decryptedImageBytes != null
                                ? 3
                                : _encryptedImageBytes != null
                                ? 2
                                : _keyImageBytes != null
                                ? 1
                                : 0)
                                : (_aesRsaDecryptedImageBytes != null
                                ? 2
                                : _aesRsaEncryptedImageBytes != null
                                ? 1
                                : 0),
                            steps: _method == ImageEncryptionMethod.visualCrypto
                                ? [
                              'Select Images',
                              'Apply Visual Encryption',
                              'View Results',
                              'Test Decryption',
                            ]
                                : [
                              'Select Plain Image',
                              'Generate Encryption Keys',
                              'Test Decryption',
                            ],
                          ),
                          SizedBox(height: 25),
                          _buildInstructionsCard(),
                          SizedBox(height: 20),
                          if (_method == ImageEncryptionMethod.visualCrypto)
                            _buildVisualCryptoUI()
                          else
                            _buildAESRSAUI(),
                          if (_errorMessage != null) _buildErrorBanner(),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: Icon(Icons.arrow_forward, color: Colors.white),
                            label: Text("Go to Decrypt", style: TextStyle(color: Colors.white)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 14, horizontal: 28),
                              textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => _goToDecrypt(context),
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

  Widget _buildMethodToggle() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              "Choose Encryption Method",
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.blueGrey[800]),
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMethodButton(ImageEncryptionMethod.visualCrypto, "Visual Crypto"),
                SizedBox(width: 10),
                _buildMethodButton(ImageEncryptionMethod.aesRsa, "AES + RSA"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodButton(ImageEncryptionMethod method, String label) {
    final bool isSelected = _method == method;
    return Expanded(
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected ? Color(0xFF43e97b) : Colors.grey[200],
          foregroundColor: isSelected ? Colors.white : Colors.black87,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          elevation: isSelected ? 4 : 0,
        ),
        onPressed: () {
          setState(() {
            _method = method;
            _resetOutputs();
          });
        },
        child: Text(
          label,
          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      color: Colors.blue[50],
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                SizedBox(width: 8),
                Text(
                  _method == ImageEncryptionMethod.visualCrypto
                      ? "Visual Cryptography"
                      : "AES + RSA Encryption",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
            Divider(color: Colors.blue[200]),
            Text(
              _method == ImageEncryptionMethod.visualCrypto
                  ? "1. Select a plain image to be encrypted\n2. Select a key image (or generate a random one)\n3. Click 'Encrypt Image' to create an encrypted version\n4. Share the encrypted image and key image separately"
                  : "1. Select a plain image to be encrypted\n2. Click 'Encrypt Image' to generate encryption keys\n3. Share the encrypted image and encrypted AES key with the recipient\n4. Keep the private key secure - only share with trusted recipients",
              style: TextStyle(fontSize: 14, color: Colors.blue[800]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualCryptoUI() {
    return Column(
      children: [
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
        _buildEncryptDecryptButtons(),
        if (_encryptedImageBytes != null) _buildEncryptedImageCard(),
        if (_decryptedImageBytes != null) _buildDecryptedImageCard(),
      ],
    );
  }

  Widget _buildAESRSAUI() {
    return Column(
      children: [
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
        _buildEncryptDecryptButtons(),
        if (_aesRsaEncryptedImageBytes != null || _aesRsaEncryptedImageText != null)
          _buildAesRsaOutputCard(),
        if (_aesRsaDecryptedImageBytes != null) _buildAesRsaDecryptedImageCard(),
      ],
    );
  }

  Widget _buildEncryptDecryptButtons() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          Text(
            "Actions",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.blueGrey[800],
            ),
          ),
          SizedBox(height: 12),
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
                  onPressed: _isEncrypting
                      ? null
                      : (_method == ImageEncryptionMethod.visualCrypto
                      ? _encryptImageVisualCrypto
                      : _encryptImageAESRSA),
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
                    _isDecrypting ? 'Decrypting...' : 'Test Decrypt',
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
                  onPressed: _isDecrypting
                      ? null
                      : (_method == ImageEncryptionMethod.visualCrypto
                      ? _decryptImageVisualCrypto
                      : _decryptImageAESRSA),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEncryptedImageCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                    Spacer(),
                    Icon(Icons.check_circle, color: Colors.white),
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
    );
  }

  Widget _buildDecryptedImageCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }

  Widget _buildAesRsaOutputCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lock, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          'Encryption Results',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        Spacer(),
                        Icon(Icons.check_circle, color: Colors.white),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Share the encrypted image and encrypted AES key with your recipient',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Card(
                elevation: 2,
                color: Colors.blue[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Base64 Encoded:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue[800],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy, color: Colors.blue),
                            tooltip: "Copy to clipboard",
                            onPressed: () async {
                              if (_aesRsaEncryptedImageText != null) {
                                await Clipboard.setData(ClipboardData(text: _aesRsaEncryptedImageText!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Encrypted image (Base64) copied!')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      Container(
                        height: 80,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _aesRsaEncryptedImageText ?? '(No encrypted image generated yet)',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                color: Colors.orange[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.key, color: Colors.orange[700]),
                          SizedBox(width: 8),
                          Text(
                            "Encrypted AES Key",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.orange[200]),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Share this with your recipient:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                                fontSize: 14,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy, color: Colors.blue),
                            tooltip: "Copy to clipboard",
                            onPressed: () async {
                              if (_aesRsaEncryptedAesKeyText != null) {
                                await Clipboard.setData(ClipboardData(text: _aesRsaEncryptedAesKeyText!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Encrypted AES key (Base64) copied!')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      Container(
                        height: 80,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange[300]!),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _aesRsaEncryptedAesKeyText ?? '(No encrypted AES key generated yet)',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),
              Card(
                elevation: 2,
                color: Colors.red[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.vpn_key, color: Colors.red),
                          SizedBox(width: 8),
                          Text(
                            "RSA Keys",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      Divider(color: Colors.red[200]),
                      Text(
                        "Private Key (KEEP SECURE!)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.red[800],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "⚠️ Only share with trusted recipients!",
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 120,
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.red[300]!),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  _aesRsaPrivateKeyPem ?? '(No private key generated yet)',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                    color: Colors.red[900],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy, color: Colors.red),
                            tooltip: "Copy Private Key",
                            onPressed: () async {
                              if (_aesRsaPrivateKeyPem != null) {
                                await Clipboard.setData(ClipboardData(text: _aesRsaPrivateKeyPem!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('RSA Private Key copied!')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Public Key (Can be shared publicly)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey[700],
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 80,
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[400]!),
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  _aesRsaPublicKeyPem ?? '(No public key generated yet)',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.copy, color: Colors.blue),
                            tooltip: "Copy Public Key",
                            onPressed: () async {
                              if (_aesRsaPublicKeyPem != null) {
                                await Clipboard.setData(ClipboardData(text: _aesRsaPublicKeyPem!));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('RSA Public Key copied!')),
                                );
                              }
                            },
                          ),
                        ],
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

  Widget _buildAesRsaDecryptedImageCard() {
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: Card(
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildErrorBanner() {
    return Padding(
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
    );
  }
}

class EncryptionParams {
  final Uint8List plainImageBytes;
  final Uint8List keyImageBytes;

  EncryptionParams(this.plainImageBytes, this.keyImageBytes);
}

class StepperWidget extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const StepperWidget({required this.currentStep, required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(steps.length, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;
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
                      : isCompleted
                      ? LinearGradient(
                    colors: [Colors.blue.shade300, Colors.blue.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                      : null,
                  color: (isActive || isCompleted) ? null : Colors.grey[200],
                  boxShadow: [
                    if (isActive || isCompleted)
                      BoxShadow(
                        color: isActive ? Color(0x3343e97b) : Colors.blue.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: Offset(0, 3),
                      ),
                  ],
                ),
                width: 42,
                height: 42,
                child: Center(
                  child: isCompleted
                      ? Icon(Icons.check, color: Colors.white)
                      : Text(
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
                  color: isActive ? Color(0xFF43e97b) : isCompleted ? Colors.blue : Colors.grey[600],
                  fontWeight: isActive ? FontWeight.bold : isCompleted ? FontWeight.w500 : FontWeight.normal,
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