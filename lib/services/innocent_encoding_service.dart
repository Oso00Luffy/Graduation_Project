import 'dart:math';

class InnocentEncodingService {
  /// Encodes the ciphertext as spam, splitting it into chunks and hiding them as order/ref codes.
  static String encodeAsSpam(String ciphertext, {String? password}) {
    final spamLines = [
      "Dear Friend, This is a one-time business offer just for you.",
      "Please consider our revolutionary proposal.",
      "If you wish to unsubscribe, let us know.",
      "This offer will not last long.",
      "Best regards, The Business Team.",
    ];

    // Split ciphertext into up to 4 chunks
    int chunkSize = (ciphertext.length / 4).ceil();
    List<String> chunks = [];
    for (int i = 0; i < ciphertext.length; i += chunkSize) {
      chunks.add(ciphertext.substring(i, (i + chunkSize > ciphertext.length) ? ciphertext.length : i + chunkSize));
    }

    // Insert each chunk as a code line between spam
    List<String> keywords = ["Order No", "Ref", "Discount code", "And don't forget"];
    StringBuffer buf = StringBuffer();
    for (int i = 0; i < spamLines.length; i++) {
      buf.writeln(spamLines[i]);
      if (i < chunks.length) {
        buf.writeln("${keywords[i]}: ${chunks[i]}");
      }
    }
    return buf.toString();
  }

  /// Decodes the hidden ciphertext from spam disguised message.
  static String? decodeFromSpam(String disguised, {String? password}) {
    final pattern = RegExp(r"(Order No|Ref|Discount code|And don't forget): ([A-Za-z0-9+/=]+)");
    final matches = pattern.allMatches(disguised);
    if (matches.isEmpty) return null;
    return matches.map((m) => m.group(2)).join('');
  }

  // --- Fake Spreadsheet ---
  static String encodeAsSpreadsheet(String ciphertext) {
    // Split into 2-3 chunks for realism
    int chunkSize = (ciphertext.length / 3).ceil();
    List<String> chunks = [];
    for (int i = 0; i < ciphertext.length; i += chunkSize) {
      chunks.add(ciphertext.substring(i, (i + chunkSize > ciphertext.length) ? ciphertext.length : i + chunkSize));
    }
    return '''
Item,Value,Note
Revenue,12345,Projected
SecretCode,${chunks.isNotEmpty ? chunks[0] : ''},Hidden
Expense,4321,Monthly
${chunks.length > 1 ? 'Voucher,' + chunks[1] + ',Extra' : ''}
${chunks.length > 2 ? 'ExtraData,' + chunks[2] + ',Misc' : ''}
''';
  }

  static String? decodeFromSpreadsheet(String disguised) {
    final pattern = RegExp(r'(SecretCode|Voucher|ExtraData),([A-Za-z0-9+/=]+),');
    final matches = pattern.allMatches(disguised);
    if (matches.isEmpty) return null;
    return matches.map((m) => m.group(2)).join('');
  }

  // --- Fake PGP ---
  static String encodeAsFakePGP(String ciphertext) =>
      '-----BEGIN PGP MESSAGE-----\n\n$ciphertext\n\n-----END PGP MESSAGE-----';

  static String? decodeFromFakePGP(String disguised) {
    final pattern = RegExp(r'-----BEGIN PGP MESSAGE-----\s*(.*?)\s*-----END PGP MESSAGE-----', dotAll: true);
    final match = pattern.firstMatch(disguised);
    if (match != null) return match.group(1)?.trim();
    return null;
  }

  // --- Fake Russian (Cyrillic) ---
  static String encodeAsFakeRussian(String ciphertext) =>
      'Уважаемый друг,\nЭто секретный код: $ciphertext\nСпасибо!';

  static String? decodeFromFakeRussian(String disguised) {
    final pattern = RegExp(r'код: ([A-Za-z0-9+/=]+)');
    final match = pattern.firstMatch(disguised);
    if (match != null) return match.group(1);
    return null;
  }

  // --- Space ENCODING ---
  static String encodeAsSpace(String ciphertext) {
    final bytes = ciphertext.codeUnits;
    // Each byte to 8 bits, 0 -> space, 1 -> tab
    return bytes
        .map((b) => List.generate(8, (i) => ((b >> (7 - i)) & 1) == 0 ? ' ' : '\t').join())
        .join();
  }

  static String? decodeFromSpace(String disguised) {
    // Only accept space/tab
    final chars = disguised.replaceAll(RegExp(r'[^\t ]'), '');
    if (chars.isEmpty) return null;
    final bits = chars.split('').map((c) => c == '\t' ? 1 : 0).toList();
    if (bits.length % 8 != 0) return null;
    final bytes = <int>[];
    for (int i = 0; i < bits.length; i += 8) {
      int byte = 0;
      for (int j = 0; j < 8; ++j) {
        byte = (byte << 1) | bits[i + j];
      }
      bytes.add(byte);
    }
    try {
      return String.fromCharCodes(bytes);
    } catch (_) {
      return null;
    }
  }
}