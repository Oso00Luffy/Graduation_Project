import 'dart:io';
import 'package:http/http.dart' as http;

class FileTransferService {
  final String endpoint = 'https://e8x7.fra202.idrivee2-99.com'; // Your IDrive e2 endpoint
  final String bucketName = 'your-bucket-name'; // Replace with your bucket name
  final String accessKey = 'your-access-key'; // Replace with your access key
  final String secretKey = 'your-secret-key'; // Replace with your secret key

  /// Uploads a file to IDrive e2 and returns the hosted URL.
  Future<String> uploadFile(String filePath) async {
    final file = File(filePath);

    if (!file.existsSync()) {
      throw Exception('File does not exist.');
    }

    final uploadUrl = Uri.parse('$endpoint/$bucketName/${file.uri.pathSegments.last}');
    final request = http.MultipartRequest('PUT', uploadUrl)
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final response = await request.send();
    if (response.statusCode == 200) {
      return '$endpoint/$bucketName/${file.uri.pathSegments.last}';
    } else {
      throw Exception('Failed to upload file. Status code: ${response.statusCode}');
    }
  }

  /// Downloads a file from IDrive e2 and saves it locally.
  Future<String> downloadFile(Uri downloadUrl, String savePath) async {
    final response = await http.get(downloadUrl);

    if (response.statusCode == 200) {
      final file = File(savePath);
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } else {
      throw Exception('Failed to download file. Status code: ${response.statusCode}');
    }
  }
}