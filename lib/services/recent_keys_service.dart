import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecentKeysService {
  static Future<void> addKey({
    required String key,
    required String type,
    String? label,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No user logged in');

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('recent_keys')
        .doc();

    await docRef.set({
      'key': key,
      'type': type,
      'label': label ?? '',
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> recentKeysStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('No user logged in');
    }
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('recent_keys')
        .orderBy('created_at', descending: true)
        .snapshots();
  }
}