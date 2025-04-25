import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:pointycastle/asymmetric/api.dart';
import 'package:pointycastle/random/fortuna_random.dart';
import 'package:ecies/ecies.dart' as ecies;

class EncryptionService {
  // ---------------- AES ----------------
  static String encryptAES(String message, String key) {
    final aesKey = Key.fromUtf8(key.padRight(32, ' '));
    final iv = IV.fromSecureRandom(16);
    final encrypter = Encrypter(AES(aesKey));
    final encrypted = encrypter.encrypt(message, iv: iv);

    final result = {
      'iv': iv.base64,
      'data': encrypted.base64,
    };
    return base64.encode(utf8.encode(jsonEncode(result)));
  }

  static String decryptAES(String encryptedMessage, String key) {
    try {
      final decoded = utf8.decode(base64.decode(encryptedMessage));
      final data = jsonDecode(decoded);
      final iv = IV.fromBase64(data['iv']);
      final encryptedData = data['data'];

      final aesKey = Key.fromUtf8(key.padRight(32, ' '));
      final encrypter = Encrypter(AES(aesKey));
      return encrypter.decrypt64(encryptedData, iv: iv);
    } catch (e) {
      return 'AES Decryption failed: ${e.toString()}';
    }
  }

  // ---------------- RSA ----------------
  static String encryptRSA(String message, RSAPublicKey publicKey) {
    final encrypter = Encrypter(RSA(publicKey: publicKey));
    return encrypter.encrypt(message).base64;
  }

  static String decryptRSA(String encryptedMessage, RSAPrivateKey privateKey) {
    try {
      final encrypter = Encrypter(RSA(privateKey: privateKey));
      return encrypter.decrypt64(encryptedMessage);
    } catch (e) {
      return 'RSA Decryption failed: ${e.toString()}';
    }
  }

  // ---------------- ChaCha20 ----------------
  static String encryptChaCha20(String message, String key) {
    final keyBytes = Uint8List.fromList(utf8.encode(key.padRight(32, ' ')));
    final nonce = IV.fromSecureRandom(12);
    final encrypter = Encrypter(ChaCha20(Key(keyBytes), nonce));
    final encrypted = encrypter.encrypt(message);

    final result = {
      'nonce': nonce.base64,
      'data': encrypted.base64,
    };
    return base64.encode(utf8.encode(jsonEncode(result)));
  }

  static String decryptChaCha20(String encryptedMessage, String key) {
    try {
      final decoded = utf8.decode(base64.decode(encryptedMessage));
      final data = jsonDecode(decoded);
      final nonce = IV.fromBase64(data['nonce']);
      final encryptedData = data['data'];

      final keyBytes = Uint8List.fromList(utf8.encode(key.padRight(32, ' ')));
      final encrypter = Encrypter(ChaCha20(Key(keyBytes), nonce));
      return encrypter.decrypt64(encryptedData);
    } catch (e) {
      return 'ChaCha20 Decryption failed: ${e.toString()}';
    }
  }

  // ---------------- ECC (ECIES) ----------------
  static Future<String> encryptECC(String message, String publicKeyHex) async {
    final messageBytes = utf8.encode(message);
    final encrypted = await ecies.encrypt(publicKeyHex, messageBytes);
    return base64.encode(encrypted);
  }

  static Future<String> decryptECC(String encryptedMessage, String privateKeyHex) async {
    try {
      final encryptedBytes = base64.decode(encryptedMessage);
      final decrypted = await ecies.decrypt(privateKeyHex, encryptedBytes);
      return utf8.decode(decrypted);
    } catch (e) {
      return 'ECC Decryption failed: ${e.toString()}';
    }
  }

  // ---------------- Hybrid (AES + ChaCha20) ----------------
  static String hybridEncrypt(String message, String aesKey, String chaChaKey) {
    final aesEncrypted = encryptAES(message, aesKey);
    return encryptChaCha20(aesEncrypted, chaChaKey);
  }

  static String hybridDecrypt(String encryptedMessage, String aesKey, String chaChaKey) {
    final decryptedChaCha = decryptChaCha20(encryptedMessage, chaChaKey);
    return decryptAES(decryptedChaCha, aesKey);
  }
}
