import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../common.dart';
import '../main.dart';

class ChatExample extends StatefulWidget {
  const ChatExample({
    super.key,
    required this.title,
  });

  final String title;

  @override
  State<ChatExample> createState() => _ChatExampleState();
}

class _ChatExampleState extends State<ChatExample> {
  final _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isComposing = false;

  final _channel = WebSocketChannel.connect(Uri.parse(dotenv.env['chatUrl']!));

  final List<ChatMessage> _messages = [];

  // register the listener
  _ChatExampleState() {
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
    return Scaffold(
      drawer: NavigationDrawer(routes: routes),
      appBar: AppBar(
        title: Text(widget.title),
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
            const Divider(height: 1.0),
            Container(
              decoration: BoxDecoration(color: Theme.of(context).cardColor),
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
            decoration:
                const InputDecoration.collapsed(hintText: 'Send a message'),
            focusNode: _focusNode,
          ),
        ),
        IconTheme(
          data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
          child: Container(
            child: Theme.of(context).platform == TargetPlatform.iOS
                ? CupertinoButton(
                    onPressed: _isComposing ? () => _sendMessage() : null,
                    child: const Text('Send'),
                  )
                : IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _isComposing ? () => _sendMessage() : null,
                  ),
          ),
        )
      ],
    );
  }

  void _sendMessage() {
    if (_textController.text.isNotEmpty) {
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

  const ChatMessage({Key? key, required this.text, required this.name})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(title: Text(text));
  }
}
