import 'package:flutter/material.dart';
import '../services/encryption_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';

class EncryptDecryptMessageScreen extends StatefulWidget {
  @override
  _EncryptDecryptMessageScreenState createState() => _EncryptDecryptMessageScreenState();
}

class _EncryptDecryptMessageScreenState extends State<EncryptDecryptMessageScreen> {
  final _encryptionService = EncryptionService();
  final _messageController = TextEditingController();
  final _resultController = TextEditingController();
  String _result = '';

  void _encryptMessage() {
    setState(() {
      _result = _encryptionService.encrypt(_messageController.text);
      _resultController.text = _result;
    });
  }

  void _decryptMessage() {
    setState(() {
      _result = _encryptionService.decrypt(_messageController.text);
      _resultController.text = _result;
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
            CustomTextField(
              controller: _resultController,
              hintText: 'Result',
            ),
          ],
        ),
      ),
    );
  }
}