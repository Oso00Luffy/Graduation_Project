import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart'; // Ensure this import is added

class SecureChatScreen extends StatefulWidget {
  @override
  _SecureChatScreenState createState() => _SecureChatScreenState();
}

class _SecureChatScreenState extends State<SecureChatScreen> {
  final _chatService = ChatService('wss://example.com/socket');
  final _messageController = TextEditingController();
  final List<String> _messages = [];

  void _sendMessage() {
    if (_messageController.text.isNotEmpty) {
      _chatService.sendMessage(_messageController.text);
      _messageController.clear();
    }
  }

  @override
  void initState() {
    super.initState();
    _chatService.messages.listen((message) {
      setState(() {
        _messages.add(message);
      });
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _chatService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Secure Chat'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_messages[index]),
                  );
                },
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: CustomTextField(
                    controller: _messageController,
                    hintText: 'Enter your message',
                  ),
                ),
                SizedBox(width: 16),
                CustomButton(
                  text: 'Send',
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}