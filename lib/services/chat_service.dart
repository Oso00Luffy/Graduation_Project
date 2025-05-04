import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/html.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb

class ChatService {
  late final WebSocketChannel _channel;
  bool _isClosed = false;

  ChatService(String url) {
    if (kIsWeb) {
      _channel = HtmlWebSocketChannel.connect(url);
    } else {
      _channel = IOWebSocketChannel.connect(Uri.parse(url));
    }
  }

  /// Stream of incoming messages
  Stream<String> get messages => _channel.stream.map((message) {
    return message.toString();
  });

  /// Send a message over WebSocket
  void sendMessage(String message) {
    if (_isClosed) {
      print("WebSocket is closed. Cannot send message.");
      return;
    }
    try {
      _channel.sink.add(message);
    } catch (e) {
      print("Error sending message: $e");
    }
  }

  /// Close the connection when done
  void dispose() {
    _isClosed = true;
    _channel.sink.close();
  }
}