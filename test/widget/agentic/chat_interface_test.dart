import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/models/conversation.dart';
import 'package:braven_charts/src/agentic/models/message.dart';
import 'package:braven_charts/src/agentic/widgets/chat_interface.dart';
import 'package:braven_charts/src/agentic/widgets/chart_widget.dart';

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
  });
}
