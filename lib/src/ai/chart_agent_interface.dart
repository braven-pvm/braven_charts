// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/widgets.dart';

import '../braven_chart_plus.dart';
import '../models/chart_series.dart';
import 'chart_config_builder.dart';
import 'chart_tool_schema.dart';

/// Callback for when a new chart is created by the AI.
typedef ChartCreatedCallback = void Function(
  String chartId,
  Widget chartWidget,
  ChartBuildResult config,
);

/// Callback for when an existing chart is modified.
typedef ChartModifiedCallback = void Function(
  String chartId,
  ChartBuildResult newConfig,
);

/// Abstract interface for AI agent chart generation.
///
/// Implement this interface to connect BravenChartPlus to your preferred
/// LLM provider (Anthropic Claude, OpenAI, etc.).
///
/// The interface handles:
/// 1. Providing tool schemas to the LLM
/// 2. Processing tool calls from the LLM
/// 3. Managing chart instances
///
/// Example implementation with a hypothetical LLM client:
/// ```dart
/// class ClaudeChartAgent extends ChartAgentInterface {
///   final AnthropicClient client;
///   final _charts = <String, ChartBuildResult>{};
///
///   ClaudeChartAgent(this.client);
///
///   @override
///   Future<Widget?> processToolCall(String toolName, Map<String, dynamic> args) async {
///     if (toolName == 'create_chart') {
///       final result = ChartConfigBuilder.fromJson(args);
///       final chartId = 'chart_${DateTime.now().millisecondsSinceEpoch}';
///       _charts[chartId] = result;
///
///       return BravenChartPlus(
///         series: result.series,
///         xAxisConfig: result.xAxisConfig,
///         yAxis: result.yAxisConfig,
///       );
///     }
///     return null;
///   }
///
///   @override
///   List<ChartSeries> getChartSeries(String chartId) {
///     return _charts[chartId]?.series ?? [];
///   }
/// }
/// ```
abstract class ChartAgentInterface {
  /// Returns the tool definitions for the LLM.
  ///
  /// Use [ChartToolSchema.toAnthropicFormat()] or [ChartToolSchema.toOpenAIFormat()]
  /// depending on your LLM provider.
  List<Map<String, dynamic>> get toolDefinitions => ChartToolSchema.toAnthropicFormat();

  /// Processes a tool call from the LLM and returns a chart widget if applicable.
  ///
  /// Returns `null` if the tool call doesn't produce a chart (e.g., `explain_data`).
  ///
  /// Tool names:
  /// - `create_chart`: Creates a new chart, returns Widget
  /// - `modify_chart`: Modifies existing chart, returns Widget or null
  /// - `explain_data`: Analyzes data, returns null (text response only)
  Future<Widget?> processToolCall(
    String toolName,
    Map<String, dynamic> arguments,
  );

  /// Returns the series data for a given chart ID.
  ///
  /// Used by `explain_data` tool to analyze chart data.
  List<ChartSeries> getChartSeries(String chartId);

  /// Returns all active chart IDs.
  List<String> get activeChartIds;

  /// Disposes of a chart instance.
  void disposeChart(String chartId);

  /// Clears all chart instances.
  void disposeAll();
}

/// Default implementation of [ChartAgentInterface] that manages chart state.
///
/// This implementation:
/// - Creates [BravenChartPlus] widgets from AI-generated configs
/// - Tracks active charts by ID
/// - Supports chart modifications
///
/// Example usage in a chat app:
/// ```dart
/// final chartAgent = DefaultChartAgent();
///
/// // When LLM returns a tool call
/// if (toolCall.name == 'create_chart') {
///   final widget = await chartAgent.processToolCall(
///     toolCall.name,
///     toolCall.arguments,
///   );
///
///   if (widget != null) {
///     // Add widget to chat message list
///     messages.add(ChartMessage(widget));
///   }
/// }
/// ```
class DefaultChartAgent implements ChartAgentInterface {
  final _charts = <String, ChartBuildResult>{};

  /// Callback invoked when a chart is created.
  ChartCreatedCallback? onChartCreated;

  /// Callback invoked when a chart is modified.
  ChartModifiedCallback? onChartModified;

  @override
  List<Map<String, dynamic>> get toolDefinitions => ChartToolSchema.toAnthropicFormat();

  @override
  Future<Widget?> processToolCall(
    String toolName,
    Map<String, dynamic> arguments,
  ) async {
    return switch (toolName) {
      'create_chart' => _handleCreateChart(arguments),
      'modify_chart' => _handleModifyChart(arguments),
      'explain_data' => _handleExplainData(arguments),
      _ => throw ArgumentError('Unknown tool: $toolName'),
    };
  }

  Widget _handleCreateChart(Map<String, dynamic> args) {
    final result = ChartConfigBuilder.fromJson(args);
    final chartId = result.chartId ?? 'chart_${DateTime.now().millisecondsSinceEpoch}';

    _charts[chartId] = result;

    final widget = _buildChartWidget(result, chartId);

    onChartCreated?.call(chartId, widget, result);

    return widget;
  }

  Widget? _handleModifyChart(Map<String, dynamic> args) {
    final chartId = args['chart_id'] as String?;
    if (chartId == null || !_charts.containsKey(chartId)) {
      throw ArgumentError('Chart not found: $chartId');
    }

    final action = args['action'] as String?;
    final params = args['parameters'] as Map<String, dynamic>? ?? {};

    final currentConfig = _charts[chartId]!;
    final newConfig = _applyModification(currentConfig, action, params);

    _charts[chartId] = newConfig;
    onChartModified?.call(chartId, newConfig);

    return _buildChartWidget(newConfig, chartId);
  }

  Widget? _handleExplainData(Map<String, dynamic> args) {
    // This tool returns analysis text, not a widget
    // The actual analysis would be done by the LLM based on the data
    // We just need to provide the data if requested
    return null;
  }

  ChartBuildResult _applyModification(
    ChartBuildResult config,
    String? action,
    Map<String, dynamic> params,
  ) {
    // For now, return config unchanged
    // Full implementation would handle each action type
    return switch (action) {
      'change_type' => config, // TODO: Implement type change
      'add_series' => config, // TODO: Implement add series
      'remove_series' => config, // TODO: Implement remove series
      'update_axis' => config, // TODO: Implement axis update
      _ => config,
    };
  }

  Widget _buildChartWidget(ChartBuildResult result, String chartId) {
    return SizedBox(
      width: 750,
      height: 450,
      child: BravenChartPlus(
        key: ValueKey(chartId),
        series: result.series,
        xAxisConfig: result.xAxisConfig,
        yAxis: result.yAxisConfig,
        interactionConfig: result.interactionConfig,
        grid: result.gridConfig,
        showLegend: result.showLegend,
      ),
    );
  }

  @override
  List<ChartSeries> getChartSeries(String chartId) {
    return _charts[chartId]?.series ?? [];
  }

  @override
  List<String> get activeChartIds => _charts.keys.toList();

  @override
  void disposeChart(String chartId) {
    _charts.remove(chartId);
  }

  @override
  void disposeAll() {
    _charts.clear();
  }

  /// Returns the configuration for a specific chart.
  ChartBuildResult? getChartConfig(String chartId) => _charts[chartId];
}
