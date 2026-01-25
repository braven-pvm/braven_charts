// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/src/agentic/models/conversation.dart';
import 'package:braven_charts/src/agentic/models/message.dart';
import 'package:braven_charts/src/agentic/providers/anthropic_provider.dart';
import 'package:braven_charts/src/agentic/services/agent_service.dart';
import 'package:braven_charts/src/agentic/tools/create_chart_tool.dart';
import 'package:braven_charts/src/agentic/tools/tool_registry.dart';
import 'package:braven_charts/src/agentic/widgets/chat_interface.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Demo showcasing agentic chart creation from natural language.
///
/// Demonstrates US1: Natural Language Chart Creation
/// - User types chart requests in natural language
/// - Agent converts requests to chart configurations
/// - Charts render with proper axes and labels
///
/// FR-027: Welcome State
/// - Displays welcome message on startup
/// - Shows example prompts
/// - Renders sample chart with demo data
void main() {
  runApp(const AgenticChartDemo());
}

class AgenticChartDemo extends StatelessWidget {
  const AgenticChartDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Agentic Chart Demo',
      theme: ThemeData.dark(useMaterial3: true),
      home: const AgenticChartScreen(),
    );
  }
}

class AgenticChartScreen extends StatefulWidget {
  const AgenticChartScreen({super.key});

  @override
  State<AgenticChartScreen> createState() => _AgenticChartScreenState();
}

class _AgenticChartScreenState extends State<AgenticChartScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  late Conversation _conversation;
  AgentService? _agentService;
  String? _apiKey;
  bool _isInitializing = false;

  static const String _welcomeMessage = '''
🎨 **Welcome to Agentic Chart Demo**

This demo showcases natural language chart creation powered by AI.

**Try these examples:**
• "Show me a line chart of power over time"
• "Create a bar chart comparing sales across quarters"
• "Make a scatter plot of temperature vs pressure"

**How it works:**
1. Type your chart request in the input below
2. The AI agent converts your request to a chart configuration
3. Your chart renders automatically with proper axes and labels

Ready? Enter your Anthropic API key below to get started!
''';

  @override
  void initState() {
    super.initState();
    _conversation = Conversation(id: const Uuid().v4());

    // Check for API key from environment
    const envApiKey = String.fromEnvironment('ANTHROPIC_API_KEY');
    if (envApiKey.isNotEmpty) {
      _apiKey = envApiKey;
      _initializeAgent(envApiKey);
    } else {
      // Add welcome message and sample chart to initial conversation
      _addWelcomeState();
    }
  }

  void _addWelcomeState() {
    // Add welcome message
    final welcomeMessage = Message(
      id: const Uuid().v4(),
      role: MessageRole.assistant,
      textContent: _welcomeMessage,
      timestamp: DateTime.now(),
    );

    // Create sample chart data
    final sampleChartData = {
      'type': 'line',
      'series': [
        {
          'id': 'power_series',
          'name': 'Power Output',
          'data': [
            {'x': 0, 'y': 100},
            {'x': 1, 'y': 150},
            {'x': 2, 'y': 180},
            {'x': 3, 'y': 220},
            {'x': 4, 'y': 190},
            {'x': 5, 'y': 250},
          ],
        }
      ],
      'xAxis': {
        'label': 'Time (hours)',
        'type': 'numeric',
      },
      'yAxes': [
        {
          'label': 'Power (watts)',
          'position': 'left',
        }
      ],
    };

    setState(() {
      _conversation = _conversation.copyWith(
        messages: [welcomeMessage],
        charts: {'welcome_chart': sampleChartData},
      );
    });
  }

  Future<void> _initializeAgent(String apiKey) async {
    setState(() {
      _isInitializing = true;
    });

    try {
      // Create provider
      final provider = AnthropicProvider(
        apiKey: apiKey,
        model: 'claude-3-5-sonnet-20241022',
        maxTokens: 2048,
      );

      // Create tool registry and register CreateChartTool
      final toolRegistry = ToolRegistry();
      toolRegistry.register(CreateChartTool());

      // Create agent service
      final agentService = AgentService(
        provider: provider,
        toolRegistry: toolRegistry,
      );

      setState(() {
        _agentService = agentService;
        _apiKey = apiKey;
        _isInitializing = false;
        // Transfer welcome state to agent's conversation
        agentService.conversation.value = _conversation;
      });
    } catch (error) {
      setState(() {
        _isInitializing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to initialize agent: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
    _initializeAgent(apiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agentic Chart Demo'),
        actions: [
          if (_apiKey != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'About',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Agentic Chart Demo'),
                    content: const Text(
                      'This demo showcases natural language chart creation.\n\n'
                      'Type chart requests in plain English and watch them come to life!',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: _apiKey == null
          ? _buildApiKeyInput()
          : _isInitializing
              ? const Center(child: CircularProgressIndicator())
              : ChatInterface(
                  conversation: _conversation,
                  agentService: _agentService,
                ),
    );
  }

  Widget _buildApiKeyInput() {
    return Center(
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
                  'To use the AI-powered chart generation, please enter your Anthropic API key below.',
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
                  'Don\'t have an API key? Get one at console.anthropic.com',
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
    );
  }
}
