/// Base class for LLM tools (function calling).
abstract class LLMTool {
  /// Unique tool name
  String get name;

  /// Description of what the tool does
  String get description;

  /// JSON schema describing the tool input
  Map<String, dynamic> get inputSchema;

  /// Executes the tool with provided arguments
  Future<dynamic> execute(Map<String, dynamic> args);
}
