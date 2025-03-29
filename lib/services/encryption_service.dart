import 'package:encrypt/encrypt.dart';

class EncryptionService {
  final _key = Key.fromUtf8('my32lengthsupersecretnooneknows1');
  final _iv = IV.fromLength(16);
  final _encrypter = Encrypter(AES(Key.fromUtf8('my32lengthsupersecretnooneknows1')));

  String encrypt(String plainText) {
    final encrypted = _encrypter.encrypt(plainText, iv: _iv);
    return encrypted.base64;
  }

  String decrypt(String encryptedText) {
    final encrypted = Encrypted.fromBase64(encryptedText);
    final decrypted = _encrypter.decrypt(encrypted, iv: _iv);
    return decrypted;
  }
}