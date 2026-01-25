import 'package:flutter/material.dart';

import '../models/conversation.dart';
import '../services/agent_service.dart';

/// Chat UI for interacting with the agent.
///
/// TODO: Implement in green phase.
class ChatInterface extends StatelessWidget {
  const ChatInterface({
    super.key,
    required this.conversation,
    this.agentService,
    this.onSend,
  });

  final Conversation conversation;
  final AgentService? agentService;
  final ValueChanged<String>? onSend;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
