/// Represents the result of a tool execution.
///
/// Contains either success data or error information from
/// executing a tool call.
class ToolResult {
  /// Unique identifier for this result
  final String id;

  /// ID of the tool call that generated this result
  final String toolCallId;

  /// Whether this result represents an error
  final bool isError;

  /// Whether the tool execution succeeded
  final bool success;

  /// Content returned by the tool
  final dynamic content;

  /// Result data from the tool
  final dynamic result;

  /// Error message if execution failed
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
        id = id ?? toolCallId,
        assert((id ?? toolCallId).isNotEmpty, 'ToolResult id cannot be empty'),
        assert(toolCallId.isNotEmpty, 'toolCallId cannot be empty'),
        assert(
          (success ?? !(isError ?? false)) == false ||
              result != null ||
              content != null,
          'Successful result must have result or content',
        ),
        assert(
          (success ?? !(isError ?? false)) == true || error != null,
          'Failed result must have error message',
        );

  /// Creates a ToolResult from JSON
  factory ToolResult.fromJson(Map<String, dynamic> json) {
    return ToolResult(
      id: json['id'] as String?,
      toolCallId: json['toolCallId'] as String,
      isError: json['isError'] as bool? ?? false,
      success: json['success'] as bool?,
      content: json['content'],
      result: json['result'],
      error: json['error'] as String?,
    );
  }

  /// Converts ToolResult to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'toolCallId': toolCallId,
      'isError': isError,
      'success': success,
      if (content != null) 'content': content,
      if (result != null) 'result': result,
      if (error != null) 'error': error,
    };
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
    return ToolResult(
      id: id ?? this.id,
      toolCallId: toolCallId ?? this.toolCallId,
      isError: isError ?? this.isError,
      success: success ?? this.success,
      content: content ?? this.content,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ToolResult &&
        other.id == id &&
        other.toolCallId == toolCallId &&
        other.success == success;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      toolCallId,
      success,
    );
  }
}
