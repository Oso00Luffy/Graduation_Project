import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // For clipboard functionality
import '../widgets/profile_keys_section.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ProfileScreen extends StatefulWidget {
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _uploading = false;
  String? _profilePicUrl;

  @override
  void initState() {
    super.initState();
    _loadProfilePic();
  }

  Future<void> _loadProfilePic() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // Try to fetch the latest profile picture from Storage
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child(user.uid)
            .child('avatar'); // You can use a default name, or load the latest
        final url = await storageRef.getDownloadURL();
        setState(() {
          _profilePicUrl = url;
        });
      } catch (e) {
        setState(() {
          _profilePicUrl = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Profile Picture with Upload Button
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 80,
                    backgroundImage: _profilePicUrl != null
                        ? NetworkImage(_profilePicUrl!)
                        : const AssetImage('assets/images/profile_picture.png')
                    as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _uploading
                          ? null
                          : () async {
                        await _changeProfilePicture(context, user);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: _uploading
                              ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2),
                          )
                              : const Icon(Icons.camera_alt, size: 28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Name
            const Text(
              'Name:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              user.displayName ?? 'No Name',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Email
            const Text(
              'Email:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              user.email ?? 'No Email',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            // Recent Keys Section
            const Text(
              'Recent Keys:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 200,
              child: ProfileKeysSection(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeProfilePicture(BuildContext context, User user) async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 75,
      );

      if (pickedFile == null) {
        setState(() => _uploading = false);
        return;
      }

      setState(() => _uploading = true);

      final bytes = await pickedFile.readAsBytes();
      // Optional: limit file size, e.g. 5MB
      if (bytes.length > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Image too large. Please pick a smaller file.')),
        );
        setState(() => _uploading = false);
        return;
      }

      // Use any extension, store as 'avatar' in user's folder
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(user.uid)
          .child('avatar'); // always overwrites the old one

      final uploadTask = storageRef.putData(bytes);

      uploadTask.snapshotEvents.listen((event) {}, onError: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload error: $e')),
        );
        setState(() => _uploading = false);
      });

      final snapshot = await uploadTask;
      if (snapshot.state == TaskState.error) {
        throw Exception('Upload failed');
      }

      final url = await storageRef.getDownloadURL();

      await user.updatePhotoURL(url);
      await user.reload();

      setState(() {
        _profilePicUrl = url;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to upload: $e')),
      );
    } finally {
      setState(() => _uploading = false);
    }
  }
}