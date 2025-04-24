import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/encryption_service.dart';
import '../widgets/custom_button.dart';

class EncryptImageScreen extends StatefulWidget {
  @override
  _EncryptImageScreenState createState() => _EncryptImageScreenState();
}

class _EncryptImageScreenState extends State<EncryptImageScreen> {
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  String? _encryptedImage;

  Future<void> _pickImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedImage;
    });
  }

  void _encryptImage() {
    if (_image != null) {
      final encryptedImage = EncryptionService.encryptImage(_image!.path);
      setState(() {
        _encryptedImage = encryptedImage;
      });
    } else {
      setState(() {
        _encryptedImage = 'Please select an image.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Encrypt Image'),
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
              text: 'Encrypt',
              onPressed: _encryptImage,
            ),
            SizedBox(height: 16),
            if (_encryptedImage != null)
              Text(
                'Encrypted Image: $_encryptedImage',
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}