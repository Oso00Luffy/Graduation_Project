import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class ChatRoomService {
  static final _firestore = FirebaseFirestore.instance;

  // Create a chat room and return its ID
  static Future<String> createRoom() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not authenticated");

    final roomId = const Uuid().v4(); // Random UUID
    await _firestore.collection('chat_rooms').doc(roomId).set({
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'members': [user.uid],
    });
    return roomId;
  }

  // Join a room by roomId (add user to members)
  static Future<void> joinRoom(String roomId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not authenticated");

    final roomRef = _firestore.collection('chat_rooms').doc(roomId);
    await roomRef.update({
      'members': FieldValue.arrayUnion([user.uid]),
    });
  }
}