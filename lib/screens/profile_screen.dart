import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart'; // For clipboard functionality
import '../widgets/profile_keys_section.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Not logged in, redirect to login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, '/');
      });
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
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
                    backgroundImage: user.photoURL != null
                        ? NetworkImage(user.photoURL!)
                        : AssetImage('assets/images/profile_picture.png')
                    as ImageProvider,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 28),
                      onPressed: () async {
                        // Add logic to upload a new profile picture
                        await _changeProfilePicture(context);
                      },
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
              height: 200, // Adjust as needed for your UI
              child: ProfileKeysSection(), // Updated to include clipboard functionality
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeProfilePicture(BuildContext context) async {
    // Logic for uploading a new profile picture
    // For example, use an image picker and upload to Firebase Storage
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile picture upload feature coming soon!')),
    );
  }
}