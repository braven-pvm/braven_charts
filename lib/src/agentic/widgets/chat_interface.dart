import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/conversation.dart';
import '../models/file_attachment.dart';
import '../models/message.dart';
import '../services/agent_service.dart';
import '../services/file_validator.dart';
import '../tools/create_chart_tool.dart';
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
  final CreateChartTool _chartTool = CreateChartTool();
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

    final current = _conversation ?? widget.conversation;
    final updatedMessages = widget.agentService == null
        ? (List<Message>.from(current.messages)
          ..add(
            Message(
              id: _uuid.v4(),
              role: MessageRole.user,
              textContent: text,
            ),
          ))
        : List<Message>.from(current.messages);

    final updatedCharts = Map<String, dynamic>.from(current.charts);

    try {
      final config = await _chartTool.execute({
        'prompt': text,
        'dataset': const {
          'columns': ['x', 'y'],
          'rows': <Map<String, dynamic>>[],
        },
      });

      final chartId = 'chart_${DateTime.now().millisecondsSinceEpoch}';
      updatedCharts[chartId] = config;
    } catch (_) {
      // Ignore prompts that do not produce charts.
    }

    final updatedConversation = current.copyWith(
      messages: updatedMessages,
      charts: updatedCharts,
    );

    if (widget.agentService != null && _agentConversation != null) {
      _agentConversation!.value = updatedConversation;
    }

    if (mounted) {
      setState(() {
        _conversation = updatedConversation;
      });
    }

    if (widget.agentService != null) {
      try {
        await widget.agentService!.processUserMessage(text);
      } catch (error) {
        if (mounted) {
          setState(() {
            _errorMessage = _describeError(error);
          });
        }
      }
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
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _handleFileUpload() async {
    // Note: This is a stub for file upload functionality
    // In a real implementation, this would integrate with platform-specific
    // file pickers or drag-and-drop APIs. For testing purposes, files can
    // be provided via the FileAttachment model directly or through
    // addFileAttachment method.

    // TODO: Implement platform-specific file picker
    // For web: Use html.FileUploadInputElement
    // For mobile: Use image_picker or file_picker package
    // For desktop: Use file_selector package

    if (mounted) {
      setState(() {
        _errorMessage =
            'File upload UI not yet implemented. Use addFileAttachment method for testing.';
      });
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
      // Save file temporarily (in production, use proper temp file handling)
      // For now, use inline content approach
      final content = String.fromCharCodes(attachment.content);

      final loadResult = await _loadDataTool.execute({
        'source': {
          'type': 'inline',
          'content': content,
          'format': attachment.fileType,
        }
      });

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
    final messageWidgets = conversation.messages
        .where((message) => message.textContent != null)
        .map((message) => MessageBubble(message: message))
        .toList(growable: false);

    final chartWidgets = conversation.charts.values
        .map(
          (chart) => ChartCard(
            child: ChartWidget(chart: chart),
          ),
        )
        .toList(growable: false);

    // Build data preview widgets
    final dataPreviewWidgets = _loadedDataIds
        .map((dataId) => DataPreview(dataId: dataId))
        .toList(growable: false);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                controller: _scrollController,
                children: [
                  if (_errorMessage != null)
                    ErrorMessage(
                      message: _errorMessage!,
                      onRetry: _isProcessing ? null : _handleRetry,
                    ),
                  if (_isProcessing)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ...messageWidgets,
                  ...dataPreviewWidgets,
                  ...chartWidgets,
                ],
              ),
            ),
            // File attachments display
            if (_attachments.isNotEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(
                    top: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _attachments
                      .map((attachment) => FileAttachmentChip(
                            attachment: attachment,
                            onRemove: () => _removeAttachment(attachment),
                          ))
                      .toList(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  IconButton(
                    key: const Key('chat_file_button'),
                    icon: const Icon(Icons.attach_file),
                    onPressed: _isProcessing ? null : _handleFileUpload,
                    tooltip: 'Attach file (FIT, CSV, TCX)',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      key: const Key('chat_input'),
                      controller: _controller,
                      enabled: !_isProcessing,
                      decoration: const InputDecoration(
                        hintText: 'Ask for a chart...',
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const Key('chat_send_button'),
                    icon: const Icon(Icons.send),
                    onPressed: _isProcessing ? null : _handleSend,
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
