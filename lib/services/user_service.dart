import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

// ... (other imports and functions)

Future<bool> getTwoFactorStatus() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  return (doc.data()?['twoFactorEnabled'] ?? false) as bool;
}

Future<void> setTwoFactorStatus(bool enabled) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .set({'twoFactorEnabled': enabled}, SetOptions(merge: true));
}

Future<void> uploadProfilePicture() async {
  final user = FirebaseAuth.instance.currentUser;
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null && user != null) {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child(user.uid)
        .child('avatar'); // Always use the same file name for the avatar

    await storageRef.putData(await pickedFile.readAsBytes());
    final downloadUrl = await storageRef.getDownloadURL();
    await user.updatePhotoURL(downloadUrl);
    await user.reload();
    print('Image uploaded! URL: $downloadUrl');
  }
}

/// Store/update the device in user's devices list (maximum 5 devices, newest first)
Future<void> logDevice(String device, String lastUsed) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

  // Fetch current devices list
  final doc = await userDoc.get();
  List devices = doc.data()?['devices'] ?? [];
  devices.removeWhere((d) => d['device'] == device); // Remove if duplicate
  devices.insert(0, {'device': device, 'lastUsed': lastUsed});
  if (devices.length > 5) devices = devices.sublist(0, 5); // Limit list

  await userDoc.set({'devices': devices}, SetOptions(merge: true));
}

/// Fetch user's devices list
Future<List<Map<String, String>>> fetchDevices() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];
  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final data = doc.data();
  if (data == null || data['devices'] == null) return [];
  return List<Map<String, String>>.from(
    (data['devices'] as List).map((e) => Map<String, String>.from(e)),
  );
}

/// Append an activity entry to the user's activity log array
Future<void> logActivity(String action, String time) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;
  final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);

  await userDoc.set({
    'activityLog': FieldValue.arrayUnion([
      {'action': action, 'time': time}
    ])
  }, SetOptions(merge: true));
}

/// Fetch user's activity log array
Future<List<Map<String, String>>> fetchActivityLog() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return [];
  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  final data = doc.data();
  if (data == null || data['activityLog'] == null) return [];
  return List<Map<String, String>>.from(
    (data['activityLog'] as List).map((e) => Map<String, String>.from(e)),
  );
}