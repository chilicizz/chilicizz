import 'dart:convert';

import 'package:flutter/material.dart';

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
