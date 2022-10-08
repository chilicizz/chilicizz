import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../common.dart';
import '../main.dart';

class ChatExample extends StatefulWidget {
  const ChatExample({
    super.key,
    required this.name,
  });

  final String name;

  @override
  State<ChatExample> createState() => _ChatExampleState();
}

class _ChatExampleState extends State<ChatExample> {
  final _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;
  final WebSocketChannel _channel;

  final List<ChatMessage> _messages = [];

  // register the listener
  _ChatExampleState()
      : _channel = WebSocketChannel.connect(Uri.parse(dotenv.env['chatUrl']!)) {
    _channel.stream.listen((event) {
      setState(() {
        _messages.insert(0, ChatMessage(body: event));
        if (_messages.length > 20) {
          _messages.removeLast();
        }
      });
    });
    _channel.sink.add(
      jsonEncode(ChatMessage(body: widget.name, type: ActionType.login)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: NavigationDrawer(routes: routes),
      appBar: AppBar(
        title: const Text("WebSocket Chat Room"),
      ),
      body: Column(
        children: [
          Flexible(
            child: ListView.builder(
              reverse: true,
              itemBuilder: (_, int index) => _messages[index],
              itemCount: _messages.length,
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: _buildTextComposer(),
      ),
    );
  }

  Widget _buildTextComposer() {
    return Row(
      children: [
        Flexible(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: TextFormField(
              controller: _textController,
              onChanged: (String text) {
                setState(() {
                  _isComposing = text.isNotEmpty;
                });
              },
              onEditingComplete: () {
                _isComposing ? _sendMessage : null;
              },
              decoration:
                  const InputDecoration.collapsed(hintText: 'Send a message'),
              focusNode: _focusNode,
              autofocus: true,
            ),
          ),
        ),
        IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
          child: Theme.of(context).platform == TargetPlatform.iOS
              ? CupertinoButton(
                  onPressed: _isComposing ? () => _sendMessage() : null,
                  child: const Text('Send'),
                )
              : IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isComposing ? () => _sendMessage() : null,
                ),
        )
      ],
    );
  }

  void _sendMessage() {
    if (_textController.text.isNotEmpty) {
      ChatMessage message =
          ChatMessage(body: _textController.text, type: ActionType.message);
      _channel.sink.add(jsonEncode(message));
      _isComposing = false;
    }
    _textController.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _channel.sink.close();
    _textController.dispose();
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final ActionType type;
  final String body;

  const ChatMessage(
      {Key? key, required this.body, this.type = ActionType.unknown})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(body));
  }

  ChatMessage.fromJson(Map<String, dynamic> json, {Key? key})
      : body = json['body'],
        type = ActionType.values.byName(json['type']),
        super(key: key);

  Map<String, dynamic> toJson() => {'body': body, 'type': type};
}

enum ActionType {
  message,
  login,
  unknown;
}
