import 'dart:convert';

import 'package:chilicizz/config/config_controller.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChatMessage extends StatelessWidget {
  final String text;
  final String name;
  final String sessionId;

  const ChatMessage({super.key, required this.text, required this.name, required this.sessionId});

  /// Factory constructor to create a ChatMessage from a JSON object.
  /// The JSON object should contain 'text' and optionally 'name'.
  /// If 'name' is not provided, it defaults to an empty string.
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      name: json['name'] as String? ?? "",
      sessionId: json['sessionId'] as String? ?? "",
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
      'sessionId': sessionId,
    };
  }

  @override
  Widget build(BuildContext context) {
    final config = context.read<ConfigController>();
    final isMe = (sessionId == config.sessionId.value) || sessionId == "system";
    return ListTile(
      leading: isMe
          ? null
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                name.isNotEmpty ? name : '?',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
              ),
            ),
      title: Align(
        alignment: isMe ? Alignment.topRight : Alignment.topLeft,
        child: Text(text),
      ),
      trailing: isMe
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                name.isNotEmpty ? name : '?',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
              ),
            )
          : null,
    );
  }
}
