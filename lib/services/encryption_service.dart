import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:pointycastle/export.dart' as pc;
import 'package:basic_utils/basic_utils.dart';

class EncryptionService {
  // --- Key Generation ---
  static String generateAesKey() => _formatKey(base64.encode(_generateSecureRandomBytes(32)), 32);
  static String generateChachaKey() => _formatKey(base64.encode(_generateSecureRandomBytes(32)), 32);
  static String generateChachaNonce() => base64.encode(_generateSecureRandomBytes(8));
  static Map<String, String> generateHybridKeys() => {
    'aesKey': generateAesKey(),
    'aesIv': base64.encode(_generateSecureRandomBytes(16)),
    'chaChaKey': generateChachaKey(),
    'chaChaNonce': generateChachaNonce(),
  };

  // --- AES (CBC with IV) ---
  static String encryptAes(String message, String key, {String? ivBase64}) {
    if (key.length != 32) throw ArgumentError('AES key must be 32 chars');
    final aesKey = encrypt.Key(Uint8List.fromList(utf8.encode(key)));
    final iv = ivBase64 != null
        ? encrypt.IV.fromBase64(ivBase64)
        : encrypt.IV.fromSecureRandom(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
    final encrypted = encrypter.encrypt(message, iv: iv);
    final result = {
      'iv': iv.base64,
      'data': encrypted.base64,
    };
    return base64.encode(utf8.encode(jsonEncode(result)));
  }

  static String decryptAes(String base64Data, String key) {
    if (key.length != 32) throw ArgumentError('AES key must be 32 chars');
    final aesKey = encrypt.Key(Uint8List.fromList(utf8.encode(key)));
    final decoded = jsonDecode(utf8.decode(base64.decode(base64Data)));
    final iv = encrypt.IV.fromBase64(decoded['iv']);
    final encryptedData = encrypt.Encrypted.fromBase64(decoded['data']);
    final encrypter = encrypt.Encrypter(encrypt.AES(aesKey, mode: encrypt.AESMode.cbc));
    return encrypter.decrypt(encryptedData, iv: iv);
  }

  // --- ChaCha20 ---
  static String encryptChacha20(String message, String key, String nonceBase64) {
    if (key.length != 32) throw ArgumentError('ChaCha20 key must be 32 chars');
    final keyBytes = Uint8List.fromList(utf8.encode(key));
    final nonce = base64.decode(nonceBase64);
    if (nonce.length != 8) throw ArgumentError('Nonce must be 8 bytes');
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

  static String decryptChacha20(String jsonStr, String key, String nonceBase64) {
    if (key.length != 32) throw ArgumentError('ChaCha20 key must be 32 chars');
    final keyBytes = Uint8List.fromList(utf8.encode(key));
    final decoded = jsonDecode(jsonStr);
    final nonce = base64.decode(nonceBase64);
    final encryptedData = base64.decode(decoded['data']);
    final cipher = pc.ChaCha20Engine()
      ..init(false, pc.ParametersWithIV(pc.KeyParameter(keyBytes), nonce));
    final decryptedBytes = cipher.process(encryptedData);
    return utf8.decode(decryptedBytes);
  }

  // --- HYBRID: AES + ChaCha20 ---
  static String hybridEncrypt(
      String message,
      String aesKey,
      String chaChaKey, {
        String? ivBase64,
        String? nonceBase64,
      }) {
    // 1. AES encrypt
    final aesEncrypted = encryptAes(message, aesKey, ivBase64: ivBase64);
    // 2. ChaCha20 encrypt
    final chachaNonce = nonceBase64 ?? generateChachaNonce();
    final result = encryptChacha20(aesEncrypted, chaChaKey, chachaNonce);
    // The result is a JSON string with {"nonce":..., "data":...}
    return result;
  }

  static String hybridDecrypt(
      String hybridData,
      String aesKey,
      String chaChaKey, {
        required String ivBase64,
        required String nonceBase64,
      }) {
    // 1. ChaCha20 decrypt
    final chachaDecrypted = decryptChacha20(hybridData, chaChaKey, nonceBase64);
    // 2. AES decrypt
    return decryptAes(chachaDecrypted, aesKey);
  }

  // --- RSA ---
  static Future<pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>> generateRsaKeyPair({int bitLength = 2048}) async {
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

  static String encryptRsa(String message, pc.RSAPublicKey key) => encryptRSA(message, key);
  static String decryptRsa(String base64Cipher, pc.RSAPrivateKey key) => decryptRSA(base64Cipher, key);

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

  // --- PEM helpers ---
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

  // --- Utility ---
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
    if (key.length == length) return key;
    if (key.length > length) return key.substring(0, length);
    return key.padRight(length, '0');
  }
}