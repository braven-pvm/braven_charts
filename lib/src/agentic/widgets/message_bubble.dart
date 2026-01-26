import 'package:flutter/material.dart';

import '../models/message.dart';

/// Chat bubble for displaying a message.
class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final Message message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final text = message.textContent ?? '';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isUser ? Colors.white : Colors.black87,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
