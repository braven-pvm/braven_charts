// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Example demonstrating AI-powered chart generation using Claude.
///
/// This demo connects to the Anthropic Claude API and uses function calling
/// to generate interactive BravenChartPlus charts from natural language.
void main() {
  runApp(const AiChartChatDemo());
}

class AiChartChatDemo extends StatelessWidget {
  const AiChartChatDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chart Chat - Claude',
      theme: ThemeData.dark(useMaterial3: true),
      home: const ChatScreen(),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messages = <ChatMessage>[];
  final _conversationHistory = <Message>[];
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _chartAgent = DefaultChartAgent();

  late final AnthropicClient _anthropic;
  bool _isLoading = false;

  // Anthropic API key
  static const _apiKey = '***REDACTED_API_KEY***';

  // Example prompts
  static const _examplePrompts = [
    'Create a line chart showing temperature rising from 20°C to 35°C over 24 hours',
    'Show me a bar chart comparing quarterly sales: Q1=120k, Q2=150k, Q3=180k, Q4=210k',
    'Make a scatter plot of 20 random data points between x:0-100 and y:0-50',
    'Visualize heart rate during a workout: starts at 70bpm, peaks at 165bpm, cools down to 90bpm',
  ];

  @override
  void initState() {
    super.initState();
    _anthropic = AnthropicClient(apiKey: _apiKey);
    _addSystemMessage(
      '🤖 **Claude Chart Assistant**\n\n'
      'I\'m connected to Claude AI and can create interactive charts from your descriptions!\n\n'
      'Try asking:\n${_examplePrompts.map((p) => '• $p').join('\n')}',
    );
  }

  /// Convert our tool schema to Anthropic Tool format
  List<Tool> _getAnthropicTools() {
    final schema = ChartToolSchema.createChartTool;
    return [
      Tool.custom(
        name: schema['name'] as String,
        description: schema['description'] as String,
        inputSchema: schema['input_schema'] as Map<String, dynamic>,
      ),
    ];
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        role: ChatMessageRole.system,
        content: text,
      ));
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        role: ChatMessageRole.user,
        content: text,
      ));
    });
    _scrollToBottom();
  }

  void _addAssistantMessage(String text, {Widget? chart}) {
    setState(() {
      _messages.add(ChatMessage(
        role: ChatMessageRole.assistant,
        content: text,
        chartWidget: chart,
      ));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleSubmit(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    _controller.clear();
    _addUserMessage(text);

    setState(() => _isLoading = true);

    try {
      await _sendToClaudeWithTools(text);
    } catch (e) {
      _addAssistantMessage('❌ Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendToClaudeWithTools(String userMessage) async {
    // Add user message to conversation history
    _conversationHistory.add(Message(
      role: MessageRole.user,
      content: MessageContent.text(userMessage),
    ));

    // System prompt for chart generation
    const systemPrompt = '''You are a helpful chart creation assistant. 
When users ask for charts or data visualizations, use the create_chart tool to generate them.
Be creative with sample data if the user doesn't provide specific values.
Always explain what chart you're creating before using the tool.
For line charts, generate smooth realistic-looking data with 20-50 points.
For bar charts, use 4-8 categories.
For scatter plots, use 15-30 points.
Use appropriate colors and labels.''';

    // Create request with tools
    final request = CreateMessageRequest(
      model: const Model.modelId('claude-sonnet-4-20250514'),
      maxTokens: 4096,
      system: const CreateMessageRequestSystem.text(systemPrompt),
      messages: _conversationHistory,
      tools: _getAnthropicTools(),
    );

    // Send to Claude
    final response = await _anthropic.createMessage(request: request);

    // Process response blocks
    String? textContent;
    ToolUseBlock? toolUse;

    for (final block in response.content.blocks) {
      if (block is TextBlock) {
        textContent = block.text;
      } else if (block is ToolUseBlock) {
        toolUse = block;
      }
    }

    // Show text response if any
    if (textContent != null && textContent.isNotEmpty) {
      _addAssistantMessage(textContent);
    }

    // Process tool call if any
    if (toolUse != null) {
      await _processToolCall(toolUse, response);
    } else if (textContent == null || textContent.isEmpty) {
      _addAssistantMessage('I received your message but had no response.');
    }
  }

  Future<void> _processToolCall(ToolUseBlock toolUse, Message response) async {
    print('🔧 Tool call: ${toolUse.name}');
    print('📥 Input: ${json.encode(toolUse.input)}');

    try {
      // Process with our chart agent
      final widget = await _chartAgent.processToolCall(
        toolUse.name,
        toolUse.input,
      );

      if (widget != null) {
        _addAssistantMessage(
          '📊 **Chart Created!**\n\n'
          '• **Pan**: Drag horizontally\n'
          '• **Zoom**: Scroll wheel or pinch\n'
          '• **Details**: Hover over data points',
          chart: widget,
        );
      }

      // Add assistant response with tool use to history
      _conversationHistory.add(Message(
        role: MessageRole.assistant,
        content: MessageContent.blocks(response.content.blocks),
      ));

      // Add tool result to history
      _conversationHistory.add(Message(
        role: MessageRole.user,
        content: MessageContent.blocks([
          Block.toolResult(
            toolUseId: toolUse.id,
            content: ToolResultBlockContent.text(
              json.encode({'success': true, 'message': 'Chart created successfully'}),
            ),
          ),
        ]),
      ));
    } catch (e) {
      _addAssistantMessage('❌ Failed to create chart: $e');

      // Add error result to history
      _conversationHistory.add(Message(
        role: MessageRole.assistant,
        content: MessageContent.blocks(response.content.blocks),
      ));
      _conversationHistory.add(Message(
        role: MessageRole.user,
        content: MessageContent.blocks([
          Block.toolResult(
            toolUseId: toolUse.id,
            isError: true,
            content: ToolResultBlockContent.text('Error: $e'),
          ),
        ]),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('AI Chart Assistant'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.green.withAlpha(50),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withAlpha(100)),
              ),
              child: const Text(
                'Claude',
                style: TextStyle(fontSize: 12, color: Colors.green),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'Show Tool Schema',
            onPressed: _showToolSchema,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Chat',
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildLoadingIndicator();
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withAlpha(50),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Claude is thinking...'),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.role == ChatMessageRole.user;
    final isSystem = message.role == ChatMessageRole.system;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary.withAlpha(50)
              : isSystem
                  ? Theme.of(context).colorScheme.secondary.withAlpha(30)
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isUser ? Theme.of(context).colorScheme.primary.withAlpha(100) : Theme.of(context).colorScheme.outline.withAlpha(50),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: TextStyle(
                color: isSystem ? Theme.of(context).colorScheme.secondary : null,
              ),
            ),
            if (message.chartWidget != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: message.chartWidget!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withAlpha(50),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_isLoading,
              decoration: InputDecoration(
                hintText: _isLoading ? 'Waiting for response...' : 'Describe the chart you want...',
                border: const OutlineInputBorder(),
              ),
              onSubmitted: _handleSubmit,
              maxLines: null,
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            onPressed: _isLoading ? null : () => _handleSubmit(_controller.text),
          ),
        ],
      ),
    );
  }

  void _showToolSchema() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chart Tool Schema (Anthropic Format)'),
        content: SingleChildScrollView(
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(
              ChartToolSchema.toAnthropicFormat(),
            ),
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.clear();
      _conversationHistory.clear();
      _chartAgent.disposeAll();
    });
    _addSystemMessage(
      '🤖 **Claude Chart Assistant**\n\n'
      'Chat cleared! Ask me to create any chart.\n\n'
      'Examples:\n${_examplePrompts.map((p) => '• $p').join('\n')}',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _chartAgent.disposeAll();
    super.dispose();
  }
}

enum ChatMessageRole { user, assistant, system }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.chartWidget,
  });

  final ChatMessageRole role;
  final String content;
  final Widget? chartWidget;
}
