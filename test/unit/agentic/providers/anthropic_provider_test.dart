library anthropic_provider_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/agentic/models/conversation.dart';
import 'package:braven_charts/src/agentic/models/message.dart';
import 'package:braven_charts/src/agentic/providers/anthropic_provider.dart';
import 'package:braven_charts/src/agentic/providers/llm_provider.dart';

class _FakeAnthropicClient {
  Future<dynamic> createMessage({required dynamic request}) async {
    return 'ok';
  }

  Stream<dynamic> streamMessage({required dynamic request}) async* {
    yield 'ok';
  }
}

class _ErrorAnthropicClient {
  _ErrorAnthropicClient(this.error);

  final Object error;

  Future<dynamic> createMessage({required dynamic request}) async {
    throw error;
  }

  Stream<dynamic> streamMessage({required dynamic request}) {
    throw error;
  }
}

class _StreamErrorAnthropicClient {
  _StreamErrorAnthropicClient(this.error);

  final Object error;

  Future<dynamic> createMessage({required dynamic request}) async {
    return 'ok';
  }

  Stream<dynamic> streamMessage({required dynamic request}) {
    return Stream<dynamic>.error(error);
  }
}

void main() {
  group('AnthropicProvider', () {
    test('implements LLMProvider and sends messages', () async {
      final provider = AnthropicProvider(
        apiKey: 'test-key',
        client: _FakeAnthropicClient(),
      );
      final conversation = Conversation(
        id: '22222222-2222-4222-8222-222222222222',
      );

      final response = await provider.sendMessage(conversation);

      expect(provider, isA<LLMProvider>());
      expect(response, isA<Message>());
    });

    test('maps authentication errors to LLMProviderException', () async {
      final provider = AnthropicProvider(
        apiKey: 'bad-key',
        client: _ErrorAnthropicClient(Exception('401 unauthorized')),
      );
      final conversation = Conversation(
        id: '33333333-3333-4333-8333-333333333333',
      );

      await expectLater(
        provider.sendMessage(conversation),
        throwsA(
          isA<LLMProviderException>()
              .having(
                  (e) => e.type, 'type', LLMProviderErrorType.authentication)
              .having(
                (e) => e.message,
                'message',
                contains('Authentication failed'),
              ),
        ),
      );
    });

    test('maps rate limit errors to LLMProviderException', () async {
      final provider = AnthropicProvider(
        apiKey: 'test-key',
        client: _ErrorAnthropicClient(Exception('429 rate limit')),
      );
      final conversation = Conversation(
        id: '44444444-4444-4444-8444-444444444444',
      );

      await expectLater(
        provider.sendMessage(conversation),
        throwsA(
          isA<LLMProviderException>()
              .having((e) => e.type, 'type', LLMProviderErrorType.rateLimited)
              .having(
                (e) => e.message,
                'message',
                contains('Rate limit reached'),
              ),
        ),
      );
    });

    test('maps network errors to LLMProviderException', () async {
      final provider = AnthropicProvider(
        apiKey: 'test-key',
        client: _ErrorAnthropicClient(Exception('socket connection failed')),
      );
      final conversation = Conversation(
        id: '55555555-5555-4555-8555-555555555555',
      );

      await expectLater(
        provider.sendMessage(conversation),
        throwsA(
          isA<LLMProviderException>()
              .having((e) => e.type, 'type', LLMProviderErrorType.network)
              .having(
                (e) => e.message,
                'message',
                contains('Network error'),
              ),
        ),
      );
    });

    test('maps streaming errors to LLMProviderException', () async {
      final provider = AnthropicProvider(
        apiKey: 'test-key',
        client: _StreamErrorAnthropicClient(Exception('429 rate limit')),
      );
      final conversation = Conversation(
        id: '66666666-6666-4666-8666-666666666666',
      );

      await expectLater(
        provider.streamMessage(conversation).toList(),
        throwsA(
          isA<LLMProviderException>()
              .having((e) => e.type, 'type', LLMProviderErrorType.rateLimited)
              .having(
                (e) => e.message,
                'message',
                contains('Rate limit reached'),
              ),
        ),
      );
    });
  });
}
