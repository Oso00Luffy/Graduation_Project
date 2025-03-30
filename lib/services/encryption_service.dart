import 'package:encrypt/encrypt.dart';

class EncryptionService {
  static String encryptMessage(String message, String key) {
    final aesKey = Key.fromUtf8(key.padRight(32, ' ')); // AES key must be 32 bytes
    final iv = IV.fromLength(16); // AES IV must be 16 bytes
    final encrypter = Encrypter(AES(aesKey));
    final encrypted = encrypter.encrypt(message, iv: iv);
    return encrypted.base64 + iv.base64; // Append IV to the encrypted message
  }

  static String decryptMessage(String encryptedMessage, String key) {
    try {
      final aesKey = Key.fromUtf8(key.padRight(32, ' ')); // AES key must be 32 bytes
      final encryptedData = encryptedMessage.substring(0, encryptedMessage.length - 24); // Remove IV from the end
      final ivData = encryptedMessage.substring(encryptedMessage.length - 24); // Extract IV from the end
      final iv = IV.fromBase64(ivData);
      final encrypter = Encrypter(AES(aesKey));
      return encrypter.decrypt64(encryptedData, iv: iv);
    } catch (e) {
      return 'Decryption failed: ${e.toString()}';
    }
  }

  static String encryptImage(String imagePath) {
    // Implement your image encryption logic here
    return "encrypted image";
  }

  static String decryptImage(String imagePath) {
    // Implement your image decryption logic here
    return "decrypted image";
  }
}