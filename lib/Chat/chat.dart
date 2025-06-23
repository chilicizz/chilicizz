import 'dart:convert';

import 'package:chilicizz/Chat/chat_provider.dart';
import 'package:chilicizz/config/config_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

  // register the listener
  _ChatScreenState();

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigController>();

    return ValueListenableBuilder(
        valueListenable: config.sessionId,
        builder: (context, sessionId, child) {
          if (sessionId.isEmpty) {
            var sessionId = DateTime.now().millisecondsSinceEpoch.toString();
            context.read<ConfigController>().setSessionId(sessionId);
            debugPrint("Session ID is empty setting new session: $sessionId.");
          }
          // _channel.sink.add(sessionId);
          return ValueListenableBuilder(
              valueListenable: config.userName,
              builder: (context, value, child) {
                var provider = Provider.of<ChatProvider>(context, listen: true);
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
                          child: ListenableBuilder(
                            listenable: provider.chatModel,
                            // Using Consumer to listen to changes in ChatProvider
                            // and rebuild the ListView when messages change.
                            builder: (context, child) {
                              return ListView.builder(
                                reverse: true,
                                itemBuilder: (_, int index) => provider.chatModel.messages[index],
                                itemCount: provider.chatModel.messages.length,
                              );
                            },
                          ),
                        ),
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
              });
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
            decoration: const InputDecoration.collapsed(hintText: 'Send a message'),
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
      var payload = jsonEncode({
        'text': _textController.text,
        'name': context.read<ConfigController>().userName.value,
        'sessionId': context.read<ConfigController>().sessionId.value,
      });
      context.read<ChatProvider>().sendMessage(ChatMessage.fromJsonString(payload));
      _isComposing = false;
    }
    _textController.clear();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }
}

class ChatMessage extends StatelessWidget {
  final String text;
  final String name;

  const ChatMessage({super.key, required this.text, required this.name});

  /// Factory constructor to create a ChatMessage from a JSON object.
  /// The JSON object should contain 'text' and optionally 'name'.
  /// If 'name' is not provided, it defaults to an empty string.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      name: json['name'] as String? ?? "",
    );
  }

  factory ChatMessage.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return ChatMessage.fromJson(json);
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'name': name,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(text),
      leading: CircleAvatar(
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
      ),
    );
  }
}
