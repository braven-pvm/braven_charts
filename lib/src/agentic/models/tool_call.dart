/// Stub implementation for ToolCall model
/// This will be implemented in the green phase of TDD
class ToolCall {
  final String id;
  final String toolName;
  final Map<String, dynamic> arguments;
  final dynamic result;

  /// Creates a new ToolCall instance
  ToolCall({
    required this.id,
    required this.toolName,
    required this.arguments,
    this.result,
  });

  /// Creates a ToolCall from JSON
  factory ToolCall.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('ToolCall.fromJson not yet implemented');
  }

  /// Converts ToolCall to JSON
  Map<String, dynamic> toJson() {
    throw UnimplementedError('ToolCall.toJson not yet implemented');
  }
}
