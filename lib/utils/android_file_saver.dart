import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

Future<String?> saveFileAndroid(Uint8List bytes, String fileName) async {
  var status = await Permission.storage.request();
  if (!status.isGranted) return null;
  final dir = await getExternalStorageDirectory();
  final file = File('${dir!.path}/$fileName');
  await file.writeAsBytes(bytes);
  return file.path;
}