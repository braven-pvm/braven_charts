import 'tool_result.dart';

/// Abstract interface for tools that can be executed by an LLM agent.
///
/// Tools provide structured operations that the LLM can invoke during
/// a conversation. Each tool exposes:
/// - A unique [name] for LLM identification
/// - A human-readable [description] explaining the tool's purpose
/// - An [inputSchema] (JSON Schema) for structured input validation
/// - An async [execute] method that performs the operation
///
/// ## Implementing a Tool
///
/// ```dart
/// class CreateChartTool extends AgentTool {
///   @override
///   String get name => 'create_chart';
///
///   @override
///   String get description => 'Creates a new chart with the specified configuration.';
///
///   @override
///   Map<String, dynamic> get inputSchema => {
///     'type': 'object',
///     'properties': {
///       'chartTitle': {'type': 'string'},
///     },
///     'required': ['chartTitle'],
///   };
///
///   @override
///   Future<ToolResult> execute(Map<String, dynamic> input) async {
///     final title = input['chartTitle'] as String;
///     final chart = ChartConfiguration(title: title);
///     return ToolResult(
///       output: jsonEncode(chart.toJson()),
///       data: chart,
///     );
///   }
/// }
/// ```
///
/// ## Error Handling
///
/// Tools should return [ToolResult] with `isError: true` for recoverable errors,
/// allowing the LLM to self-correct:
///
/// ```dart
/// @override
/// Future<ToolResult> execute(Map<String, dynamic> input) async {
///   final chartType = input['chartType'] as String?;
///   if (chartType == null) {
///     return ToolResult(
///       output: 'Error: chartType is required',
///       isError: true,
///     );
///   }
///   // ... normal execution
/// }
/// ```
///
/// ## Registration
///
/// Tools are registered with the agent session and exposed to the LLM
/// through the tool definitions in API requests.
abstract class AgentTool {
  /// Unique identifier for this tool.
  ///
  /// Used by the LLM to specify which tool to invoke. Must be unique
  /// across all registered tools. Convention: snake_case (e.g., 'create_chart').
  String get name;

  /// Human-readable description of what this tool does.
  ///
  /// Provided to the LLM to help it understand when to use this tool.
  /// Should be clear and concise, explaining the tool's purpose and
  /// any important constraints.
  String get description;

  /// JSON Schema defining the expected input structure.
  ///
  /// Used by the LLM to format its tool invocation correctly.
  /// Should follow JSON Schema specification (draft-07 or later).
  ///
  /// Example:
  /// ```dart
  /// {
  ///   'type': 'object',
  ///   'properties': {
  ///     'title': {'type': 'string', 'description': 'Chart title'},
  ///     'chartType': {
  ///       'type': 'string',
  ///       'enum': ['line', 'bar', 'area', 'scatter'],
  ///     },
  ///   },
  ///   'required': ['chartType'],
  /// }
  /// ```
  Map<String, dynamic> get inputSchema;

  /// Executes the tool with the given input parameters.
  ///
  /// The [input] map contains parameters matching the [inputSchema].
  /// Returns a [ToolResult] with the execution outcome.
  ///
  /// For successful execution, return [ToolResult] with the output string
  /// and optionally structured [ToolResult.data].
  ///
  /// For errors, return [ToolResult] with `isError: true` and an error
  /// message in [ToolResult.output] to enable LLM self-correction.
  ///
  /// Throws should be reserved for unrecoverable errors (e.g., network failure).
  Future<ToolResult> execute(Map<String, dynamic> input);
}
