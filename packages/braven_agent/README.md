# braven_agent

Headless AI orchestration engine for chart generation. This package manages
conversation state, communicates with LLMs, and executes tools that produce
`ChartConfiguration` objects you can render in Flutter.

## Installation

Add the dependency in your `pubspec.yaml`:

```yaml
dependencies:
  braven_agent:
    path: ../packages/braven_agent
```

Then run `flutter pub get`.

## Quick Start

Create a session, send a prompt, and render the resulting chart:

```dart
import 'package:braven_agent/braven_agent.dart';
import 'package:flutter/material.dart';

final config = LLMConfig(
  apiKey: 'YOUR_ANTHROPIC_KEY',
  model: 'claude-sonnet-4-20250514',
);
final llmProvider = AnthropicAdapter(config);

late final AgentSessionImpl session;
session = AgentSessionImpl(
  llmProvider: llmProvider,
  tools: [
    CreateChartTool(),
    ModifyChartTool(getActiveChart: () => session.state.value.activeChart),
  ],
  systemPrompt: defaultSystemPrompt,
);

await session.transform('Create a line chart with monthly sales data');

final chart = session.state.value.activeChart;
final widget = const ChartRenderer().render(chart!);
```

## AgentSession Usage

Use the session to send prompts and bind UI to state updates:

```dart
ValueListenableBuilder<SessionState>(
  valueListenable: session.state,
  builder: (context, state, _) {
    if (state.status == ActivityStatus.thinking) {
      return const CircularProgressIndicator();
    }
    if (state.activeChart != null) {
      return ChartRenderer().render(state.activeChart!);
    }
    return const Text('Ask me to create a chart!');
  },
)
```

The active chart is always available via `session.state.value.activeChart`.

## ChartRenderer

Render a configuration into a widget:

```dart
final renderer = const ChartRenderer();
final widget = renderer.render(chartConfiguration);
```

`render()` accepts a `ChartConfiguration` or a JSON-style `Map<String, dynamic>`
that can be parsed into a configuration.

## Tools

### CreateChartTool

Creates a new chart from structured input (type, series, styling). Register it
when starting a session so the LLM can produce an initial configuration.

### ModifyChartTool

Updates an existing chart by applying partial changes (titles, series edits,
styling updates). Wire it to the session using `getActiveChart` so it always
modifies the current chart state.

## Event Stream (Persistence & Side Effects)

Subscribe to `session.events` for persistence, navigation, or notifications:

```dart
session.events.listen((event) {
  switch (event) {
    case ChartCreatedEvent(:final config):
      database.insertChart(config);
    case ChartUpdatedEvent(:final config):
      database.updateChart(config.id!, config);
    case ErrorEvent(:final message):
      showErrorDialog(message);
    case ToolStartEvent(:final toolName):
      debugPrint('Executing: $toolName');
    case ToolEndEvent(:final toolName, :final success):
      debugPrint('$toolName ${success ? 'succeeded' : 'failed'}');
    case CancelledEvent():
      debugPrint('Request cancelled');
  }
});
```

## API Reference

Key public APIs exposed by the package:

- `AgentSession` / `AgentSessionImpl`
- `ChartRenderer`
- `CreateChartTool`, `ModifyChartTool`
- `ChartConfiguration`, `SeriesConfig`, `AnnotationConfig`
- `LLMProvider`, `AnthropicAdapter`, `LLMConfig`

For examples and patterns, see the demo in `example/lib/demos/braven_agent_demo.dart`.
