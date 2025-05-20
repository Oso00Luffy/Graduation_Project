import 'dart:typed_data';

/// Utility to extract the file extension from a picked file path or file name.
String getFileExtension(String pathOrName) {
  final dot = pathOrName.lastIndexOf('.');
  if (dot == -1) return '';
  return pathOrName.substring(dot); // includes the dot, e.g., ".jpg"
}

/// Optionally, guess file extension from bytes (for jpg/png/webp/gif only).
String guessImageExtension(Uint8List bytes) {
  if (bytes.length >= 4) {
    // JPEG
    if (bytes[0] == 0xFF && bytes[1] == 0xD8) return ".jpg";
    // PNG
    if (bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) return ".png";
    // GIF
    if (bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) return ".gif";
    // WEBP
    if (bytes[8] == 0x57 &&
        bytes[9] == 0x45 &&
        bytes[10] == 0x42 &&
        bytes[11] == 0x50) return ".webp";
  }
  return "";
}