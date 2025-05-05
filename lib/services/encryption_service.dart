import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'package:pointycastle/export.dart' as pc;
import 'package:basic_utils/basic_utils.dart';

class EncryptionService {
  // --- AES-256/CBC ---
  static String generateAESKey() => base64.encode(_randomBytes(32));
  static String generateIV() => base64.encode(_randomBytes(8)); // 8 bytes IV

  static String encryptAES(String message, String base64Key, {String? base64IV, required String ivBase64}) {
    final key = base64.decode(base64Key);
    final iv = base64IV != null ? base64.decode(base64IV) : _randomBytes(8);

    if (key.length != 32) throw ArgumentError('AES key must decode to 32 bytes.');
    if (iv.length != 8) throw ArgumentError('AES IV must decode to 8 bytes.');

    final cipher = pc.PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        true,
        pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>(
          pc.ParametersWithIV(pc.KeyParameter(key), iv),
          null,
        ),
      );

    final plain = utf8.encode(message);
    final encrypted = cipher.process(Uint8List.fromList(plain));
    return jsonEncode({
      'iv': base64.encode(iv),
      'data': base64.encode(encrypted),
    });
  }

  static String decryptAES(String jsonData, String base64Key) {
    final key = base64.decode(base64Key);
    final map = jsonDecode(jsonData);
    final iv = base64.decode(map['iv']);
    final encrypted = base64.decode(map['data']);

    if (key.length != 32) throw ArgumentError('AES key must decode to 32 bytes.');
    if (iv.length != 8) throw ArgumentError('AES IV must decode to 8 bytes.');

    final cipher = pc.PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        false,
        pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>(
          pc.ParametersWithIV(pc.KeyParameter(key), iv),
          null,
        ),
      );
    final decrypted = cipher.process(Uint8List.fromList(encrypted));
    return utf8.decode(decrypted);
  }

  // --- ChaCha20 (8-byte nonce/IV) ---
  static String generateChaCha20Key() => base64.encode(_randomBytes(32));
  static String generateChaCha20Nonce() => base64.encode(_randomBytes(8)); // 8 bytes per PointyCastle spec

  static String encryptChaCha20(String message, String base64Key, String base64Nonce) {
    final key = base64.decode(base64Key);
    final nonce = base64.decode(base64Nonce);

    if (key.length != 32) throw Exception('ChaCha20 key must be 32 bytes (base64-encoded 44 chars)');
    if (nonce.length != 8) throw Exception('ChaCha20 nonce must be 8 bytes (base64-encoded 12 chars)');

    final pc.ChaCha20Engine engine = pc.ChaCha20Engine()
      ..init(true, pc.ParametersWithIV(pc.KeyParameter(key), nonce));
    final plain = utf8.encode(message);
    final encrypted = engine.process(Uint8List.fromList(plain));

    return jsonEncode({
      'nonce': base64.encode(nonce),
      'data': base64.encode(encrypted),
    });
  }

  static String decryptChaCha20(String jsonData, String base64Key) {
    final key = base64.decode(base64Key);
    final map = jsonDecode(jsonData);
    final nonce = base64.decode(map['nonce']);
    final encrypted = base64.decode(map['data']);

    if (key.length != 32) throw Exception('ChaCha20 key must be 32 bytes');
    if (nonce.length != 8) throw Exception('ChaCha20 nonce must be 8 bytes');

    final pc.ChaCha20Engine engine = pc.ChaCha20Engine()
      ..init(false, pc.ParametersWithIV(pc.KeyParameter(key), nonce));
    final decrypted = engine.process(encrypted);
    return utf8.decode(decrypted);
  }

  // --- Hybrid: AES then ChaCha20 (all 8 bytes IV/nonce) ---
  static String hybridEncrypt(String message, String base64AesKey, String base64AesIv, String base64ChaChaKey, String base64ChaChaNonce) {
    // AES Encrypt
    final aesKey = base64.decode(base64AesKey);
    final aesIv = base64.decode(base64AesIv);
    if (aesKey.length != 32) throw ArgumentError('AES key must decode to 32 bytes.');
    if (aesIv.length != 8) throw ArgumentError('AES IV must decode to 8 bytes.');

    final cipher = pc.PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        true,
        pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>(
          pc.ParametersWithIV(pc.KeyParameter(aesKey), aesIv),
          null,
        ),
      );
    final aesEncrypted = cipher.process(Uint8List.fromList(utf8.encode(message)));
    final aesResult = jsonEncode({
      'iv': base64.encode(aesIv),
      'data': base64.encode(aesEncrypted),
    });

    // ChaCha20 Encrypt
    return encryptChaCha20(aesResult, base64ChaChaKey, base64ChaChaNonce);
  }

  static String hybridDecrypt(String jsonData, String base64AesKey, String base64ChaChaKey) {
    // ChaCha20 Decrypt
    final aesResult = decryptChaCha20(jsonData, base64ChaChaKey);

    // AES Decrypt
    final map = jsonDecode(aesResult);
    final aesIv = base64.decode(map['iv']);
    final aesEncrypted = base64.decode(map['data']);
    final aesKey = base64.decode(base64AesKey);

    if (aesKey.length != 32) throw ArgumentError('AES key must decode to 32 bytes.');
    if (aesIv.length != 8) throw ArgumentError('AES IV must decode to 8 bytes.');

    final cipher = pc.PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        false,
        pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>(
          pc.ParametersWithIV(pc.KeyParameter(aesKey), aesIv),
          null,
        ),
      );
    final decrypted = cipher.process(aesEncrypted);
    return utf8.decode(decrypted);
  }

  // --- RSA ---
  static Future<pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>> generateRSAKeyPair({int bitLength = 2048}) async {
    final secureRandom = _secureRandom();
    final keyGen = pc.RSAKeyGenerator()
      ..init(pc.ParametersWithRandom(
        pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        secureRandom,
      ));
    final pair = keyGen.generateKeyPair();
    return pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>(
        pair.publicKey as pc.RSAPublicKey, pair.privateKey as pc.RSAPrivateKey);
  }

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

  // --- Utility ---
  static Uint8List _randomBytes(int length) {
    final rand = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => rand.nextInt(256)));
  }

  static pc.SecureRandom _secureRandom() {
    final secureRandom = pc.FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }
}