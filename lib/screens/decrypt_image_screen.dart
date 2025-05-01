import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../services/image_encryption_service.dart';

class DecryptImageScreen extends StatefulWidget {
  @override
  _DecryptImageScreenState createState() => _DecryptImageScreenState();
}

class _DecryptImageScreenState extends State<DecryptImageScreen> {
  Uint8List? _encryptedImageBytes;
  Uint8List? _keyImageBytes;
  Uint8List? _decryptedImageBytes;
  final ImagePicker _picker = ImagePicker();
  String? _errorMessage;
  bool _isDecrypting = false;

  static const int MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5 MB

  Future<void> _pickImage(String purpose, Function(Uint8List) onImageSelected) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      try {
        final bytes = await pickedFile.readAsBytes();

        if (bytes.length > MAX_IMAGE_SIZE) {
          setState(() {
            _errorMessage = '$purpose image is too large. Please pick an image under 5 MB.';
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

  Future<void> _decryptImage() async {
    if (_encryptedImageBytes == null || _keyImageBytes == null) {
      setState(() {
        _errorMessage = 'Please select both encrypted and key images.';
      });
      return;
    }

    setState(() {
      _isDecrypting = true;
      _errorMessage = null;
    });

    try {
      final decryptedBytes = await compute(
        _performDecryption,
        DecryptionParams(_encryptedImageBytes!, _keyImageBytes!),
      );

      setState(() {
        _decryptedImageBytes = decryptedBytes;
        _isDecrypting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Decryption failed: $e';
        _isDecrypting = false;
      });
    }
  }

  static Uint8List _performDecryption(DecryptionParams params) {
    return ImageEncryptionService.decryptImageWithKey(
      params.encryptedImageBytes,
      params.keyImageBytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Decrypt Image'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Encrypted Image Picker
              Text('Select Encrypted Image', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              _buildImagePreview(_encryptedImageBytes),
              ElevatedButton(
                onPressed: () => _pickImage('Encrypted', (bytes) {
                  setState(() => _encryptedImageBytes = bytes);
                }),
                child: Text('Pick Encrypted Image'),
              ),
              SizedBox(height: 20),

              // Key Image Picker
              Text('Select Key Image', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              _buildImagePreview(_keyImageBytes),
              ElevatedButton(
                onPressed: () => _pickImage('Key', (bytes) {
                  setState(() => _keyImageBytes = bytes);
                }),
                child: Text('Pick Key Image'),
              ),

              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isDecrypting ? null : _decryptImage,
                child: _isDecrypting
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(width: 10),
                    Text('Decrypting...'),
                  ],
                )
                    : Text('Decrypt Image'),
              ),

              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: Colors.red, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),

              if (_decryptedImageBytes != null) ...[
                SizedBox(height: 20),
                Text('Decrypted Image', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Image.memory(
                  _decryptedImageBytes!,
                  fit: BoxFit.contain,
                  filterQuality: ui.FilterQuality.medium,
                ),
              ]
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview(Uint8List? imageBytes) {
    if (imageBytes == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(child: Text('No image selected')),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.memory(
        imageBytes,
        height: 200,
        fit: BoxFit.contain,
        filterQuality: ui.FilterQuality.medium,
      ),
    );
  }
}

class DecryptionParams {
  final Uint8List encryptedImageBytes;
  final Uint8List keyImageBytes;

  DecryptionParams(this.encryptedImageBytes, this.keyImageBytes);
}