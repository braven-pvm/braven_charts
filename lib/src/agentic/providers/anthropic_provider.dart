import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;

import '../models/conversation.dart';
import '../models/message.dart';
import 'llm_provider.dart';

/// Anthropic (Claude) LLM provider implementation.
class AnthropicProvider extends LLMProvider {
  AnthropicProvider({
    required this.apiKey,
    dynamic client,
    this.model = 'claude-sonnet-4-20250514',
    this.maxTokens = 1024,
  }) : _client = client ?? anthropic.AnthropicClient(apiKey: apiKey);

  final String apiKey;
  final String model;
  final int maxTokens;
  final dynamic _client;

  @override
  Future<Message> sendMessage(Conversation conversation) async {
    final messages = _buildMessages(conversation);

    try {
      final request = anthropic.CreateMessageRequest(
        model: anthropic.Model.modelId(model),
        maxTokens: maxTokens,
        messages: messages,
      );
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
    // Streaming not yet supported by anthropic_sdk_dart
    // Return empty stream to trigger fallback to non-streaming in agent_service
    return;
  }

  List<anthropic.Message> _buildMessages(Conversation conversation) {
    if (conversation.messages.isEmpty) {
      return [];
    }

    final result = <anthropic.Message>[];

    for (final message in conversation.messages) {
      if (message.textContent == null || message.textContent!.trim().isEmpty) {
        continue;
      }

      final role = message.role == MessageRole.user
          ? anthropic.MessageRole.user
          : anthropic.MessageRole.assistant;

      result.add(
        anthropic.Message(
          role: role,
          content: anthropic.MessageContent.text(message.textContent!),
        ),
      );
    }

    return result;
  }

  String _extractText(dynamic response) {
    if (response == null) {
      return '';
    }

    // Handle anthropic SDK response with content.blocks
    try {
      final dynamic content = (response as dynamic).content;
      if (content != null) {
        // Check if content is MessageContentBlocks
        if (content is anthropic.MessageContent) {
          return content.map(
            text: (textContent) => textContent.text,
            blocks: (blocksContent) {
              for (final block in blocksContent.value) {
                if (block is anthropic.TextBlock) {
                  return block.text;
                }
                // Try to get text from block dynamically
                try {
                  final text = (block as dynamic).text;
                  if (text is String && text.isNotEmpty) {
                    return text;
                  }
                } catch (_) {}
              }
              return '';
            },
          );
        }

        // Fallback: try to access blocks directly
        try {
          final blocks = (content as dynamic).value;
          if (blocks is List) {
            for (final block in blocks) {
              if (block is anthropic.TextBlock) {
                return block.text;
              }
            }
          }
        } catch (_) {}
      }
    } catch (_) {}

    // Fallback for other response formats
    if (response is String) {
      return response;
    }

    if (response is Map<String, dynamic>) {
      final content = response['content'];
      return _extractFromContent(content);
    }

    return '';
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
