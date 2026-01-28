# Quickstart: Braven Agent Package

**Feature**: 004-braven-agent-package  
**Date**: 2026-01-28  
**Status**: Complete

## Overview

This guide provides practical usage examples for the `braven_agent` package. Examples progress from basic to advanced usage patterns.

---

## 1. Installation

### 1.1 Add Dependency

```yaml
# pubspec.yaml
dependencies:
  braven_agent:
    path: ../packages/braven_agent # During development
  # braven_agent: ^1.0.0           # After publishing
```

### 1.2 Get Dependencies

```bash
flutter pub get
```

---

## 2. Basic Usage

### 2.1 Create an Agent Session

```dart
import 'package:braven_agent/braven_agent.dart';

void main() {
  // 1. Register provider (once at app startup)
  LLMRegistry.register('anthropic', (config) => AnthropicAdapter(config));

  // 2. Create LLM configuration
  final llmConfig = LLMConfig(
    apiKey: 'your-api-key',
    model: 'claude-sonnet-4-20250514',
    temperature: 0.7,
    maxTokens: 4096,
  );

  // 3. Create provider
  final provider = LLMRegistry.create('anthropic', llmConfig);

  // 4. Create session
  final session = AgentSessionImpl(
    provider: provider,
    tools: [CreateChartTool(), ModifyChartTool(...)],
    systemPrompt: defaultSystemPrompt,  // Or custom prompt
  );
}
```

### 2.2 Send a Message

```dart
// Send user message and get response
await session.transform(
  TextContent(text: 'Create a line chart showing sales data from January to March'),
);

// Or with image attachment
await session.transform([
  TextContent(text: 'Create a chart like this image'),
  ImageContent(
    base64Data: base64EncodedPng,
    mediaType: 'image/png',
  ),
]);
```

### 2.3 Listen to State Changes

```dart
// Using ValueListenableBuilder in Flutter
ValueListenableBuilder<SessionState>(
  valueListenable: session.state,
  builder: (context, state, child) {
    if (state.isProcessing) {
      return const CircularProgressIndicator();
    }

    if (state.hasError) {
      return Text('Error: ${state.errorMessage}');
    }

    if (state.activeChart != null) {
      return const ChartRenderer().render(state.activeChart!);
    }

    return const Text('Ask me to create a chart!');
  },
);
```

---

## 3. Complete Flutter Widget Example

### 3.1 Chat Screen with Chart

```dart
import 'package:flutter/material.dart';
import 'package:braven_agent/braven_agent.dart';

class AgentChatScreen extends StatefulWidget {
  final AgentSession session;

  const AgentChatScreen({super.key, required this.session});

  @override
  State<AgentChatScreen> createState() => _AgentChatScreenState();
}

class _AgentChatScreenState extends State<AgentChatScreen> {
  final _textController = TextEditingController();
  late final StreamSubscription<AgentEvent> _eventSub;

  @override
  void initState() {
    super.initState();
    _eventSub = widget.session.events.listen(_handleEvent);
  }

  @override
  void dispose() {
    _eventSub.cancel();
    _textController.dispose();
    super.dispose();
  }

  void _handleEvent(AgentEvent event) {
    switch (event) {
      case ChartCreatedEvent(:final chart):
        // Optional: Save chart to database
        _saveChart(chart);
      case ErrorEvent(:final message):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $message')),
        );
      case _:
        break;
    }
  }

  Future<void> _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    _textController.clear();
    await widget.session.transform(TextContent(text: text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chart Agent')),
      body: Column(
        children: [
          // Chart Display Area
          Expanded(
            flex: 2,
            child: ValueListenableBuilder<SessionState>(
              valueListenable: widget.session.state,
              builder: (context, state, _) => _buildChartArea(state),
            ),
          ),

          const Divider(),

          // Message History
          Expanded(
            flex: 1,
            child: ValueListenableBuilder<SessionState>(
              valueListenable: widget.session.state,
              builder: (context, state, _) => _buildHistory(state),
            ),
          ),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildChartArea(SessionState state) {
    if (state.activeChart == null) {
      return const Center(
        child: Text('Ask me to create a chart!'),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: const ChartRenderer().render(state.activeChart!),
    );
  }

  Widget _buildHistory(SessionState state) {
    return ListView.builder(
      itemCount: state.history.length,
      itemBuilder: (context, index) {
        final message = state.history[index];
        return ListTile(
          leading: Icon(
            message.role == MessageRole.user
                ? Icons.person
                : Icons.smart_toy,
          ),
          title: Text(_extractText(message)),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return ValueListenableBuilder<SessionState>(
      valueListenable: widget.session.state,
      builder: (context, state, _) {
        return Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  enabled: !state.isProcessing,
                  decoration: const InputDecoration(
                    hintText: 'Describe the chart you want...',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 8),
              if (state.isProcessing)
                IconButton(
                  icon: const Icon(Icons.cancel),
                  onPressed: () => widget.session.cancel(),
                )
              else
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
            ],
          ),
        );
      },
    );
  }

  String _extractText(AgentMessage message) {
    for (final content in message.content) {
      if (content is TextContent) return content.text;
    }
    return '[Non-text content]';
  }

  void _saveChart(ChartConfiguration chart) {
    // Implement persistence as needed
  }
}
```

---

## 4. Direct Rendering (No AI)

### 4.1 Render from ChartConfiguration

```dart
import 'package:braven_agent/braven_agent.dart';

// Create configuration programmatically
final config = ChartConfiguration(
  id: 'my-chart-1',
  type: ChartType.line,
  title: 'Monthly Sales',
  series: [
    SeriesConfig(
      id: 'sales',
      name: 'Revenue',
      color: '#2196F3',
      data: [
        DataPoint(x: 1, y: 1000),
        DataPoint(x: 2, y: 1500),
        DataPoint(x: 3, y: 1250),
      ],
      strokeWidth: 2.0,
      showPoints: true,
    ),
  ],
  xAxis: XAxisConfig(
    label: 'Month',
    showGridLines: true,
  ),
  showLegend: true,
  legendPosition: LegendPosition.bottom,
);

// Render to widget
final chartWidget = const ChartRenderer().render(config);
```

### 4.2 Render from JSON

```dart
// Load saved configuration
final json = {
  'id': 'chart-123',
  'type': 'line',
  'title': 'Power Output',
  'series': [
    {
      'id': 'power',
      'name': 'Watts',
      'color': '#F44336',
      'data': [
        {'x': 0, 'y': 200},
        {'x': 1, 'y': 250},
        {'x': 2, 'y': 225},
      ],
    },
  ],
};

// Render directly from JSON
final widget = const ChartRenderer().render(json);
```

---

## 5. User Chart Editing

### 5.1 Sync User Edits Back to Agent

```dart
// User modifies chart outside agent (e.g., in a chart editor UI)
void onUserEditedChart(ChartConfiguration updatedChart) {
  // Update session state so agent sees the change
  session.updateChart(updatedChart);

  // Next transform() will include updated chart context
}
```

### 5.2 Example: Color Picker

```dart
class ChartColorPicker extends StatelessWidget {
  final AgentSession session;
  final String seriesId;

  const ChartColorPicker({
    super.key,
    required this.session,
    required this.seriesId,
  });

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SessionState>(
      valueListenable: session.state,
      builder: (context, state, _) {
        if (state.activeChart == null) return const SizedBox.shrink();

        final series = state.activeChart!.series
            .firstWhere((s) => s.id == seriesId);

        return ColorPicker(
          currentColor: _parseHex(series.color ?? '#2196F3'),
          onColorChanged: (color) {
            final updated = state.activeChart!.copyWith(
              series: state.activeChart!.series.map((s) {
                if (s.id == seriesId) {
                  return s.copyWith(color: _toHex(color));
                }
                return s;
              }).toList(),
            );
            session.updateChart(updated);
          },
        );
      },
    );
  }
}
```

---

## 6. Event Handling

### 6.1 Persistence on Chart Creation

```dart
session.events.listen((event) {
  switch (event) {
    case ChartCreatedEvent(:final chart):
      // Save new chart to database
      database.insertChart(chart.toJson());

    case ChartUpdatedEvent(:final chart):
      // Update existing chart
      database.updateChart(chart.id, chart.toJson());

    case ErrorEvent(:final message, :final error):
      // Log error
      analytics.logError(message, error);

    case _:
      break;
  }
});
```

### 6.2 UI Feedback

```dart
session.events.listen((event) {
  switch (event) {
    case ProcessingStartedEvent():
      showLoadingOverlay();

    case ProcessingCompletedEvent():
      hideLoadingOverlay();

    case CancelledEvent():
      showToast('Request cancelled');

    case _:
      break;
  }
});
```

---

## 7. Cancellation

```dart
// Start a long-running request
session.transform(TextContent(text: 'Create a complex chart...'));

// User clicks cancel
session.cancel();

// CancelledEvent is emitted
// State returns to idle
```

---

## 8. Custom System Prompt

```dart
final customPrompt = '''
You are a sports analytics chart expert.
When creating charts, always use:
- Dark theme for visibility
- Per-series normalization for multi-metric overlays
- Reference lines for threshold values

Available tools: create_chart, modify_chart
''';

final session = AgentSessionImpl(
  provider: provider,
  tools: [CreateChartTool(), ModifyChartTool(...)],
  systemPrompt: customPrompt,
);
```

---

## 9. Multi-Provider Support (Future)

```dart
// Register multiple providers
LLMRegistry.register('anthropic', (c) => AnthropicAdapter(c));
LLMRegistry.register('openai', (c) => OpenAIAdapter(c));

// Switch providers dynamically
final anthropic = LLMRegistry.create('anthropic', anthropicConfig);
final openai = LLMRegistry.create('openai', openaiConfig);

// Create sessions with different providers
final session1 = AgentSessionImpl(provider: anthropic, ...);
final session2 = AgentSessionImpl(provider: openai, ...);
```

---

## 10. Demo App Entry Point

```dart
// lib/main.dart of demo app
import 'package:flutter/material.dart';
import 'package:braven_agent/braven_agent.dart';

void main() {
  // Initialize providers
  LLMRegistry.register('anthropic', (c) => AnthropicAdapter(c));

  runApp(const DemoApp());
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Braven Agent Demo',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const ApiKeyScreen(),  // First, get API key
    );
  }
}

class ApiKeyScreen extends StatefulWidget {
  const ApiKeyScreen({super.key});

  @override
  State<ApiKeyScreen> createState() => _ApiKeyScreenState();
}

class _ApiKeyScreenState extends State<ApiKeyScreen> {
  final _controller = TextEditingController();

  void _startSession() {
    final apiKey = _controller.text.trim();
    if (apiKey.isEmpty) return;

    final config = LLMConfig(
      apiKey: apiKey,
      model: 'claude-sonnet-4-20250514',
    );

    final provider = LLMRegistry.create('anthropic', config);

    final session = AgentSessionImpl(
      provider: provider,
      tools: [
        CreateChartTool(),
        ModifyChartTool(getActiveChart: () => session.state.value.activeChart),
      ],
    );

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => AgentChatScreen(session: session),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Enter API Key')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _controller,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Anthropic API Key',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _startSession,
              child: const Text('Start Session'),
            ),
          ],
        ),
      ),
    );
  }
}
```
