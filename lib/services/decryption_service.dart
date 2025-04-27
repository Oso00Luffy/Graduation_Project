import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/asymmetric/api.dart'; // لإدخال مفاتيح RSA بشكل صحيح

class DecryptionService {
  // ---------------- AES Decryption ----------------
  static String decryptAES(String base64Input, String key) {
    final decoded = jsonDecode(utf8.decode(base64.decode(base64Input)));
    final iv = IV.fromBase64(decoded['iv']);
    final encryptedData = Encrypted.fromBase64(decoded['data']);
    final aesKey = Key(Uint8List.fromList(_formatKey(key, 32)));
    final encrypter = Encrypter(AES(aesKey));
    return encrypter.decrypt(encryptedData, iv: iv);
  }

  // ---------------- RSA Decryption ----------------
  static String decryptRSA(String base64Input, RSAPrivateKey privateKey) {
    final encrypted = base64.decode(base64Input);

    // التحقق من طول النص المشفر
    final expectedLength = (privateKey.modulus!.bitLength + 7) ~/ 8;
    if (encrypted.length != expectedLength) {
      throw ArgumentError(
          'Invalid encrypted data length: ${encrypted.length}. Expected: $expectedLength');
    }

    // فك التشفير
    final cipher = RSAEngine()
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final decrypted = cipher.process(encrypted);

    // تحويل النص المفكوك
    return utf8.decode(decrypted);
  }

  // ---------------- ChaCha20 Decryption ----------------
  static String decryptChaCha20(String jsonInput, String key) {
    final parsed = jsonDecode(jsonInput);
    final nonce = base64.decode(parsed['nonce']);
    final data = base64.decode(parsed['data']);
    final keyBytes = _formatKey(key, 32);

    final cipher = ChaCha20Engine()
      ..init(false, ParametersWithIV(KeyParameter(keyBytes), nonce));

    final decryptedBytes = cipher.process(data);
    return utf8.decode(decryptedBytes);
  }

  // ---------------- Hybrid Decryption ----------------
  static String hybridDecrypt(String input, String aesKey, String chaChaKey) {
    final decryptedChaCha = decryptChaCha20(input, chaChaKey);
    return decryptAES(decryptedChaCha, aesKey);
  }

  // ---------------- Utility ----------------
  static Uint8List _formatKey(String key, int length) {
    final keyBytes = Uint8List.fromList(utf8.encode(key));
    if (keyBytes.length == length) {
      return keyBytes;
    } else if (keyBytes.length > length) {
      return keyBytes.sublist(0, length);
    } else {
      final paddedKey = Uint8List(length);
      paddedKey.setAll(0, keyBytes);
      return paddedKey;
    }
  }

  static RSAPrivateKey parsePrivateKey(String privateKeyPem) {
    // تحليل المفتاح الخاص من صيغة PEM
    final parser = RSAKeyParser(); // مكتبة PointyCastle توفر هذا المحلل
    return parser.parse(privateKeyPem) as RSAPrivateKey;
  }
}
