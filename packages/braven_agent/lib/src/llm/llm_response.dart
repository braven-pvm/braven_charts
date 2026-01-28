import 'package:equatable/equatable.dart';

import 'models/agent_message.dart';
import 'models/message_content.dart';

/// Response from an LLM completion request.
///
/// Contains the generated message along with token usage statistics
/// and the reason for stopping generation.
///
/// ## Example
///
/// ```dart
/// final response = LLMResponse(
///   message: AgentMessage(...),
///   inputTokens: 150,
///   outputTokens: 50,
///   stopReason: 'end_turn',
/// );
///
/// print('Total tokens: ${response.inputTokens + response.outputTokens}');
/// ```
class LLMResponse with EquatableMixin {
  /// The generated message from the LLM.
  final AgentMessage message;

  /// Number of tokens in the input prompt.
  final int inputTokens;

  /// Number of tokens in the generated output.
  final int outputTokens;

  /// Reason why generation stopped.
  ///
  /// Common values:
  /// - 'end_turn': Natural end of response
  /// - 'tool_use': LLM requested tool execution
  /// - 'max_tokens': Reached token limit
  /// - 'stop_sequence': Hit a stop sequence
  final String? stopReason;

  /// Creates an [LLMResponse] with the given parameters.
  const LLMResponse({
    required this.message,
    required this.inputTokens,
    required this.outputTokens,
    this.stopReason,
  });

  /// Creates an [LLMResponse] from a JSON map.
  factory LLMResponse.fromJson(Map<String, dynamic> json) {
    return LLMResponse(
      message: AgentMessage.fromJson(json['message'] as Map<String, dynamic>),
      inputTokens: json['inputTokens'] as int,
      outputTokens: json['outputTokens'] as int,
      stopReason: json['stopReason'] as String?,
    );
  }

  /// Converts this [LLMResponse] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'message': message.toJson(),
      'inputTokens': inputTokens,
      'outputTokens': outputTokens,
      if (stopReason != null) 'stopReason': stopReason,
    };
  }

  /// Creates a copy of this [LLMResponse] with optionally overridden values.
  LLMResponse copyWith({
    AgentMessage? message,
    int? inputTokens,
    int? outputTokens,
    String? stopReason,
  }) {
    return LLMResponse(
      message: message ?? this.message,
      inputTokens: inputTokens ?? this.inputTokens,
      outputTokens: outputTokens ?? this.outputTokens,
      stopReason: stopReason ?? this.stopReason,
    );
  }

  @override
  List<Object?> get props => [message, inputTokens, outputTokens, stopReason];

  @override
  String toString() =>
      'LLMResponse(inputTokens: $inputTokens, outputTokens: $outputTokens, stopReason: $stopReason)';
}

/// A chunk of a streaming LLM response.
///
/// Used for real-time UI updates during response generation.
/// Each chunk may contain incremental text or a complete tool call.
///
/// ## Example
///
/// ```dart
/// // Text streaming chunk
/// final textChunk = LLMChunk(
///   textDelta: 'Here is your ',
///   isComplete: false,
/// );
///
/// // Tool use chunk
/// final toolChunk = LLMChunk(
///   toolUse: ToolUseContent(
///     id: 'toolu_123',
///     toolName: 'create_chart',
///     input: {'type': 'line'},
///   ),
///   isComplete: false,
/// );
///
/// // Final chunk
/// final finalChunk = LLMChunk(
///   isComplete: true,
///   stopReason: 'end_turn',
/// );
/// ```
class LLMChunk with EquatableMixin {
  /// Incremental text content being streamed.
  ///
  /// Null for non-text chunks (e.g., tool use chunks).
  final String? textDelta;

  /// Complete tool call when detected in the stream.
  ///
  /// Tool use content is typically provided as a complete object
  /// rather than streamed incrementally.
  final ToolUseContent? toolUse;

  /// Whether this is the final chunk in the stream.
  final bool isComplete;

  /// Reason why streaming stopped.
  ///
  /// Only set on the final chunk. Common values:
  /// - 'end_turn': Natural end of response
  /// - 'tool_use': LLM requested tool execution
  /// - 'max_tokens': Reached token limit
  final String? stopReason;

  /// Creates an [LLMChunk] with the given parameters.
  const LLMChunk({
    this.textDelta,
    this.toolUse,
    this.isComplete = false,
    this.stopReason,
  });

  /// Creates an [LLMChunk] from a JSON map.
  factory LLMChunk.fromJson(Map<String, dynamic> json) {
    return LLMChunk(
      textDelta: json['textDelta'] as String?,
      toolUse: json['toolUse'] != null
          ? ToolUseContent.fromJson(json['toolUse'] as Map<String, dynamic>)
          : null,
      isComplete: json['isComplete'] as bool? ?? false,
      stopReason: json['stopReason'] as String?,
    );
  }

  /// Converts this [LLMChunk] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      if (textDelta != null) 'textDelta': textDelta,
      if (toolUse != null) 'toolUse': toolUse!.toJson(),
      'isComplete': isComplete,
      if (stopReason != null) 'stopReason': stopReason,
    };
  }

  /// Creates a copy of this [LLMChunk] with optionally overridden values.
  LLMChunk copyWith({
    String? textDelta,
    ToolUseContent? toolUse,
    bool? isComplete,
    String? stopReason,
  }) {
    return LLMChunk(
      textDelta: textDelta ?? this.textDelta,
      toolUse: toolUse ?? this.toolUse,
      isComplete: isComplete ?? this.isComplete,
      stopReason: stopReason ?? this.stopReason,
    );
  }

  @override
  List<Object?> get props => [textDelta, toolUse, isComplete, stopReason];

  @override
  String toString() =>
      'LLMChunk(textDelta: ${textDelta?.length ?? 0} chars, toolUse: ${toolUse != null}, isComplete: $isComplete)';
}
