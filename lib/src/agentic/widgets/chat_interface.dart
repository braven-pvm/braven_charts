import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../models/chart_configuration.dart';
import '../models/conversation.dart';
import '../models/file_attachment.dart';
import '../models/message.dart';
import '../services/agent_service.dart';
import '../services/file_picker.dart' as file_picker;
import '../services/file_validator.dart';
import '../tools/data_store.dart';
import '../tools/load_data_tool.dart';
import 'chart_card.dart';
import 'chart_widget.dart';
import 'data_preview.dart';
import 'error_message.dart';
import 'file_attachment_chip.dart';
import 'message_bubble.dart';

/// Chat UI for interacting with the agent.
class ChatInterface extends StatefulWidget {
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
  State<ChatInterface> createState() => ChatInterfaceState();
}

class ChatInterfaceState extends State<ChatInterface> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final LoadDataTool _loadDataTool = LoadDataTool();
  final FileValidator _fileValidator = FileValidator();
  final Uuid _uuid = const Uuid();

  Conversation? _conversation;
  ValueNotifier<Conversation>? _agentConversation;
  ValueNotifier<AgentState>? _agentState;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _lastUserMessage;
  final List<FileAttachment> _attachments = [];
  final List<String> _loadedDataIds = [];

  @override
  void initState() {
    super.initState();
    _attachConversation();
  }

  @override
  void didUpdateWidget(ChatInterface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agentService != widget.agentService ||
        oldWidget.conversation != widget.conversation) {
      _detachConversation();
      _attachConversation();
    }
  }

  @override
  void dispose() {
    _detachConversation();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _attachConversation() {
    if (widget.agentService != null) {
      _agentConversation = widget.agentService!.conversation;
      _agentState = widget.agentService!.state;
      _conversation = _agentConversation!.value;
      _agentConversation!.addListener(_handleConversationUpdate);
      _agentState!.addListener(_handleStateUpdate);
      _isProcessing = _agentState!.value == AgentState.processing;
    } else {
      _conversation = widget.conversation;
      _isProcessing = false;
    }
  }

  void _detachConversation() {
    _agentConversation?.removeListener(_handleConversationUpdate);
    _agentConversation = null;
    _agentState?.removeListener(_handleStateUpdate);
    _agentState = null;
  }

  void _handleConversationUpdate() {
    if (!mounted || _agentConversation == null) {
      return;
    }
    final incoming = _agentConversation!.value;

    // Merge charts: keep existing charts and add/update from incoming
    final existingCharts = _conversation?.charts ?? const <String, dynamic>{};
    final mergedCharts = {
      ...existingCharts,
      ...incoming.charts,
    };

    setState(() {
      _conversation = incoming.copyWith(charts: mergedCharts);
    });
    _scrollToBottom();
  }

  void _handleStateUpdate() {
    if (!mounted || _agentState == null) {
      return;
    }
    setState(() {
      _isProcessing = _agentState!.value == AgentState.processing;
    });
  }

  Future<void> _handleSend() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isProcessing) {
      return;
    }

    _controller.clear();
    widget.onSend?.call(text);
    _lastUserMessage = text;

    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }

    // Let AgentService handle everything if available
    if (widget.agentService != null) {
      try {
        // Build data context from loaded files
        final dataContext = _buildDataContext();
        final messageWithContext = dataContext.isEmpty
            ? text
            : '$text\n\n[DATA CONTEXT]\n$dataContext';

        await widget.agentService!.processUserMessage(messageWithContext);
      } catch (error) {
        if (mounted) {
          setState(() {
            _errorMessage = _describeError(error);
          });
        }
      }
      _scrollToBottom();
      return;
    }

    // Fallback for when no AgentService is available
    final current = _conversation ?? widget.conversation;
    final updatedMessages = List<Message>.from(current.messages)
      ..add(
        Message(
          id: _uuid.v4(),
          role: MessageRole.user,
          textContent: text,
        ),
      );

    final updatedConversation = current.copyWith(
      messages: updatedMessages,
    );

    if (mounted) {
      setState(() {
        _conversation = updatedConversation;
      });
    }

    _scrollToBottom();
  }

  String _describeError(Object error) {
    final details = error.toString();
    if (details.contains('LLMProviderException')) {
      return details;
    }
    return 'Something went wrong. Please try again.';
  }

  /// Build data context string from loaded files to pass to the LLM
  String _buildDataContext() {
    if (_loadedDataIds.isEmpty) {
      return '';
    }

    final buffer = StringBuffer();
    final dataStore = DataStore();

    for (final dataId in _loadedDataIds) {
      final frame = dataStore.get(dataId);
      if (frame == null) continue;

      buffer.writeln('File: ${frame.fileName} (${frame.rowCount} rows)');
      buffer.writeln('Columns:');

      for (final col in frame.columns) {
        buffer.write('  - ${col.name} (${col.type})');
        if (col.stats.min != null && col.stats.max != null) {
          buffer.write(
              ' [min: ${col.stats.min}, max: ${col.stats.max}, mean: ${col.stats.mean?.toStringAsFixed(2)}]');
        }
        buffer.writeln();
      }

      if (frame.timeRange != null) {
        buffer.writeln(
            'Time range: ${frame.timeRange!.start} to ${frame.timeRange!.end}');
      }
      buffer.writeln();
    }

    return buffer.toString();
  }

  Future<void> _handleRetry() async {
    final message = _lastUserMessage;
    if (message == null || _isProcessing || widget.agentService == null) {
      return;
    }

    if (mounted) {
      setState(() {
        _errorMessage = null;
      });
    }

    try {
      await widget.agentService!.processUserMessage(message);
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _describeError(error);
        });
      }
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) {
      return;
    }
    // Schedule scroll after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleFileUpload() async {
    // Check if file picking is supported on this platform
    if (!file_picker.isFilePickingSupported) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'File upload is not supported on this platform. Use addFileAttachment method for testing.';
        });
      }
      return;
    }

    try {
      // Pick a file using the platform-specific file picker
      final result = await file_picker.pickFile(
        allowedExtensions: ['fit', 'csv', 'tcx'],
      );

      if (result == null) {
        // User cancelled the file picker
        return;
      }

      // Add the file attachment
      await addFileAttachment(
        fileName: result.fileName,
        content: result.content,
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to pick file: $error';
        });
      }
    }
  }

  /// Adds a file attachment programmatically (for testing or external integration)
  Future<void> addFileAttachment({
    required String fileName,
    required Uint8List content,
  }) async {
    // Determine file type from extension
    final lastDot = fileName.lastIndexOf('.');
    final extension =
        lastDot >= 0 ? fileName.substring(lastDot + 1).toLowerCase() : '';
    final fileType =
        ['fit', 'csv', 'tcx'].contains(extension) ? extension : 'csv';

    // Validate the file
    final validationResult = _fileValidator.validate(
      fileName: fileName,
      fileSizeBytes: content.length,
      content: content,
    );

    if (!validationResult.success) {
      if (mounted) {
        setState(() {
          _errorMessage = validationResult.errorMessage;
        });
      }
      return;
    }

    // Create FileAttachment
    final attachment = FileAttachment(
      id: _uuid.v4(),
      fileName: fileName,
      fileType: fileType,
      fileSizeBytes: content.length,
      content: content,
      status: FileStatus.pending,
    );

    if (mounted) {
      setState(() {
        _attachments.add(attachment);
        _errorMessage = null;
      });
    }

    // Process the file with LoadDataTool
    await _processFileAttachment(attachment);
  }

  Future<void> _processFileAttachment(FileAttachment attachment) async {
    // Update status to parsing
    final index = _attachments.indexOf(attachment);
    if (index == -1) return;

    if (mounted) {
      setState(() {
        _attachments[index] = attachment.copyWith(status: FileStatus.parsing);
      });
    }

    try {
      Map<String, dynamic> loadResult;

      // Use 'bytes' source type for binary FIT files to avoid corrupting binary data
      if (attachment.fileType == 'fit') {
        loadResult = await _loadDataTool.execute({
          'source': {
            'type': 'bytes',
            'bytes': attachment.content,
            'format': 'fit',
            'file_name': attachment.fileName,
          }
        });
      } else {
        // For text formats (CSV, JSON), use inline content
        final content = String.fromCharCodes(attachment.content);
        loadResult = await _loadDataTool.execute({
          'source': {
            'type': 'inline',
            'content': content,
            'format': attachment.fileType,
          }
        });
      }

      final dataId = loadResult['data_id'] as String;

      // Update status to ready
      if (mounted) {
        setState(() {
          _attachments[index] = attachment.copyWith(
            status: FileStatus.ready,
            dataId: dataId,
          );
          _loadedDataIds.add(dataId);
        });
      }
    } catch (error) {
      // Update status to error
      if (mounted) {
        setState(() {
          _attachments[index] = attachment.copyWith(
            status: FileStatus.error,
            errorMessage: error.toString(),
          );
        });
      }
    }
  }

  void _removeAttachment(FileAttachment attachment) {
    if (mounted) {
      setState(() {
        _attachments.remove(attachment);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final conversation = _conversation ?? widget.conversation;

    // Build chronological list of all content items
    // Charts are rendered inline after the message that created them
    final contentItems = <Widget>[];
    final renderedChartIds = <String>{};

    // Render messages in order, with charts inline after their source message
    for (final message in conversation.messages) {
      // Add the message bubble if it has text content
      if (message.textContent != null &&
          message.textContent!.trim().isNotEmpty) {
        contentItems.add(MessageBubble(message: message));
      }

      // Check if this message has tool results with charts
      if (message.toolResults != null) {
        for (final toolResult in message.toolResults!) {
          if (toolResult.chartId != null) {
            // Always get LATEST chart data from conversation.charts
            final chart = conversation.charts[toolResult.chartId];
            if (chart != null &&
                !renderedChartIds.contains(toolResult.chartId)) {
              renderedChartIds.add(toolResult.chartId!);
              try {
                final chartConfig =
                    ChartConfiguration.fromJson(chart as Map<String, dynamic>);
                // Use a key that includes chart content hash so widget rebuilds when chart data changes
                final chartKey = ValueKey(
                    '${toolResult.chartId}_${chartConfig.series.length}_${chartConfig.hashCode}');
                contentItems.add(
                  ChartCard(
                    key: chartKey,
                    chartId: toolResult.chartId!,
                    chartConfiguration: chartConfig,
                    agentService: widget.agentService,
                    child: ChartWidget(chart: chart),
                  ),
                );
              } catch (e) {
                // If ChartConfiguration parsing fails, fall back to simple rendering
                // This can happen with incomplete chart data in tests or malformed data
                contentItems.add(ChartWidget(chart: chart));
              }
            }
          }
        }
      }
    }

    // Add data previews at the end
    for (final dataId in _loadedDataIds) {
      contentItems.add(DataPreview(dataId: dataId));
    }

    // Add any charts that weren't associated with a message (shouldn't happen, but just in case)
    for (final entry in conversation.charts.entries) {
      if (!renderedChartIds.contains(entry.key)) {
        try {
          final chartConfig =
              ChartConfiguration.fromJson(entry.value as Map<String, dynamic>);
          contentItems.add(
            Row(
              children: [
                ChartCard(
                  chartId: entry.key,
                  chartConfiguration: chartConfig,
                  agentService: widget.agentService,
                  child: ChartWidget(chart: entry.value),
                ),
              ],
            ),
          );
        } catch (e) {
          // If ChartConfiguration parsing fails, fall back to simple rendering
          contentItems.add(ChartWidget(chart: entry.value));
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.all(15),
                children: [
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ErrorMessage(
                        message: _errorMessage!,
                        onRetry: _isProcessing ? null : _handleRetry,
                      ),
                    ),
                  if (_isProcessing)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ...contentItems,
                ],
              ),
            ),
            // File attachments display
            if (_attachments.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(
                    top: BorderSide(color: Colors.grey[200]!),
                  ),
                ),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _attachments
                      .map((attachment) => FileAttachmentChip(
                            attachment: attachment,
                            onRemove: () => _removeAttachment(attachment),
                          ))
                      .toList(),
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(width: 0.5, color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 25, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('chat_input'),
                          maxLines: 8,
                          // expands: true,
                          minLines: 1,
                          controller: _controller,
                          enabled: !_isProcessing,
                          style: GoogleFonts.notoSansJp(fontSize: 12),
                          decoration: InputDecoration(
                            hintText: 'Ask for a chart...',
                            hintStyle: GoogleFonts.notoSansJp(fontSize: 12),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            isDense: true,
                            focusedBorder: null,
                          ),
                          onSubmitted: (_) => _handleSend(),
                        ),
                      ),
                      IconButton(
                        key: const Key('chat_send_button'),
                        icon: const Icon(Icons.send, size: 15),
                        onPressed: _isProcessing ? null : _handleSend,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton(
                        key: const Key('chat_file_button'),
                        onPressed: _isProcessing ? null : _handleFileUpload,

                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                8.0), // Adjust value for more/less roundness
                          ),
                          backgroundColor: Colors.grey.shade300.withAlpha(60),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          side: BorderSide(
                              width: 0.5,
                              color: Colors.grey
                                  .shade300), // Optional: define border width/color
                        ),
                        // tooltip: 'Attach file (FIT, CSV, TCX)',
                        // visualDensity: VisualDensity.compact,

                        child: Row(spacing: 4, children: [
                          const Icon(Icons.attach_file, size: 15),
                          Text(
                            'Attach',
                            style: GoogleFonts.notoSansJp(fontSize: 11),
                          )
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
