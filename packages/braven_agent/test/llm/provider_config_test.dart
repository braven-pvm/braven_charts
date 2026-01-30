import 'dart:async';

import 'package:anthropic_sdk_dart/anthropic_sdk_dart.dart' as anthropic;
import 'package:braven_agent/src/llm/llm_config.dart';
import 'package:braven_agent/src/llm/providers/anthropic_adapter.dart';
import 'package:braven_agent/src/session/agent_events.dart';
import 'package:braven_agent/src/session/agent_session_impl.dart';
import 'package:braven_agent/src/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAnthropicClient implements anthropic.AnthropicClient {
  anthropic.CreateMessageRequest? capturedRequest;
  Exception? messageException;

  @override
  Future<anthropic.Message> createMessage({
    required anthropic.CreateMessageRequest request,
  }) async {
    capturedRequest = request;

    if (messageException != null) {
      throw messageException!;
    }

    return const anthropic.Message(
      id: 'msg_test_001',
      role: anthropic.MessageRole.assistant,
      content: anthropic.MessageContent.text('Mock response'),
      model: 'claude-sonnet-4-20250514',
      stopReason: anthropic.StopReason.endTurn,
      usage: anthropic.Usage(inputTokens: 1, outputTokens: 1),
    );
  }

  @override
  Stream<anthropic.MessageStreamEvent> createMessageStream({
    required anthropic.CreateMessageRequest request,
  }) {
    capturedRequest = request;
    return const Stream<anthropic.MessageStreamEvent>.empty();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  group('Provider configuration validation', () {
    test('LLMConfig accepts valid temperature values', () {
      for (final value in [0.0, 0.7, 1.0, 2.0]) {
        expect(
          () => LLMConfig(apiKey: 'test-key', temperature: value),
          returnsNormally,
        );
      }
    });

    test('LLMConfig rejects invalid temperature values', () {
      expect(
        // ignore: prefer_const_constructors
        () => LLMConfig(apiKey: 'test-key', temperature: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        // ignore: prefer_const_constructors
        () => LLMConfig(apiKey: 'test-key', temperature: 2.1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('LLMConfig rejects empty model string', () {
      expect(
        // ignore: prefer_const_constructors
        () => LLMConfig(apiKey: 'test-key', model: ''),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('Provider options passthrough', () {
    test('AnthropicAdapter forwards providerOptions to request', () async {
      final mockClient = MockAnthropicClient();
      const config = LLMConfig(
        apiKey: 'test-key',
        providerOptions: {
          'top_p': 0.9,
          'top_k': 42,
          'metadata': {'user_id': 'user-123'},
        },
      );

      final adapter = AnthropicAdapter(config, client: mockClient);

      await adapter.generateResponse(
        systemPrompt: 'Test system prompt',
        history: const [],
      );

      final request = mockClient.capturedRequest!;
      expect(request.topP, equals(0.9));
      expect(request.topK, equals(42));
      expect(request.metadata?.userId, equals('user-123'));
      expect(request.temperature, equals(config.temperature));
    });
  });

  group('Authentication error surfacing', () {
    test('Invalid API key errors surface through ErrorEvent and state',
        () async {
      final mockClient = MockAnthropicClient()
        ..messageException = Exception('401 Unauthorized');
      const config = LLMConfig(apiKey: 'bad-key');
      final adapter = AnthropicAdapter(config, client: mockClient);
      final session = AgentSessionImpl(
        llmProvider: adapter,
        tools: const [],
        systemPrompt: 'Test system prompt',
      );

      final events = <AgentEvent>[];
      final subscription = session.events.listen(events.add);

      await session.transform('Hello');
      await Future<void>.delayed(Duration.zero);

      final errorEvent = events.whereType<ErrorEvent>().single;
      expect(errorEvent.message, contains('Invalid API key'));
      expect(session.state.value.status, equals(ActivityStatus.error));

      await subscription.cancel();
      session.dispose();
    });
  });
}
