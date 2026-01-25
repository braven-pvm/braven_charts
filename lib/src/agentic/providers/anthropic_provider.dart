import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart'
    hide Message, MessageRole;

import '../models/conversation.dart';
import '../models/message.dart';
import 'llm_provider.dart';

/// Anthropic (Claude) LLM provider implementation.
class AnthropicProvider extends LLMProvider {
  AnthropicProvider({
    required this.apiKey,
    dynamic client,
    this.model = 'claude-3-5-sonnet-20241022',
    this.maxTokens = 1024,
  }) : _client = client ?? AnthropicClient(apiKey: apiKey);

  final String apiKey;
  final String model;
  final int maxTokens;
  final dynamic _client;

  @override
  Future<Message> sendMessage(Conversation conversation) async {
    final request = _buildRequest(conversation);

    try {
      final response = await _client.createMessage(request: request);
      final text = _extractText(response);
      return Message(
        id: _generateMessageId(),
        role: MessageRole.assistant,
        textContent: text.isEmpty ? '...' : text,
        timestamp: DateTime.now().toUtc(),
      );
    } catch (error) {
      throw _mapError(error);
    }
  }

  @override
  Stream<String> streamMessage(Conversation conversation) async* {
    final request = _buildRequest(conversation);

    try {
      final stream = _client.streamMessage(request: request) as Stream<dynamic>;
      await for (final chunk in stream) {
        final text = _extractText(chunk);
        if (text.isNotEmpty) {
          yield text;
        }
      }
    } catch (error) {
      throw _mapError(error);
    }
  }

  dynamic _buildRequest(Conversation conversation) {
    final prompt = _buildPrompt(conversation);
    return {
      'model': model,
      'max_tokens': maxTokens,
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        }
      ],
    };
  }

  String _buildPrompt(Conversation conversation) {
    if (conversation.messages.isEmpty) {
      return '';
    }

    return conversation.messages
        .map((message) => message.textContent ?? '')
        .where((text) => text.trim().isNotEmpty)
        .join('\n');
  }

  String _extractText(dynamic response) {
    if (response == null) {
      return '';
    }

    if (response is String) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      final content = response['content'];
      return _extractFromContent(content);
    }

    final dynamic content = (response as dynamic).content;
    return _extractFromContent(content);
  }

  String _extractFromContent(dynamic content) {
    if (content == null) {
      return '';
    }

    if (content is String) {
      return content;
    }

    if (content is List) {
      for (final block in content) {
        final text = _extractText(block);
        if (text.isNotEmpty) {
          return text;
        }
      }
    }

    if (content is Map<String, dynamic>) {
      final text = content['text'];
      if (text is String) {
        return text;
      }
    }

    try {
      final dynamic text = (content as dynamic).text;
      if (text is String) {
        return text;
      }
    } catch (_) {}

    return '';
  }

  LLMProviderException _mapError(Object error) {
    final raw = error.toString().toLowerCase();

    if (raw.contains('401') ||
        raw.contains('unauthorized') ||
        raw.contains('invalid api key') ||
        raw.contains('authentication')) {
      return LLMProviderException(
        'Authentication failed. Please check your API key.',
        type: LLMProviderErrorType.authentication,
      );
    }

    if (raw.contains('429') || raw.contains('rate limit')) {
      return LLMProviderException(
        'Rate limit reached. Please wait and try again.',
        type: LLMProviderErrorType.rateLimited,
      );
    }

    if (raw.contains('socket') ||
        raw.contains('network') ||
        raw.contains('timeout') ||
        raw.contains('connection')) {
      return LLMProviderException(
        'Network error. Please check your connection and retry.',
        type: LLMProviderErrorType.network,
      );
    }

    return LLMProviderException(
      'Unexpected error from LLM provider. Please try again.',
      type: LLMProviderErrorType.unknown,
    );
  }

  String _generateMessageId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
