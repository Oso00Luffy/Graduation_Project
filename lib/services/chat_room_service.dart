import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatRoomService {
  static final _firestore = FirebaseFirestore.instance;

  static Future<Map<String, String>> createRoom({
    required String type, // 'private' or 'group'
    required String name,
  }) async {
    final user = FirebaseAuth.instance.currentUser!;
    final roomId = _firestore.collection('chat_rooms').doc().id;
    final joinToken = _generateJoinToken();
    final members = [user.uid];
    final allowedUids = type == 'private' ? [user.uid] : [];
    final data = {
      'hostUid': user.uid, // <-- Ensure this field matches your hosted rooms filter!
      'hostId': user.uid,  // (optional, for backward compatibility)
      'createdAt': FieldValue.serverTimestamp(),
      'members': members,
      'type': type,
      'name': name,
      'pendingRequests': [],
      'allowedUids': allowedUids,
      'qrJoinToken': joinToken,
    };
    await _firestore.collection('chat_rooms').doc(roomId).set(data);
    return {'roomId': roomId, 'joinToken': joinToken};
  }

  static Future<void> requestJoinGroupRoom(String roomId) async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = _firestore.collection('chat_rooms').doc(roomId);
    await doc.update({
      'pendingRequests': FieldValue.arrayUnion([user.uid])
    });
  }

  static Future<void> approveMember(String roomId, String uid) async {
    final doc = _firestore.collection('chat_rooms').doc(roomId);
    await doc.update({
      'pendingRequests': FieldValue.arrayRemove([uid]),
      'members': FieldValue.arrayUnion([uid]),
      'allowedUids': FieldValue.arrayUnion([uid]),
    });
  }

  static Future<void> joinPrivateRoom(String roomId, String joinToken) async {
    final user = FirebaseAuth.instance.currentUser!;
    final doc = await _firestore.collection('chat_rooms').doc(roomId).get();
    final data = doc.data()!;
    if (data['type'] != 'private') throw Exception('Not a private room');
    if (data['members'].length >= 2) throw Exception('Room full');
    if (data['qrJoinToken'] != joinToken) throw Exception('Invalid token');
    await doc.reference.update({
      'members': FieldValue.arrayUnion([user.uid]),
      'allowedUids': FieldValue.arrayUnion([user.uid]),
    });
  }
  static Future<void> deleteRoom(String roomId) async {
    // Delete all messages in the room
    final messages = await _firestore
        .collection('chat_rooms')
        .doc(roomId)
        .collection('messages')
        .get();
    for (final doc in messages.docs) {
      await doc.reference.delete();
    }
    // Delete the room document itself
    await _firestore.collection('chat_rooms').doc(roomId).delete();
  }
  static String _generateJoinToken() {
    final rand = Random.secure();
    return List.generate(24, (_) => rand.nextInt(36).toRadixString(36)).join();
  }
}