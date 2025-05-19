import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../services/chat_room_service.dart';
import 'chat_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  String? _roomId;
  String? _joinToken;
  String? _roomType = 'private';
  String? _error;
  final _nameController = TextEditingController();

  Future<void> _create() async {
    setState(() => _error = null);
    try {
      final result = await ChatRoomService.createRoom(
        type: _roomType!,
        name: _nameController.text.trim().isEmpty
            ? (_roomType == 'private' ? 'Private Chat' : 'Group Chat')
            : _nameController.text.trim(),
      );
      setState(() {
        _roomId = result['roomId'];
        _joinToken = result['joinToken'];
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Room')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Room Name'),
            ),
            const SizedBox(height: 12),
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
            ElevatedButton(
              onPressed: _create,
              child: const Text('Create Room'),
            ),
            if (_roomId != null && _joinToken != null) ...[
              const SizedBox(height: 24),
              const Text('Share this QR code or token to invite:'),
              QrImageView(
                data: '{"roomId":"$_roomId","joinToken":"$_joinToken"}',
                size: 160,
                backgroundColor: Colors.white,
              ),
              SelectableText('Room ID: $_roomId'),
              SelectableText('Token: $_joinToken'),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(roomId: _roomId!),
                    ),
                  );
                },
                child: const Text('Enter Room'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}