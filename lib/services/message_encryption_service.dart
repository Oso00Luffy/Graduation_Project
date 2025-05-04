import 'dart:convert';
import 'package:encrypt/encrypt.dart'; // pub add encrypt

class MessageEncryptionService {
  static final Key _key = Key.fromUtf8('my32lengthsupersecretaes256key!!'); // 32 chars
  static final IV _iv = IV.fromLength(16); // CBC mode requires IV

  static String encryptMessage(String plainText) {
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final encrypted = encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  static String decryptMessage(String encryptedText) {
    final encrypter = Encrypter(AES(_key, mode: AESMode.cbc));
    final decrypted = encrypter.decrypt64(encryptedText, iv: _iv);
    return decrypted;
  }
}