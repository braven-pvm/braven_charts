// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

// Braven Agent Demo - Interactive Agentic Chart Creation (V2 Schema)
//
// This demo showcases the V2 agentic chart schema features:
// - **Nested yAxis**: Each series defines its own y-axis configuration
// - **System-generated IDs**: Annotations have auto-assigned UUIDs
// - **Deep merge updates**: Partial modifications preserve unspecified fields
// - **Per-series normalization**: Independent min/max scaling per series
//
// ## Usage
//
// 1. Enter your Anthropic or Grok API key
// 2. Use natural language to describe charts:
//    - "Create a line chart showing temperature from 0 to 100"
//    - "Add a reference line at 75 labeled 'threshold'"
//    - "Change the series color to red"
//
// ## Example Prompts for V2 Features
//
// Multi-axis chart with nested yAxis:
// "Create a chart with temperature (°C) on the left axis
// and humidity (%) on the right axis"
//
// The LLM will generate series with nested yAxis configurations:
// ```json
// {
//   "series": [{
//     "id": "temp",
//     "yAxis": {"position": "left", "label": "Temp", "unit": "°C"}
//   }, {
//     "id": "humidity",
//     "yAxis": {"position": "right", "label": "Humidity", "unit": "%"}
//   }]
// }
// ```

import 'dart:convert';

import 'package:braven_agent/braven_agent.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A holder for the chart capture callback that can be set after session creation.
///
/// This allows the [SeeChartTool] to be registered with the session at creation time,
/// while the actual capture callback is set later by the ChatScreen widget that owns
/// the [ChartSnapshotWrapper].
class ChartCaptureCallbackHolder {
  /// The callback that captures the chart. Set by ChatScreen when it has access
  /// to the [ChartSnapshotWrapperState].
  ChartCaptureCallback? callback;
}

/// Simple API key storage service using shared_preferences.
///
/// Keys are stored locally in the browser (web) or app storage (mobile).
/// Keys are stored per-provider for convenience.
class ApiKeyStore {
  static const _keyPrefix = 'braven_agent_api_key_';
  static const _providerKey = 'braven_agent_selected_provider';
  static const _modelKey = 'braven_agent_selected_model';

  static SharedPreferences? _prefs;

  /// Initialize the store. Call once at app startup.
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Get stored API key for a provider.
  static String? getApiKey(String provider) {
    // Map provider to base key (grok-responses uses same key as grok)
    final baseProvider = provider == 'grok-responses' ? 'grok' : provider;
    return _prefs?.getString('$_keyPrefix$baseProvider');
  }

  /// Save API key for a provider.
  static Future<void> setApiKey(String provider, String apiKey) async {
    // Map provider to base key (grok-responses uses same key as grok)
    final baseProvider = provider == 'grok-responses' ? 'grok' : provider;
    await _prefs?.setString('$_keyPrefix$baseProvider', apiKey);
  }

  /// Get last selected provider.
  static String? getSelectedProvider() {
    return _prefs?.getString(_providerKey);
  }

  /// Save selected provider.
  static Future<void> setSelectedProvider(String provider) async {
    await _prefs?.setString(_providerKey, provider);
  }

  /// Get last selected model.
  static String? getSelectedModel() {
    return _prefs?.getString(_modelKey);
  }

  /// Save selected model.
  static Future<void> setSelectedModel(String model) async {
    await _prefs?.setString(_modelKey, model);
  }

  /// Check if we have a stored key for any provider.
  static bool hasAnyStoredKey() {
    for (final provider in ['anthropic', 'openai', 'gemini', 'grok']) {
      if (getApiKey(provider)?.isNotEmpty == true) return true;
    }
    return false;
  }

  /// Clear all stored keys.
  static Future<void> clearAll() async {
    for (final provider in ['anthropic', 'openai', 'gemini', 'grok']) {
      await _prefs?.remove('$_keyPrefix$provider');
    }
    await _prefs?.remove(_providerKey);
    await _prefs?.remove(_modelKey);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiKeyStore.init();
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
  String _selectedProvider = 'anthropic';
  String _selectedModel = 'claude-sonnet-4-20250514';

  /// Holder for the chart capture callback, set by ChatScreen.
  final ChartCaptureCallbackHolder _captureCallbackHolder = ChartCaptureCallbackHolder();

  // Available models per provider
  static const Map<String, List<({String id, String name, String description})>> _availableModels = {
    'anthropic': [
      (id: 'claude-sonnet-4-20250514', name: 'Claude Sonnet 4', description: 'Best balance of speed and capability'),
      (id: 'claude-opus-4-20250514', name: 'Claude Opus 4', description: 'Most capable, best for complex tasks'),
    ],
    'openai': [
      // GPT-5 series (frontier, latest - Jan 2026)
      (id: 'gpt-5.2', name: 'GPT-5.2', description: 'Best for coding and agentic tasks'),
      (id: 'gpt-5.2-pro', name: 'GPT-5.2 Pro', description: 'Smarter, more precise responses'),
      (id: 'gpt-5-mini', name: 'GPT-5 Mini', description: 'Fast, cost-efficient'),
      (id: 'gpt-5-nano', name: 'GPT-5 Nano', description: 'Fastest, most cost-efficient'),
      // GPT-4.1 series (non-reasoning)
      (id: 'gpt-4.1', name: 'GPT-4.1', description: 'Smartest non-reasoning model'),
      (id: 'gpt-4.1-mini', name: 'GPT-4.1 Mini', description: 'Smaller, faster'),
      // Legacy (still available)
      (id: 'gpt-4o', name: 'GPT-4o', description: 'Previous flagship (128K context)'),
      (id: 'gpt-4o-mini', name: 'GPT-4o Mini', description: 'Fast and affordable'),
    ],
    'gemini': [
      // Gemini 3 (preview - Jan 2026)
      (id: 'gemini-3-pro-preview', name: 'Gemini 3 Pro', description: 'Most powerful agentic model'),
      (id: 'gemini-3-flash-preview', name: 'Gemini 3 Flash', description: 'Best for speed and scale'),
      // Gemini 2.5 (stable)
      (id: 'gemini-2.5-flash', name: 'Gemini 2.5 Flash', description: 'Best price-performance, agentic'),
      (id: 'gemini-2.5-flash-lite', name: 'Gemini 2.5 Flash Lite', description: 'Fastest, cost-efficient'),
      (id: 'gemini-2.5-pro', name: 'Gemini 2.5 Pro', description: 'Advanced thinking model'),
    ],
    // Grok Responses API (hybrid mode - RECOMMENDED for agentic workflows)
    'grok-responses': [
      (id: 'grok-4-1-fast', name: 'Grok 4.1 Fast', description: 'Best for agentic mode (hybrid server/client)'),
      (id: 'grok-4-1-fast-reasoning', name: 'Grok 4.1 Reasoning', description: 'With extended reasoning'),
      (id: 'grok-4-1-fast-non-reasoning', name: 'Grok 4.1 Non-Reasoning', description: 'Faster, less reasoning'),
    ],
    // Grok Chat Completions API (OpenAI-compatible - less reliable for tools)
    'grok': [
      // Grok 4 series - NON-REASONING FIRST (reasoning models have tool error issues)
      (id: 'grok-4-1-fast-non-reasoning', name: 'Grok 4.1 Fast', description: 'Latest, best for tools (2M context)'),
      (id: 'grok-4-fast-non-reasoning', name: 'Grok 4 Fast', description: 'Fast without reasoning (2M context)'),
      (id: 'grok-4-0709', name: 'Grok 4', description: 'Grok 4 base (256K context)'),
      // Grok 4 reasoning models (may ignore tool errors in loops)
      (id: 'grok-4-1-fast-reasoning', name: 'Grok 4.1 Reasoning', description: 'With reasoning - may loop on errors'),
      (id: 'grok-4-fast-reasoning', name: 'Grok 4 Reasoning', description: 'With reasoning - may loop on errors'),
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
    _loadSavedSettings();
  }

  Future<void> _loadSavedSettings() async {
    // 1. First, try to restore from saved preferences
    final savedProvider = ApiKeyStore.getSelectedProvider();
    final savedModel = ApiKeyStore.getSelectedModel();

    if (savedProvider != null) {
      final savedKey = ApiKeyStore.getApiKey(savedProvider);
      if (savedKey != null && savedKey.isNotEmpty) {
        _selectedProvider = savedProvider;
        _selectedModel = savedModel ?? _availableModels[savedProvider]!.first.id;
        _apiKeyController.text = savedKey;
        _setApiKey(savedKey);
        return;
      }
    }

    // 2. Fall back to environment variables
    final anthropicKey = const String.fromEnvironment('ANTHROPIC_API_KEY');
    if (anthropicKey.isNotEmpty) {
      _selectedProvider = 'anthropic';
      _selectedModel = 'claude-sonnet-4-20250514';
      _setApiKey(anthropicKey);
      return;
    }
    final openaiKey = const String.fromEnvironment('OPENAI_API_KEY');
    if (openaiKey.isNotEmpty) {
      _selectedProvider = 'openai';
      _selectedModel = 'gpt-5.2';
      _setApiKey(openaiKey);
      return;
    }
    final geminiKey = const String.fromEnvironment('GEMINI_API_KEY');
    if (geminiKey.isNotEmpty) {
      _selectedProvider = 'gemini';
      _selectedModel = 'gemini-2.5-flash';
      _setApiKey(geminiKey);
      return;
    }
    final grokKey = const String.fromEnvironment('GROK_API_KEY');
    if (grokKey.isNotEmpty) {
      // Prefer Responses API (hybrid mode) for better agentic tool handling
      _selectedProvider = 'grok-responses';
      _selectedModel = 'grok-4-1-fast';
      _setApiKey(grokKey);
    }
  }

  void _onProviderChanged(String provider) {
    setState(() {
      _selectedProvider = provider;
      // Set default model for the selected provider
      _selectedModel = _availableModels[provider]!.first.id;
      // Load stored API key for this provider
      final storedKey = ApiKeyStore.getApiKey(provider);
      if (storedKey != null && storedKey.isNotEmpty) {
        _apiKeyController.text = storedKey;
      } else {
        _apiKeyController.clear();
      }
    });
    // Save selected provider
    ApiKeyStore.setSelectedProvider(provider);
  }

  void _setApiKey(String apiKey) {
    _session?.dispose();

    // Save API key and selections to store
    ApiKeyStore.setApiKey(_selectedProvider, apiKey);
    ApiKeyStore.setSelectedProvider(_selectedProvider);
    ApiKeyStore.setSelectedModel(_selectedModel);

    final LLMProvider llmProvider;
    final config = LLMConfig(
      apiKey: apiKey,
      model: _selectedModel,
    );

    switch (_selectedProvider) {
      case 'openai':
        final adapter = OpenAIAdapter(config);
        adapter.debugLogging = true;
        llmProvider = adapter;
      case 'gemini':
        final adapter = GeminiAdapter(config);
        adapter.debugLogging = true;
        llmProvider = adapter;
      case 'grok-responses':
        final adapter = GrokResponsesAdapter(config);
        adapter.debugLogging = true;
        llmProvider = adapter;
      case 'grok':
        final adapter = GrokAdapter(config);
        adapter.debugLogging = true;
        llmProvider = adapter;
      case 'anthropic':
      default:
        llmProvider = AnthropicAdapter(config);
    }

    // Create session first, then pass getActiveChart callback to ModifyChartTool
    // and getChartById callback to GetChartTool
    late final AgentSessionImpl session;
    session = AgentSessionImpl(
      llmProvider: llmProvider,
      tools: [
        CreateChartTool(),
        ModifyChartTool(getActiveChart: () => session.state.value.activeChart),
        GetChartTool(
          getChartById: (id) {
            final chart = session.state.value.activeChart;
            return chart?.id == id ? chart : null;
          },
        ),
        // SeeChartTool uses a late-bound callback that ChatScreen will set
        SeeChartTool(
          onCapture: () async {
            final callback = _captureCallbackHolder.callback;
            if (callback == null) {
              return null; // Callback not yet set by ChatScreen
            }
            return callback();
          },
        ),
      ],
      systemPrompt: defaultSystemPrompt,
      debugLogging: true, // Enable verbose logging for debugging
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

    return ChatScreen(
      session: session,
      onChangeProvider: _resetToSettings,
      captureCallbackHolder: _captureCallbackHolder,
    );
  }

  void _resetToSettings() {
    setState(() {
      _apiKey = null;
      _session?.dispose();
      _session = null;
    });
  }

  Widget _buildApiKeyInput() {
    final (providerName, hintText, consoleUrl) = switch (_selectedProvider) {
      'openai' => ('OpenAI', 'sk-...', 'platform.openai.com'),
      'gemini' => ('Google Gemini', 'AIza...', 'aistudio.google.com'),
      'grok' => ('Grok (xAI)', 'xai-...', 'console.x.ai'),
      _ => ('Anthropic', 'sk-ant-...', 'console.anthropic.com'),
    };

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
                  // Provider selector (using dropdown for 4 providers)
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProvider,
                    decoration: const InputDecoration(
                      labelText: 'LLM Provider',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.cloud),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'anthropic',
                        child: Row(
                          children: [
                            Icon(Icons.auto_awesome, size: 20),
                            SizedBox(width: 8),
                            Text('Anthropic (Claude)'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'openai',
                        child: Row(
                          children: [
                            Icon(Icons.smart_toy, size: 20),
                            SizedBox(width: 8),
                            Text('OpenAI (GPT)'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'gemini',
                        child: Row(
                          children: [
                            Icon(Icons.diamond, size: 20),
                            SizedBox(width: 8),
                            Text('Google (Gemini)'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'grok-responses',
                        child: Row(
                          children: [
                            Icon(Icons.psychology_alt, size: 20),
                            SizedBox(width: 8),
                            Text('xAI (Grok Responses API)'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: 'grok',
                        child: Row(
                          children: [
                            Icon(Icons.psychology, size: 20),
                            SizedBox(width: 8),
                            Text('xAI (Grok Chat API)'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value != null) {
                        _onProviderChanged(value);
                      }
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
  const ChatScreen({
    super.key,
    required this.session,
    this.onChangeProvider,
    this.captureCallbackHolder,
  });

  final AgentSession session;
  final VoidCallback? onChangeProvider;

  /// Holder for the chart capture callback. If provided, this widget will set
  /// the callback so that [SeeChartTool] can capture chart screenshots.
  final ChartCaptureCallbackHolder? captureCallbackHolder;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _inputFocusNode = FocusNode();
  GlobalKey<ChartSnapshotWrapperState> _chartSnapshotKey = GlobalKey<ChartSnapshotWrapperState>();
  int? _lastCapturedChartHash;
  int? _currentChartKeyHash;

  /// Persistent annotation controller to preserve user interactions (e.g., drag positions)
  /// across parent widget rebuilds.
  final AnnotationController _annotationController = AnnotationController();

  /// Cached ChartRenderer with persistent controller.
  late final ChartRenderer _chartRenderer;

  /// Flag to prevent re-entrant annotation sync (avoid loops).
  bool _syncingAnnotations = false;

  /// Pending image attachment for the next message.
  ImageContent? _pendingImageAttachment;
  String? _pendingImageName;

  @override
  void initState() {
    super.initState();
    _chartRenderer = ChartRenderer(annotationController: _annotationController);

    // Set the capture callback for SeeChartTool
    widget.captureCallbackHolder?.callback = () async {
      return _chartSnapshotKey.currentState?.capture();
    };

    // Listen for annotation changes from user interactions (drag, right-click menu, etc.)
    // and sync them back to the session so the agent has current state.
    _annotationController.addListener(_onAnnotationsChanged);
  }

  @override
  void dispose() {
    _annotationController.removeListener(_onAnnotationsChanged);
    _messageController.dispose();
    _inputFocusNode.dispose();
    _annotationController.dispose();
    super.dispose();
  }

  /// Called when the annotation controller changes (user edits).
  /// Syncs the updated annotations back to the session's ChartConfiguration.
  void _onAnnotationsChanged() {
    // Prevent re-entrant sync (the render() also updates the controller)
    if (_syncingAnnotations) return;

    final currentChart = widget.session.state.value.activeChart;
    if (currentChart == null) return;

    _syncingAnnotations = true;
    try {
      // Use the renderer to convert current annotations back to config
      final updatedConfig = _chartRenderer.syncAnnotationsToConfig(currentChart);
      if (updatedConfig != null && updatedConfig != currentChart) {
        // Sync back to session so agent tools see the current state
        // ignore: avoid_print
        print('[AnnotationSync] Syncing ${updatedConfig.annotations.length} annotations to session (was ${currentChart.annotations.length})');
        for (final ann in updatedConfig.annotations) {
          // ignore: avoid_print
          print('[AnnotationSync]   - ${ann.id}: ${ann.type.name} "${ann.label ?? 'no label'}"');
        }
        widget.session.updateChart(updatedConfig);
      }
    } finally {
      _syncingAnnotations = false;
    }
  }

  Future<void> _sendMessage(SessionState state) async {
    final text = _messageController.text.trim();
    if (text.isEmpty || state.status == ActivityStatus.thinking || state.status == ActivityStatus.calling_tool) {
      return;
    }

    _messageController.clear();

    // Capture and clear the pending attachment
    final attachments = _pendingImageAttachment != null ? [_pendingImageAttachment!] : null;
    setState(() {
      _pendingImageAttachment = null;
      _pendingImageName = null;
    });

    // Start the transform (adds user message to history)
    final transformFuture = widget.session.transform(text, attachments: attachments);

    // Scroll will be triggered by _onStateChanged when history updates

    await transformFuture;
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        final base64Data = base64Encode(file.bytes!);
        final extension = file.extension?.toLowerCase() ?? 'png';
        final mediaType = switch (extension) {
          'jpg' || 'jpeg' => 'image/jpeg',
          'gif' => 'image/gif',
          'webp' => 'image/webp',
          _ => 'image/png',
        };

        setState(() {
          _pendingImageAttachment = ImageContent(
            data: base64Data,
            mediaType: mediaType,
          );
          _pendingImageName = file.name;
        });
      }
    }
  }

  void _clearPendingImage() {
    setState(() {
      _pendingImageAttachment = null;
      _pendingImageName = null;
    });
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
                      child: _chartRenderer.render(activeChart),
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
          onPickImage: _pickImage,
          pendingImageName: _pendingImageName,
          onClearImage: _clearPendingImage,
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
            actions: [
              if (widget.onChangeProvider != null)
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: 'Change Provider/Model',
                  onPressed: widget.onChangeProvider,
                ),
            ],
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
    required this.onPickImage,
    required this.onClearImage,
    this.pendingImageName,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isProcessing;
  final VoidCallback onSend;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;
  final String? pendingImageName;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Pending image preview
            if (pendingImageName != null)
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.image,
                      size: 20,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        pendingImageName!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          fontSize: 13,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onClearImage,
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            // Input row
            Row(
              children: [
                // Attachment button
                IconButton(
                  onPressed: isProcessing ? null : onPickImage,
                  icon: const Icon(Icons.attach_file),
                  tooltip: 'Attach image',
                ),
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
