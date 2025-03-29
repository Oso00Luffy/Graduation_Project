import 'package:flutter/material.dart';
import '../services/encryption_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/show_more_text.dart';

class EncryptDecryptMessageScreen extends StatefulWidget {
  @override
  _EncryptDecryptMessageScreenState createState() => _EncryptDecryptMessageScreenState();
}

class _EncryptDecryptMessageScreenState extends State<EncryptDecryptMessageScreen> {
  final _encryptionService = EncryptionService();
  final _messageController = TextEditingController();
  final _resultController = TextEditingController();
  String _result = '';
  String _errorMessage = '';

  void _encryptMessage() {
    setState(() {
      try {
        _result = _encryptionService.encrypt(_messageController.text);
        _resultController.text = _result;
        _errorMessage = '';
      } catch (e) {
        _errorMessage = 'Encryption failed: ${e.toString()}';
      }
    });
  }

  void _decryptMessage() {
    setState(() {
      try {
        _result = _encryptionService.decrypt(_messageController.text);
        _resultController.text = _result;
        _errorMessage = '';
      } catch (e) {
        _errorMessage = 'Decryption failed: ${e.toString()}';
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _resultController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Encrypt/Decrypt Messages'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            CustomTextField(
              controller: _messageController,
              hintText: 'Enter your message',
            ),
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
                    text: 'Encrypt',
                    onPressed: _encryptMessage,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Decrypt',
                    onPressed: _decryptMessage,
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