import 'package:flutter/material.dart';

import '../models/message.dart';

/// Chat bubble for displaying a message with collapsible content.
///
/// Shows a summary (first line) when collapsed, full content when expanded.
/// User messages default to collapsed, assistant messages default to collapsed.
class MessageBubble extends StatefulWidget {
  const MessageBubble({
    super.key,
    required this.message,
    this.initiallyExpanded = false,
    this.maxCollapsedLines = 1,
    this.expandThreshold = 80,
  });

  final Message message;

  /// Whether the bubble starts expanded
  final bool initiallyExpanded;

  /// Maximum lines to show when collapsed
  final int maxCollapsedLines;

  /// Character threshold - messages shorter than this won't be collapsible
  final int expandThreshold;

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
  }

  String get _text => widget.message.textContent ?? '';

  bool get _isCollapsible => _text.length > widget.expandThreshold;

  String get _summaryText {
    if (!_isCollapsible) return _text;

    // Get first line or first N characters
    final firstLine = _text.split('\n').first;
    if (firstLine.length <= widget.expandThreshold) {
      return firstLine.length < _text.length ? '$firstLine...' : firstLine;
    }
    return '${firstLine.substring(0, widget.expandThreshold)}...';
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: isUser ? Colors.blue : Colors.grey.shade200.withAlpha(50),
          borderRadius: BorderRadius.circular(12),
          // border: Border.all(color: Colors.black38, width: 0.5),
        ),
        child: _isCollapsible
            ? _buildCollapsibleContent(isUser)
            : _buildSimpleContent(isUser),
      ),
    );
  }

  Widget _buildSimpleContent(bool isUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        _text,
        style: GoogleFonts.lato((
          color: isUser ? Colors.white : Colors.black87,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildCollapsibleContent(bool isUser) {
    final textColor = isUser ? Colors.white : Colors.black87;
    final iconColor = isUser ? Colors.white70 : Colors.black54;

    return InkWell(
      onTap: () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _isExpanded ? _text : _summaryText,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                    ),
                    maxLines: _isExpanded ? null : widget.maxCollapsedLines,
                    overflow: _isExpanded
                        ? TextOverflow.visible
                        : TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: iconColor,
                ),
              ],
            ),
            // if (!_isExpanded)
            //   Padding(
            //     padding: const EdgeInsets.only(top: 2),
            //     child: Text(
            //       '${_text.length} chars • tap to expand',
            //       style: TextStyle(
            //         color: iconColor,
            //         fontSize: 10,
            //         fontStyle: FontStyle.italic,
            //       ),
            //     ),
            //   ),
          ],
        ),
      ),
    );
  }
}
