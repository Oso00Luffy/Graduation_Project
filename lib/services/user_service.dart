import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';

Future<void> uploadProfilePicture() async {
  final user = FirebaseAuth.instance.currentUser;
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);

  if (pickedFile != null && user != null) {
    final storageRef = FirebaseStorage.instance
        .ref()
        .child('profile_pictures')
        .child(user.uid)
        .child(pickedFile.name);

    await storageRef.putData(await pickedFile.readAsBytes());
    final downloadUrl = await storageRef.getDownloadURL();
    print('Image uploaded! URL: $downloadUrl');
  }
}