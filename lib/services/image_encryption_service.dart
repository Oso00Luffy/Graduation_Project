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

  static Future<Map<String, dynamic>> encryptImageWithAESRSA(
      Uint8List imageBytes, {
        pc.RSAPublicKey? publicKey,
        pc.RSAPrivateKey? privateKey,
      }) async {
    // Generate AES key and IV
    final aesKey = _randomBytes(32); // AES-256
    final iv = _randomBytes(16);     // 16 bytes IV

    // Encrypt image with AES (PKCS7 padding, CBC)
    final pc.PaddedBlockCipher aesCipher = pc.PaddedBlockCipherImpl(
        pc.PKCS7Padding(), pc.CBCBlockCipher(pc.AESEngine()));
    aesCipher.init(true, pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>(
        pc.ParametersWithIV<pc.KeyParameter>(pc.KeyParameter(aesKey), iv),
        null
    ));
    final encryptedImage = aesCipher.process(imageBytes);

    // Generate RSA keypair if not provided
    pc.RSAPublicKey pub;
    pc.RSAPrivateKey priv;
    if (publicKey == null || privateKey == null) {
      final pair = await _generateRsaKeyPair();
      pub = pair.publicKey;
      priv = pair.privateKey;
    } else {
      pub = publicKey;
      priv = privateKey;
    }

    // Concatenate AES key and IV for RSA encryption
    final aesKeyIv = Uint8List.fromList([...aesKey, ...iv]);

    // RSA encrypt the AES key+IV using OAEP padding
    final rsaEngine = pc.OAEPEncoding(pc.RSAEngine());
    rsaEngine.init(true, pc.PublicKeyParameter<pc.RSAPublicKey>(pub));

    // Make sure we don't exceed RSA key size minus padding (typically for 2048-bit RSA, max is ~200 bytes)
    // AES-256 (32 bytes) + IV (16 bytes) = 48 bytes, which should be well within limits
    final encryptedAesKey = rsaEngine.process(aesKeyIv);

    // Export RSA keys as PEM
    final privateKeyPem = CryptoUtils.encodeRSAPrivateKeyToPem(priv);
    final publicKeyPem = CryptoUtils.encodeRSAPublicKeyToPem(pub);

    return {
      'encryptedImage': encryptedImage,
      'encryptedAesKey': encryptedAesKey,
      'privateKeyPem': privateKeyPem,
      'publicKeyPem': publicKeyPem,
    };
  }

  /// Decrypts AES+RSA encrypted image.
  /// Requires: encryptedImage, encryptedAesKey, and privateKeyPem.
  static Future<Uint8List> decryptImageWithAESRSA(
      Uint8List encryptedImage,
      Uint8List encryptedAesKey,
      String privateKeyPem,
      ) async {
    // Input validation
    if (encryptedImage.isEmpty) {
      throw Exception("Encrypted image data is empty");
    }

    if (encryptedAesKey.isEmpty) {
      throw Exception("Encrypted AES key data is empty");
    }

    if (privateKeyPem.trim().isEmpty) {
      throw Exception("Private key PEM is empty");
    }

    try {
      // Parse private key from PEM
      pc.RSAPrivateKey? privKey;
      try {
        // Try using correct PEM format (with BEGIN/END RSA PRIVATE KEY)
        privKey = CryptoUtils.rsaPrivateKeyFromPem(privateKeyPem);
      } catch (e) {
        print("Initial RSA key parsing failed: $e");
        // Try fixing the PEM format if needed
        final fixedPem = _ensureProperPemFormat(privateKeyPem);
        privKey = CryptoUtils.rsaPrivateKeyFromPem(fixedPem);
      }

      if (privKey == null) {
        throw Exception("Failed to parse RSA private key");
      }

      // Initialize RSA decryption
      final rsaEngine = pc.OAEPEncoding(pc.RSAEngine());
      rsaEngine.init(false, pc.PrivateKeyParameter<pc.RSAPrivateKey>(privKey));

      // Decrypt the AES key and IV
      Uint8List aesKeyIv;
      try {
        aesKeyIv = rsaEngine.process(encryptedAesKey);
      } catch (e) {
        throw Exception("Failed to decrypt AES key: $e");
      }

      print("Decrypted AES key+IV length: ${aesKeyIv.length}");

      if (aesKeyIv.length < 48) {
        throw Exception("Decrypted AES key+IV is too short. Expected at least 48 bytes, got ${aesKeyIv.length}");
      }

      // Extract AES key and IV
      final aesKey = aesKeyIv.sublist(0, 32);
      final iv = aesKeyIv.sublist(32, 48);

      // Initialize AES decryption
      final aesCipher = pc.PaddedBlockCipherImpl(
          pc.PKCS7Padding(),
          pc.CBCBlockCipher(pc.AESEngine())
      );

      aesCipher.init(false,
          pc.PaddedBlockCipherParameters<pc.ParametersWithIV<pc.KeyParameter>, Null>(
              pc.ParametersWithIV<pc.KeyParameter>(pc.KeyParameter(aesKey), iv),
              null
          )
      );

      // Decrypt the image
      Uint8List decryptedImage;
      try {
        decryptedImage = aesCipher.process(encryptedImage);
      } catch (e) {
        throw Exception("Failed to decrypt image: $e");
      }

      return decryptedImage;
    } catch (e) {
      // Add detailed error information
      print("Decryption error: $e");
      throw Exception("Decryption failed: $e");
    }
  }

  // Ensures PEM format is correct with appropriate headers and footers
  static String _ensureProperPemFormat(String pem) {
    final content = pem.trim();
    if (content.startsWith("-----BEGIN") && content.endsWith("KEY-----")) {
      // Already has the correct format
      return content;
    }

    // Try to extract base64 part and wrap it with headers
    String base64Part = content;

    // Remove any non-base64 characters
    base64Part = base64Part.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');

    return """-----BEGIN RSA PRIVATE KEY-----
$base64Part
-----END RSA PRIVATE KEY-----""";
  }

  // --- Helpers ---
  static Uint8List _randomBytes(int length) {
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
}