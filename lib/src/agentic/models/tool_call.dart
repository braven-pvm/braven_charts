/// Represents an LLM tool invocation request.
///
/// A ToolCall contains the tool name and arguments for a function
/// that the LLM wants to execute. It may also contain the result
/// once the tool has been executed.
class ToolCall {
  /// Unique identifier for this tool call
  final String id;

  /// Name of the tool being called
  final String toolName;

  /// Arguments passed to the tool
  final Map<String, dynamic> arguments;

  /// Optional result after tool execution
  final dynamic result;

  /// Creates a new ToolCall instance
  ToolCall({
    required this.id,
    required this.toolName,
    required this.arguments,
    this.result,
  })  : assert(id.isNotEmpty, 'ToolCall id cannot be empty'),
        assert(toolName.isNotEmpty, 'toolName cannot be empty');

  /// Creates a ToolCall from JSON
  factory ToolCall.fromJson(Map<String, dynamic> json) {
    return ToolCall(
      id: json['id'] as String,
      toolName: json['toolName'] as String,
      arguments: Map<String, dynamic>.from(json['arguments'] as Map),
      result: json['result'],
    );
  }

  /// Converts ToolCall to JSON
  Map<String, dynamic> toJson() {
    final json = {
      'id': id,
      'toolName': toolName,
      'arguments': arguments,
    };

    if (result != null) {
      if (result is Map) {
        json['result'] = result as Map<String, dynamic>;
      } else {
        // If result is a ToolResult object, serialize it
        json['result'] = (result as dynamic).toJson();
      }
    }

    return json;
  }

  /// Creates a copy with modified values
  ToolCall copyWith({
    String? id,
    String? toolName,
    Map<String, dynamic>? arguments,
    dynamic result,
  }) {
    return ToolCall(
      id: id ?? this.id,
      toolName: toolName ?? this.toolName,
      arguments: arguments ?? this.arguments,
      result: result ?? this.result,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolCall && other.id == id && other.toolName == toolName;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      toolName,
    );
  }
}
