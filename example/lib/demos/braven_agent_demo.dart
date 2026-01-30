// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_agent/braven_agent.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BravenAgentDemo());
}

class BravenAgentDemo extends StatelessWidget {
  const BravenAgentDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Braven Agent Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const ApiKeyGateScreen(),
    );
  }
}

class ApiKeyGateScreen extends StatefulWidget {
  const ApiKeyGateScreen({super.key});

  @override
  State<ApiKeyGateScreen> createState() => _ApiKeyGateScreenState();
}

class _ApiKeyGateScreenState extends State<ApiKeyGateScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  String? _apiKey;
  AgentSession? _session;

  @override
  void initState() {
    super.initState();
    final envApiKey = const String.fromEnvironment('ANTHROPIC_API_KEY');
    if (envApiKey.isNotEmpty) {
      _setApiKey(envApiKey);
    }
  }

  void _setApiKey(String apiKey) {
    _session?.dispose();
    final config = LLMConfig(
      apiKey: apiKey,
      model: 'claude-sonnet-4-20250514',
    );
    final llmProvider = AnthropicAdapter(config);
    // Create session first, then pass getActiveChart callback to ModifyChartTool
    late final AgentSessionImpl session;
    session = AgentSessionImpl(
      llmProvider: llmProvider,
      tools: [
        CreateChartTool(),
        ModifyChartTool(getActiveChart: () => session.state.value.activeChart),
      ],
      systemPrompt: defaultSystemPrompt,
    );
    setState(() {
      _apiKey = apiKey;
      _session = session;
    });
  }

  void _handleApiKeySubmit() {
    final apiKey = _apiKeyController.text.trim();
    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid API key'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    _setApiKey(apiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    _session?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_apiKey == null) {
      return _buildApiKeyInput();
    }

    final session = _session;
    if (session == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ChatScreen(session: session);
  }

  Widget _buildApiKeyInput() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Braven Agent Demo'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.key,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Anthropic API Key Required',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Enter your Anthropic API key to start the demo.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _apiKeyController,
                    decoration: const InputDecoration(
                      labelText: 'API Key',
                      hintText: 'sk-ant-...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.vpn_key),
                    ),
                    obscureText: true,
                    onSubmitted: (_) => _handleApiKeySubmit(),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _handleApiKeySubmit,
                    icon: const Icon(Icons.check),
                    label: const Text('Connect'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Get a key at console.anthropic.com',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.session});

  final AgentSession session;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  int _lastItemCount = 0;
  bool _hasInput = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_handleInputChanged);
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleInputChanged() {
    final hasInput = _messageController.text.trim().isNotEmpty;
    if (hasInput != _hasInput) {
      setState(() {
        _hasInput = hasInput;
      });
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _maybeScroll(int itemCount) {
    if (itemCount == _lastItemCount) return;
    _lastItemCount = itemCount;
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _sendMessage(SessionState state) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || state.status == ActivityStatus.thinking || state.status == ActivityStatus.calling_tool) {
      return;
    }

    _messageController.clear();
    await widget.session.transform(text);
  }

  Widget _buildChartPanel(SessionState state) {
    final activeChart = state.activeChart;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Chart Preview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: activeChart == null ? const _ChartPlaceholder() : const ChartRenderer().render(activeChart),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatPanel(SessionState state) {
    final isProcessing = state.status == ActivityStatus.thinking || state.status == ActivityStatus.calling_tool;
    final messages = state.history;
    final itemCount = messages.length + (isProcessing ? 1 : 0);
    _maybeScroll(itemCount);

    return Column(
      children: [
        if (state.status == ActivityStatus.error && state.errorMessage != null) _ErrorBanner(message: state.errorMessage!),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index >= messages.length) {
                if (state.status == ActivityStatus.calling_tool && state.activeTool != null) {
                  return _ToolExecutionBubble(
                    toolName: state.activeTool!.name,
                  );
                }
                return const _ThinkingBubble();
              }
              final message = messages[index];
              return _MessageBubble(message: message);
            },
          ),
        ),
        _ChatInputBar(
          controller: _messageController,
          enabled: _hasInput && !isProcessing,
          onSend: () => _sendMessage(state),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SessionState>(
      valueListenable: widget.session.state,
      builder: (context, state, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Braven Agent Demo'),
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useRowLayout = constraints.maxWidth >= 900;

                if (useRowLayout) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: _buildChatPanel(state),
                      ),
                      Expanded(
                        flex: 4,
                        child: _buildChartPanel(state),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Expanded(
                      flex: 3,
                      child: _buildChatPanel(state),
                    ),
                    SizedBox(
                      height: 360,
                      child: _buildChartPanel(state),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ChartPlaceholder extends StatelessWidget {
  const _ChartPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_chart_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          const Text(
            'Create a chart to see it here',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.controller,
    required this.enabled,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => enabled ? onSend() : null,
                decoration: const InputDecoration(
                  hintText: 'Ask the agent to create a chart...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final AgentMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;
    final backgroundColor = isUser ? Colors.blue : Colors.grey.shade200;
    final textColor = isUser ? Colors.white : Colors.black87;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
      bottomRight: isUser ? Radius.zero : const Radius.circular(16),
    );

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: const BoxConstraints(maxWidth: 320),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: borderRadius,
        ),
        child: Text(
          _extractMessageText(message),
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }

  String _extractMessageText(AgentMessage message) {
    final buffer = StringBuffer();
    for (final content in message.content) {
      switch (content) {
        case TextContent(:final text):
          buffer.writeln(text);
        case ToolResultContent(:final output):
          buffer.writeln(output);
        case ToolUseContent(:final toolName):
          buffer.writeln('Calling tool: $toolName');
        case ImageContent():
          buffer.writeln('[Image]');
        case BinaryContent(:final filename):
          buffer.writeln('[File${filename != null ? ': $filename' : ''}]');
      }
    }
    final result = buffer.toString().trim();
    return result.isEmpty ? '[No content]' : result;
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 8),
            Text('Thinking...'),
          ],
        ),
      ),
    );
  }
}

class _ToolExecutionBubble extends StatelessWidget {
  const _ToolExecutionBubble({required this.toolName});

  final String toolName;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade600),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.build, size: 16, color: Colors.blue),
            const SizedBox(width: 4),
            Text(
              'Calling: $toolName...',
              style: TextStyle(color: Colors.blue.shade700),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade50,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
