import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/file_transfer_service.dart';
import '../widgets/custom_button.dart';

class FileSenderScreen extends StatefulWidget {
  @override
  _FileSenderScreenState createState() => _FileSenderScreenState();
}

class _FileSenderScreenState extends State<FileSenderScreen> {
  final _fileTransferService = FileTransferService();
  XFile? _file;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFile() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _file = pickedFile;
    });
  }

  Future<void> _uploadFile() async {
    if (_file != null) {
      await _fileTransferService.uploadFile(
        _file!.path,
        Uri.parse('https://example.com/upload'),
      );
    }
  }

  Future<void> _downloadFile() async {
    await _fileTransferService.downloadFile(
      Uri.parse('https://example.com/download'),
      '/path/to/save/file',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Sender'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            _file != null
                ? Text('Selected file: ${_file!.name}')
                : Text('No file selected.'),
            SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: CustomButton(
                    text: 'Pick File',
                    onPressed: _pickFile,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Upload',
                    onPressed: _uploadFile,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    text: 'Download',
                    onPressed: _downloadFile,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}