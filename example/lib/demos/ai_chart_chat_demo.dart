// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';

/// Example demonstrating AI-powered chart generation in a chat interface.
///
/// This demo shows how to:
/// 1. Define chart tools for an LLM
/// 2. Process tool calls to generate charts
/// 3. Display interactive charts in a chat UI
///
/// In a real implementation, you would integrate with an LLM API like:
/// - Anthropic Claude (claude-sonnet-4-20250514)
/// - OpenAI GPT-4
/// - Google Gemini
///
/// For this demo, we simulate LLM responses to show the integration pattern.
void main() {
  runApp(const AiChartChatDemo());
}

class AiChartChatDemo extends StatelessWidget {
  const AiChartChatDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Chart Chat Demo',
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
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _chartAgent = DefaultChartAgent();

  // Example prompts the user might type
  static const _examplePrompts = [
    'Show me a line chart of temperature over time',
    'Create a bar chart comparing sales by region',
    'Plot a scatter chart of height vs weight',
    'Visualize my workout data with heart rate and power',
  ];

  @override
  void initState() {
    super.initState();
    _addSystemMessage(
      'Welcome! I can create interactive charts from your data. '
      'Try asking me to visualize something!\n\n'
      'Example prompts:\n${_examplePrompts.map((p) => '• $p').join('\n')}',
    );
  }

  void _addSystemMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        role: MessageRole.system,
        content: text,
      ));
    });
  }

  void _addUserMessage(String text) {
    setState(() {
      _messages.add(ChatMessage(
        role: MessageRole.user,
        content: text,
      ));
    });
  }

  void _addAssistantMessage(String text, {Widget? chart}) {
    setState(() {
      _messages.add(ChatMessage(
        role: MessageRole.assistant,
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
    if (text.trim().isEmpty) return;

    _controller.clear();
    _addUserMessage(text);

    // Simulate LLM processing delay
    await Future<void>.delayed(const Duration(milliseconds: 500));

    // In a real app, you would:
    // 1. Send message to LLM API with chartAgent.toolDefinitions
    // 2. Check if response contains tool calls
    // 3. Process tool calls with chartAgent.processToolCall()

    // For this demo, we simulate the LLM response
    await _simulateLlmResponse(text);
  }

  Future<void> _simulateLlmResponse(String userMessage) async {
    final lowerMessage = userMessage.toLowerCase();

    // Simulate different chart types based on keywords
    Map<String, dynamic>? toolCall;

    if (lowerMessage.contains('temperature') || lowerMessage.contains('line')) {
      toolCall = _simulateTemperatureChart();
    } else if (lowerMessage.contains('sales') || lowerMessage.contains('bar')) {
      toolCall = _simulateSalesChart();
    } else if (lowerMessage.contains('scatter') || lowerMessage.contains('height') || lowerMessage.contains('weight')) {
      toolCall = _simulateScatterChart();
    } else if (lowerMessage.contains('workout') || lowerMessage.contains('heart') || lowerMessage.contains('power')) {
      toolCall = _simulateWorkoutChart();
    } else {
      // Default to a simple demo chart
      toolCall = _simulateDefaultChart();
    }

    try {
      // Process the simulated tool call
      final widget = await _chartAgent.processToolCall(
        'create_chart',
        toolCall,
      );

      _addAssistantMessage(
        'Here\'s your chart! You can:\n'
        '• **Pan** by dragging horizontally\n'
        '• **Zoom** with scroll or pinch\n'
        '• **Hover** to see values',
        chart: widget,
      );
    } catch (e) {
      _addAssistantMessage('Error creating chart: $e');
    }
  }

  Map<String, dynamic> _simulateTemperatureChart() {
    return {
      'title': 'Temperature Over Time',
      'chart_type': 'line',
      'series': [
        {
          'id': 'temp',
          'name': 'Temperature',
          'color': '#FF5733',
          'unit': '°C',
          'data': [
            for (int i = 0; i < 24; i++)
              {
                'x': i.toDouble(),
                'y': 18.0 + 8.0 * _sine(i / 24.0) + (i % 3) * 0.5,
              },
          ],
        },
      ],
      'x_axis': {'label': 'Hour', 'unit': 'h'},
      'style': {'line_interpolation': 'bezier'},
    };
  }

  Map<String, dynamic> _simulateSalesChart() {
    return {
      'title': 'Sales by Region',
      'chart_type': 'bar',
      'series': [
        {
          'id': 'sales',
          'name': 'Q4 Sales',
          'color': '#4CAF50',
          'unit': 'USD',
          'data': [
            {'x': 1, 'y': 125000, 'label': 'North'},
            {'x': 2, 'y': 98000, 'label': 'South'},
            {'x': 3, 'y': 156000, 'label': 'East'},
            {'x': 4, 'y': 87000, 'label': 'West'},
            {'x': 5, 'y': 142000, 'label': 'Central'},
          ],
        },
      ],
      'x_axis': {'label': 'Region'},
      'y_axis': {'label': 'Sales', 'unit': 'USD'},
    };
  }

  Map<String, dynamic> _simulateScatterChart() {
    return {
      'title': 'Height vs Weight Correlation',
      'chart_type': 'scatter',
      'series': [
        {
          'id': 'measurements',
          'name': 'Participants',
          'color': '#2196F3',
          'data': [
            for (int i = 0; i < 50; i++)
              {
                'x': 150.0 + (i % 10) * 4 + (i ~/ 10) * 2,
                'y': 50.0 + (i % 10) * 5 + (i ~/ 10) * 3 + (i % 7),
              },
          ],
        },
      ],
      'x_axis': {'label': 'Height', 'unit': 'cm'},
      'y_axis': {'label': 'Weight', 'unit': 'kg'},
    };
  }

  Map<String, dynamic> _simulateWorkoutChart() {
    return {
      'title': 'Workout Metrics',
      'chart_type': 'line',
      'series': [
        {
          'id': 'heart_rate',
          'name': 'Heart Rate',
          'color': '#E91E63',
          'unit': 'bpm',
          'data': [
            for (int i = 0; i < 60; i++)
              {
                'x': i.toDouble(),
                'y': 120.0 + 40.0 * _sine(i / 15.0) + (i % 5) * 2,
              },
          ],
        },
        {
          'id': 'power',
          'name': 'Power',
          'color': '#FF9800',
          'unit': 'W',
          'data': [
            for (int i = 0; i < 60; i++)
              {
                'x': i.toDouble(),
                'y': 150.0 + 100.0 * _sine(i / 20.0 + 0.5) + (i % 7) * 5,
              },
          ],
        },
      ],
      'x_axis': {'label': 'Time', 'unit': 'min'},
      'style': {'line_interpolation': 'monotone'},
    };
  }

  Map<String, dynamic> _simulateDefaultChart() {
    return {
      'title': 'Sample Data',
      'chart_type': 'area',
      'series': [
        {
          'id': 'demo',
          'name': 'Demo Series',
          'color': '#9C27B0',
          'data': [
            for (int i = 0; i < 20; i++)
              {
                'x': i.toDouble(),
                'y': 50.0 + 30.0 * _sine(i / 5.0) + (i % 4) * 3,
              },
          ],
        },
      ],
      'x_axis': {'label': 'X Value'},
      'y_axis': {'label': 'Y Value'},
      'style': {'line_interpolation': 'bezier'},
    };
  }

  double _sine(double x) => (x * 3.14159 * 2).remainder(6.28318) < 3.14159
      ? (x * 3.14159 * 2).remainder(3.14159) / 1.5708 - 1
      : 1 - ((x * 3.14159 * 2).remainder(3.14159) / 1.5708 - 1);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chart Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.code),
            tooltip: 'Show Tool Schema',
            onPressed: _showToolSchema,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.role == MessageRole.user;
    final isSystem = message.role == MessageRole.system;

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
              decoration: const InputDecoration(
                hintText: 'Ask me to create a chart...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _handleSubmit,
            ),
          ),
          const SizedBox(width: 12),
          IconButton.filled(
            icon: const Icon(Icons.send),
            onPressed: () => _handleSubmit(_controller.text),
          ),
        ],
      ),
    );
  }

  void _showToolSchema() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chart Tool Schema'),
        content: SingleChildScrollView(
          child: SelectableText(
            const JsonEncoder.withIndent('  ').convert(ChartToolSchema.toAnthropicFormat()),
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _chartAgent.disposeAll();
    super.dispose();
  }
}

enum MessageRole { user, assistant, system }

class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.chartWidget,
  });

  final MessageRole role;
  final String content;
  final Widget? chartWidget;
}
