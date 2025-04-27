import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart' as pc;
import 'package:basic_utils/basic_utils.dart';

class EncryptionService {
  // ---------------- AES Encryption ----------------
  static String encryptAES(String message, String key, {String? ivBase64}) {
    if (key.length != 32) {
      throw ArgumentError('AES Key must be exactly 32 characters long.');
    }

    final aesKey = encrypt.Key(Uint8List.fromList(utf8.encode(key)));
    final iv = ivBase64 != null
        ? encrypt.IV.fromBase64(ivBase64)
        : encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey));
    final encrypted = encrypter.encrypt(message, iv: iv);

    final result = {
      'iv': iv.base64,
      'data': encrypted.base64,
    };
    return base64.encode(utf8.encode(jsonEncode(result)));
  }

  static String decryptAES(String base64Data, String key) {
    if (key.length != 32) {
      throw ArgumentError('AES Key must be exactly 32 characters long.');
    }

    final aesKey = encrypt.Key(Uint8List.fromList(utf8.encode(key)));
    final decoded = jsonDecode(utf8.decode(base64.decode(base64Data)));
    final iv = encrypt.IV.fromBase64(decoded['iv']);
    final encryptedData = encrypt.Encrypted.fromBase64(decoded['data']);

    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey));
    return encrypter.decrypt(encryptedData, iv: iv);
  }

  // ---------------- RSA Encryption ----------------
  static String encryptRSA(String message, pc.RSAPublicKey publicKey) {
    final cipher = pc.RSAEngine()
      ..init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(publicKey));
    final input = Uint8List.fromList(utf8.encode(message));
    final encrypted = cipher.process(input);
    return base64.encode(encrypted);
  }

  static String decryptRSA(String base64Data, pc.RSAPrivateKey privateKey) {
    final cipher = pc.RSAEngine()
      ..init(false, pc.PrivateKeyParameter<pc.RSAPrivateKey>(privateKey));
    final input = base64.decode(base64Data);
    final decrypted = cipher.process(input);
    return utf8.decode(decrypted);
  }

  // ---------------- ChaCha20 Encryption ----------------
  static String encryptChaCha20(String message, String key, {String? nonceBase64}) {
    if (key.length != 32) {
      throw ArgumentError('ChaCha20 Key must be exactly 32 characters long.');
    }

    final keyBytes = Uint8List.fromList(utf8.encode(key));
    final nonce = nonceBase64 != null
        ? base64.decode(nonceBase64)
        : _generateSecureRandomBytes(8);

    if (nonce.length != 8) {
      throw ArgumentError('Nonce must be exactly 8 bytes long.');
    }

    final cipher = pc.ChaCha20Engine()
      ..init(true, pc.ParametersWithIV(pc.KeyParameter(keyBytes), nonce));

    final input = Uint8List.fromList(utf8.encode(message));
    final encryptedBytes = cipher.process(input);

    final result = {
      'nonce': base64.encode(nonce),
      'data': base64.encode(encryptedBytes),
    };
    return jsonEncode(result);
  }

  static String decryptChaCha20(String jsonStr, String key, String nonce) {
    if (key.length != 32) {
      throw ArgumentError('ChaCha20 Key must be exactly 32 characters long.');
    }

    final keyBytes = Uint8List.fromList(utf8.encode(key));
    final decoded = jsonDecode(jsonStr);
    final nonce = base64.decode(decoded['nonce']);
    final encryptedData = base64.decode(decoded['data']);

    final cipher = pc.ChaCha20Engine()
      ..init(false, pc.ParametersWithIV(pc.KeyParameter(keyBytes), nonce));

    final decryptedBytes = cipher.process(encryptedData);
    return utf8.decode(decryptedBytes);
  }

  // ---------------- Hybrid Encryption ----------------
  static String hybridEncrypt(String message, String aesKey, String chaChaKey) {
    final aesEncrypted = encryptAES(message, aesKey);
    return encryptChaCha20(aesEncrypted, chaChaKey);
  }

  static String hybridDecrypt(String data, String aesKey, String chaChaKey) {
    final decryptedChaCha = decryptChaCha20(data, chaChaKey, aesKey);
    return decryptAES(decryptedChaCha, aesKey);
  }

  // ---------------- Key Generation ----------------
  static String generateAESKey() {
    final keyBytes = _generateSecureRandomBytes(32); // 32 bytes = 256 bits
    return _formatKey(base64.encode(keyBytes), 32); // Ensure key is exactly 32 characters
  }

  static Map<String, String> generateChaCha20Key() {
    final keyBytes = _generateSecureRandomBytes(32); // 32 bytes = 256 bits
    final nonceBytes = _generateSecureRandomBytes(8); // Nonce is 8 bytes
    return {
      'key': _formatKey(base64.encode(keyBytes), 32), // Ensure key is exactly 32 characters
      'nonce': base64.encode(nonceBytes),
    };
  }

  static Map<String, String> generateHybridKeys() {
    final aesKey = generateAESKey();
    final chaChaKeyData = generateChaCha20Key();
    return {
      'aesKey': aesKey,
      'chaChaKey': chaChaKeyData['key']!,
      'chaChaNonce': chaChaKeyData['nonce']!,
    };
  }

  static Future<pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>> generateRSAKeyPair({int bitLength = 2048}) async {
    final secureRandom = _getSecureRandom();

    final keyGen = pc.RSAKeyGenerator()
      ..init(pc.ParametersWithRandom(
        pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        secureRandom,
      ));

    final pair = keyGen.generateKeyPair();

    final publicKey = pair.publicKey as pc.RSAPublicKey;
    final privateKey = pair.privateKey as pc.RSAPrivateKey;

    return pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>(publicKey, privateKey);
  }

  // ---------------- Parse & Encode RSA Keys ----------------
  static pc.RSAPublicKey parsePublicKeyFromPem(String pem) {
    return CryptoUtils.rsaPublicKeyFromPem(pem);
  }

  static pc.RSAPrivateKey parsePrivateKeyFromPem(String pem) {
    return CryptoUtils.rsaPrivateKeyFromPem(pem);
  }

  static String encodePublicKeyToPem(pc.RSAPublicKey publicKey) {
    return CryptoUtils.encodeRSAPublicKeyToPemPkcs1(publicKey);
  }

  static String encodePrivateKeyToPem(pc.RSAPrivateKey privateKey) {
    return CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(privateKey);
  }

  // ---------------- Utility ----------------
  static pc.SecureRandom _getSecureRandom() {
    final secureRandom = pc.FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  static Uint8List _generateSecureRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => random.nextInt(256)));
  }

  static String _formatKey(String key, int length) {
    if (key.length == length) {
      return key;
    } else if (key.length > length) {
      return key.substring(0, length);
    } else {
      return key.padRight(length, '0'); // Pad with '0' to ensure the length is exactly 32
    }
  }
}