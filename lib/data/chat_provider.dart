import 'dart:convert';

import 'package:chilicizz/Chat/chat_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:async';

class ChatModel extends ChangeNotifier {
  final List<ChatMessage> _messages = [];

  ChatModel();

  void addMessage(ChatMessage message) {
    _messages.insert(0, message);
    if (_messages.length > 20) {
      _messages.removeLast();
    }
    notifyListeners();
  }

  List<ChatMessage> get messages => _messages;
}

// ChatProvider manages the WebSocket connection and message handling
class ChatProvider {
  final Uri chatUrl;
  final chatModel = ChatModel();
  WebSocketChannel? _channel;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  ChatProvider(this.chatUrl) {
    _connect();
  }

  void _connect() {
    if (_disposed) return;
    debugPrint('ChatProvider connecting to WebSocket...');
    try {
      _channel = WebSocketChannel.connect(chatUrl);
      _channel!.stream.listen(
        (message) {
          debugPrint('ChatProvider Received message: $message');
          chatModel.addMessage(ChatMessage.fromJsonString(message));
        },
        onError: (error) {
          debugPrint('ChatProvider Error receiving message: $error');
          _reconnect();
        },
        onDone: () {
          debugPrint('ChatProvider WebSocket connection closed');
          _reconnect();
        },
        cancelOnError: true,
      );
      _reconnectAttempts = 0;
      debugPrint('ChatProvider WebSocket connection established');
    } catch (error) {
      debugPrint('ChatProvider Error connecting to WebSocket: $error');
      _reconnect();
    }
  }

  void _reconnect() {
    if (_disposed) return;
    _reconnectAttempts++;
    final delay = Duration(seconds: 2 * _reconnectAttempts);
    debugPrint('ChatProvider attempting to reconnect in ${delay.inSeconds} seconds...');
    Future.delayed(delay, () {
      if (!_disposed) {
        _connect();
      }
    });
  }

  void sendMessage(ChatMessage message) {
    if (_disposed || _channel == null) {
      debugPrint('ChatProvider cannot send message, WebSocket is not connected');
      return;
    }
    try {
      var messageJson = jsonEncode(message.toJson());
      debugPrint('ChatProvider Sending message: $messageJson');
      _channel!.sink.add(messageJson);
    } catch (error) {
      debugPrint('ChatProvider Error sending message: $error');
      _reconnect();
    }
  }

  void dispose() {
    _disposed = true;
    _channel?.sink.close();
    chatModel.dispose();
  }
}
