import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

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
          color: isUser
              ? Colors.blueGrey.withAlpha(35)
              : Colors.grey.shade200.withAlpha(50),
          borderRadius: BorderRadius.circular(10),
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
      child: isUser
          ? Text(
              _text,
              style: GoogleFonts.poppins(
                color: Colors.black54,
                fontWeight: FontWeight.w400,
                fontSize: 12,
              ),
            )
          : _buildMarkdownContent(_text),
    );
  }

  /// Renders markdown content for assistant messages
  Widget _buildMarkdownContent(String content) {
    return GptMarkdown(
      content,
      style: GoogleFonts.poppins(
        color: Colors.black87,
        fontWeight: FontWeight.w400,
        fontSize: 12,
        height: 1.5,
      ),
    );
  }

  Widget _buildCollapsibleContent(bool isUser) {
    final textColor = isUser ? Colors.black54 : Colors.black87;
    final iconColor = isUser ? Colors.red : Colors.red;

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _isExpanded
                      ? (isUser
                          ? Text(
                              _text,
                              style: GoogleFonts.poppins(
                                color: textColor,
                                fontWeight: FontWeight.w300,
                                fontSize: 11.5,
                              ),
                            )
                          : _buildMarkdownContent(_text))
                      : Text(
                          _summaryText,
                          style: GoogleFonts.poppins(
                            color: textColor,
                            fontWeight: FontWeight.w300,
                            fontSize: 11.5,
                          ),
                          maxLines: widget.maxCollapsedLines,
                          overflow: TextOverflow.ellipsis,
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
