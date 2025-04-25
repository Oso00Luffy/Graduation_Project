import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';

class EncryptionService {
  // ---------------- RSA Key Generation ----------------
  static Map<String, dynamic> generateRSAKeyPair({int bitLength = 2048}) {
    final secureRandom = FortunaRandom();
    final seed = Uint8List.fromList(List<int>.generate(32, (_) => Random.secure().nextInt(256)));
    secureRandom.seed(KeyParameter(seed));

    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        secureRandom,
      ));

    final pair = keyGen.generateKeyPair();
    return {
      'publicKey': pair.publicKey as RSAPublicKey,
      'privateKey': pair.privateKey as RSAPrivateKey,
    };
  }

  static Future<Map<String, dynamic>> generateRSAKeyPairAsync({int bitLength = 2048}) async {
    return await Future.delayed(
      const Duration(milliseconds: 10),
          () => generateRSAKeyPair(bitLength: bitLength),
    );
  }

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

  static Future<String> encryptAESAsync(String message, String key) async {
    return await Future.delayed(
      const Duration(milliseconds: 10),
          () => encryptAES(message, key),
    );
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

  // ---------------- ChaCha20 ----------------
  static String encryptChaCha20(String message, String key, String nonce) {
    if (key.length != 32) {
      throw ArgumentError('ChaCha20 requires a 32-character key.');
    }
    if (nonce.length != 8) {
      throw ArgumentError('ChaCha20 requires exactly 8 characters for nonce.');
    }
    final keyBytes = utf8.encode(key);
    final nonceBytes = utf8.encode(nonce);

    final chacha = ChaCha20Engine()
      ..init(
        true,
        ParametersWithIV(KeyParameter(Uint8List.fromList(keyBytes)), Uint8List.fromList(nonceBytes)),
      );

    final input = utf8.encode(message);
    final output = chacha.process(Uint8List.fromList(input));
    return base64.encode(output);
  }

  static String decryptChaCha20(String cipherText, String key, String nonce) {
    if (key.length != 32) {
      throw ArgumentError('ChaCha20 requires a 32-character key.');
    }
    if (nonce.length != 8) {
      throw ArgumentError('ChaCha20 requires exactly 8 characters for nonce.');
    }
    final keyBytes = utf8.encode(key);
    final nonceBytes = utf8.encode(nonce);

    final chacha = ChaCha20Engine()
      ..init(
        false,
        ParametersWithIV(KeyParameter(Uint8List.fromList(keyBytes)), Uint8List.fromList(nonceBytes)),
      );

    final input = base64.decode(cipherText);
    final output = chacha.process(Uint8List.fromList(input));
    return utf8.decode(output);
  }

  // ---------------- RSA ----------------
  static Encrypter rsaEncrypter({RSAPublicKey? publicKey, RSAPrivateKey? privateKey}) {
    return Encrypter(RSA(
      publicKey: publicKey,
      privateKey: privateKey,
    ));
  }

  static String encryptRSA(String message, RSAPublicKey publicKey) {
    final encrypter = rsaEncrypter(publicKey: publicKey);
    return encrypter.encrypt(message).base64;
  }

  static Future<String> encryptRSAAsync(String message, RSAPublicKey publicKey) async {
    return await Future.delayed(
      const Duration(milliseconds: 10),
          () => encryptRSA(message, publicKey),
    );
  }

  static String decryptRSA(String encryptedMessage, RSAPrivateKey privateKey) {
    try {
      final encrypter = rsaEncrypter(privateKey: privateKey);
      return encrypter.decrypt64(encryptedMessage);
    } catch (e) {
      return 'RSA Decryption failed: ${e.toString()}';
    }
  }

  // ---------------- Hybrid Encryption (RSA + AES) ----------------
  static String hybridEncrypt(String message, RSAPublicKey rsaPublicKey) {
    // 1. Generate random AES key
    final randomAESKeyBytes = List<int>.generate(32, (_) => Random.secure().nextInt(256));
    final aesKeyString = base64.encode(randomAESKeyBytes);

    // 2. Encrypt message using AES
    final encryptedData = encryptAES(message, aesKeyString);

    // 3. Encrypt AES key using RSA
    final encryptedAESKey = encryptRSA(aesKeyString, rsaPublicKey);

    // 4. Combine and encode
    final result = {
      'aesKey': encryptedAESKey,
      'data': encryptedData,
    };

    return base64.encode(utf8.encode(jsonEncode(result)));
  }

  static Future<String> hybridEncryptAsync(String message, RSAPublicKey rsaPublicKey) async {
    return await Future.delayed(
      const Duration(milliseconds: 10),
          () => hybridEncrypt(message, rsaPublicKey),
    );
  }

  static String hybridDecrypt(String encryptedMessage, RSAPrivateKey rsaPrivateKey) {
    try {
      final decoded = utf8.decode(base64.decode(encryptedMessage));
      final data = jsonDecode(decoded);

      final encryptedAESKey = data['aesKey'];
      final encryptedData = data['data'];

      final aesKey = decryptRSA(encryptedAESKey, rsaPrivateKey);
      return decryptAES(encryptedData, aesKey);
    } catch (e) {
      return 'Hybrid Decryption failed: ${e.toString()}';
    }
  }

  // ---------------- Placeholders for image ----------------
  static String encryptImage(String imagePath) => "encrypted image";
  static String decryptImage(String imagePath) => "decrypted image";
}