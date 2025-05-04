import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';

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

      // Add user info to members array if not already a member
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
          .then((_) => setState(() {})); // Refresh on return
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
    // Replace with your app's scheme or domain if you use dynamic links
    return 'mychatapp://chat?room=$roomId';
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

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
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
                        data: _generateRoomLink(_createdRoomId!),
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

// -----------------------------------------------------------

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
    // Defensive: make sure user is in members (in case user navigates directly)
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
    // Remove from members
    await roomDocRef.update({
      'members': FieldValue.arrayRemove([userMap]),
    });

    // After removal, check if room is now empty
    final roomSnap = await roomDocRef.get();
    final data = roomSnap.data() as Map<String, dynamic>?;
    final members = (data?['members'] ?? []) as List<dynamic>;
    if (members.isEmpty) {
      // Delete messages subcollection first
      final messagesSnapshot = await roomDocRef.collection('messages').get();
      for (final doc in messagesSnapshot.docs) {
        await doc.reference.delete();
      }
      // Delete the room document
      await roomDocRef.delete();
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

  @override
  Widget build(BuildContext context) {
    final messagesRef = roomDocRef
        .collection('messages')
        .orderBy('sentAt', descending: false);

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
      body: Column(
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
                    final isMine = msg['senderUid'] == _user?.uid;
                    final senderName = msg['senderName'] ?? msg['senderEmail'] ?? 'User';
                    final senderPhotoURL = msg['senderPhotoURL'];
                    final messageText = msg['text'] ?? '';
                    final sentAt = msg['sentAt'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: Row(
                        mainAxisAlignment:
                        isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Incoming: Show avatar for others
                          if (!isMine)
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: (senderPhotoURL != null && senderPhotoURL != '')
                                  ? NetworkImage(senderPhotoURL)
                                  : const AssetImage('assets/images/profile_picture.png')
                              as ImageProvider,
                            ),
                          if (!isMine) const SizedBox(width: 8),
                          // Message bubble + name + timestamp
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
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF4682B4),
                                      ),
                                    ),
                                  ),
                                Container(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                  decoration: BoxDecoration(
                                    color: isMine ? Colors.blue[100] : Colors.grey[200],
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft:
                                      isMine ? const Radius.circular(16) : const Radius.circular(4),
                                      bottomRight:
                                      isMine ? const Radius.circular(4) : const Radius.circular(16),
                                    ),
                                  ),
                                  child: Text(
                                    messageText,
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 2.0, right: 4.0, left: 4.0),
                                  child: Text(
                                    _formatTimestamp(sentAt),
                                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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