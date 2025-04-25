import 'dart:convert';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/export.dart';
import 'package:ecies/ecies.dart' as ecies;

class DecryptionService {
  static String decryptAES(String encryptedMessage, String key) {
    try {
      final decoded = jsonDecode(utf8.decode(base64.decode(encryptedMessage)));
      final iv = IV.fromBase64(decoded['iv']);
      final encryptedData = decoded['data'];
      final aesKey = Key.fromUtf8(key.padRight(32, ' '));
      final encrypter = Encrypter(AES(aesKey));
      return encrypter.decrypt64(encryptedData, iv: iv);
    } catch (e) {
      return 'AES Decryption failed: ${e.toString()}';
    }
  }

  static String decryptRSA(String encryptedMessage, RSAPrivateKey privateKey) {
    try {
      final encrypter = Encrypter(RSA(privateKey: privateKey));
      return encrypter.decrypt64(encryptedMessage);
    } catch (e) {
      return 'RSA Decryption failed: ${e.toString()}';
    }
  }

  static String decryptChaCha20(String encryptedMessage, String key, String nonce) {
    try {
      final decoded = jsonDecode(utf8.decode(base64.decode(encryptedMessage)));
      final nonceBytes = Nonce.fromBase64(decoded['nonce']);
      final chachaKey = Key.fromUtf8(key.padRight(32, ' '));
      final chacha = Encrypter(ChaCha20(chachaKey));
      return chacha.decrypt64(decoded['data'], iv: nonceBytes);
    } catch (e) {
      return 'ChaCha20 Decryption failed: ${e.toString()}';
    }
  }

  static String decryptECC(String encryptedMessage, String privateKeyHex) {
    try {
      final privateKeyBytes = hexToBytes(privateKeyHex);
      final decrypted = ecies.decrypt(privateKeyBytes, base64.decode(encryptedMessage));
      return utf8.decode(decrypted);
    } catch (e) {
      return 'ECC Decryption failed: ${e.toString()}';
    }
  }

  static String decryptHybrid(String encryptedMessage, String key, {bool isAES = true, required String ivOrNonce}) {
    try {
      final decoded = jsonDecode(utf8.decode(base64.decode(encryptedMessage)));
      final encryptedData = decoded['data'];

      if (isAES) {
        return decryptAES(encryptedData, key);
      } else {
        return decryptChaCha20(encryptedData, key, ivOrNonce);
      }
    } catch (e) {
      return 'Hybrid Decryption failed: ${e.toString()}';
    }
  }

  static List<int> hexToBytes(String hex) {
    final buffer = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      buffer.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return buffer;
  }
}
