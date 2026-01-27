// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:io';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Demo showcasing agentic chart creation from natural language.
///
/// Demonstrates US1: Natural Language Chart Creation
/// - User types chart requests in natural language
/// - Agent converts requests to chart configurations
/// - Charts render with proper axes and labels
///
/// Demonstrates US2: Sport Science File Analysis
/// - Upload FIT files from fitness devices
/// - Preview data columns and statistics
/// - Create charts with data transformations (rolling averages)
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
      debugShowCheckedModeBanner: false,
      title: 'Agentic Chart Demo',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
      ),
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
  final GlobalKey<ChatInterfaceState> _chatInterfaceKey = GlobalKey<ChatInterfaceState>();

  static const String _welcomeMessage = '''
**Welcome to Agentic Charts**

Create charts using natural language and AI-powered analysis.

**Quick Start:**
• Try: "Show me a line chart of power over time"
• Upload a FIT file and ask for rolling averages
• Create bar charts comparing metrics

**Tips:** Upload files using the button above, then type your chart request below.
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
    // Add welcome message only - no demo chart
    final welcomeMessage = Message(
      id: const Uuid().v4(),
      role: MessageRole.assistant,
      textContent: _welcomeMessage,
      timestamp: DateTime.now(),
    );

    setState(() {
      _conversation = _conversation.copyWith(
        messages: [welcomeMessage],
      );
    });
  }

  Future<void> _initializeAgent(String apiKey) async {
    setState(() {
      _isInitializing = true;
    });

    try {
      // Create shared chart store for tools to access charts by ID
      final chartStore = DataStore<ChartConfiguration>();

      // Create tool registry and register tools
      final toolRegistry = ToolRegistry();
      final createChartTool = CreateChartTool();
      final modifyChartTool = ModifyChartTool(dataStore: chartStore);
      final calculateMetricTool = CalculateMetricTool();
      toolRegistry.register(createChartTool);
      toolRegistry.register(modifyChartTool);
      toolRegistry.register(calculateMetricTool);

      // Create provider with tools so Claude knows to use them
      final provider = AnthropicProvider(
        apiKey: apiKey,
        model: 'claude-sonnet-4-20250514',
        maxTokens: 2048,
        tools: [createChartTool, modifyChartTool, calculateMetricTool],
      );

      // Create agent service with shared chart store
      final agentService = AgentService(
        provider: provider,
        toolRegistry: toolRegistry,
        chartStore: chartStore,
      );

      setState(() {
        _agentService = agentService;
        _apiKey = apiKey;
        _isInitializing = false;
        // Transfer welcome state to agent's conversation
        agentService.conversation.value = _conversation;
      });

      // Listen to conversation updates from the agent
      agentService.conversation.addListener(() {
        if (mounted) {
          setState(() {
            _conversation = agentService.conversation.value;
          });
        }
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

  /// Handle file upload button press - show sample file selector
  Future<void> _handleFileUpload() async {
    // Show dialog to select from sample FIT files in data directory
    final sampleFiles = [
      'tp-2023646.2026-01-10-11-27-44-360Z.GarminPing.AAAAAGliN69r93wK.FIT',
      'tp-2023646.2026-01-15-16-23-44-609Z.GarminPing.AAAAAGlpFJD7Zfeh.FIT',
      'tp-2023646.2026-01-17-11-07-37-163Z.GarminPing.AAAAAGlrbXhXqZ3H.FIT',
      'tp-2023646.2026-01-18-11-37-13-293Z.GarminPing.AAAAAGlsxejfj7QD.FIT',
    ];

    final selectedFile = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Sample FIT File'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sampleFiles.length,
            itemBuilder: (context, index) {
              final fileName = sampleFiles[index];
              return ListTile(
                leading: const Icon(Icons.fitness_center, color: Colors.blue),
                title: Text(
                  fileName,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: const Text('Garmin FIT Activity'),
                onTap: () => Navigator.pop(context, fileName),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selectedFile != null) {
      await _loadSampleFile(selectedFile);
    }
  }

  /// Load a sample FIT file from the data directory
  Future<void> _loadSampleFile(String fileName) async {
    try {
      // Construct path to data directory (assuming example/data or ../data)
      final dataPath = 'data/$fileName';
      final file = File(dataPath);

      // Check if file exists, try alternative path if not
      File? actualFile;
      if (await file.exists()) {
        actualFile = file;
      } else {
        // Try parent directory path
        final parentPath = '../data/$fileName';
        final parentFile = File(parentPath);
        if (await parentFile.exists()) {
          actualFile = parentFile;
        }
      }

      if (actualFile == null) {
        throw Exception('Sample file not found: $fileName');
      }

      // Read file content
      final content = await actualFile.readAsBytes();

      // Get the ChatInterface and add the file attachment
      final chatInterface = _chatInterfaceKey.currentState;
      if (chatInterface != null) {
        await chatInterface.addFileAttachment(
          fileName: fileName,
          content: content,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Loaded: $fileName'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load file: $error'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
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
          if (_apiKey != null) ...[
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Upload FIT File',
              onPressed: _handleFileUpload,
            ),
            IconButton(
              icon: const Icon(Icons.info_outline),
              tooltip: 'About',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Agentic Chart Demo'),
                    content: const Text(
                      'This demo showcases natural language chart creation and sport science file analysis.\n\n'
                      'Upload FIT files and type chart requests in plain English!',
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
        ],
      ),
      body: _apiKey == null
          ? _buildApiKeyInput()
          : _isInitializing
              ? const Center(child: CircularProgressIndicator())
              : ChatInterface(
                  key: _chatInterfaceKey,
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
