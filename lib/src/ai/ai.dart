// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// AI integration for BravenChartPlus.
///
/// This library provides tools for integrating BravenChartPlus with AI agents,
/// enabling natural language chart generation in chat interfaces.
///
/// ## Overview
///
/// The AI integration consists of three main components:
///
/// 1. **[ChartToolSchema]** - JSON Schema definitions for LLM function calling
/// 2. **[ChartConfigBuilder]** - Converts LLM JSON output to Flutter widgets
/// 3. **[ChartAgentInterface]** - Abstract interface for LLM integration
///
/// ## Quick Start
///
/// ### 1. Define tools for your LLM
///
/// ```dart
/// import 'package:braven_charts/ai.dart';
///
/// // Get tool definitions in your LLM's format
/// final tools = ChartToolSchema.toAnthropicFormat(); // For Claude
/// // or
/// final tools = ChartToolSchema.toOpenAIFormat(); // For GPT-4
/// ```
///
/// ### 2. Process tool calls
///
/// ```dart
/// final chartAgent = DefaultChartAgent();
///
/// // When LLM returns a tool call
/// final widget = await chartAgent.processToolCall(
///   toolCall.name,      // 'create_chart'
///   toolCall.arguments, // JSON from LLM
/// );
///
/// if (widget != null) {
///   // Render the interactive chart in your UI
///   chatMessages.add(ChartMessage(widget: widget));
/// }
/// ```
///
/// ### 3. Handle chart modifications
///
/// ```dart
/// // User: "Change it to a bar chart"
/// // LLM calls modify_chart tool
/// final updatedWidget = await chartAgent.processToolCall(
///   'modify_chart',
///   {'chart_id': 'chart_123', 'action': 'change_type', 'parameters': {'type': 'bar'}},
/// );
/// ```
///
/// ## Architecture
///
/// ```
/// ┌──────────────┐     ┌──────────────┐     ┌───────────────────┐
/// │   User Chat  │────▶│  LLM API     │────▶│ Tool Call         │
/// │   Message    │     │  (Claude/    │     │ create_chart({    │
/// │              │     │   GPT-4)     │     │   series: [...],  │
/// │              │     │              │     │   chart_type: ... │
/// └──────────────┘     └──────────────┘     └─────────┬─────────┘
///                                                     │
///                                                     ▼
/// ┌──────────────┐     ┌──────────────┐     ┌───────────────────┐
/// │  Interactive │◀────│ ChartConfig  │◀────│  ChartAgent       │
/// │  Chart       │     │ Builder      │     │  Interface        │
/// │  Widget      │     │              │     │                   │
/// └──────────────┘     └──────────────┘     └───────────────────┘
/// ```
///
/// ## LLM Integration Examples
///
/// ### Anthropic Claude
///
/// ```dart
/// import 'package:anthropic_sdk/anthropic_sdk.dart';
/// import 'package:braven_charts/ai.dart';
///
/// class ClaudeChartChat {
///   final AnthropicClient client;
///   final chartAgent = DefaultChartAgent();
///
///   Future<void> sendMessage(String userMessage) async {
///     final response = await client.messages.create(
///       model: 'claude-sonnet-4-20250514',
///       tools: chartAgent.toolDefinitions,
///       messages: [
///         Message(role: 'user', content: userMessage),
///       ],
///     );
///
///     for (final block in response.content) {
///       if (block is ToolUseBlock) {
///         final widget = await chartAgent.processToolCall(
///           block.name,
///           block.input,
///         );
///         if (widget != null) {
///           // Add to chat UI
///         }
///       }
///     }
///   }
/// }
/// ```
///
/// ### OpenAI GPT-4
///
/// ```dart
/// import 'package:openai_dart/openai_dart.dart';
/// import 'package:braven_charts/ai.dart';
///
/// class GPTChartChat {
///   final OpenAIClient client;
///   final chartAgent = DefaultChartAgent();
///
///   Future<void> sendMessage(String userMessage) async {
///     final response = await client.createChatCompletion(
///       model: 'gpt-4',
///       tools: ChartToolSchema.toOpenAIFormat(),
///       messages: [
///         ChatMessage(role: 'user', content: userMessage),
///       ],
///     );
///
///     final toolCalls = response.choices.first.message.toolCalls;
///     for (final call in toolCalls ?? []) {
///       final widget = await chartAgent.processToolCall(
///         call.function.name,
///         jsonDecode(call.function.arguments),
///       );
///       // Handle widget...
///     }
///   }
/// }
/// ```
///
/// ## Supported Tools
///
/// | Tool | Description |
/// |------|-------------|
/// | `create_chart` | Creates a new interactive chart from data |
/// | `modify_chart` | Modifies an existing chart (type, series, axis) |
/// | `explain_data` | Analyzes data patterns and provides insights |
///
/// ## Chart Types
///
/// The AI can generate these chart types:
/// - **Line**: Best for trends over time
/// - **Area**: Line chart with filled region
/// - **Bar**: Best for comparisons
/// - **Scatter**: Best for correlations
///
/// ## Data Format
///
/// The LLM generates data in this format:
/// ```json
/// {
///   "series": [{
///     "id": "temperature",
///     "name": "Temperature",
///     "color": "#FF5733",
///     "unit": "°C",
///     "data": [
///       {"x": 0, "y": 20.5},
///       {"x": 1, "y": 22.3}
///     ]
///   }],
///   "x_axis": {"label": "Time", "unit": "hours"},
///   "chart_type": "line"
/// }
/// ```
library;

export 'chart_agent_interface.dart';
export 'chart_config_builder.dart';
export 'chart_tool_schema.dart';
