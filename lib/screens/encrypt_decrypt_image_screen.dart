import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../services/encryption_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/show_more_text.dart';

class EncryptDecryptImageScreen extends StatefulWidget {
  @override
  _EncryptDecryptImageScreenState createState() => _EncryptDecryptImageScreenState();
}

class _EncryptDecryptImageScreenState extends State<EncryptDecryptImageScreen> {
  final _encryptionService = EncryptionService();
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  String _result = '';
  Uint8List? _imageBytes;
  String _errorMessage = '';

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
          _imageBytes = null; // Reset image bytes
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to pick image: ${e.toString()}';
      });
    }
  }

  void _encryptImage() async {
    try {
      if (_image != null) {
        final bytes = await _image!.readAsBytes();
        final base64String = base64Encode(bytes);
        final encrypted = _encryptionService.encrypt(base64String);
        setState(() {
          _result = encrypted;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Encryption failed: ${e.toString()}';
      });
    }
  }

  void _decryptImage() {
    try {
      if (_result.isNotEmpty) {
        final decrypted = _encryptionService.decrypt(_result);
        final bytes = base64Decode(decrypted);
        setState(() {
          _imageBytes = bytes;
          _errorMessage = '';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Decryption failed: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Encrypt/Decrypt Images'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _image != null && _imageBytes == null
                ? Image.network(_image!.path)
                : _imageBytes != null
                ? Image.memory(_imageBytes!)
                : Text('No image selected.'),
            SizedBox(height: 16),
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
              ),
            SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: CustomButton(
                    text: 'Pick Image',
                    onPressed: _pickImage,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Encrypt',
                    onPressed: _encryptImage,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Decrypt',
                    onPressed: _decryptImage,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            ShowMoreText(
              text: _result,
            ),
          ],
        ),
      ),
    );
  }
}