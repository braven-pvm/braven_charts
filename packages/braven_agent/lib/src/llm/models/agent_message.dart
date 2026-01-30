import 'package:equatable/equatable.dart';

import 'message_content.dart';

/// Role of a message in a conversation.
///
/// Defines the sender type for [AgentMessage] instances.
enum MessageRole {
  /// Message from the user.
  user,

  /// Message from the assistant/LLM.
  assistant,

  /// System message providing context or instructions.
  system,

  /// Message containing tool execution results.
  tool,
}

/// A message in an agent conversation.
///
/// Represents a single turn in the conversation history, including
/// the role (user, assistant, system, tool), content blocks, and metadata.
///
/// ## Example
///
/// ```dart
/// final message = AgentMessage(
///   id: 'msg_123',
///   role: MessageRole.user,
///   content: [TextContent(text: 'Create a line chart')],
///   timestamp: DateTime.now(),
/// );
/// ```
///
/// ## JSON Serialization
///
/// ```dart
/// final json = message.toJson();
/// final restored = AgentMessage.fromJson(json);
/// ```
class AgentMessage with EquatableMixin {
  /// Unique identifier for this message.
  final String id;

  /// Role of the message sender.
  final MessageRole role;

  /// Content blocks in this message.
  ///
  /// A message can contain multiple content blocks of different types
  /// (text, images, tool calls, tool results).
  final List<MessageContent> content;

  /// Timestamp when the message was created.
  final DateTime timestamp;

  /// Optional metadata associated with the message.
  ///
  /// Can contain provider-specific data or application metadata.
  final Map<String, dynamic>? metadata;

  /// Creates an [AgentMessage] with the given parameters.
  ///
  /// [id], [role], [content], and [timestamp] are required.
  const AgentMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.metadata,
  });

  /// Creates an [AgentMessage] from a JSON map.
  ///
  /// Parses the content list using [MessageContent.fromJson].
  factory AgentMessage.fromJson(Map<String, dynamic> json) {
    return AgentMessage(
      id: json['id'] as String,
      role: MessageRole.values.byName(json['role'] as String),
      content: (json['content'] as List<dynamic>)
          .map((e) => MessageContent.fromJson(e as Map<String, dynamic>))
          .toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  /// Converts this [AgentMessage] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.name,
      'content': content.map((e) => e.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
    };
  }

  /// Creates a copy of this [AgentMessage] with optionally overridden values.
  AgentMessage copyWith({
    String? id,
    MessageRole? role,
    List<MessageContent>? content,
    DateTime? timestamp,
    Map<String, dynamic>? metadata,
  }) {
    return AgentMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [id, role, content, timestamp, metadata];

  @override
  String toString() =>
      'AgentMessage(id: $id, role: $role, content: ${content.length} blocks)';
}
