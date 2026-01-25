// @orchestra-task: 8
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/models/conversation.dart';
import 'package:braven_charts/src/agentic/models/message.dart';
import 'package:braven_charts/src/agentic/providers/llm_provider.dart';
import 'package:braven_charts/src/agentic/services/agent_service.dart';
import 'package:braven_charts/src/agentic/tools/create_chart_tool.dart';
import 'package:braven_charts/src/agentic/tools/tool_registry.dart';
import 'package:braven_charts/src/agentic/widgets/chat_interface.dart';
import 'package:braven_charts/src/agentic/widgets/chart_widget.dart';

class FakeProvider extends LLMProvider {
  @override
  Future<Message> sendMessage(Conversation conversation) async {
    throw UnimplementedError('FakeProvider.sendMessage');
  }

  @override
  Stream<String> streamMessage(Conversation conversation) async* {
    throw UnimplementedError('FakeProvider.streamMessage');
  }
}

class FakeAgentService extends AgentService {
  FakeAgentService()
      : super(
          provider: FakeProvider(),
          toolRegistry: ToolRegistry()..register(CreateChartTool()),
        );
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
  }, tags: ['tdd-red']);
}
