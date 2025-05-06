import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../services/image_encryption_service.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

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
  bool _showSuccess = false;

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
      _showSuccess = false;
    });

    try {
      final encryptedBytes = await compute(
        _performEncryption,
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

  static Uint8List _performEncryption(EncryptionParams params) {
    return ImageEncryptionService.encryptImageWithKey(
      params.plainImageBytes,
      params.keyImageBytes,
    );
  }

  Future<void> _downloadEncryptedImage() async {
    if (_encryptedImageBytes == null) return;

    if (kIsWeb) {
      final blob = html.Blob([_encryptedImageBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'encrypted_image.png')
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      final result = await ImageGallerySaver.saveImage(
        _encryptedImageBytes!,
        quality: 100,
        name: "encrypted_image",
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
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Encrypt Image'),
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
              constraints: BoxConstraints(maxWidth: 440),
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
                          StepperWidget(
                            currentStep: _encryptedImageBytes == null
                                ? (_keyImageBytes == null ? 0 : 1)
                                : 2,
                            steps: [
                              'Select Plain Image',
                              'Select Key Image',
                              'Encrypt & Download',
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

                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [Color(0xFF43e97b), Color(0xFF38f9d7)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                            ),
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
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onPressed: _isEncrypting ? null : _encryptImage,
                            ),
                          ),

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
                          if (_showSuccess && _encryptedImageBytes != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14.0),
                              child: MaterialBanner(
                                backgroundColor: Colors.green.shade100,
                                content: Text(
                                  'Image encrypted successfully!',
                                  style: TextStyle(color: Colors.green[900], fontSize: 15),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => setState(() => _showSuccess = false),
                                    child: Text('Dismiss'),
                                  ),
                                ],
                              ),
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
                                          'Download',
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
                                        onPressed: _downloadEncryptedImage,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
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