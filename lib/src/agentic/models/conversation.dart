/// Stub implementation for Conversation model
/// This will be implemented in the green phase of TDD
class Conversation {
  final String id;
  final List<dynamic> messages;
  final DateTime createdAt;
  final Map<String, dynamic> dataStore;
  final Map<String, dynamic> charts;
  final int totalInputTokens;
  final int totalOutputTokens;
  final double? estimatedCostUsd;

  /// Creates a new Conversation instance
  Conversation({
    required this.id,
    List<dynamic>? messages,
    DateTime? createdAt,
    Map<String, dynamic>? dataStore,
    Map<String, dynamic>? charts,
    int? totalInputTokens,
    int? totalOutputTokens,
    this.estimatedCostUsd,
  })  : messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        dataStore = dataStore ?? {},
        charts = charts ?? {},
        totalInputTokens = totalInputTokens ?? 0,
        totalOutputTokens = totalOutputTokens ?? 0;

  /// Creates a Conversation from JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('Conversation.fromJson not yet implemented');
  }

  /// Converts Conversation to JSON
  Map<String, dynamic> toJson() {
    throw UnimplementedError('Conversation.toJson not yet implemented');
  }

  /// Creates a copy with modified values
  Conversation copyWith({
    String? id,
    List<dynamic>? messages,
    DateTime? createdAt,
    Map<String, dynamic>? dataStore,
    Map<String, dynamic>? charts,
    int? totalInputTokens,
    int? totalOutputTokens,
    double? estimatedCostUsd,
  }) {
    throw UnimplementedError('Conversation.copyWith not yet implemented');
  }
}
