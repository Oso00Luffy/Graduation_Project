import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CryptoService {
  static final _algorithm = X25519();
  static final _storage = FlutterSecureStorage();

  /// Generate and store private key locally, return public key bytes (to upload to Firestore)
  static Future<List<int>> generateAndStoreKeyPair(String uid) async {
    final keyPair = await _algorithm.newKeyPair();
    final publicKey = await keyPair.extractPublicKey();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();

    // Store private key securely on device
    await _storage.write(key: 'privateKey_$uid', value: base64Encode(privateKeyBytes));

    // Return public key bytes (to save in Firestore)
    return publicKey.bytes;
  }

  /// Load private key for this user
  static Future<SimpleKeyPair> loadPrivateKey(String uid) async {
    final privateBytesBase64 = await _storage.read(key: 'privateKey_$uid');
    if (privateBytesBase64 == null) {
      throw Exception('No private key found. Generate one first.');
    }
    final privateBytes = base64Decode(privateBytesBase64);
    return _algorithm.newKeyPairFromSeed(privateBytes);
  }

  /// Create public key object from bytes
  static SimplePublicKey publicKeyFromBytes(List<int> bytes) {
    return SimplePublicKey(bytes, type: KeyPairType.x25519);
  }
}