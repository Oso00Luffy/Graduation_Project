import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/export.dart';
import 'package:basic_utils/basic_utils.dart';
import 'package:pointycastle/api.dart';

class EncryptionService {
  // ---- Secure Random ----
  static final _secureRandom = Random.secure();

  static Uint8List _randomBytes(int length) =>
      Uint8List.fromList(List.generate(length, (_) => _secureRandom.nextInt(256)));

  // ---- PKCS7 Padding Helpers ----
  static Uint8List pkcs7Pad(Uint8List bytes, [int blockSize = 16]) {
    final pad = blockSize - (bytes.length % blockSize);
    return Uint8List.fromList(bytes + List.filled(pad, pad));
  }

  static Uint8List pkcs7Unpad(Uint8List padded) {
    final pad = padded.last;
    return padded.sublist(0, padded.length - pad);
  }

  // ---- AES (ECB, PKCS7) ---- NO IV
  static String generateAesKey() => base64.encode(_randomBytes(32));

  static String encryptAes(String plaintext, String base64Key) {
    final key = base64.decode(base64Key);
    final padded = pkcs7Pad(Uint8List.fromList(utf8.encode(plaintext)));
    final cipher = AESEngine()..init(true, KeyParameter(key));
    final encrypted = Uint8List(padded.length);
    int offset = 0;
    while (offset < padded.length) {
      cipher.processBlock(padded, offset, encrypted, offset);
      offset += cipher.blockSize;
    }
    return base64.encode(encrypted);
  }

  static String decryptAes(String base64Cipher, String base64Key) {
    final key = base64.decode(base64Key);
    final cipher = AESEngine()..init(false, KeyParameter(key));
    final encrypted = base64.decode(base64Cipher);
    final decrypted = Uint8List(encrypted.length);
    int offset = 0;
    while (offset < encrypted.length) {
      cipher.processBlock(encrypted, offset, decrypted, offset);
      offset += cipher.blockSize;
    }
    final unpadded = pkcs7Unpad(decrypted);
    return utf8.decode(unpadded);
  }

  // ---- ChaCha20 (12-byte nonce, 32-byte key) ----
  static String generateChachaKey() => base64.encode(_randomBytes(32));
  static String generateChachaNonce() => base64.encode(_randomBytes(12));

  static String encryptChacha20(String plaintext, String base64Key, String base64Nonce) {
    final key = base64.decode(base64Key);
    final nonce = base64.decode(base64Nonce);
    final cipher = StreamCipher('ChaCha20')
      ..init(true, ParametersWithIV(KeyParameter(key), nonce));
    final encrypted = cipher.process(Uint8List.fromList(utf8.encode(plaintext)));
    return base64.encode(encrypted);
  }

  static String decryptChacha20(String base64Cipher, String base64Key, String base64Nonce) {
    final key = base64.decode(base64Key);
    final nonce = base64.decode(base64Nonce);
    final cipher = StreamCipher('ChaCha20')
      ..init(false, ParametersWithIV(KeyParameter(key), nonce));
    final decrypted = cipher.process(base64.decode(base64Cipher));
    return utf8.decode(decrypted);
  }

  // ---- RSA (OAEP) ----
  static Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>> generateRsaKeyPair() async {
    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        FortunaRandom()..seed(KeyParameter(_randomBytes(32))),
      ));
    final pair = keyGen.generateKeyPair();
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );
  }

  static String encryptRsa(String plaintext, RSAPublicKey publicKey) {
    final cipher = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    final data = utf8.encode(plaintext);
    final encrypted = cipher.process(Uint8List.fromList(data));
    return base64.encode(encrypted);
  }

  static String decryptRsa(String base64Cipher, RSAPrivateKey privateKey) {
    final cipher = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final decrypted = cipher.process(base64.decode(base64Cipher));
    return utf8.decode(decrypted);
  }

  // ---- Hybrid Encryption (AES in ECB + RSA) ----
  // Encrypts message with AES, then encrypts AES key with RSA, returns JSON
  static String hybridEncrypt(String plaintext, RSAPublicKey rsaPublicKey) {
    final aesKey = _randomBytes(32);

    // AES encryption (ECB, PKCS7)
    final padded = pkcs7Pad(Uint8List.fromList(utf8.encode(plaintext)));
    final cipher = AESEngine()..init(true, KeyParameter(aesKey));
    final aesEncrypted = Uint8List(padded.length);
    int offset = 0;
    while (offset < padded.length) {
      cipher.processBlock(padded, offset, aesEncrypted, offset);
      offset += cipher.blockSize;
    }

    // Encrypt AES key with RSA
    final rsaCipher = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(rsaPublicKey));
    final encryptedKey = rsaCipher.process(Uint8List.fromList(aesKey));

    // Output as JSON
    final result = {
      'data': base64.encode(aesEncrypted),
      'key': base64.encode(encryptedKey),
    };
    return jsonEncode(result);
  }

  static String hybridDecrypt(String hybridJson, RSAPrivateKey rsaPrivateKey) {
    final parsed = jsonDecode(hybridJson) as Map<String, dynamic>;
    final aesEncrypted = base64.decode(parsed['data']);
    final encryptedKey = base64.decode(parsed['key']);

    // Decrypt AES key
    final rsaCipher = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(rsaPrivateKey));
    final aesKey = rsaCipher.process(encryptedKey);

    // AES decryption (ECB, PKCS7)
    final cipher = AESEngine()..init(false, KeyParameter(aesKey));
    final decrypted = Uint8List(aesEncrypted.length);
    int offset = 0;
    while (offset < aesEncrypted.length) {
      cipher.processBlock(aesEncrypted, offset, decrypted, offset);
      offset += cipher.blockSize;
    }
    final unpadded = pkcs7Unpad(decrypted);
    return utf8.decode(unpadded);
  }

  // ---- Double Encryption (any two) ----
  static String doubleEncrypt({
    required String plaintext,
    required String first, // "AES", "RSA", "ChaCha20", "Hybrid"
    required String second,
    required Map<String, dynamic> params,
  }) {
    String encrypted = plaintext;

    // First encryption
    encrypted = _applyEncryption(encrypted, first, params);
    // Second encryption
    encrypted = _applyEncryption(encrypted, second, params);

    return encrypted;
  }

  static String _applyEncryption(String data, String algo, Map<String, dynamic> params) {
    switch (algo) {
      case "AES":
        return encryptAes(data, params['aesKey']);
      case "ChaCha20":
        return encryptChacha20(data, params['chachaKey'], params['chachaNonce']);
      case "RSA":
        return encryptRsa(data, params['rsaPublicKey']);
      case "Hybrid":
        return hybridEncrypt(data, params['rsaPublicKey']);
      default:
        throw ArgumentError("Unknown algorithm: $algo");
    }
  }

  static String doubleDecrypt({
    required String ciphertext,
    required String first, // "AES", "RSA", "ChaCha20", "Hybrid"
    required String second,
    required Map<String, dynamic> params,
  }) {
    String decrypted = ciphertext;
    // Reverse order for decryption
    decrypted = _applyDecryption(decrypted, second, params);
    decrypted = _applyDecryption(decrypted, first, params);
    return decrypted;
  }

  static String _applyDecryption(String data, String algo, Map<String, dynamic> params) {
    switch (algo) {
      case "AES":
        return decryptAes(data, params['aesKey']);
      case "ChaCha20":
        return decryptChacha20(data, params['chachaKey'], params['chachaNonce']);
      case "RSA":
        return decryptRsa(data, params['rsaPrivateKey']);
      case "Hybrid":
        return hybridDecrypt(data, params['rsaPrivateKey']);
      default:
        throw ArgumentError("Unknown algorithm: $algo");
    }
  }
}