import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
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
      print('[DEBUG] Uploading image: ${picked.name} for room: ${widget.roomId}');
      final url = await ChatService.uploadImage(picked, widget.roomId);
      print('[DEBUG] Image uploaded: $url');
      await ChatService.sendMessage(roomId: widget.roomId, text: '', imageUrl: url);
      print('[DEBUG] Sent image message to room: ${widget.roomId}');
      setState(() => _sending = false);
    }
  }

  Future<void> _sendFile() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery); // For demo, use image picker for files; use file_picker for all files
    if (picked != null) {
      setState(() => _sending = true);
      print('[DEBUG] Uploading file: ${picked.name} for room: ${widget.roomId}');
      final url = await ChatService.uploadFile(picked, widget.roomId);
      print('[DEBUG] File uploaded: $url');
      await ChatService.sendMessage(
        roomId: widget.roomId,
        text: '',
        fileUrl: url,
        fileName: picked.name,
        fileType: 'image', // For demo, use 'image'; extend for other types
      );
      print('[DEBUG] Sent file message to room: ${widget.roomId}');
      setState(() => _sending = false);
    }
  }

  Future<void> _saveImageToGallery(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final result = await ImageGallerySaverPlus.saveImage(
          response.bodyBytes,
          quality: 100,
          name: "chat_image_${DateTime.now().millisecondsSinceEpoch}",
          isReturnImagePathOfIOS: true, // Ensures correct path on iOS
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['isSuccess'] == true
                ? 'Image saved to gallery!'
                : 'Failed to save image.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to download image.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<Size?> _getImageSize(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        final image = frame.image;
        return Size(image.width.toDouble(), image.height.toDouble());
      }
    } catch (_) {}
    return null;
  }

  Future<Widget> _buildDecryptedText(Map<String, dynamic> data) async {
    if (data['encrypted'] != null) {
      try {
        final decrypted = await ChatService.decryptMessage(
          Map<String, dynamic>.from(data['encrypted']),
          widget.roomId,
        );
        return Text(decrypted);
      } catch (e) {
        return const Text('[Encrypted]', style: TextStyle(color: Colors.red));
      }
    }
    if ((data['text'] ?? '').isNotEmpty) {
      return Text(data['text']);
    }
    return const SizedBox.shrink();
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
                          FutureBuilder<Widget>(
                            future: _buildDecryptedText(data),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Text('Decrypting...');
                              }
                              return snapshot.data ?? const SizedBox.shrink();
                            },
                          ),
                          if (isImage)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  Container(
                                    constraints: const BoxConstraints(
                                      maxHeight: 120,
                                      maxWidth: 220,
                                    ),
                                    child: Image.network(
                                      data['imageUrl'],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.download),
                                    tooltip: 'Download Image',
                                    onPressed: () async {
                                      await _saveImageToGallery(data['imageUrl']);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          if (isFile)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () async {
                                      final url = data['fileUrl'];
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.attach_file),
                                        Text(data['fileName'] ?? 'File'),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.download),
                                    tooltip: 'Download File',
                                    onPressed: () async {
                                      final url = data['fileUrl'];
                                      if (await canLaunchUrl(Uri.parse(url))) {
                                        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                                      }
                                    },
                                  ),
                                ],
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
                      print('[DEBUG] Sending text message to room: ${widget.roomId} - ${messageController.text.trim()}');
                      await ChatService.sendMessage(
                        roomId: widget.roomId,
                        text: messageController.text.trim(),
                      );
                      print('[DEBUG] Sent text message to room: ${widget.roomId}');
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
