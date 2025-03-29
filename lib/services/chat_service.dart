import 'package:web_socket_channel/web_socket_channel.dart';

class ChatService {
  final WebSocketChannel _channel;

  ChatService(String url) : _channel = WebSocketChannel.connect(Uri.parse(url));

  Stream<dynamic> get messages => _channel.stream;

  void sendMessage(String message) {
    _channel.sink.add(message);
  }

  void dispose() {
    _channel.sink.close();
  }
}