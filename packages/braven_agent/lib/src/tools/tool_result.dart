import 'package:equatable/equatable.dart';

import '../llm/models/message_content.dart';

/// Result of executing an [AgentTool].
///
/// Captures the outcome of a tool execution, providing both human-readable
/// output (for LLM consumption) and optional structured data (for programmatic use).
///
/// The [isError] flag enables LLM self-correction - when a tool fails,
/// the LLM can see the error and attempt to fix its input.
///
/// ## Example
///
/// ```dart
/// // Successful tool result
/// final success = ToolResult(
///   output: '{"chartId": "chart_123", "type": "line"}',
///   data: chartConfiguration,
/// );
///
/// // Error result (LLM can self-correct)
/// final error = ToolResult(
///   output: 'Invalid chart type: "invalid". Valid types: line, bar, area, scatter.',
///   isError: true,
/// );
/// ```
///
/// ## Usage in AgentSession
///
/// The [data] field is used by AgentSession to capture structured objects
/// like [ChartConfiguration] for state updates:
///
/// ```dart
/// final result = await tool.execute(input);
/// if (!result.isError && result.data is ChartConfiguration) {
///   session.updateActiveChart(result.data as ChartConfiguration);
/// }
/// ```
class ToolResult with EquatableMixin {
  /// String output returned to the LLM.
  ///
  /// Typically JSON-encoded for structured data, or a human-readable
  /// message for errors. The LLM uses this to continue the conversation.
  final String output;

  /// Whether the tool execution resulted in an error.
  ///
  /// When `true`, the [output] contains an error message that the LLM
  /// can use for self-correction. The LLM may retry with corrected input.
  ///
  /// Defaults to `false` for successful executions.
  final bool isError;

  /// Optional structured data from the tool execution.
  ///
  /// Used to pass typed objects (like [ChartConfiguration]) to the
  /// AgentSession for state updates. Not sent to the LLM directly.
  ///
  /// This is `null` for error results or tools that don't produce
  /// structured data.
  final Object? data;

  /// Optional image content from the tool execution.
  ///
  /// When set, this image will be included in the tool result message
  /// sent to the LLM, enabling vision-capable models to "see" the result.
  ///
  /// This is useful for tools like `see_chart` that capture screenshots
  /// of charts for visual analysis.
  final ImageContent? imageContent;

  /// Creates a [ToolResult] with the given parameters.
  ///
  /// The [output] parameter is required and contains the string result
  /// returned to the LLM.
  ///
  /// The [isError] parameter defaults to `false`. Set to `true` when
  /// the tool execution failed.
  ///
  /// The [data] parameter is optional and can contain any structured
  /// object for programmatic use.
  const ToolResult({
    required this.output,
    this.isError = false,
    this.data,
    this.imageContent,
  });

  @override
  List<Object?> get props => [output, isError, data, imageContent];

  @override
  String toString() => 'ToolResult(output: ${output.length} chars, isError: $isError, data: ${data?.runtimeType}, hasImage: ${imageContent != null})';
}
