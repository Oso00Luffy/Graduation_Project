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

  // Diffusion Phase (Pixel Value Masking)
  static img.Image _applyDiffusion(img.Image image, Uint8List key) {
    final width = image.width, height = image.height;
    final keyLen = key.length;

    // Flatten the pixels (row-major order)
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

    // Diffuse: Each pixel depends on previous pixel and key
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
      // Alpha channel left unchanged
    }

    // Write back
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

    // Reverse diffusion: go backwards
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
      // Alpha channel left unchanged
    }

    // Write back
    final out = img.Image(width: width, height: height);
    for (int i = 0; i < totalPixels; i++) {
      int x = i % width, y = i ~/ width;
      out.setPixelRgba(x, y, pixels[i][0], pixels[i][1], pixels[i][2], pixels[i][3]);
    }
    return out;
  }
}