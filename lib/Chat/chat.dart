import 'package:chilicizz/Chat/chat_model.dart';
import 'package:chilicizz/config/config_controller.dart';
import 'package:chilicizz/data/chat_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../common.dart';
import '../main.dart';

// This screen displays a chat interface where users can send and receive messages.
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

  @override
  Widget build(BuildContext context) {
    final config = context.watch<ConfigController>();

    return ValueListenableBuilder(
        valueListenable: config.sessionId,
        builder: (context, sessionId, child) {
          if (sessionId == null) {
            debugPrint("Session Id not yet loaded"); // Session ID is null, show a loading indicator
            return LoadingListView();
          }
          return ValueListenableBuilder(
              valueListenable: config.userName,
              builder: (context, usernameVar, child) {
                if (usernameVar == null || usernameVar.isEmpty) {
                  // TODO do this better
                  Future.microtask(() {
                    context.mounted
                        ? showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (context) {
                              final usernameController = TextEditingController();
                              return AlertDialog(
                                title: const Text('Enter your display name'),
                                content: TextField(
                                  controller: usernameController,
                                  decoration: const InputDecoration(hintText: 'Display Name'),
                                  autofocus: true,
                                  onSubmitted: (value) {
                                    if (value.trim().isNotEmpty) {
                                      config.setUserName(value.trim());
                                      Navigator.of(context).pop();
                                    }
                                  },
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      if (usernameController.text.trim().isNotEmpty) {
                                        config.setUserName(usernameController.text.trim());
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              );
                            },
                          )
                        : null;
                  });
                }

                var provider = Provider.of<ChatProvider>(context, listen: true);
                return Scaffold(
                  drawer: NavDrawer(routes: routes),
                  appBar: AppBar(
                    title: Text("${widget.title} (${usernameVar ?? ""})"),
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
                                itemBuilder: (context, int index) {
                                  // Display messages in reverse order
                                  var message = provider.chatModel.messages[index];
                                  return message;
                                },
                                itemCount: provider.chatModel.messages.length,
                              );
                            },
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            border:
                                Border.all(color: Theme.of(context).colorScheme.primaryContainer),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: _buildTextComposer(),
                        ),
                      ],
                    ),
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
          data: IconThemeData(color: Theme.of(context).colorScheme.primary),
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
      var chatMessage = ChatMessage(
        text: _textController.text,
        name: context.read<ConfigController>().userName.value ?? "",
        sessionId: context.read<ConfigController>().sessionId.value ?? "",
      );
      context.read<ChatProvider>().sendMessage(chatMessage);
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
