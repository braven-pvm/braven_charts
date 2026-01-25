// @orchestra-task: 4
@Tags(['tdd-red'])
library llm_provider_test;

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts_plus/src/agentic/models/conversation.dart';
import 'package:braven_charts_plus/src/agentic/models/message.dart';
import 'package:braven_charts_plus/src/agentic/providers/llm_provider.dart';

class _TestProvider extends LLMProvider {
  @override
  Future<Message> sendMessage(Conversation conversation) async {
    return Message(
      id: '00000000-0000-4000-8000-000000000000',
      role: MessageRole.assistant,
      textContent: 'ok',
      timestamp: DateTime.utc(2026, 1, 25),
    );
  }
}

void main() {
  group('LLMProvider', () {
    test('defines sendMessage that returns Message', () async {
      final provider = _TestProvider();
      final conversation = Conversation(
        id: '11111111-1111-4111-8111-111111111111',
      );

      final response = await provider.sendMessage(conversation);

      expect(response, isA<Message>());
      expect(response.role, MessageRole.assistant);
    });
  });
}
