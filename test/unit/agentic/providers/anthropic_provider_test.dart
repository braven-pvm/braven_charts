// @orchestra-task: 4
@Tags(['tdd-red'])
library anthropic_provider_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts_plus/src/agentic/models/conversation.dart';
import 'package:braven_charts_plus/src/agentic/models/message.dart';
import 'package:braven_charts_plus/src/agentic/providers/anthropic_provider.dart';
import 'package:braven_charts_plus/src/agentic/providers/llm_provider.dart';

void main() {
  group('AnthropicProvider', () {
    test('implements LLMProvider and sends messages', () async {
      final provider = AnthropicProvider(apiKey: 'test-key');
      final conversation = Conversation(
        id: '22222222-2222-4222-8222-222222222222',
      );

      final response = await provider.sendMessage(conversation);

      expect(provider, isA<LLMProvider>());
      expect(response, isA<Message>());
    });
  });
}
