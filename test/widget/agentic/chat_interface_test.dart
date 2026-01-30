import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/models/conversation.dart';
import 'package:braven_charts/src/agentic/models/message.dart';
import 'package:braven_charts/src/agentic/providers/llm_provider.dart';
import 'package:braven_charts/src/agentic/services/agent_service.dart';
import 'package:braven_charts/src/agentic/tools/tool_registry.dart';
import 'package:braven_charts/src/agentic/widgets/chat_interface.dart';
import 'package:braven_charts/src/agentic/widgets/chart_widget.dart';
import 'package:braven_charts/src/agentic/widgets/error_message.dart';

void main() {
  group('ChatInterface', () {
    testWidgets('renders messages and chart widgets', (tester) async {
      final conversation = Conversation(
        id: '00000000-0000-4000-8000-000000000000',
        messages: [
          Message(
            id: 'msg-1',
            role: MessageRole.user,
            textContent: 'Show me a line chart of power over time',
          ),
          Message(
            id: 'msg-2',
            role: MessageRole.assistant,
            textContent: 'Here is your chart',
          ),
        ],
        charts: {
          'chart-1': <String, dynamic>{'type': 'line'},
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatInterface(conversation: conversation),
        ),
      );

      expect(
          find.text('Show me a line chart of power over time'), findsOneWidget);
      expect(find.byType(ChartWidget), findsOneWidget);
    });

    testWidgets('has text input and send button', (tester) async {
      final conversation = Conversation(
        id: '00000000-0000-4000-8000-000000000001',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatInterface(conversation: conversation),
        ),
      );

      expect(find.byKey(const Key('chat_input')), findsOneWidget);
      expect(find.byKey(const Key('chat_send_button')), findsOneWidget);
    });

    testWidgets('tapping send forwards message to handler', (tester) async {
      final conversation = Conversation(
        id: '00000000-0000-4000-8000-000000000002',
      );

      String? sentText;

      await tester.pumpWidget(
        MaterialApp(
          home: ChatInterface(
            conversation: conversation,
            onSend: (text) => sentText = text,
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('chat_input')), 'Line chart');
      await tester.tap(find.byKey(const Key('chat_send_button')));
      await tester.pump();

      expect(sentText, equals('Line chart'));
    });

    testWidgets('shows loading indicator and disables input', (tester) async {
      final conversation = Conversation(
        id: '00000000-0000-4000-8000-000000000010',
      );
      final service = AgentService(
        provider: _StubProvider(),
        toolRegistry: ToolRegistry(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatInterface(
            conversation: conversation,
            agentService: service,
          ),
        ),
      );

      service.state.value = AgentState.processing;
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      final textField = tester.widget<TextField>(
        find.byKey(const Key('chat_input')),
      );
      expect(textField.enabled, isFalse);
    });

    testWidgets('shows error with retry when processing fails', (tester) async {
      final conversation = Conversation(
        id: '00000000-0000-4000-8000-000000000011',
      );
      final provider = _FlakyProvider();
      final service = AgentService(
        provider: provider,
        toolRegistry: ToolRegistry(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChatInterface(
            conversation: conversation,
            agentService: service,
          ),
        ),
      );

      await tester.enterText(find.byKey(const Key('chat_input')), 'Line chart');
      await tester.tap(find.byKey(const Key('chat_send_button')));
      await tester.pumpAndSettle();

      expect(find.byType(ErrorMessage), findsOneWidget);
      expect(find.byKey(const Key('error_retry_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('error_retry_button')));
      await tester.pumpAndSettle();

      expect(provider.callCount, equals(2));
      expect(find.byType(ErrorMessage), findsNothing);
    });
  });
}

class _StubProvider implements LLMProvider {
  @override
  Future<Message> sendMessage(Conversation conversation) async {
    return Message(
      id: 'assistant-1',
      role: MessageRole.assistant,
      textContent: 'ok',
    );
  }

  @override
  Stream<String> streamMessage(Conversation conversation) async* {}
}

class _FlakyProvider implements LLMProvider {
  int callCount = 0;

  @override
  Future<Message> sendMessage(Conversation conversation) async {
    callCount += 1;
    if (callCount == 1) {
      throw Exception('network');
    }
    return Message(
      id: 'assistant-2',
      role: MessageRole.assistant,
      textContent: 'done',
    );
  }

  @override
  Stream<String> streamMessage(Conversation conversation) async* {}
}
