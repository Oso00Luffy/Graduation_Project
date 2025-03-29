import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../services/encryption_service.dart';
import '../widgets/custom_button.dart';

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

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
        _imageBytes = null; // Reset image bytes
      });
    }
  }

  void _encryptImage() async {
    if (_image != null) {
      final bytes = await _image!.readAsBytes();
      final base64String = base64Encode(bytes);
      final encrypted = _encryptionService.encrypt(base64String);
      setState(() {
        _result = encrypted;
      });
    }
  }

  void _decryptImage() {
    if (_result.isNotEmpty) {
      final decrypted = _encryptionService.decrypt(_result);
      final bytes = base64Decode(decrypted);
      setState(() {
        _imageBytes = bytes;
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
            Text('Result: $_result'),
          ],
        ),
      ),
    );
  }
}