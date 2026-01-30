import '../models/conversation.dart';
import '../models/message.dart';

enum LLMProviderErrorType {
  authentication,
  network,
  rateLimited,
  unknown,
}

class LLMProviderException implements Exception {
  final String message;
  final LLMProviderErrorType type;

  LLMProviderException(this.message,
      {this.type = LLMProviderErrorType.unknown});

  @override
  String toString() => 'LLMProviderException($type): $message';
}

/// Abstract interface for Large Language Model providers.
abstract class LLMProvider {
  /// Sends a message and returns a single response.
  Future<Message> sendMessage(Conversation conversation);

  /// Streams a message response as incremental text chunks.
  Stream<String> streamMessage(Conversation conversation);
}
