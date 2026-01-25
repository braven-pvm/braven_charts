import 'file_attachment.dart';
import 'tool_call.dart';
import 'tool_result.dart';

/// Message role enumeration
enum MessageRole {
  user,
  assistant,
  system,
}

/// Represents a single chat message (user, assistant, or system).
///
/// Either textContent or toolCalls must be present.
/// Attachments are only valid for user messages.
class Message {
  /// Unique identifier for the message
  final String id;

  /// Role of the message sender
  final MessageRole role;

  /// Text content of the message (optional if toolCalls present)
  final String? textContent;

  /// Tool calls made by the assistant (optional)
  final List<ToolCall>? toolCalls;

  /// Results from tool executions (optional)
  final List<ToolResult>? toolResults;

  /// File attachments (only for user messages)
  final List<FileAttachment>? attachments;

  /// Timestamp when the message was created
  final DateTime timestamp;

  /// Creates a new Message instance
  Message({
    required this.id,
    required this.role,
    this.textContent,
    this.toolCalls,
    this.toolResults,
    this.attachments,
    DateTime? timestamp,
  })  : timestamp = timestamp ?? DateTime.now(),
        assert(
          textContent != null || toolCalls != null || toolResults != null,
          'Message must have textContent, toolCalls, or toolResults',
        ),
        assert(
          attachments == null || role == MessageRole.user,
          'Only user messages can have attachments',
        );

  /// Creates a Message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      role: MessageRole.values.firstWhere(
        (e) => e.name == json['role'],
      ),
      textContent: json['textContent'] as String?,
      toolCalls: json['toolCalls'] != null
          ? (json['toolCalls'] as List)
              .map((e) => ToolCall.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      toolResults: json['toolResults'] != null
          ? (json['toolResults'] as List)
              .map((e) => ToolResult.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      attachments: json['attachments'] != null
          ? (json['attachments'] as List)
              .map((e) => FileAttachment.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  /// Converts Message to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      if (textContent != null) 'textContent': textContent,
      if (toolCalls != null)
        'toolCalls': toolCalls!.map((tc) => tc.toJson()).toList(),
      if (toolResults != null)
        'toolResults': toolResults!.map((tr) => tr.toJson()).toList(),
      if (attachments != null)
        'attachments': attachments!.map((a) => a.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Creates a copy with modified values
  Message copyWith({
    String? id,
    MessageRole? role,
    String? textContent,
    List<ToolCall>? toolCalls,
    List<ToolResult>? toolResults,
    List<FileAttachment>? attachments,
    DateTime? timestamp,
  }) {
    return Message(
      id: id ?? this.id,
      role: role ?? this.role,
      textContent: textContent ?? this.textContent,
      toolCalls: toolCalls ?? this.toolCalls,
      toolResults: toolResults ?? this.toolResults,
      attachments: attachments ?? this.attachments,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message &&
        other.id == id &&
        other.role == role &&
        other.textContent == textContent &&
        other.timestamp == timestamp;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      role,
      textContent,
      timestamp,
    );
  }
}
