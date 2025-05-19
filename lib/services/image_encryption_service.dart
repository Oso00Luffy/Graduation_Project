import 'dart:typed_data';
import 'dart:math';
import 'dart:convert';
import 'package:image/image.dart' as img;
import 'package:pointycastle/export.dart' as pc;
import 'package:basic_utils/basic_utils.dart';

class ImageEncryptionService {
  // ===========================
  // VISUAL CRYPTOGRAPHY SECTION
  // ===========================
  static Uint8List encryptImageWithKey(Uint8List plainImageBytes, Uint8List keyImageBytes) {
    if (plainImageBytes.isEmpty) throw Exception("Input image is empty");
    if (keyImageBytes.isEmpty) throw Exception("Key image is empty");
    final decodedImage = img.decodeImage(plainImageBytes);
    if (decodedImage == null) throw Exception("Input is not a valid image");
    var confusionImage = _applyConfusion(decodedImage, keyImageBytes);
    var finalImage = _applyDiffusion(confusionImage, keyImageBytes);
    return Uint8List.fromList(img.encodePng(finalImage));
  }

  static Uint8List decryptImageWithKey(Uint8List encryptedBytes, Uint8List keyImageBytes) {
    if (encryptedBytes.isEmpty) throw Exception("Encrypted image is empty");
    if (keyImageBytes.isEmpty) throw Exception("Key image is empty");
    final decodedImage = img.decodeImage(encryptedBytes);
    if (decodedImage == null) throw Exception("Input is not a valid image");
    var deDiffusedImage = _removeDiffusion(decodedImage, keyImageBytes);
    var originalImage = _removeConfusion(deDiffusedImage, keyImageBytes);
    return Uint8List.fromList(img.encodePng(originalImage));
  }

  // Confusion Phase (Pixel Shuffling)
  static img.Image _applyConfusion(img.Image image, Uint8List key) {
    final width = image.width, height = image.height;
    final totalPixels = width * height;
    final indices = List<int>.generate(totalPixels, (i) => i);
    final shuffledIndices = _shuffleList(indices, key);
    final tempImage = img.Image(width: width, height: height);
    for (int i = 0; i < totalPixels; i++) {
      final x1 = i % width, y1 = i ~/ width;
      final idx2 = shuffledIndices[i];
      final x2 = idx2 % width, y2 = idx2 ~/ width;
      final pixel = image.getPixel(x1, y1);
      tempImage.setPixelRgba(x2, y2, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), pixel.a.toInt());
    }
    return tempImage;
  }

  static img.Image _removeConfusion(img.Image image, Uint8List key) {
    final width = image.width, height = image.height;
    final totalPixels = width * height;
    final indices = List<int>.generate(totalPixels, (i) => i);
    final shuffledIndices = _shuffleList(indices, key);
    final tempImage = img.Image(width: width, height: height);
    for (int i = 0; i < totalPixels; i++) {
      final idx2 = shuffledIndices[i];
      final x1 = i % width, y1 = i ~/ width;
      final x2 = idx2 % width, y2 = idx2 ~/ width;
      final pixel = image.getPixel(x2, y2);
      tempImage.setPixelRgba(x1, y1, pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt(), pixel.a.toInt());
    }
    return tempImage;
  }

  static List<int> _shuffleList(List<int> list, Uint8List key) {
    if (key.isEmpty) throw Exception("Key must not be empty");
    final seed = key.fold<int>(0, (sum, byte) => (sum + byte) % 99999999);
    final random = Random(seed);
    final result = List<int>.from(list);
    for (var i = result.length - 1; i > 0; i--) {
      final j = random.nextInt(i + 1);
      final temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }
    return result;
  }

  // Diffusion Phase (Pixel Value Masking)
  static img.Image _applyDiffusion(img.Image image, Uint8List key) {
    final width = image.width, height = image.height;
    final keyLen = key.length;
    if (keyLen == 0) throw Exception("Key must not be empty");
    int totalPixels = width * height;
    List<List<int>> pixels = List.generate(
        totalPixels, (_) => List.filled(4, 0),
        growable: false);
    for (int i = 0; i < totalPixels; i++) {
      int x = i % width, y = i ~/ width;
      final p = image.getPixel(x, y);
      pixels[i][0] = p.r.toInt();
      pixels[i][1] = p.g.toInt();
      pixels[i][2] = p.b.toInt();
      pixels[i][3] = p.a.toInt();
    }
    for (int i = 0; i < totalPixels; i++) {
      int k = key[i % keyLen];
      if (i == 0) {
        pixels[i][0] = (pixels[i][0] + k) % 256;
        pixels[i][1] = (pixels[i][1] + k) % 256;
        pixels[i][2] = (pixels[i][2] + k) % 256;
      } else {
        pixels[i][0] = (pixels[i][0] + pixels[i - 1][0] + k) % 256;
        pixels[i][1] = (pixels[i][1] + pixels[i - 1][1] + k) % 256;
        pixels[i][2] = (pixels[i][2] + pixels[i - 1][2] + k) % 256;
      }
    }
    final out = img.Image(width: width, height: height);
    for (int i = 0; i < totalPixels; i++) {
      int x = i % width, y = i ~/ width;
      out.setPixelRgba(x, y, pixels[i][0], pixels[i][1], pixels[i][2], pixels[i][3]);
    }
    return out;
  }

  static img.Image _removeDiffusion(img.Image image, Uint8List key) {
    final width = image.width, height = image.height;
    final keyLen = key.length;
    if (keyLen == 0) throw Exception("Key must not be empty");
    int totalPixels = width * height;
    List<List<int>> pixels = List.generate(
        totalPixels, (_) => List.filled(4, 0),
        growable: false);
    for (int i = 0; i < totalPixels; i++) {
      int x = i % width, y = i ~/ width;
      final p = image.getPixel(x, y);
      pixels[i][0] = p.r.toInt();
      pixels[i][1] = p.g.toInt();
      pixels[i][2] = p.b.toInt();
      pixels[i][3] = p.a.toInt();
    }
    for (int i = totalPixels - 1; i >= 0; i--) {
      int k = key[i % keyLen];
      if (i == 0) {
        pixels[i][0] = (pixels[i][0] - k + 256) % 256;
        pixels[i][1] = (pixels[i][1] - k + 256) % 256;
        pixels[i][2] = (pixels[i][2] - k + 256) % 256;
      } else {
        pixels[i][0] = (pixels[i][0] - pixels[i - 1][0] - k + 256 * 2) % 256;
        pixels[i][1] = (pixels[i][1] - pixels[i - 1][1] - k + 256 * 2) % 256;
        pixels[i][2] = (pixels[i][2] - pixels[i - 1][2] - k + 256 * 2) % 256;
      }
    }
    final out = img.Image(width: width, height: height);
    for (int i = 0; i < totalPixels; i++) {
      int x = i % width, y = i ~/ width;
      out.setPixelRgba(x, y, pixels[i][0], pixels[i][1], pixels[i][2], pixels[i][3]);
    }
    return out;
  }

  // ===========================
  // AES + RSA IMAGE ENCRYPTION
  // ===========================
  // Encrypts image bytes using AES, then encrypts the AES key with RSA.
  // Returns a map with 'encryptedImage', 'encryptedAesKey', 'privateKeyPem', 'publicKeyPem'
  static Future<Map<String, dynamic>> encryptImageWithAESRSA(
      Uint8List imageBytes, {
        pc.RSAPublicKey? publicKey,
        pc.RSAPrivateKey? privateKey,
      }) async {
    // 1. Generate AES key (32 bytes) and IV (16 bytes)
    final aesKey = _generateRandomBytes(32);
    final iv = _generateRandomBytes(16);

    // 2. AES encrypt image
    final cipher = pc.CBCBlockCipher(pc.AESEngine())
      ..init(
        true,
        pc.ParametersWithIV(pc.KeyParameter(aesKey), iv),
      );
    final padded = _pkcs7Pad(imageBytes, 16);
    final encryptedImage = Uint8List(padded.length);
    for (int offset = 0; offset < padded.length; offset += 16) {
      cipher.processBlock(padded, offset, encryptedImage, offset);
    }

    // 3. Generate RSA keypair if not provided
    pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>? keyPair;
    pc.RSAPublicKey pub;
    pc.RSAPrivateKey priv;
    if (publicKey == null || privateKey == null) {
      keyPair = await _generateRsaKeyPair();
      pub = keyPair.publicKey;
      priv = keyPair.privateKey;
    } else {
      pub = publicKey;
      priv = privateKey;
    }

    // 4. Encrypt AES key+IV using RSA
    final aesKeyIv = Uint8List.fromList(aesKey + iv);
    final rsaEngine = pc.OAEPEncoding(pc.RSAEngine())
      ..init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(pub));
    final encryptedAesKey = _rsaProcessInBlocks(rsaEngine, aesKeyIv);

    // 5. Export keys as PEM
    final privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPemPkcs1(priv);
    final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPemPkcs1(pub);

    return {
      'encryptedImage': encryptedImage,
      'encryptedAesKey': encryptedAesKey,
      'privateKeyPem': privateKeyPem,
      'publicKeyPem': publicKeyPem,
    };
  }

  static Future<Uint8List> decryptImageWithAESRSA(
      Uint8List encryptedImage,
      Uint8List encryptedAesKey,
      String privateKeyPem,
      ) async {
    final privKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);

    // 1. Decrypt AES key+IV with RSA private key
    final rsaEngine = pc.OAEPEncoding(pc.RSAEngine())
      ..init(false, pc.PrivateKeyParameter<pc.RSAPrivateKey>(privKey));
    final aesKeyIv = _rsaProcessInBlocks(rsaEngine, encryptedAesKey);

    if (aesKeyIv.length < 48) {
      throw Exception("Decrypted AES key+IV is invalid or corrupted (length: ${aesKeyIv.length})");
    }
    final aesKey = aesKeyIv.sublist(0, 32);
    final iv = aesKeyIv.sublist(32, 48);

    // 2. AES decrypt image
    final cipher = pc.CBCBlockCipher(pc.AESEngine())
      ..init(
        false,
        pc.ParametersWithIV(pc.KeyParameter(aesKey), iv),
      );
    final out = Uint8List(encryptedImage.length);
    for (int offset = 0; offset < encryptedImage.length; offset += 16) {
      cipher.processBlock(encryptedImage, offset, out, offset);
    }
    return _pkcs7Unpad(out);
  }

  /// Standalone utility for AES+RSA decryption (for message screens etc)
  static String decryptAesRsa(
      Uint8List encryptedMessage,
      Uint8List encryptedAesKey,
      pc.RSAPrivateKey privateKey,
      ) {
    // 1. Decrypt AES key+iv with RSA
    final rsaEngine = pc.OAEPEncoding(pc.RSAEngine())
      ..init(false, pc.PrivateKeyParameter<pc.RSAPrivateKey>(privateKey));
    Uint8List decryptedKeyIv = _rsaProcessInBlocks(rsaEngine, encryptedAesKey);

    if (decryptedKeyIv.length < 48) {
      throw Exception("Decrypted AES key+IV is invalid or corrupted (length: ${decryptedKeyIv.length})");
    }
    final aesKey = decryptedKeyIv.sublist(0, 32);    // 32 bytes = 256 bit key
    final iv = decryptedKeyIv.sublist(32, 48);       // 16 bytes = 128 bit IV

    final cipher = pc.CBCBlockCipher(pc.AESEngine());
    final params = pc.PaddedBlockCipherParameters<pc.KeyParameter, pc.ParametersWithIV<pc.KeyParameter>>(
      pc.KeyParameter(aesKey),
      pc.ParametersWithIV<pc.KeyParameter>(pc.KeyParameter(aesKey), iv),
    );
    final paddedBlockCipher = pc.PaddedBlockCipherImpl(pc.PKCS7Padding(), cipher)
      ..init(false, params);

    final decrypted = paddedBlockCipher.process(encryptedMessage);
    return utf8.decode(decrypted);
  }

  // --- Helpers ---
  static Uint8List _generateRandomBytes(int length) {
    final rnd = Random.secure();
    return Uint8List.fromList(List<int>.generate(length, (_) => rnd.nextInt(256)));
  }

  static Future<pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>> _generateRsaKeyPair({int bitLength = 2048}) async {
    final secureRandom = pc.FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(pc.KeyParameter(Uint8List.fromList(seeds)));
    final keyGen = pc.RSAKeyGenerator()
      ..init(pc.ParametersWithRandom(
        pc.RSAKeyGeneratorParameters(BigInt.parse('65537'), bitLength, 64),
        secureRandom,
      ));
    final pair = keyGen.generateKeyPair();
    return pc.AsymmetricKeyPair<pc.RSAPublicKey, pc.RSAPrivateKey>(
      pair.publicKey as pc.RSAPublicKey,
      pair.privateKey as pc.RSAPrivateKey,
    );
  }

  static Uint8List _rsaProcessInBlocks(pc.AsymmetricBlockCipher engine, Uint8List input) {
    var out = <int>[];
    final inputLen = input.length;
    final blockSize = engine.inputBlockSize;
    for (int offset = 0; offset < inputLen; offset += blockSize) {
      int end = (offset + blockSize < inputLen) ? offset + blockSize : inputLen;
      out.addAll(engine.process(input.sublist(offset, end)));
    }
    return Uint8List.fromList(out);
  }

  static Uint8List _pkcs7Pad(Uint8List input, int blockSize) {
    final padLen = blockSize - (input.length % blockSize);
    final padded = Uint8List(input.length + padLen);
    padded.setRange(0, input.length, input);
    for (int i = 0; i < padLen; i++) {
      padded[input.length + i] = padLen;
    }
    return padded;
  }

  static Uint8List _pkcs7Unpad(Uint8List input) {
    int padLen = input.last;
    if (padLen > 16 || padLen == 0) return input; // fallback
    return input.sublist(0, input.length - padLen);
  }
}