import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart'; // For compute function
import 'package:image/image.dart' as img; // For resizing images
import '../services/image_encryption_service.dart';

class EncryptImageScreen extends StatefulWidget {
  @override
  _EncryptImageScreenState createState() => _EncryptImageScreenState();
}

class _EncryptImageScreenState extends State<EncryptImageScreen> {
  Uint8List? _plainImageBytes;
  Uint8List? _keyImageBytes;
  final ImagePicker _picker = ImagePicker();
  Uint8List? _encryptedImageBytes;
  String? _errorMessage; // To display error messages
  bool _isEncrypting = false; // To show loading indicator

  Future<void> _pickPlainImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final bytes = await pickedImage.readAsBytes();
      setState(() {
        _plainImageBytes = bytes;
        _errorMessage = null; // Clear errors when a new image is picked
      });
    }
  }

  Future<void> _pickKeyImage() async {
    final pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      final bytes = await pickedImage.readAsBytes();
      setState(() {
        _keyImageBytes = bytes;
        _errorMessage = null; // Clear errors when a new image is picked
      });
    }
  }

  Uint8List resizeImage(Uint8List imageBytes, int targetWidth, int targetHeight) {
    final image = img.decodeImage(imageBytes);
    if (image == null) {
      throw ArgumentError('Invalid image format.');
    }

    final resizedImage = img.copyResize(image, width: targetWidth, height: targetHeight);
    return Uint8List.fromList(img.encodePng(resizedImage));
  }

  Future<void> _encryptImage() async {
    if (_plainImageBytes != null && _keyImageBytes != null) {
      try {
        setState(() {
          _isEncrypting = true; // Show loading indicator
        });

        // Resize the key image if dimensions do not match
        final plainImage = img.decodeImage(_plainImageBytes!);
        final keyImage = img.decodeImage(_keyImageBytes!);

        if (plainImage == null || keyImage == null) {
          setState(() {
            _errorMessage = 'Invalid image format.';
            _isEncrypting = false;
          });
          return;
        }

        if (plainImage.width != keyImage.width || plainImage.height != keyImage.height) {
          _keyImageBytes = resizeImage(
            _keyImageBytes!,
            plainImage.width,
            plainImage.height,
          );
        }

        // Offload encryption process to a background isolate
        final encryptedBytes = await compute(
          _performEncryption,
          EncryptionParams(_plainImageBytes!, _keyImageBytes!),
        );

        setState(() {
          _encryptedImageBytes = encryptedBytes; // Update the UI with the encrypted image
          _errorMessage = null; // Clear errors
          _isEncrypting = false; // Hide loading indicator
        });
      } catch (e) {
        setState(() {
          _errorMessage = 'Encryption failed: $e'; // Display the error message
          _isEncrypting = false; // Hide loading indicator
        });
      }
    } else {
      setState(() {
        _errorMessage = 'Please select both plain and key images.';
      });
    }
  }

  // Background encryption process
  static Uint8List _performEncryption(EncryptionParams params) {
    // Since compute requires a synchronous function, use a synchronous implementation here
    final plainImageBytes = params.plainImageBytes;
    final keyImageBytes = params.keyImageBytes;

    if (plainImageBytes.length != keyImageBytes.length) {
      throw ArgumentError('Plain image and key image must have the same size.');
    }

    Uint8List encryptedBytes = Uint8List(plainImageBytes.length);
    for (int i = 0; i < plainImageBytes.length; i++) {
      encryptedBytes[i] = plainImageBytes[i] ^ keyImageBytes[i];
    }

    return encryptedBytes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Encrypt Image'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Select Plain Image:'),
              _plainImageBytes != null
                  ? SizedBox(
                height: 200, // Constrain the widget's height
                child: Image.memory(
                  _plainImageBytes!,
                  fit: BoxFit.contain,
                ),
              )
                  : Text('No plain image selected.'),
              ElevatedButton(
                onPressed: _pickPlainImage,
                child: Text('Pick Plain Image'),
              ),
              SizedBox(height: 16),
              Text('Select Key Image:'),
              _keyImageBytes != null
                  ? SizedBox(
                height: 200, // Constrain the widget's height
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
                onPressed: _isEncrypting ? null : _encryptImage, // Disable button while encrypting
                child: _isEncrypting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Encrypt'),
              ),
              SizedBox(height: 16),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              if (_encryptedImageBytes != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Encrypted Image:'),
                    SizedBox(
                      height: 200,
                      child: Image.memory(
                        _encryptedImageBytes!,
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

/// Parameters for background encryption
class EncryptionParams {
  final Uint8List plainImageBytes;
  final Uint8List keyImageBytes;

  EncryptionParams(this.plainImageBytes, this.keyImageBytes);
}