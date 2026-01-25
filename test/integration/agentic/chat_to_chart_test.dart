// @orchestra-task: 8
@Tags(['tdd-red'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/models/conversation.dart';

class AgentService {
  const AgentService();
}

class CreateChartTool {
  const CreateChartTool();
}

class ChatInterface extends StatelessWidget {
  const ChatInterface({
    super.key,
    required this.conversation,
    this.agentService,
  });

  final Conversation conversation;
  final AgentService? agentService;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class ChartWidget extends StatelessWidget {
  const ChartWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

class FakeAgentService extends AgentService {
  const FakeAgentService();
}

@Tags(['tdd-red'])
void main() {
  testWidgets('chat input produces a chart widget', (tester) async {
    final conversation = Conversation(
      id: '00000000-0000-4000-8000-000000000003',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ChatInterface(
          conversation: conversation,
          agentService: FakeAgentService(),
        ),
      ),
    );

    await tester.enterText(
      find.byKey(const Key('chat_input')),
      'Show me a line chart of power over time',
    );
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pumpAndSettle();

    expect(find.byType(ChartWidget), findsOneWidget);
  });
}
