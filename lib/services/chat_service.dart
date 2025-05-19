import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class ChatService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  static Stream<QuerySnapshot> messagesStream(String roomId) {
    return _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('sentAt', descending: false)
        .snapshots();
  }

  static Future<void> sendMessage({
    required String roomId,
    required String text,
    String? imageUrl,
    String? fileUrl,
    String? fileName,
    String? fileType,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'senderUid': user.uid,
      'senderName': user.displayName ?? user.email ?? 'User',
      'senderPhotoUrl': user.photoURL,
      'text': text,
      'imageUrl': imageUrl,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'fileType': fileType,
      'sentAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<String?> uploadImage(XFile file, String roomId) async {
    final ref = _storage
        .ref()
        .child('chat_rooms/$roomId/images/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
    await ref.putFile(File(file.path));
    return await ref.getDownloadURL();
  }

  static Future<String?> uploadFile(XFile file, String roomId) async {
    final ref = _storage
        .ref()
        .child('chat_rooms/$roomId/files/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
    await ref.putFile(File(file.path));
    return await ref.getDownloadURL();
  }
}