import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:basic_utils/basic_utils.dart';
import '../lib/services/encryption_service.dart';

void main() {
  group('EncryptionService', () {
    const plainText = 'Hello, World! This is a test message!';
    const aesKey = 'mysecretpassword1234567890123456'; // 32 chars
    const chachaKey = 'chacha20supersecretpasswordkey!xx'; // 32 chars
    const chachaNonce = 'uniqueNonce12'; // 12 chars

    test('AES encryption and decryption', () {
      final encrypted = EncryptionService.encryptAES(plainText, aesKey);
      final decrypted = EncryptionService.decryptAES(encrypted, aesKey);
      expect(decrypted, plainText,
          reason: 'AES should encrypt and decrypt correctly with the same key');
    });

    test('RSA encryption and decryption', () {
      // Generate RSA key pair
      final keys = EncryptionService.generateRSAKeyPair();
      final RSAPublicKey publicKey = keys['publicKey'] as RSAPublicKey;
      final RSAPrivateKey privateKey = keys['privateKey'] as RSAPrivateKey;

      final encrypted = EncryptionService.encryptRSA(plainText, publicKey);
      final decrypted = EncryptionService.decryptRSA(encrypted, privateKey);
      expect(decrypted, plainText,
          reason: 'RSA should encrypt with public and decrypt with private correctly');
    });

    test('Hybrid encryption and decryption (RSA + AES)', () {
      // Generate RSA key pair
      final keys = EncryptionService.generateRSAKeyPair();
      final RSAPublicKey publicKey = keys['publicKey'] as RSAPublicKey;
      final RSAPrivateKey privateKey = keys['privateKey'] as RSAPrivateKey;

      final encrypted = EncryptionService.hybridEncrypt(plainText, publicKey);
      final decrypted = EncryptionService.hybridDecrypt(encrypted, privateKey);
      expect(decrypted, plainText,
          reason: 'Hybrid should encrypt with hybridEncrypt and decrypt with hybridDecrypt correctly');
    });

    test('ChaCha20 encryption and decryption', () {
      final encrypted = EncryptionService.encryptChaCha20(plainText, chachaKey, chachaNonce);
      final decrypted = EncryptionService.decryptChaCha20(encrypted, chachaKey, chachaNonce);
      expect(decrypted, plainText,
          reason: 'ChaCha20 should encrypt and decrypt correctly with the same key and nonce');
    });
  });
}