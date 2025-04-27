import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart'; // Import the file picker package
import '../services/file_transfer_service.dart';

class FileSenderScreen extends StatefulWidget {
  @override
  _FileSenderScreenState createState() => _FileSenderScreenState();
}

class _FileSenderScreenState extends State<FileSenderScreen> {
  final _fileTransferService = FileTransferService();
  File? _file;
  String? _hostedUrl;
  String? _downloadUrl;
  bool _isUploading = false;
  bool _isDownloading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickFile() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _file = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_file == null) {
      _showErrorDialog('No file selected.');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final hostedUrl = await _fileTransferService.uploadFile(_file!.path);

      setState(() {
        _hostedUrl = hostedUrl;
      });

      _showSuccessDialog('File uploaded successfully! Share this URL:\n$hostedUrl');
    } catch (e) {
      _showErrorDialog('Failed to upload file: $e');
    } finally {
      setState(() {
        _isUploading = false);
      });
    }
  }

  Future<void> _downloadFile() async {
    if (_downloadUrl == null || _downloadUrl!.isEmpty) {
      _showErrorDialog('Please enter a valid URL to download the file.');
      return;
    }

    // Let the user choose a save location
    final savePath = await FilePicker.platform.saveFile(
      dialogTitle: 'Select a location to save the file',
      fileName: 'downloaded_file', // Default file name
    );

    if (savePath == null) {
      // User canceled the file selection
      _showErrorDialog('Save location not selected.');
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final savedPath = await _fileTransferService.downloadFile(
        Uri.parse(_downloadUrl!),
        savePath,
      );

      _showSuccessDialog('File downloaded successfully! Saved at:\n$savedPath');
    } catch (e) {
      _showErrorDialog('Failed to download file: $e');
    } finally {
      setState(() {
        _isDownloading = false);
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Step 1: Select a file to upload.'),
            _file != null
                ? Text('Selected file: ${_file!.path.split('/').last}')
                : Text('No file selected.'),
            SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickFile,
                    child: Text('Pick File'),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadFile,
                    child: Text(_isUploading ? 'Uploading...' : 'Upload'),
                  ),
                ),
              ],
            ),
            if (_hostedUrl != null) ...[
              SizedBox(height: 16),
              Text('Hosted URL: $_hostedUrl'),
              SizedBox(height: 8),
              SelectableText(
                _hostedUrl!,
                style: TextStyle(color: Colors.blue),
              ),
            ],
            SizedBox(height: 32),
            Text('Step 2: Enter the hosted URL to download the file.'),
            TextField(
              decoration: InputDecoration(
                labelText: 'Hosted URL',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _downloadUrl = value;
              },
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isDownloading ? null : _downloadFile,
              child: Text(_isDownloading ? 'Downloading...' : 'Download'),
            ),
          ],
        ),
      ),
    );
  }
}