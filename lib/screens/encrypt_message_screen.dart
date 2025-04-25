import 'package:flutter/material.dart';
import '../services/encryption_service.dart';  // فرضًا أن خدمات التشفير في هذا الملف
import '../widgets/custom_text_field.dart';    // واجهة لإدخال النصوص
import '../widgets/custom_button.dart';        // زر لتفعيل التشفير

class EncryptMessageScreen extends StatefulWidget {
  @override
  _EncryptMessageScreenState createState() => _EncryptMessageScreenState();
}

class _EncryptMessageScreenState extends State<EncryptMessageScreen> {
  final _messageController = TextEditingController();
  final _keyController = TextEditingController();
  String? _encryptedMessage;

  // متغير لاختيار نوع التشفير
  String selectedEncryptionType = 'AES'; // القيمة الافتراضية

  // دالة لتشفير الرسالة بناءً على نوع التشفير المختار
  void _encryptMessage() {
    final message = _messageController.text;
    final key = _keyController.text;

    if (message.isNotEmpty && key.isNotEmpty) {
      String encryptedMessage = '';
      if (selectedEncryptionType == 'AES') {
        encryptedMessage = EncryptionService.encryptAES(message, key);
      } else if (selectedEncryptionType == 'RSA') {
        encryptedMessage = EncryptionService.encryptRSA(message, EncryptionService.publicKey);
      } else if (selectedEncryptionType == 'ChaCha20') {
        encryptedMessage = EncryptionService.encryptChaCha20(message, key);
      } else if (selectedEncryptionType == 'ECC') {
        encryptedMessage = EncryptionService.encryptECC(message, key);
      }

      setState(() {
        _encryptedMessage = encryptedMessage;
      });
    } else {
      setState(() {
        _encryptedMessage = 'Please enter both a message and a key.';
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Encrypt Message'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              // حقل إدخال الرسالة
              CustomTextField(
                controller: _messageController,
                hintText: 'Enter your message',
              ),
              SizedBox(height: 16),

              // حقل إدخال المفتاح
              CustomTextField(
                controller: _keyController,
                hintText: 'Enter your key',
              ),
              SizedBox(height: 16),

              // Dropdown لاختيار نوع التشفير
              DropdownButton<String>(
                value: selectedEncryptionType,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedEncryptionType = newValue!;
                  });
                },
                items: <String>['AES', 'RSA', 'ChaCha20', 'ECC']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              SizedBox(height: 16),

              // زر التشفير
              CustomButton(
                text: 'Encrypt',
                onPressed: _encryptMessage,
              ),
              SizedBox(height: 16),

              // عرض النتيجة بعد التشفير
              if (_encryptedMessage != null)
                SelectableText(
                  'Encrypted Message:\n$_encryptedMessage',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
