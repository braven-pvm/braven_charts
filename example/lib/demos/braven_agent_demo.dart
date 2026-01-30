// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:convert';

import 'package:braven_agent/braven_agent.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

void main() {
  runApp(const BravenAgentDemo());
}

class BravenAgentDemo extends StatelessWidget {
  const BravenAgentDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Braven Agentic Charts',
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
  String _selectedProvider = 'anthropic'; // 'anthropic' or 'grok'
  String _selectedModel = 'claude-sonnet-4-20250514';

  // Available models per provider
  static const Map<String, List<({String id, String name, String description})>> _availableModels = {
    'anthropic': [
      (id: 'claude-sonnet-4-20250514', name: 'Claude Sonnet 4', description: 'Best balance of speed and capability'),
      (id: 'claude-opus-4-20250514', name: 'Claude Opus 4', description: 'Most capable, best for complex tasks'),
    ],
    'grok': [
      // Grok 4 series (2M context)
      (id: 'grok-4-1-fast-reasoning', name: 'Grok 4.1 Fast Reasoning', description: 'Latest with reasoning (2M context)'),
      (id: 'grok-4-1-fast-non-reasoning', name: 'Grok 4.1 Fast', description: 'Latest without reasoning (2M context)'),
      (id: 'grok-4-fast-reasoning', name: 'Grok 4 Fast Reasoning', description: 'Fast with reasoning (2M context)'),
      (id: 'grok-4-fast-non-reasoning', name: 'Grok 4 Fast', description: 'Fast without reasoning (2M context)'),
      (id: 'grok-4-0709', name: 'Grok 4', description: 'Grok 4 base (256K context)'),
      // Grok 3 series (131K context)
      (id: 'grok-3', name: 'Grok 3', description: 'Full Grok 3 (131K context)'),
      (id: 'grok-3-mini', name: 'Grok 3 Mini', description: 'Lighter Grok 3 (131K context)'),
      // Specialized
      (id: 'grok-code-fast-1', name: 'Grok Code Fast', description: 'Code-optimized (256K context)'),
      (id: 'grok-2-vision-1212', name: 'Grok 2 Vision', description: 'Vision-capable (32K context)'),
    ],
  };

  @override
  void initState() {
    super.initState();
    // Check for Anthropic API key first
    final anthropicKey = const String.fromEnvironment('ANTHROPIC_API_KEY');
    if (anthropicKey.isNotEmpty) {
      _selectedProvider = 'anthropic';
      _selectedModel = 'claude-sonnet-4-20250514';
      _setApiKey(anthropicKey);
      return;
    }
    // Check for Grok API key
    final grokKey = const String.fromEnvironment('GROK_API_KEY');
    if (grokKey.isNotEmpty) {
      _selectedProvider = 'grok';
      _selectedModel = 'grok-4-fast-non-reasoning';
      _setApiKey(grokKey);
    }
  }

  void _onProviderChanged(String provider) {
    setState(() {
      _selectedProvider = provider;
      // Set default model for the selected provider
      _selectedModel = _availableModels[provider]!.first.id;
    });
  }

  void _setApiKey(String apiKey) {
    _session?.dispose();

    final LLMProvider llmProvider;
    if (_selectedProvider == 'grok') {
      final config = LLMConfig(
        apiKey: apiKey,
        model: _selectedModel,
      );
      llmProvider = GrokAdapter(config);
    } else {
      final config = LLMConfig(
        apiKey: apiKey,
        model: _selectedModel,
      );
      llmProvider = AnthropicAdapter(config);
    }

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
    final isGrok = _selectedProvider == 'grok';
    final providerName = isGrok ? 'Grok (xAI)' : 'Anthropic';
    final hintText = isGrok ? 'xai-...' : 'sk-ant-...';
    final consoleUrl = isGrok ? 'console.x.ai' : 'console.anthropic.com';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Braven Agentic Charts'),
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
                  Text(
                    '$providerName API Key Required',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Select your LLM provider and enter your API key.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  // Provider selector
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(
                        value: 'anthropic',
                        label: Text('Anthropic'),
                        icon: Icon(Icons.auto_awesome),
                      ),
                      ButtonSegment<String>(
                        value: 'grok',
                        label: Text('Grok'),
                        icon: Icon(Icons.psychology),
                      ),
                    ],
                    selected: {_selectedProvider},
                    onSelectionChanged: (Set<String> selection) {
                      _onProviderChanged(selection.first);
                    },
                  ),
                  const SizedBox(height: 16),
                  // Model selector
                  DropdownButtonFormField<String>(
                    initialValue: _selectedModel,
                    decoration: const InputDecoration(
                      labelText: 'Model',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.memory),
                    ),
                    items: _availableModels[_selectedProvider]!
                        .map((model) => DropdownMenuItem<String>(
                              value: model.id,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(model.name),
                                  Text(
                                    model.description,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (String? value) {
                      if (value != null) {
                        setState(() {
                          _selectedModel = value;
                        });
                      }
                    },
                    selectedItemBuilder: (BuildContext context) {
                      return _availableModels[_selectedProvider]!.map((model) => Text(model.name)).toList();
                    },
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _apiKeyController,
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      hintText: hintText,
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.vpn_key),
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
                  Text(
                    'Get a key at $consoleUrl',
                    style: const TextStyle(
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
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  GlobalKey<ChartSnapshotWrapperState> _chartSnapshotKey = GlobalKey<ChartSnapshotWrapperState>();
  int? _lastCapturedChartHash;
  int? _currentChartKeyHash;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendMessage(SessionState state) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || state.status == ActivityStatus.thinking || state.status == ActivityStatus.calling_tool) {
      return;
    }

    _messageController.clear();

    // Start the transform (adds user message to history)
    final transformFuture = widget.session.transform(text);

    // Scroll will be triggered by _onStateChanged when history updates

    await transformFuture;
  }

  Widget _buildChartPanel(SessionState state) {
    final activeChart = state.activeChart;

    // Capture snapshot when chart changes (creation OR modification)
    if (activeChart != null) {
      final chartHash = activeChart.hashCode;

      // Regenerate key when chart changes to force complete widget recreation
      // This resets zoom/pan state
      if (chartHash != _currentChartKeyHash) {
        _currentChartKeyHash = chartHash;
        _chartSnapshotKey = GlobalKey<ChartSnapshotWrapperState>();
      }

      if (chartHash != _lastCapturedChartHash) {
        _captureChartSnapshot(chartHash);
      }
    }

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
              child: activeChart == null
                  ? const _ChartPlaceholder()
                  : ChartSnapshotWrapper(
                      key: _chartSnapshotKey,
                      child: const ChartRenderer().render(activeChart),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _captureChartSnapshot(int chartHash) {
    // Schedule capture after the chart is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Double-check we haven't already captured this one
      if (_lastCapturedChartHash == chartHash) return;
      _lastCapturedChartHash = chartHash;

      // Wait a bit for rendering to complete
      await Future<void>.delayed(const Duration(milliseconds: 100));

      final imageContent = await _chartSnapshotKey.currentState?.capture();
      if (imageContent != null) {
        widget.session.addChartSnapshot(imageContent);
      }
    });
  }

  Widget _buildChatPanel(SessionState state) {
    final isProcessing = state.status == ActivityStatus.thinking || state.status == ActivityStatus.calling_tool;
    final messages = state.history;
    final itemCount = messages.length + (isProcessing ? 1 : 0);

    return Column(
      children: [
        if (state.status == ActivityStatus.error && state.errorMessage != null) _ErrorBanner(message: state.errorMessage!),
        Expanded(
          child: ListView.builder(
            // Reversed ListView: items are built from bottom to top
            // This ensures new items appear at the bottom and stay visible
            reverse: true,
            padding: const EdgeInsets.all(16),
            itemCount: itemCount,
            itemBuilder: (context, index) {
              // Because list is reversed, we need to reverse the index
              final reversedIndex = itemCount - 1 - index;

              if (reversedIndex >= messages.length) {
                // This is the processing indicator (last item visually)
                if (state.status == ActivityStatus.calling_tool && state.activeTool != null) {
                  return _ToolExecutionBubble(
                    toolName: state.activeTool!.name,
                  );
                }
                return const _ThinkingBubble();
              }
              final message = messages[reversedIndex];
              return _MessageBubble(message: message);
            },
          ),
        ),
        _ChatInputBar(
          controller: _messageController,
          focusNode: _inputFocusNode,
          isProcessing: isProcessing,
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
            title: const Text('Braven Agentic Charts'),
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
    required this.focusNode,
    required this.isProcessing,
    required this.onSend,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isProcessing;
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
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) {
                  if (!isProcessing && controller.text.trim().isNotEmpty) {
                    onSend();
                  }
                },
                decoration: const InputDecoration(
                  hintText: 'Ask the agent to create a chart...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Use ListenableBuilder so only the button rebuilds when text changes
            ListenableBuilder(
              listenable: controller,
              builder: (context, _) {
                final hasInput = controller.text.trim().isNotEmpty;
                final enabled = hasInput && !isProcessing;
                return IconButton.filled(
                  onPressed: enabled ? onSend : null,
                  icon: const Icon(Icons.send),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatefulWidget {
  const _MessageBubble({required this.message});

  final AgentMessage message;

  @override
  State<_MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<_MessageBubble> {
  final Map<int, bool> _expandedContent = {};

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == MessageRole.user;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Role badge
            _RoleBadge(role: widget.message.role),
            const SizedBox(height: 0),
            // Content blocks
            ...widget.message.content.asMap().entries.map((entry) {
              final index = entry.key;
              final content = entry.value;
              final isExpanded = _expandedContent[index] ?? _defaultExpanded(content);
              return _ContentBlock(
                content: content,
                isUser: isUser,
                messageRole: widget.message.role,
                isExpanded: isExpanded,
                onToggle: () {
                  setState(() {
                    _expandedContent[index] = !isExpanded;
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  bool _defaultExpanded(MessageContent content) {
    return switch (content) {
      TextContent() => true,
      ToolUseContent() => false,
      ToolResultContent() => false,
      ImageContent() => true,
      BinaryContent() => false,
    };
  }
}

/// Simple label showing the message role
class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final MessageRole role;

  @override
  Widget build(BuildContext context) {
    final label = switch (role) {
      MessageRole.user => 'You',
      MessageRole.assistant => 'Agent',
      MessageRole.system => 'System',
      MessageRole.tool => 'Tool',
    };

    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: Colors.grey.shade600,
      ),
    );
  }
}

/// Widget for displaying a single content block
class _ContentBlock extends StatelessWidget {
  const _ContentBlock({
    required this.content,
    required this.isUser,
    required this.messageRole,
    required this.isExpanded,
    required this.onToggle,
  });

  final MessageContent content;
  final bool isUser;
  final MessageRole messageRole;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return switch (content) {
      TextContent(:final text) => _TextBlock(
          text: text,
          isUser: isUser,
        ),
      ToolUseContent(:final toolName, :final input) => _CollapsibleBlock(
          typeLabel: 'Tool',
          summary: toolName,
          isExpanded: isExpanded,
          onToggle: onToggle,
          child: _ToolUseDetails(toolName: toolName, input: input),
        ),
      ToolResultContent(:final output, :final isError) => _CollapsibleBlock(
          typeLabel: isError ? 'Error' : 'Result',
          summary: _truncate(output, 60),
          isExpanded: isExpanded,
          onToggle: onToggle,
          isError: isError,
          child: _ToolResultDetails(output: output, isError: isError),
        ),
      // Show images for system messages (chart snapshots), hide for assistant
      ImageContent(:final data, :final mediaType) =>
        messageRole == MessageRole.assistant ? const SizedBox.shrink() : _ImageBlock(data: data, mediaType: mediaType),
      BinaryContent(:final filename) => _CollapsibleBlock(
          typeLabel: 'File',
          summary: filename ?? 'Binary data',
          isExpanded: isExpanded,
          onToggle: onToggle,
          child: Text(filename ?? 'Binary data'),
        ),
    };
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

/// Text block with markdown rendering for assistant and copy support
class _TextBlock extends StatelessWidget {
  const _TextBlock({
    required this.text,
    required this.isUser,
  });

  final String text;
  final bool isUser;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isUser ? Colors.grey.shade100 : Colors.grey.shade50;

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.fromLTRB(12, 10, 36, 10),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          isUser
              ? SelectableText(
                  text,
                  style: const TextStyle(color: Colors.black87, fontSize: 13),
                )
              : GptMarkdown(
                  text,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
          Positioned(
            top: -4,
            right: -24,
            child: _CopyButton(text: text),
          ),
        ],
      ),
    );
  }
}

/// Collapsible block for tool calls, results, and other content
class _CollapsibleBlock extends StatelessWidget {
  const _CollapsibleBlock({
    required this.typeLabel,
    required this.summary,
    required this.isExpanded,
    required this.onToggle,
    required this.child,
    this.isError = false,
  });

  final String typeLabel;
  final String summary;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget child;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 0),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header (always visible, clickable)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  Text(
                    typeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isError ? Colors.red.shade700 : Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      summary,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontFamily: 'monospace',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 16,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          // Expanded content
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: child,
            ),
        ],
      ),
    );
  }
}

/// Tool use details showing name and input parameters
class _ToolUseDetails extends StatelessWidget {
  const _ToolUseDetails({
    required this.toolName,
    required this.input,
  });

  final String toolName;
  final Map<String, dynamic> input;

  @override
  Widget build(BuildContext context) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(input);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Spacer(),
            _CopyButton(text: jsonString),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText(
            jsonString,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Tool result details showing output
class _ToolResultDetails extends StatelessWidget {
  const _ToolResultDetails({
    required this.output,
    required this.isError,
  });

  final String output;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    // Try to format as JSON if possible
    String displayText = output;
    try {
      final parsed = json.decode(output);
      displayText = const JsonEncoder.withIndent('  ').convert(parsed);
    } catch (_) {
      // Not JSON, use as-is
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            const Spacer(),
            _CopyButton(text: output),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isError ? Colors.red.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText(
            displayText,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: isError ? Colors.red.shade700 : Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}

/// Image content block that decodes and displays base64 images
class _ImageBlock extends StatelessWidget {
  const _ImageBlock({
    required this.data,
    required this.mediaType,
  });

  final String data;
  final String mediaType;

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(data);
      return Container(
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Image.memory(
              bytes,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return _buildErrorPlaceholder('Failed to decode image');
              },
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.image, size: 12, color: Colors.white70),
                    const SizedBox(width: 4),
                    Text(
                      mediaType,
                      style: const TextStyle(fontSize: 10, color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      return _buildErrorPlaceholder('Invalid image data');
    }
  }

  Widget _buildErrorPlaceholder(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// Copy to clipboard button
class _CopyButton extends StatefulWidget {
  const _CopyButton({required this.text});

  final String text;

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: widget.text));
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() => _copied = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _copyToClipboard,
      icon: Icon(
        _copied ? Icons.check : Icons.copy_outlined,
        size: 14,
        color: _copied ? Colors.green : Colors.grey.shade400,
      ),
      tooltip: _copied ? 'Copied!' : 'Copy',
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
      visualDensity: VisualDensity.compact,
    );
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
