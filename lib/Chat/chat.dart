import 'package:chilicizz/config/config_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../common.dart';
import '../main.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  final _channel = WebSocketChannel.connect(Uri.parse(dotenv.env['chatUrl']!));

  final List<ChatMessage> _messages = [];

  // register the listener
  _ChatScreenState() {
    _channel.stream.listen((event) {
      setState(() {
        _messages.insert(0, ChatMessage(text: event, name: ""));
        if (_messages.length > 20) {
          _messages.removeLast();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigController>();
    return ValueListenableBuilder(
        valueListenable: config.userName,
        builder: (context, value, child) {
          return Scaffold(
            drawer: NavDrawer(routes: routes),
            appBar: AppBar(
              title: Text("${widget.title} (${config.userName.value})"),
            ),
            body: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Flexible(
                    child: ListView.builder(
                      reverse: true,
                      itemBuilder: (_, int index) => _messages[index],
                      itemCount: _messages.length,
                    ),
                  ),
                  Container(
                    decoration:
                        BoxDecoration(color: Theme.of(context).cardColor),
                    child: _buildTextComposer(),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: _sendMessage,
              tooltip: 'Send message',
              child: const Icon(Icons.send),
            ),
          );
        });
  }

  Widget _buildTextComposer() {
    return Row(
      children: [
        Flexible(
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
            onFieldSubmitted: (value) {
              _isComposing ? _sendMessage() : null;
            },
            decoration:
                const InputDecoration.collapsed(hintText: 'Send a message'),
            focusNode: _focusNode,
          ),
        ),
        IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
          child: IconButton(
            icon: const Icon(Icons.send),
            onPressed: _isComposing ? () => _sendMessage() : null,
          ),
        )
      ],
    );
  }

  void _sendMessage() {
    if (_textController.value.text.isNotEmpty) {
      _channel.sink.add(_textController.text);
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
  final String text;
  final String name;

  const ChatMessage({super.key, required this.text, required this.name});

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(text));
  }
}
