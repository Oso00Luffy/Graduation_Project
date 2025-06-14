import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cryptography/cryptography.dart';

class ChatService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;

  // Helper: Get or generate a ChaCha20 key for a room (demo: store in Firestore)
  static Future<SecretKey> _getRoomKey(String roomId) async {
    final doc = await _firestore.collection('chat_rooms').doc(roomId).get();
    if (doc.data()?['encryptionKey'] != null) {
      final keyBytes = base64Decode(doc['encryptionKey']);
      return SecretKey(keyBytes);
    } else {
      final key = SecretKey(List<int>.generate(32, (i) => i + DateTime.now().millisecondsSinceEpoch % 255));
      final keyBytes = await key.extractBytes();
      // Store the key in Firestore (create if missing)
      await _firestore.collection('chat_rooms').doc(roomId).set(
        {'encryptionKey': base64Encode(keyBytes)},
        SetOptions(merge: true),
      );
      return key;
    }
  }

  // Encrypt message text with ChaCha20
  static Future<Map<String, dynamic>> encryptMessage(String plainText, String roomId) async {
    final algorithm = Chacha20.poly1305Aead();
    final key = await _getRoomKey(roomId);
    final nonce = algorithm.newNonce();
    final secretBox = await algorithm.encrypt(
      utf8.encode(plainText),
      secretKey: key,
      nonce: nonce,
    );
    return {
      'cipherText': base64Encode(secretBox.cipherText),
      'nonce': base64Encode(secretBox.nonce),
      'mac': base64Encode(secretBox.mac.bytes),
    };
  }

  // Decrypt message text with ChaCha20
  static Future<String> decryptMessage(Map<String, dynamic> data, String roomId) async {
    final algorithm = Chacha20.poly1305Aead();
    final key = await _getRoomKey(roomId);
    final cipherText = base64Decode(data['cipherText']);
    final nonce = base64Decode(data['nonce']);
    final mac = Mac(base64Decode(data['mac']));
    final secretBox = SecretBox(cipherText, nonce: nonce, mac: mac);
    final clear = await algorithm.decrypt(secretBox, secretKey: key);
    return utf8.decode(clear);
  }

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
    Map<String, dynamic>? encrypted;
    if (text.isNotEmpty) {
      encrypted = await encryptMessage(text, roomId);
    }
    await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .add({
      'senderUid': user.uid,
      'senderName': user.displayName ?? user.email ?? 'User',
      'senderPhotoUrl': user.photoURL,
      'text': '', // Don't store plain text
      'encrypted': encrypted, // Store encrypted map
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
    final bytes = await file.readAsBytes();
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }

  static Future<String?> uploadFile(XFile file, String roomId) async {
    final ref = _storage
        .ref()
        .child('chat_rooms/$roomId/files/${DateTime.now().millisecondsSinceEpoch}_${file.name}');
    final bytes = await file.readAsBytes();
    await ref.putData(bytes);
    return await ref.getDownloadURL();
  }
}
