import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../services/user_service.dart';
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
  bool _editingName = false;
  late TextEditingController _nameController;
  bool _deletingAccount = false;

  // --- New state for extra features ---
  int _autoLogoutMinutes = 30;
  List<Map<String, String>> _activityLog = [
    {"device": "Chrome (Windows)", "time": "2025-05-04 19:25"},
    {"device": "Pixel 7 (Android)", "time": "2025-05-03 10:12"},
  ];

  @override
  void initState() {
    super.initState();
    _loadProfilePic();
    final user = FirebaseAuth.instance.currentUser;
    _nameController = TextEditingController(text: user?.displayName ?? "");
  }

  Future<void> _loadProfilePic() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (user.photoURL != null && user.photoURL!.isNotEmpty) {
        setState(() {
          _profilePicUrl = user.photoURL;
        });
        return;
      }
      try {
        final storageRef = FirebaseStorage.instance
            .ref()
            .child('profile_pictures')
            .child(user.uid)
            .child('avatar');
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final isVerified = user.emailVerified;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Log Out",
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Profile Pic
            Center(
              child: Stack(
                children: [
                  Hero(
                    tag: 'profile-picture',
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: theme.scaffoldBackgroundColor,
                      backgroundImage: (_profilePicUrl != null && _profilePicUrl!.isNotEmpty)
                          ? NetworkImage(_profilePicUrl!)
                          : const AssetImage('assets/images/profile_picture.png') as ImageProvider,
                    ),
                  ),
                  // Edit Pic Button
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
                          padding: const EdgeInsets.all(7.0),
                          child: _uploading
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                              : const Icon(Icons.camera_alt, size: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // --- Collapsible Account Info ---
            ExpansionTile(
              leading: const Icon(Icons.person),
              title: const Text("Account Info"),
              children: [
                // ---- Display Name ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_editingName)
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _nameController,
                          autofocus: true,
                          decoration: InputDecoration(
                            labelText: "Display Name",
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.check),
                              onPressed: () async {
                                if (_nameController.text.trim().isEmpty) return;
                                await user.updateDisplayName(_nameController.text.trim());
                                await user.reload();
                                setState(() => _editingName = false);
                              },
                            ),
                          ),
                          onSubmitted: (_) async {
                            if (_nameController.text.trim().isEmpty) return;
                            await user.updateDisplayName(_nameController.text.trim());
                            await user.reload();
                            setState(() => _editingName = false);
                          },
                        ),
                      )
                    else
                      Text(
                        user.displayName ?? user.email ?? 'User',
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    IconButton(
                      icon: Icon(_editingName ? Icons.close : Icons.edit),
                      onPressed: () {
                        setState(() => _editingName = !_editingName);
                      },
                      tooltip: _editingName ? "Cancel" : "Edit Name",
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // ---- Email (with copy, verify badge, etc.) ----
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SelectableText(
                      user.email ?? 'No Email',
                      style: theme.textTheme.bodyLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: "Copy Email",
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: user.email ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Email copied')));
                      },
                    ),
                    if (isVerified)
                      Tooltip(
                        message: "Email Verified",
                        child: Icon(Icons.verified, color: Colors.green[600], size: 22),
                      )
                    else
                      TextButton.icon(
                        onPressed: () async {
                          await user.sendEmailVerification();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Verification email sent!')),
                          );
                        },
                        icon: const Icon(Icons.warning, color: Colors.orange, size: 18),
                        label: const Text("Verify", style: TextStyle(fontSize: 12)),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                  ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(user.phoneNumber!),
                  ),
                ListTile(
                  leading: const Icon(Icons.calendar_today),
                  title: Text(
                      "Joined: ${user.metadata.creationTime != null ? "${user.metadata.creationTime!.year}-${user.metadata.creationTime!.month.toString().padLeft(2, "0")}-${user.metadata.creationTime!.day.toString().padLeft(2, "0")}" : "Unknown"}"),
                ),
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: Text(
                      "Last Login: ${user.metadata.lastSignInTime != null ? "${user.metadata.lastSignInTime!.year}-${user.metadata.lastSignInTime!.month.toString().padLeft(2, "0")}-${user.metadata.lastSignInTime!.day.toString().padLeft(2, "0")} ${user.metadata.lastSignInTime!.hour.toString().padLeft(2, "0")}:${user.metadata.lastSignInTime!.minute.toString().padLeft(2, "0")}" : "Unknown"}"),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SelectableText("UID: ${user.uid}", style: theme.textTheme.bodySmall),
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      tooltip: "Copy UID",
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: user.uid));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('UID copied')));
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),

            // --- Collapsible 2FA ---
            ExpansionTile(
              leading: const Icon(Icons.shield),
              title: const Text("Two-Factor Authentication"),
              children: [
                FutureBuilder<bool>(
                  future: getTwoFactorStatus(),
                  builder: (context, snapshot) {
                    final enabled = snapshot.data ?? false;
                    return ListTile(
                      leading: Icon(
                        enabled ? Icons.verified_user : Icons.security,
                        color: enabled ? Colors.green : Colors.teal[600],
                      ),
                      title: Text(enabled ? "2FA Enabled" : "2FA Not Enabled"),
                      subtitle: Text(
                        enabled
                            ? "Your account is protected by two-factor authentication."
                            : "Your account is not protected by two-factor authentication.",
                        style: TextStyle(color: enabled ? Colors.green[700] : Colors.red[700]),
                      ),
                      trailing: OutlinedButton(
                        child: Text(enabled ? "Disable" : "Enable"),
                        onPressed: () async {
                          await setTwoFactorStatus(!enabled);
                          setState(() {}); // Refresh UI
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('2FA ${!enabled ? "enabled" : "disabled"}')),
                          );
                        },
                      ),
                    );
                  },
                )
              ],
            ),

            // --- Collapsible Activity Log ---
            ExpansionTile(
              leading: const Icon(Icons.history),
              title: const Text("Recent Activity"),
              children: [
                ..._activityLog.map((log) => ListTile(
                  leading: const Icon(Icons.devices),
                  title: Text(log["device"]!),
                  subtitle: Text(log["time"]!),
                )),
              ],
            ),

            // --- Collapsible Invite Friends ---
            ExpansionTile(
              leading: const Icon(Icons.group_add),
              title: const Text("Invite Friends"),
              children: [
                ListTile(
                  leading: const Icon(Icons.link),
                  title: const Text("Copy Invite Link"),
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: "https://yourapp.com/invite?uid=${user.uid}"));
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Invite link copied!')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.qr_code),
                  title: const Text("Show QR Code"),
                  onTap: () {
                    // You can implement qr_flutter here!
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Show QR code coming soon!')));
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.share),
                  title: const Text("Share..."),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Share sheet coming soon!')));
                  },
                ),
              ],
            ),

            // --- Collapsible Auto-Logout Timer ---
            ExpansionTile(
              leading: const Icon(Icons.timer),
              title: const Text("Auto-Logout Timer"),
              children: [
                ListTile(
                  title: const Text("Logout after inactivity (minutes)"),
                  trailing: DropdownButton<int>(
                    value: _autoLogoutMinutes,
                    items: [5, 10, 15, 30, 60, 120]
                        .map((m) => DropdownMenuItem(value: m, child: Text(m.toString())))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _autoLogoutMinutes = v);
                    },
                  ),
                ),
              ],
            ),

            // --- Collapsible Keys Section ---
            ExpansionTile(
              leading: const Icon(Icons.key),
              title: const Text("Recent Keys"),
              children: [
                SizedBox(
                  height: 200,
                  child: ProfileKeysSection(),
                ),
              ],
            ),
            const SizedBox(height: 30),
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
      if (bytes.length > 5 * 1024 * 1024) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Image too large. Please pick a smaller file.')),
        );
        setState(() => _uploading = false);
        return;
      }

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('profile_pictures')
          .child(user.uid)
          .child('avatar');

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