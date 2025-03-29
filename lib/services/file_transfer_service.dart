import 'dart:convert';
import 'package:http/http.dart' as http;

class FileTransferService {
  Future<void> uploadFile(String filePath, Uri uri) async {
    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    var response = await request.send();

    if (response.statusCode == 200) {
      print('File uploaded successfully.');
    } else {
      print('File upload failed.');
    }
  }

  Future<void> downloadFile(Uri uri, String savePath) async {
    var response = await http.get(uri);

    if (response.statusCode == 200) {
      var fileBytes = response.bodyBytes;
      // Save file to local storage
      // File(savePath).writeAsBytesSync(fileBytes);
      print('File downloaded successfully.');
    } else {
      print('File download failed.');
    }
  }
}