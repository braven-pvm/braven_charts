/// Stub implementation for ToolResult model
/// This will be implemented in the green phase of TDD
class ToolResult {
  final String id;
  final String toolCallId;
  final bool isError;
  final bool success;
  final dynamic content;
  final dynamic result;
  final String? error;

  /// Creates a new ToolResult instance
  ToolResult({
    String? id,
    required this.toolCallId,
    bool? isError,
    bool? success,
    this.content,
    this.result,
    this.error,
  })  : isError = isError ?? false,
        success = success ?? !(isError ?? false),
        id = id ?? toolCallId;

  /// Creates a ToolResult from JSON
  factory ToolResult.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('ToolResult.fromJson not yet implemented');
  }

  /// Converts ToolResult to JSON
  Map<String, dynamic> toJson() {
    throw UnimplementedError('ToolResult.toJson not yet implemented');
  }

  /// Creates a copy with modified values
  ToolResult copyWith({
    String? id,
    String? toolCallId,
    bool? isError,
    bool? success,
    dynamic content,
    dynamic result,
    String? error,
  }) {
    throw UnimplementedError('ToolResult.copyWith not yet implemented');
  }
}
