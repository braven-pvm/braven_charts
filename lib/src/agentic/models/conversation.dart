import 'loaded_data.dart';
import 'message.dart';

/// Represents a chat session between user and AI agent.
///
/// Contains messages, loaded data, charts, and token tracking.
/// IDs must be valid UUID v4 format and token counts must be non-negative.
class Conversation {
  /// Unique identifier (UUID v4 format)
  final String id;

  /// List of messages in the conversation
  final List<Message> messages;

  /// Timestamp when the conversation was created
  final DateTime createdAt;

  /// Data store mapping UUID to LoadedData
  final Map<String, LoadedData> dataStore;

  /// Charts mapping chartId to ChartState
  final Map<String, dynamic> charts;

  /// Total input tokens used
  final int totalInputTokens;

  /// Total output tokens generated
  final int totalOutputTokens;

  /// Estimated cost in USD
  final double? estimatedCostUsd;

  /// Creates a new Conversation instance
  Conversation({
    required this.id,
    List<Message>? messages,
    DateTime? createdAt,
    Map<String, LoadedData>? dataStore,
    Map<String, dynamic>? charts,
    int? totalInputTokens,
    int? totalOutputTokens,
    this.estimatedCostUsd,
  })  : messages = messages ?? [],
        createdAt = createdAt ?? DateTime.now(),
        dataStore = dataStore ?? {},
        charts = charts ?? {},
        totalInputTokens = totalInputTokens ?? 0,
        totalOutputTokens = totalOutputTokens ?? 0,
        assert(
          _isValidUuidV4(id),
          'Conversation id must be a valid UUID v4 format',
        ),
        assert(
          (totalInputTokens ?? 0) >= 0,
          'totalInputTokens must be non-negative',
        ),
        assert(
          (totalOutputTokens ?? 0) >= 0,
          'totalOutputTokens must be non-negative',
        );

  /// Validates UUID v4 format
  static bool _isValidUuidV4(String id) {
    final uuidV4Pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidV4Pattern.hasMatch(id);
  }

  /// Creates a Conversation from JSON
  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] as String,
      messages: (json['messages'] as List)
          .map((e) => Message.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      dataStore: (json['dataStore'] as Map).map(
        (key, value) => MapEntry(
            key as String, LoadedData.fromJson(value as Map<String, dynamic>)),
      ),
      charts: Map<String, dynamic>.from(json['charts'] as Map? ?? {}),
      totalInputTokens: json['totalInputTokens'] as int,
      totalOutputTokens: json['totalOutputTokens'] as int,
      estimatedCostUsd: json['estimatedCostUsd'] as double?,
    );
  }

  /// Converts Conversation to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'messages': messages.map((m) => m.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'dataStore': dataStore.map((key, value) => MapEntry(key, value.toJson())),
      'charts': charts,
      'totalInputTokens': totalInputTokens,
      'totalOutputTokens': totalOutputTokens,
      if (estimatedCostUsd != null) 'estimatedCostUsd': estimatedCostUsd,
    };
  }

  /// Creates a copy with modified values
  Conversation copyWith({
    String? id,
    List<Message>? messages,
    DateTime? createdAt,
    Map<String, LoadedData>? dataStore,
    Map<String, dynamic>? charts,
    int? totalInputTokens,
    int? totalOutputTokens,
    double? estimatedCostUsd,
  }) {
    return Conversation(
      id: id ?? this.id,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      dataStore: dataStore ?? this.dataStore,
      charts: charts ?? this.charts,
      totalInputTokens: totalInputTokens ?? this.totalInputTokens,
      totalOutputTokens: totalOutputTokens ?? this.totalOutputTokens,
      estimatedCostUsd: estimatedCostUsd ?? this.estimatedCostUsd,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Conversation &&
        other.id == id &&
        _messagesEqual(other.messages, messages) &&
        other.totalInputTokens == totalInputTokens &&
        other.totalOutputTokens == totalOutputTokens &&
        other.estimatedCostUsd == estimatedCostUsd;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      Object.hashAll(messages),
      totalInputTokens,
      totalOutputTokens,
      estimatedCostUsd,
    );
  }

  static bool _messagesEqual(List<Message> a, List<Message> b) {
    if (identical(a, b)) {
      return true;
    }
    if (a.length != b.length) {
      return false;
    }
    for (var i = 0; i < a.length; i += 1) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }
}
