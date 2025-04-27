import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageEncryptionService {
  /// Encrypts an image with another image to produce a blurry encrypted image.
  ///
  /// [plainImageBytes]: The raw bytes of the plain image.
  /// [keyImageBytes]: The raw bytes of the key image.
  ///
  /// Returns the encrypted image bytes as `Uint8List`.
  static Uint8List encryptImageWithImage(Uint8List plainImageBytes, Uint8List keyImageBytes) {
    // Decode the plain and key images
    final plainImage = img.decodeImage(plainImageBytes);
    final keyImage = img.decodeImage(keyImageBytes);

    if (plainImage == null || keyImage == null) {
      throw ArgumentError('Invalid image format');
    }

    // Resize the key image to match the plain image dimensions
    final resizedKeyImage = img.copyResize(
      keyImage,
      width: plainImage.width,
      height: plainImage.height,
    );

    // Create a new image for the encrypted result
    final encryptedImage = img.Image(
      width: plainImage.width,
      height: plainImage.height,
    );

    // Perform the blending/encryption operation
    for (int y = 0; y < plainImage.height; y++) {
      for (int x = 0; x < plainImage.width; x++) {
        final plainPixel = plainImage.getPixel(x, y);
        final keyPixel = resizedKeyImage.getPixel(x, y);

        // Get RGB values from both images using the Pixel API
        final plainR = plainPixel.r;
        final plainG = plainPixel.g;
        final plainB = plainPixel.b;

        final keyR = keyPixel.r;
        final keyG = keyPixel.g;
        final keyB = keyPixel.b;

        // Blending/Encryption: Add and mod 256
        final encryptedR = (plainR + keyR) % 256;
        final encryptedG = (plainG + keyG) % 256;
        final encryptedB = (plainB + keyB) % 256;

        // Set the encrypted pixel in the new image
        encryptedImage.setPixelRgb(x, y, encryptedR, encryptedG, encryptedB);
      }
    }

    // Encode the encrypted image back to bytes
    return Uint8List.fromList(img.encodePng(encryptedImage));
  }

  /// Decrypts an image encrypted with another image to retrieve the original plain image.
  ///
  /// [encryptedImageBytes]: The raw bytes of the encrypted image.
  /// [keyImageBytes]: The raw bytes of the key image.
  ///
  /// Returns the decrypted image bytes as `Uint8List`.
  static Uint8List decryptImageWithImage(Uint8List encryptedImageBytes, Uint8List keyImageBytes) {
    // Decode the encrypted and key images
    final encryptedImage = img.decodeImage(encryptedImageBytes);
    final keyImage = img.decodeImage(keyImageBytes);

    if (encryptedImage == null || keyImage == null) {
      throw ArgumentError('Invalid image format');
    }

    // Resize the key image to match the encrypted image dimensions
    final resizedKeyImage = img.copyResize(
      keyImage,
      width: encryptedImage.width,
      height: encryptedImage.height,
    );

    // Create a new image for the decrypted result
    final decryptedImage = img.Image(
      width: encryptedImage.width,
      height: encryptedImage.height,
    );

    // Perform the reverse blending/decryption operation
    for (int y = 0; y < encryptedImage.height; y++) {
      for (int x = 0; x < encryptedImage.width; x++) {
        final encryptedPixel = encryptedImage.getPixel(x, y);
        final keyPixel = resizedKeyImage.getPixel(x, y);

        // Get RGB values from both images using the Pixel API
        final encryptedR = encryptedPixel.r;
        final encryptedG = encryptedPixel.g;
        final encryptedB = encryptedPixel.b;

        final keyR = keyPixel.r;
        final keyG = keyPixel.g;
        final keyB = keyPixel.b;

        // Reverse Blending/Decryption: Subtract and mod 256
        final decryptedR = (encryptedR - keyR + 256) % 256;
        final decryptedG = (encryptedG - keyG + 256) % 256;
        final decryptedB = (encryptedB - keyB + 256) % 256;

        // Set the decrypted pixel in the new image
        decryptedImage.setPixelRgb(x, y, decryptedR, decryptedG, decryptedB);
      }
    }

    // Encode the decrypted image back to bytes
    return Uint8List.fromList(img.encodePng(decryptedImage));
  }
}