import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../services/image_encryption_service.dart';

class EncryptImageScreen extends StatefulWidget {
  @override
  _EncryptImageScreenState createState() => _EncryptImageScreenState();
}

class _EncryptImageScreenState extends State<EncryptImageScreen> {
  Uint8List? _plainImageBytes;
  Uint8List? _keyImageBytes;
  Uint8List? _encryptedImageBytes;
  final ImagePicker _picker = ImagePicker();
  String? _errorMessage;
  bool _isEncrypting = false;

  static const int MAX_IMAGE_SIZE = 5 * 1024 * 1024;

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

  Future<void> _encryptImage() async {
    if (_plainImageBytes == null || _keyImageBytes == null) {
      setState(() {
        _errorMessage = 'Please select both plain and key images.';
      });
      return;
    }

    setState(() {
      _isEncrypting = true;
      _errorMessage = null;
    });

    try {
      final encryptedBytes = await compute(
        _performEncryption,
        EncryptionParams(_plainImageBytes!, _keyImageBytes!),
      );

      setState(() {
        _encryptedImageBytes = encryptedBytes;
        _isEncrypting = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Encryption failed: $e';
        _isEncrypting = false;
      });
    }
  }

  static Uint8List _performEncryption(EncryptionParams params) {
    return ImageEncryptionService.encryptImageWithKey(
      params.plainImageBytes,
      params.keyImageBytes,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Encrypt Image')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Select Plain Image', style: TextStyle(fontSize: 16)),
              SizedBox(height: 8),
              _buildImagePreview(_plainImageBytes),
              ElevatedButton(
                onPressed: () => _pickImage('Plain', (bytes) {
                  setState(() => _plainImageBytes = bytes);
                }),
                child: Text('Pick Plain Image'),
              ),
              SizedBox(height: 20),

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
                onPressed: _isEncrypting ? null : _encryptImage,
                child: _isEncrypting
                    ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(width: 10),
                    Text('Encrypting...'),
                  ],
                )
                    : Text('Encrypt Image'),
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

              if (_encryptedImageBytes != null) ...[
                SizedBox(height: 20),
                Text('Encrypted Image', style: TextStyle(fontSize: 16)),
                SizedBox(height: 8),
                Image.memory(
                  _encryptedImageBytes!,
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

class EncryptionParams {
  final Uint8List plainImageBytes;
  final Uint8List keyImageBytes;

  EncryptionParams(this.plainImageBytes, this.keyImageBytes);
}