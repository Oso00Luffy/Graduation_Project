import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:cryptography/cryptography.dart' as crypto;
import 'package:pointycastle/asn1.dart';

class EncryptionService {
  // ==========================================================================
  // AES SECTION (unchanged)
  // ==========================================================================

  static String encryptAes(
      String plaintext,
      String keyBase64, {
        required String ivBase64,
      }) {
    final keyBytes = base64Decode(keyBase64);
    final ivBytes = base64Decode(ivBase64);

    final cipherParams = PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
      ParametersWithIV(KeyParameter(keyBytes), ivBytes),
      null,
    );

    final paddedBlockCipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESFastEngine()),
    );
    paddedBlockCipher.init(true, cipherParams);

    final inputBytes = utf8.encode(plaintext);
    final outputBytes = paddedBlockCipher.process(inputBytes);

    return base64Encode(outputBytes);
  }

  static String decryptAes(
      String ciphertextBase64,
      String keyBase64, {
        required String ivBase64,
      }) {
    final keyBytes = base64Decode(keyBase64);
    final ivBytes = base64Decode(ivBase64);
    final bytesToDecrypt = base64Decode(ciphertextBase64);

    final cipherParams = PaddedBlockCipherParameters<ParametersWithIV<KeyParameter>, Null>(
      ParametersWithIV(KeyParameter(keyBytes), ivBytes),
      null,
    );

    final paddedBlockCipher = PaddedBlockCipherImpl(
      PKCS7Padding(),
      CBCBlockCipher(AESFastEngine()),
    );
    paddedBlockCipher.init(false, cipherParams);

    final outputBytes = paddedBlockCipher.process(bytesToDecrypt);
    return utf8.decode(outputBytes);
  }

  static String generateAesKey() {
    final rnd = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    return base64Encode(keyBytes);
  }

  static String generateAesIv() {
    final rnd = Random.secure();
    final ivBytes = List<int>.generate(16, (_) => rnd.nextInt(256));
    return base64Encode(ivBytes);
  }

  // ==========================================================================
  // MINIMAL RSA SECTION (PKCS#1 PEM, no basic_utils required)
  // ==========================================================================

  static AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> generateRsaKeyPair({int bitLength = 2048}) {
    final generator = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        _secureRandom(),
      ));
    final pair = generator.generateKeyPair();
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );
  }

  static String encryptRsa(String plaintext, RSAPublicKey publicKey) {
    final cipher = RSAEngine()..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));
    final input = Uint8List.fromList(utf8.encode(plaintext));
    final blockSize = cipher.inputBlockSize;
    final output = <int>[];
    for (int offset = 0; offset < input.length; offset += blockSize) {
      final end = (offset + blockSize < input.length) ? offset + blockSize : input.length;
      output.addAll(cipher.process(input.sublist(offset, end)));
    }
    return base64Encode(output);
  }

  static String decryptRsa(String ciphertextBase64, RSAPrivateKey privateKey) {
    final cipher = RSAEngine()..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));
    final input = base64Decode(ciphertextBase64);
    final blockSize = cipher.inputBlockSize;
    final output = <int>[];
    for (int offset = 0; offset < input.length; offset += blockSize) {
      final end = (offset + blockSize < input.length) ? offset + blockSize : input.length;
      output.addAll(cipher.process(input.sublist(offset, end)));
    }
    return utf8.decode(output);
  }

  static String encodeRsaPublicKeyToPem(RSAPublicKey publicKey) {
    final asn1Seq = ASN1Sequence()
      ..add(ASN1Integer(publicKey.modulus!))
      ..add(ASN1Integer(publicKey.exponent!));
    final bytes = asn1Seq.encodedBytes ?? Uint8List(0);
    final b64 = base64Encode(bytes);
    final lines = _chunk(b64, 64);
    return [
      '-----BEGIN RSA PUBLIC KEY-----',
      ...lines,
      '-----END RSA PUBLIC KEY-----'
    ].join('\n');
  }

  static String encodeRsaPrivateKeyToPem(RSAPrivateKey privateKey) {
    final asn1Seq = ASN1Sequence()
      ..add(ASN1Integer(BigInt.zero)) // version
      ..add(ASN1Integer(privateKey.n!))
      ..add(ASN1Integer(privateKey.publicExponent!))
      ..add(ASN1Integer(privateKey.exponent!))
      ..add(ASN1Integer(privateKey.p!))
      ..add(ASN1Integer(privateKey.q!))
      ..add(ASN1Integer(privateKey.exponent! % (privateKey.p! - BigInt.one)))
      ..add(ASN1Integer(privateKey.exponent! % (privateKey.q! - BigInt.one)))
      ..add(ASN1Integer(privateKey.q!.modInverse(privateKey.p!)));
    final bytes = asn1Seq.encodedBytes ?? Uint8List(0);
    final b64 = base64Encode(bytes);
    final lines = _chunk(b64, 64);
    return [
      '-----BEGIN RSA PRIVATE KEY-----',
      ...lines,
      '-----END RSA PRIVATE KEY-----'
    ].join('\n');
  }

  static RSAPublicKey parseRsaPublicKeyPem(String pem) {
    final b64 = pem
        .replaceAll('-----BEGIN RSA PUBLIC KEY-----', '')
        .replaceAll('-----END RSA PUBLIC KEY-----', '')
        .replaceAll('\n', '');
    final bytes = base64Decode(b64);
    final asn1 = ASN1Parser(bytes);
    final seq = asn1.nextObject() as ASN1Sequence;
    final modulus = (seq.elements![0] as ASN1Integer).integer!;
    final exponent = (seq.elements![1] as ASN1Integer).integer!;
    return RSAPublicKey(modulus, exponent);
  }

  static RSAPrivateKey parseRsaPrivateKeyPem(String pem) {
    final b64 = pem
        .replaceAll('-----BEGIN RSA PRIVATE KEY-----', '')
        .replaceAll('-----END RSA PRIVATE KEY-----', '')
        .replaceAll('\n', '');
    final bytes = base64Decode(b64);
    final asn1 = ASN1Parser(bytes);
    final seq = asn1.nextObject() as ASN1Sequence;
    final n = (seq.elements![1] as ASN1Integer).integer!;
    final pubE = (seq.elements![2] as ASN1Integer).integer!;
    final privE = (seq.elements![3] as ASN1Integer).integer!;
    final p = (seq.elements![4] as ASN1Integer).integer!;
    final q = (seq.elements![5] as ASN1Integer).integer!;
    return RSAPrivateKey(n, privE, p, q, pubE);
  }

  static SecureRandom _secureRandom() {
    final secureRandom = FortunaRandom();
    final seed = Uint8List.fromList(List.generate(32, (_) => Random.secure().nextInt(256)));
    secureRandom.seed(KeyParameter(seed));
    return secureRandom;
  }

  static List<String> _chunk(String str, int size) {
    final List<String> chunks = [];
    for (int i = 0; i < str.length; i += size) {
      chunks.add(str.substring(i, (i + size > str.length) ? str.length : i + size));
    }
    return chunks;
  }

  // ==========================================================================
  // ChaCha20 SECTION (unchanged)
  // ==========================================================================

  static Future<String> encryptChacha20(
      String plaintext,
      String keyBase64,
      String nonceBase64,
      ) async {
    final key = crypto.SecretKey(base64Decode(keyBase64));
    final nonce = base64Decode(nonceBase64);

    final algorithm = crypto.Chacha20.poly1305Aead();
    final secretBox = await algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      nonce: nonce,
    );
    final combined = <int>[]
      ..addAll(secretBox.nonce)
      ..addAll(secretBox.cipherText)
      ..addAll(secretBox.mac.bytes);
    return base64Encode(combined);
  }

  static Future<String> decryptChacha20(
      String ciphertextBase64,
      String keyBase64,
      String nonceBase64,
      ) async {
    final key = crypto.SecretKey(base64Decode(keyBase64));
    final nonce = base64Decode(nonceBase64);
    final combined = base64Decode(ciphertextBase64);

    final nonceLen = nonce.length;
    final macLen = 16;
    if (combined.length < nonceLen + macLen) {
      throw Exception("Invalid ciphertext format.");
    }
    final actualNonce = combined.sublist(0, nonceLen);
    final macStart = combined.length - macLen;
    final ciphertext = combined.sublist(nonceLen, macStart);
    final macBytes = combined.sublist(macStart);

    final secretBox = crypto.SecretBox(
      ciphertext,
      nonce: actualNonce,
      mac: crypto.Mac(macBytes),
    );

    final clearData = await crypto.Chacha20.poly1305Aead().decrypt(
      secretBox,
      secretKey: key,
    );
    return utf8.decode(clearData);
  }

  static String generateChachaKey() {
    final rnd = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => rnd.nextInt(256));
    return base64Encode(keyBytes);
  }

  static String generateChachaNonce() {
    final rnd = Random.secure();
    final nonceBytes = List<int>.generate(12, (_) => rnd.nextInt(256));
    return base64Encode(nonceBytes);
  }

  // ==========================================================================
  // Hybrid AES + ChaCha20 (unchanged)
  // ==========================================================================
  static Map<String, String> generateHybridKeys() {
    final aesIv = generateAesIv();
    final chachaKey = generateChachaKey();
    final chachaNonce = generateChachaNonce();
    final aesKey = generateAesKey();
    return {
      'aesKey': aesKey,
      'aesIv': aesIv,
      'chachaKey': chachaKey,
      'chachaNonce': chachaNonce,
    };
  }

  static Future<String> hybridEncrypt(
      String plaintext,
      String aesKeyBase64,
      String chachaKeyBase64, {
        required String ivBase64,
        required String nonceBase64,
      }) async {
    final aesEncrypted = encryptAes(
      plaintext,
      aesKeyBase64,
      ivBase64: ivBase64,
    );

    final doubleEncrypted = await encryptChacha20(aesEncrypted, chachaKeyBase64, nonceBase64);

    return doubleEncrypted;
  }

  static Future<String> hybridDecrypt(
      String ciphertextBase64,
      String aesKeyBase64,
      String chachaKeyBase64, {
        required String ivBase64,
        required String nonceBase64,
      }) async {
    final onceDecrypted = await decryptChacha20(ciphertextBase64, chachaKeyBase64, nonceBase64);

    final original = decryptAes(
      onceDecrypted,
      aesKeyBase64,
      ivBase64: ivBase64,
    );

    return original;
  }
}