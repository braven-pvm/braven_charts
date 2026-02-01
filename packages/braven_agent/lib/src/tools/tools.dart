/// Tool Layer for the braven_agent package.
///
/// This library exports the foundation classes for the Tool Layer:
/// - [AgentTool] - Abstract interface for tools executable by an LLM agent
/// - [ToolResult] - Result model capturing tool execution outcomes
///
/// ## Overview
///
/// Tools enable LLM agents to perform structured operations during
/// conversations. Each tool defines its interface through:
/// - A unique name for identification
/// - A description for LLM guidance
/// - A JSON Schema for input validation
/// - An execute method for performing the operation
///
/// ## Example
///
/// ```dart
/// import 'package:braven_agent/src/tools/tools.dart';
///
/// class EchoTool extends AgentTool {
///   @override
///   String get name => 'echo';
///
///   @override
///   String get description => 'Echoes back the input message.';
///
///   @override
///   Map<String, dynamic> get inputSchema => {
///     'type': 'object',
///     'properties': {
///       'message': {'type': 'string'},
///     },
///     'required': ['message'],
///   };
///
///   @override
///   Future<ToolResult> execute(Map<String, dynamic> input) async {
///     final message = input['message'] as String;
///     return ToolResult(output: 'Echo: $message');
///   }
/// }
/// ```
library;

export 'agent_tool.dart';
export 'create_chart_tool.dart';
export 'get_chart_tool.dart';
export 'modify_chart_tool.dart';
export 'see_chart_tool.dart';
export 'tool_result.dart';
