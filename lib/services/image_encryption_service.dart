import 'dart:typed_data';
import 'dart:math';
import 'package:image/image.dart' as img;

class ImageEncryptionService {
  static Uint8List encryptImageWithKey(Uint8List plainImageBytes, Uint8List keyImageBytes) {
    var decodedImage = img.decodeImage(plainImageBytes)!;
    var confusionImage = _applyConfusion(decodedImage, keyImageBytes);
    var finalImage = _applyDiffusion(confusionImage, keyImageBytes);
    return Uint8List.fromList(img.encodePng(finalImage));
  }

  static Uint8List decryptImageWithKey(Uint8List encryptedBytes, Uint8List keyImageBytes) {
    var decodedImage = img.decodeImage(encryptedBytes)!;
    var deDiffusedImage = _removeDiffusion(decodedImage, keyImageBytes);
    var originalImage = _removeConfusion(deDiffusedImage, keyImageBytes);
    return Uint8List.fromList(img.encodePng(originalImage));
  }

  // Confusion Phase
  static img.Image _applyConfusion(img.Image image, Uint8List key) {
    final width = image.width;
    final height = image.height;
    final totalPixels = width * height;

    final indices = List<int>.generate(totalPixels, (i) => i);
    final shuffledIndices = _shuffleList(indices, key);

    final tempImage = img.Image(width: width, height: height);

    for (var i = 0; i < totalPixels; i++) {
      final x1 = i % width;
      final y1 = i ~/ width;
      final idx2 = shuffledIndices[i];
      final x2 = idx2 % width;
      final y2 = idx2 ~/ width;

      final pixel = image.getPixel(x1, y1);
      tempImage.setPixel(x2, y2, pixel);
    }

    return tempImage;
  }

  static img.Image _removeConfusion(img.Image image, Uint8List key) {
    final width = image.width;
    final height = image.height;
    final totalPixels = width * height;

    final indices = List<int>.generate(totalPixels, (i) => i);
    final shuffledIndices = _shuffleList(indices, key);

    final tempImage = img.Image(width: width, height: height);

    for (var i = 0; i < totalPixels; i++) {
      final idx2 = shuffledIndices[i];
      final x1 = i % width;
      final y1 = i ~/ width;
      final x2 = idx2 % width;
      final y2 = idx2 ~/ width;

      final pixel = image.getPixel(x2, y2);
      tempImage.setPixel(x1, y1, pixel);
    }

    return tempImage;
  }

  static List<int> _shuffleList(List<int> list, Uint8List key) {
    assert(key.isNotEmpty, "Key must not be empty");
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

  // Diffusion Phase
  static img.Image _applyDiffusion(img.Image image, Uint8List key) {
    final width = image.width;
    final height = image.height;

    int prev = key[0];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final r = ((pixel.r + prev) % 256).toInt();
        final g = ((pixel.g + r) % 256).toInt();
        final b = ((pixel.b + g) % 256).toInt();
        image.setPixelRgba(x, y, r, g, b, 255); // ✅ 6 positional args
        prev = b;
      }
    }
    return image;
  }

  static img.Image _removeDiffusion(img.Image image, Uint8List key) {
    final width = image.width;
    final height = image.height;

    int prev = key[0];
    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final pixel = image.getPixel(x, y);
        final b = ((pixel.b - prev + 256) % 256).toInt();
        final g = ((pixel.g - b + 256) % 256).toInt();
        final r = ((pixel.r - g + 256) % 256).toInt();
        image.setPixelRgba(x, y, r, g, b, pixel.a.toInt()); // ✅ 6 positional args
        prev = pixel.b.toInt();
      }
    }
    return image;
  }
}