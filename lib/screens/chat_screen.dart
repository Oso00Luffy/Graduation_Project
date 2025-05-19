import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import '../services/chat_service.dart';

class ChatScreen extends StatefulWidget {
  final String roomId;
  const ChatScreen({Key? key, required this.roomId}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final messageController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _sending = false;

  Future<void> _sendImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _sending = true);
      final url = await ChatService.uploadImage(picked, widget.roomId);
      await ChatService.sendMessage(roomId: widget.roomId, text: '', imageUrl: url);
      setState(() => _sending = false);
    }
  }

  Future<void> _sendFile() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery); // For demo, use image picker for files; use file_picker for all files
    if (picked != null) {
      setState(() => _sending = true);
      final url = await ChatService.uploadFile(picked, widget.roomId);
      await ChatService.sendMessage(
        roomId: widget.roomId,
        text: '',
        fileUrl: url,
        fileName: picked.name,
        fileType: 'image', // For demo, use 'image'; extend for other types
      );
      setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final messages = ChatService.messagesStream(widget.roomId);

    return Scaffold(
      appBar: AppBar(title: const Text('Chat Room')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: messages,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = (snapshot.data! as QuerySnapshot).docs;
                if (docs.isEmpty) {
                  return const Center(child: Text('No messages yet. Say hello!'));
                }
                return ListView(
                  children: docs.map<Widget>((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final isImage = data['imageUrl'] != null;
                    final isFile = data['fileUrl'] != null && !isImage;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: data['senderPhotoUrl'] != null
                            ? NetworkImage(data['senderPhotoUrl'])
                            : null,
                        child: data['senderPhotoUrl'] == null ? const Icon(Icons.person) : null,
                      ),
                      title: Text(data['senderName'] ?? 'User'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if ((data['text'] ?? '').isNotEmpty) Text(data['text']),
                          if (isImage)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Image.network(data['imageUrl'], height: 120),
                            ),
                          if (isFile)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: InkWell(
                                onTap: () async {
                                  // Optionally open/download file
                                },
                                child: Row(
                                  children: [
                                    const Icon(Icons.attach_file),
                                    Text(data['fileName'] ?? 'File'),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ),
          if (_sending) const LinearProgressIndicator(),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.photo),
                  onPressed: _sendImage,
                ),
                IconButton(
                  icon: const Icon(Icons.attach_file),
                  onPressed: _sendFile,
                ),
                Expanded(
                  child: TextField(
                    controller: messageController,
                    decoration: const InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () async {
                    if (messageController.text.trim().isNotEmpty) {
                      await ChatService.sendMessage(
                        roomId: widget.roomId,
                        text: messageController.text.trim(),
                      );
                      messageController.clear();
                    }
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}