import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';

import '../services/chat_room_service.dart';
import '../services/chat_service.dart';
import 'chat_screen.dart';

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({Key? key}) : super(key: key);

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  // Room creation
  String? _createdRoomId;
  String? _createdRoomToken;
  String? _createdRoomType; // 'private' or 'group'
  final TextEditingController _roomNameController = TextEditingController();
  String _roomType = 'private';
  String? _createError;

  // Join room
  final TextEditingController _roomIdController = TextEditingController();
  final TextEditingController _joinTokenController = TextEditingController();
  String? _joinError;

  // Approval state for group rooms
  List<Map<String, dynamic>> _pendingRequests = [];
  bool _loadingPending = false;

  // Hosted rooms state
  List<Map<String, dynamic>> _hostedRooms = [];
  bool _loadingHostedRooms = false;

  // QR Scanner
  bool _showQRScanner = false;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  // For file/image
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadHostedRooms();
  }

  @override
  void dispose() {
    _roomNameController.dispose();
    _roomIdController.dispose();
    _joinTokenController.dispose();
    super.dispose();
  }

  // -------- Room Creation --------
  Future<void> _createRoom() async {
    setState(() {
      _createError = null;
      _createdRoomId = null;
      _createdRoomToken = null;
      _createdRoomType = null;
    });
    try {
      final result = await ChatRoomService.createRoom(
        type: _roomType,
        name: _roomNameController.text.trim().isEmpty
            ? (_roomType == 'private' ? 'Private Chat' : 'Group Chat')
            : _roomNameController.text.trim(),
      );
      setState(() {
        _createdRoomId = result['roomId'];
        _createdRoomToken = result['joinToken'];
        _createdRoomType = _roomType;
      });
      if (_roomType == 'private') {
        // Enter room immediately for private
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(roomId: _createdRoomId!),
          ),
        );
      }
      // After creating room, refresh hosted rooms
      _loadHostedRooms();
    } catch (e) {
      setState(() => _createError = 'Failed: $e');
    }
  }

  // -------- Join Room (Manual) ----------
  Future<void> _joinRoom() async {
    setState(() => _joinError = null);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(_roomIdController.text.trim())
          .get();
      if (!doc.exists) throw Exception('Room not found');
      final data = doc.data()!;
      if (data['type'] == 'private') {
        await ChatRoomService.joinPrivateRoom(
            _roomIdController.text.trim(), _joinTokenController.text.trim());
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) =>
                    ChatScreen(roomId: _roomIdController.text.trim())));
      } else {
        await ChatRoomService.requestJoinGroupRoom(_roomIdController.text.trim());
        setState(() {
          _joinError = "Join request sent. Wait for host's approval.";
        });
      }
    } catch (e) {
      setState(() => _joinError = 'Failed: $e');
    }
  }

  // --------- Load Pending Requests (for group host) -----------
  Future<void> _loadPendingRequests(String roomId) async {
    setState(() {
      _loadingPending = true;
      _pendingRequests = [];
    });
    final doc = await FirebaseFirestore.instance.collection('chat_rooms').doc(roomId).get();
    final data = doc.data()!;
    final List<dynamic> pending = data['pendingRequests'] ?? [];
    List<Map<String, dynamic>> users = [];
    for (var uid in pending) {
      final userDoc =
      await FirebaseFirestore.instance.collection('users').doc(uid).get();
      users.add({
        'uid': uid,
        'name': userDoc.data()?['displayName'] ?? uid,
        'photoUrl': userDoc.data()?['photoURL'],
      });
    }
    setState(() {
      _pendingRequests = users;
      _loadingPending = false;
    });
  }

  Future<void> _approveUser(String roomId, String uid) async {
    await ChatRoomService.approveMember(roomId, uid);
    _loadPendingRequests(roomId);
  }

  // --------- Load Hosted Rooms ----------
  Future<void> _loadHostedRooms() async {
    setState(() {
      _loadingHostedRooms = true;
      _hostedRooms = [];
    });
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _loadingHostedRooms = false;
      });
      return;
    }
    final snap = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('hostUid', isEqualTo: user.uid)
        .get();

    setState(() {
      _hostedRooms = snap.docs.map((doc) {
        final data = doc.data();
        return {
          'roomId': doc.id,
          'roomName': data['name'] ?? doc.id,
          'type': data['type'] ?? 'private',
        };
      }).toList();
      _loadingHostedRooms = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Rooms'),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: CircleAvatar(
                backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null ? const Icon(Icons.person) : null,
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ----- Hosted Rooms -----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text("Rooms You Host", style: TextStyle(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        onPressed: _loadHostedRooms,
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                  if (_loadingHostedRooms)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (!_loadingHostedRooms && _hostedRooms.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Text('No hosted rooms found.'),
                    ),
                  if (!_loadingHostedRooms && _hostedRooms.isNotEmpty)
                    ..._hostedRooms.map((room) => ListTile(
                      leading: Icon(
                        room['type'] == 'group' ? Icons.groups : Icons.person,
                        color: Colors.blue,
                      ),
                      title: Text(room['roomName']),
                      subtitle: Text('Room ID: ${room['roomId']}'),
                      trailing: ElevatedButton.icon(
                        icon: const Icon(Icons.chat),
                        label: const Text("Enter"),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(roomId: room['roomId']),
                            ),
                          );
                        },
                      ),
                    )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ----- Create Room -----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Create Room", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _roomNameController,
                    decoration: const InputDecoration(labelText: 'Room Name'),
                  ),
                  Row(
                    children: [
                      Radio(
                        value: 'private',
                        groupValue: _roomType,
                        onChanged: (v) => setState(() => _roomType = v as String),
                      ),
                      const Text('1-to-1 (private)'),
                      Radio(
                        value: 'group',
                        groupValue: _roomType,
                        onChanged: (v) => setState(() => _roomType = v as String),
                      ),
                      const Text('Group'),
                    ],
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Create Room"),
                    onPressed: _createRoom,
                  ),
                  if (_createError != null)
                    Padding(
                      padding: const EdgeInsets.only(top:8),
                      child: Text(_createError!, style: const TextStyle(color: Colors.red)),
                    ),
                  if (_createdRoomId != null && _createdRoomToken != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(),
                        const Text("Room Created! Share this code or QR:"),
                        SelectableText("Room ID: $_createdRoomId"),
                        SelectableText("Token: $_createdRoomToken"),
                        QrImageView(
                          data: '{"roomId":"$_createdRoomId","joinToken":"$_createdRoomToken"}',
                          size: 140,
                          backgroundColor: Colors.white,
                        ),
                        if (_createdRoomType == "group") ...[
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.people),
                            label: const Text("View Pending Requests"),
                            onPressed: () async {
                              await _loadPendingRequests(_createdRoomId!);
                              showModalBottomSheet(
                                context: context,
                                builder: (_) => SizedBox(
                                  height: 300,
                                  child: _loadingPending
                                      ? const Center(child: CircularProgressIndicator())
                                      : _pendingRequests.isEmpty
                                      ? const Center(child: Text("No pending requests."))
                                      : ListView(
                                    children: _pendingRequests
                                        .map((user) => ListTile(
                                      leading: CircleAvatar(
                                        backgroundImage: user['photoUrl'] != null
                                            ? NetworkImage(user['photoUrl'])
                                            : null,
                                        child: user['photoUrl'] == null
                                            ? const Icon(Icons.person)
                                            : null,
                                      ),
                                      title: Text(user['name']),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.check, color: Colors.green),
                                        onPressed: () async {
                                          await _approveUser(_createdRoomId!, user['uid']);
                                          Navigator.pop(context);
                                        },
                                      ),
                                    ))
                                        .toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                        ElevatedButton.icon(
                          icon: const Icon(Icons.chat),
                          label: const Text("Enter Room"),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(roomId: _createdRoomId!),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // ----- Join Room -----
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Join Room", style: TextStyle(fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _roomIdController,
                    decoration: const InputDecoration(labelText: "Room ID"),
                  ),
                  TextField(
                    controller: _joinTokenController,
                    decoration: const InputDecoration(labelText: "Join Token (for private rooms)"),
                  ),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text("Scan QR"),
                        onPressed: () => setState(() => _showQRScanner = true),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.login),
                        label: const Text("Join Room"),
                        onPressed: _joinRoom,
                      ),
                    ],
                  ),
                  if (_joinError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_joinError!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}