import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/chart_configuration.dart';
import '../models/message.dart';
import '../services/agent_service.dart';

/// Static history manager for persisting inline chat conversations.
///
/// Conversations are keyed by chartId and survive widget dispose/rebuild.
class _InlineChatHistoryManager {
  _InlineChatHistoryManager._();

  static final _InlineChatHistoryManager instance =
      _InlineChatHistoryManager._();

  final Map<String, List<Message>> _histories = {};

  /// Get the message history for a chart.
  List<Message> getHistory(String chartId) {
    return _histories.putIfAbsent(chartId, () => []);
  }

  /// Add a message to the chart's history.
  void addMessage(String chartId, Message message) {
    final history = getHistory(chartId);
    history.add(message);
  }

  /// Clear history for a chart (used for testing or reset).
  void clearHistory(String chartId) {
    _histories.remove(chartId);
  }
}

/// Inline chat UI scoped to a specific chart.
///
/// Each InlineChat instance maintains its own conversation state keyed by
/// chartId. Messages sent here only affect the linked chart, not others.
/// Chat history persists across widget dispose/rebuild cycles.
class InlineChat extends StatefulWidget {
  const InlineChat({
    super.key,
    required this.chartId,
    required this.agentService,
    this.chartConfiguration,
    this.onClose,
  });

  /// Unique identifier for the chart this chat is scoped to.
  final String chartId;

  /// The agent service to send messages to.
  final AgentService agentService;

  /// Optional chart configuration for context.
  final ChartConfiguration? chartConfiguration;

  /// Callback when the chat is closed.
  final VoidCallback? onClose;

  @override
  State<InlineChat> createState() => _InlineChatState();
}

class _InlineChatState extends State<InlineChat> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Uuid _uuid = const Uuid();

  List<Message> get _messages =>
      _InlineChatHistoryManager.instance.getHistory(widget.chartId);

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    // Set the current chart before sending so AgentService knows which
    // chart to modify.
    widget.agentService.currentChart.value = widget.chartConfiguration;

    // Create user message
    final userMessage = Message(
      id: _uuid.v4(),
      role: MessageRole.user,
      textContent: content,
    );

    // Add to persistent history
    _InlineChatHistoryManager.instance.addMessage(widget.chartId, userMessage);

    // Clear input
    _textController.clear();

    // Trigger rebuild
    setState(() {});

    // Send message to agent service
    widget.agentService.processUserMessage(content).then((_) {
      // Add assistant response if available
      final conversation = widget.agentService.conversation.value;
      if (conversation.messages.isNotEmpty) {
        final lastMessage = conversation.messages.last;
        if (lastMessage.role == MessageRole.assistant &&
            lastMessage.textContent != null) {
          _InlineChatHistoryManager.instance.addMessage(
            widget.chartId,
            lastMessage,
          );
          if (mounted) {
            setState(() {});
          }
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        key: Key('inline_chat_${widget.chartId}'),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Message history
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                key: Key('inline_chat_history_${widget.chartId}'),
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final message = _messages[index];
                  final isUser = message.role == MessageRole.user;
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue[100] : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment:
                        isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      message.textContent ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.blue[900] : Colors.black87,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Input row
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: Key('inline_chat_input_${widget.chartId}'),
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Ask about this chart...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  key: Key('inline_chat_send_${widget.chartId}'),
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  tooltip: 'Send',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
