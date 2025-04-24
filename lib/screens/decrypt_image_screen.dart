import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/encryption_service.dart';
import '../widgets/custom_button.dart';

class DecryptImageScreen extends StatefulWidget {
  @override
  _DecryptImageScreenState createState() => _DecryptImageScreenState();
}

class _DecryptImageScreenState extends State<DecryptImageScreen> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  String? _decryptedImage;

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage;
    });
  }

  void _decryptImage() {
    if (_image != null) {
      final decryptedImage = EncryptionService.decryptImage(_image!.path);
      setState(() {
        _decryptedImage = decryptedImage;
      });
    } else {
      setState(() {
        _decryptedImage = 'Please select an image.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Decrypt Image'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _image != null
                ? Image.file(File(_image!.path))
                : Text('No image selected.'),
            SizedBox(height: 16),
            CustomButton(
              text: 'Pick Image',
              onPressed: _pickImage,
            ),
            SizedBox(height: 16),
            CustomButton(
              text: 'Decrypt',
              onPressed: _decryptImage,
            ),
            SizedBox(height: 16),
            if (_decryptedImage != null)
              Text(
                'Decrypted Image: $_decryptedImage',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}