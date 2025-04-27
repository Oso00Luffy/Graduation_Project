import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // For compute function
import '../services/image_encryption_service.dart';

class DecryptImageScreen extends StatefulWidget {
  @override
  _DecryptImageScreenState createState() => _DecryptImageScreenState();
}

class _DecryptImageScreenState extends State<DecryptImageScreen> {
  Uint8List? _encryptedImageBytes;
  Uint8List? _keyImageBytes;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _decryptedImageBytes;
  String? _errorMessage;
  bool _isDecrypting = false;

  Future<void> _pickEncryptedImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final bytes = await pickedImage.readAsBytes();
      setState(() {
        _encryptedImageBytes = bytes;
        _errorMessage = null;
      });
    }
  }

  Future<void> _pickKeyImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final bytes = await pickedImage.readAsBytes();
      setState(() {
        _keyImageBytes = bytes;
        _errorMessage = null;
      });
    }
  }

  Future<void> _decryptImage() async {
    if (_encryptedImageBytes != null && _keyImageBytes != null) {
      try {
        setState(() {
          _isDecrypting = true;
        });

        final decryptedBytes = await compute(
          _performDecryption,
          DecryptionParams(_encryptedImageBytes!, _keyImageBytes!),
        );

        setState(() {
          _decryptedImageBytes = decryptedBytes;
          _errorMessage = null;
          _isDecrypting = false;
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Decryption failed: $e';
          _isDecrypting = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Please select both encrypted and key images.';
      });
    }
  }

  static Uint8List _performDecryption(DecryptionParams params) {
    // Use the correct method from the ImageEncryptionService
    return ImageEncryptionService.decryptImageWithImage(
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text('Select Encrypted Image:'),
              _encryptedImageBytes != null
                  ? SizedBox(
                height: 200,
                child: Image.memory(
                  _encryptedImageBytes!,
                  fit: BoxFit.contain,
                ),
              )
                  : Text('No encrypted image selected.'),
              ElevatedButton(
                onPressed: _pickEncryptedImage,
                child: Text('Pick Encrypted Image'),
              ),
              SizedBox(height: 16),
              Text('Select Key Image:'),
              _keyImageBytes != null
                  ? SizedBox(
                height: 200,
                child: Image.memory(
                  _keyImageBytes!,
                  fit: BoxFit.contain,
                ),
              )
                  : Text('No key image selected.'),
              ElevatedButton(
                onPressed: _pickKeyImage,
                child: Text('Pick Key Image'),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isDecrypting ? null : _decryptImage,
                child: _isDecrypting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Decrypt'),
              ),
              SizedBox(height: 16),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              if (_decryptedImageBytes != null)
                Column(
                  children: [
                    Text('Decrypted Image:'),
                    SizedBox(
                      height: 200,
                      child: Image.memory(
                        _decryptedImageBytes!,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class DecryptionParams {
  final Uint8List encryptedImageBytes;
  final Uint8List keyImageBytes;

  DecryptionParams(this.encryptedImageBytes, this.keyImageBytes);
}