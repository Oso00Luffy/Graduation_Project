import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({Key? key}) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _joinRoomController = TextEditingController();
  String? _createdRoomId;
  String? _lastJoinedRoomId;
  bool _creatingRoom = false;
  bool _joiningRoom = false;
  String? _error;

  @override
  void dispose() {
    _joinRoomController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() {
      _creatingRoom = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("You must be logged in.");

      final roomId = const Uuid().v4();
      await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).set({
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'members': [
          {
            'uid': user.uid,
            'displayName': user.displayName ?? user.email ?? 'User',
            'photoURL': user.photoURL,
          }
        ],
      });
      setState(() {
        _createdRoomId = roomId;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to create room: $e";
      });
    } finally {
      setState(() {
        _creatingRoom = false;
      });
    }
  }

  Future<void> _joinRoom() async {
    final roomId = _joinRoomController.text.trim();
    if (roomId.isEmpty) {
      setState(() {
        _error = "Please enter a room ID.";
      });
      return;
    }
    setState(() {
      _joiningRoom = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception("You must be logged in.");

      final roomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(roomId);
      final snapshot = await roomRef.get();
      if (!snapshot.exists) {
        setState(() {
          _error = "Room not found.";
        });
        return;
      }

      final userMap = {
        'uid': user.uid,
        'displayName': user.displayName ?? user.email ?? 'User',
        'photoURL': user.photoURL,
      };
      await roomRef.update({
        'members': FieldValue.arrayUnion([userMap]),
      });

      setState(() {
        _lastJoinedRoomId = roomId;
      });

      if (!mounted) return;
      Navigator.of(context)
          .push(MaterialPageRoute(
          builder: (_) => ChatScreen(roomId: roomId)))
          .then((_) => setState(() {}));
    } catch (e) {
      setState(() {
        _error = "Failed to join room: $e";
      });
    } finally {
      setState(() {
        _joiningRoom = false;
      });
    }
  }

  void _goToCreatedRoom() {
    if (_createdRoomId != null) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ChatScreen(roomId: _createdRoomId!)));
    }
  }

  String _generateRoomLink(String roomId) {
    return 'sccapp://chat?room=$roomId';
  }

  Widget _buildCopyRoomCodeSection({required String roomId, String? label}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            if (label != null)
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            if (label != null) const SizedBox(width: 10),
            Expanded(
              child: SelectableText(
                roomId,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.copy),
              tooltip: "Copy Room Code",
              onPressed: () {
                Clipboard.setData(ClipboardData(text: roomId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Room code copied!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteRoom(String roomId) async {
    final roomRef = FirebaseFirestore.instance.collection('chat_rooms').doc(roomId);
    // Delete all messages
    final messages = await roomRef.collection('messages').get();
    for (var msg in messages.docs) {
      await msg.reference.delete();
    }
    // Delete room doc
    await roomRef.delete();
    setState(() {
      if (_createdRoomId == roomId) _createdRoomId = null;
      if (_lastJoinedRoomId == roomId) _lastJoinedRoomId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);

    // Robust: Always use the latest user for the stream
    final myCreatedRoomsStream = (user == null)
        ? Stream<QuerySnapshot<Object?>>.empty()
        : FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('createdAt', isNotEqualTo: null)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Rooms'),
        actions: [
          if (user != null)
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
            )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: ListView(
          children: [
            // --- Hosted Rooms Section ---
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Your Hosted Rooms",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    StreamBuilder<QuerySnapshot>(
                      stream: myCreatedRoomsStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }
                        final docs = snapshot.data!.docs;
                        if (docs.isEmpty) {
                          return const Text("You haven't created any rooms.");
                        }
                        return Column(
                          children: docs.map((room) {
                            final roomId = room.id;
                            final createdAt = (room['createdAt'] as Timestamp?)?.toDate();
                            return ListTile(
                              title: Text(roomId),
                              subtitle: createdAt != null
                                  ? Text("Created: ${createdAt.toLocal()}")
                                  : null,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chat),
                                    tooltip: "Enter Room",
                                    onPressed: () {
                                      Navigator.of(context).push(MaterialPageRoute(
                                        builder: (_) => ChatScreen(roomId: roomId),
                                      ));
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete),
                                    tooltip: "Delete Room",
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          title: const Text("Delete Room?"),
                                          content: const Text("This will delete all messages in the room."),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                                            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                                          ],
                                        ),
                                      );
                                      if (confirmed ?? false) {
                                        await _deleteRoom(roomId);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            if (_createdRoomId != null)
              _buildCopyRoomCodeSection(roomId: _createdRoomId!, label: "Created Room Code"),
            if (_lastJoinedRoomId != null)
              _buildCopyRoomCodeSection(roomId: _lastJoinedRoomId!, label: "Last Joined Room"),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "Create a new chat room",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    if (_createdRoomId == null)
                      _creatingRoom
                          ? const CircularProgressIndicator()
                          : ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text("Create Room"),
                        onPressed: _createRoom,
                      ),
                    if (_createdRoomId != null) ...[
                      const Text("Room created!"),
                      QrImageView(
                        data: 'sccapp://chat?room=$_createdRoomId',
                        size: 160,
                        backgroundColor: Colors.white,
                      ),
                      SelectableText(
                        _generateRoomLink(_createdRoomId!),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.chat_bubble),
                        label: const Text("Enter Room"),
                        onPressed: _goToCreatedRoom,
                      )
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "Join a chat room",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _joinRoomController,
                      decoration: const InputDecoration(
                        labelText: "Enter Room ID",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    _joiningRoom
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                      icon: const Icon(Icons.login),
                      label: const Text("Join Room"),
                      onPressed: _joinRoom,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------- ChatScreen -------------------

class ChatScreen extends StatefulWidget {
  final String roomId;
  const ChatScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  late final User? _user;
  late final CollectionReference chatRoomRef;
  late final DocumentReference roomDocRef;
  late Stream<DocumentSnapshot<Object?>> _roomStream;

  // Drag-and-drop support (for web/desktop)
  bool _dragging = false;

  @override
  void initState() {
    super.initState();
    _user = FirebaseAuth.instance.currentUser;
    chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms');
    roomDocRef = chatRoomRef.doc(widget.roomId);
    _roomStream = roomDocRef.snapshots();
    _addCurrentUserToRoom();
  }

  @override
  void dispose() {
    _removeCurrentUserFromRoom();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _addCurrentUserToRoom() async {
    if (_user == null) return;
    final userMap = {
      'uid': _user!.uid,
      'displayName': _user!.displayName ?? _user!.email ?? 'User',
      'photoURL': _user!.photoURL,
    };
    await roomDocRef.update({
      'members': FieldValue.arrayUnion([userMap]),
    });
  }

  Future<void> _removeCurrentUserFromRoom() async {
    if (_user == null) return;
    final userMap = {
      'uid': _user!.uid,
      'displayName': _user!.displayName ?? _user!.email ?? 'User',
      'photoURL': _user!.photoURL,
    };
    try {
      await roomDocRef.update({
        'members': FieldValue.arrayRemove([userMap]),
      });

      final roomSnap = await roomDocRef.get();
      final data = roomSnap.data() as Map<String, dynamic>?;
      final members = (data?['members'] ?? []) as List<dynamic>;
      if (members.isEmpty) {
        final messagesSnapshot = await roomDocRef.collection('messages').get();
        for (final doc in messagesSnapshot.docs) {
          await doc.reference.delete();
        }
        await roomDocRef.delete();
      }
    } catch (_) {
      // Room might already be deleted, ignore errors
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    final now = Timestamp.now();
    await roomDocRef.collection('messages').add({
      'senderUid': _user?.uid,
      'senderEmail': _user?.email,
      'senderName': _user?.displayName ?? _user?.email ?? 'User',
      'senderPhotoURL': _user?.photoURL,
      'text': text,
      'sentAt': now,
    });
    _messageController.clear();
  }

  // ----- Media/File Sending -----

  Future<void> _sendImage({File? file, XFile? xfile}) async {
    XFile? picked;
    if (xfile == null && file == null) {
      final picker = ImagePicker();
      picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    }
    final usedFile = file ?? (picked != null ? File(picked.path) : null);
    if (usedFile == null && xfile == null) return;

    final fileName = xfile?.name ?? picked?.name ?? usedFile!.path.split('/').last;
    final storageRef = FirebaseStorage.instance.ref().child('chat_images/${widget.roomId}/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    final task = await storageRef.putFile(usedFile ?? File(xfile!.path));
    final url = await task.ref.getDownloadURL();
    await roomDocRef.collection('messages').add({
      'senderUid': _user?.uid,
      'senderEmail': _user?.email,
      'senderName': _user?.displayName ?? _user?.email ?? 'User',
      'senderPhotoURL': _user?.photoURL,
      'imageUrl': url,
      'imageName': fileName,
      'sentAt': Timestamp.now(),
    });
  }

  Future<void> _sendFile({File? file, PlatformFile? pfile}) async {
    PlatformFile? pickedFile = pfile;
    if (file == null && pfile == null) {
      final result = await FilePicker.platform.pickFiles();
      if (result == null || result.files.isEmpty) return;
      pickedFile = result.files.single;
    }
    final fileName = pickedFile?.name ?? file!.path.split('/').last;
    final storageRef = FirebaseStorage.instance.ref().child('chat_files/${widget.roomId}/${DateTime.now().millisecondsSinceEpoch}_$fileName');
    UploadTask task;
    if (pickedFile != null && pickedFile.bytes != null) {
      task = storageRef.putData(pickedFile.bytes!, SettableMetadata(contentType: pickedFile.extension));
    } else if (file != null) {
      task = storageRef.putFile(file);
    } else {
      return;
    }
    final url = await (await task).ref.getDownloadURL();
    await roomDocRef.collection('messages').add({
      'senderUid': _user?.uid,
      'senderEmail': _user?.email,
      'senderName': _user?.displayName ?? _user?.email ?? 'User',
      'senderPhotoURL': _user?.photoURL,
      'fileUrl': url,
      'fileName': fileName,
      'sentAt': Timestamp.now(),
    });
  }

  // Drag-and-drop support for web/desktop
  Widget _buildDropZone({required Widget child}) {
    return DragTarget<XFile>(
      onWillAccept: (data) {
        setState(() => _dragging = true);
        return true;
      },
      onLeave: (data) {
        setState(() => _dragging = false);
      },
      onAccept: (xfile) async {
        setState(() => _dragging = false);
        await _sendImage(xfile: xfile);
      },
      builder: (context, candidateData, rejectedData) {
        return Stack(
          children: [
            child,
            if (_dragging)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.15),
                    border: Border.all(color: Colors.blue, width: 3),
                  ),
                  child: const Center(
                    child: Text(
                      "Drop image here to send",
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  // Launch file or image URL
  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not launch file!')),
      );
    }
  }

  // File preview (basic)
  Widget _filePreviewWidget(String url, String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg') ||
        lower.endsWith('.png') || lower.endsWith('.gif') || lower.endsWith('.bmp') ||
        lower.endsWith('.webp')) {
      return GestureDetector(
        onTap: () => _launchUrl(url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(url, width: 210, height: 210, fit: BoxFit.cover, errorBuilder: (c, _, __) => Icon(Icons.broken_image, size: 48)),
        ),
      );
    } else if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi')) {
      return GestureDetector(
        onTap: () => _launchUrl(url),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam, color: Colors.blue),
            const SizedBox(width: 8),
            Flexible(child: Text(fileName, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.blue))),
          ],
        ),
      );
    } else {
      return GestureDetector(
        onTap: () => _launchUrl(url),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.insert_drive_file, color: Colors.blue),
            const SizedBox(width: 8),
            Flexible(child: Text(fileName, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline))),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final messagesRef = roomDocRef
        .collection('messages')
        .orderBy('sentAt', descending: false);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Room: ${widget.roomId.substring(0, 8)}...'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: "Copy Room Code",
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.roomId));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Room code copied!')),
              );
            },
          ),
        ],
      ),
      body: _buildDropZone(
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: messagesRef.snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const Center(child: Text("No messages yet."));
                  }
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final msg = docs[index];
                      final data = msg.data() as Map<String, dynamic>?;
                      final isMine = data?['senderUid'] == _user?.uid;
                      final senderName = data?['senderName'] ?? data?['senderEmail'] ?? 'User';
                      final senderPhotoURL = data?['senderPhotoURL'];
                      final messageText = data?['text'] ?? '';
                      final sentAt = data?['sentAt'];

                      final Color myBubbleColor = colorScheme.primary.withOpacity(isDark ? 0.25 : 0.13);
                      final Color otherBubbleColor = isDark
                          ? colorScheme.surface.withOpacity(0.9)
                          : colorScheme.surface.withOpacity(0.95);

                      final TextStyle myTextStyle = theme.textTheme.bodyLarge!.copyWith(
                        color: colorScheme.onPrimary,
                      );
                      final TextStyle otherTextStyle = theme.textTheme.bodyLarge!.copyWith(
                        color: colorScheme.onSurface,
                      );
                      final Color textColor = isDark ? Colors.white : Colors.black;

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Row(
                          mainAxisAlignment:
                          isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isMine)
                              CircleAvatar(
                                radius: 18,
                                backgroundImage: (senderPhotoURL != null && senderPhotoURL != '')
                                    ? NetworkImage(senderPhotoURL)
                                    : const AssetImage('assets/images/profile_picture.png')
                                as ImageProvider,
                              ),
                            if (!isMine) const SizedBox(width: 8),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: isMine
                                    ? CrossAxisAlignment.end
                                    : CrossAxisAlignment.start,
                                children: [
                                  if (!isMine)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 2.0, bottom: 2.0),
                                      child: Text(
                                        senderName,
                                        style: theme.textTheme.bodySmall!.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: colorScheme.secondary,
                                        ),
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                    decoration: BoxDecoration(
                                      color: isMine ? myBubbleColor : otherBubbleColor,
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(16),
                                        topRight: const Radius.circular(16),
                                        bottomLeft: isMine ? const Radius.circular(16) : const Radius.circular(4),
                                        bottomRight: isMine ? const Radius.circular(4) : const Radius.circular(16),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (data != null && data.containsKey('imageUrl'))
                                          GestureDetector(
                                            onTap: () => _launchUrl(data['imageUrl']),
                                            child: ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: Image.network(
                                                data['imageUrl'],
                                                width: 210,
                                                height: 210,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 48),
                                              ),
                                            ),
                                          ),
                                        if (data != null && data.containsKey('fileUrl'))
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: 8.0),
                                            child: _filePreviewWidget(data['fileUrl'], data['fileName'] ?? "File"),
                                          ),
                                        if (messageText.isNotEmpty)
                                          Text(
                                            messageText,
                                            style: (isMine ? myTextStyle : otherTextStyle).copyWith(
                                              color: textColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 17,
                                              shadows: [
                                                Shadow(
                                                  blurRadius: 2.5,
                                                  color: isDark
                                                      ? Colors.black.withOpacity(0.9)
                                                      : Colors.white.withOpacity(0.8),
                                                  offset: const Offset(0.5, 0.5),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0, right: 4.0, left: 4.0),
                                    child: Text(
                                      _formatTimestamp(sentAt),
                                      style: theme.textTheme.bodySmall!.copyWith(
                                        color: theme.textTheme.bodySmall!.color?.withOpacity(0.6),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isMine) const SizedBox(width: 8),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image),
                      tooltip: "Send Image",
                      onPressed: _sendImage,
                    ),
                    IconButton(
                      icon: const Icon(Icons.attach_file),
                      tooltip: "Send File",
                      onPressed: _sendFile,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: _sendMessage,
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic ts) {
    if (ts is Timestamp) {
      final dt = ts.toDate();
      return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
    }
    return "";
  }
}