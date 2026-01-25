/// Message role enumeration
enum MessageRole {
  user,
  assistant,
  system,
}

/// Stub implementation for Message model
/// This will be implemented in the green phase of TDD
class Message {
  final String id;
  final MessageRole role;
  final String? textContent;
  final List<dynamic>? toolCalls;
  final List<dynamic>? toolResults;
  final List<dynamic>? attachments;
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
  }) : timestamp = timestamp ?? DateTime.now();

  /// Creates a Message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('Message.fromJson not yet implemented');
  }

  /// Converts Message to JSON
  Map<String, dynamic> toJson() {
    throw UnimplementedError('Message.toJson not yet implemented');
  }

  /// Creates a copy with modified values
  Message copyWith({
    String? id,
    MessageRole? role,
    String? textContent,
    List<dynamic>? toolCalls,
    List<dynamic>? toolResults,
    List<dynamic>? attachments,
    DateTime? timestamp,
  }) {
    throw UnimplementedError('Message.copyWith not yet implemented');
  }
}
