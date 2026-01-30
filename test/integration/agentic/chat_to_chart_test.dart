import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/models/chart_configuration.dart';
import 'package:braven_charts/src/agentic/models/conversation.dart';
import 'package:braven_charts/src/agentic/models/message.dart';
import 'package:braven_charts/src/agentic/models/tool_call.dart';
import 'package:braven_charts/src/agentic/models/tool_result.dart';
import 'package:braven_charts/src/agentic/providers/llm_provider.dart';
import 'package:braven_charts/src/agentic/services/agent_service.dart';
import 'package:braven_charts/src/agentic/tools/create_chart_tool.dart';
import 'package:braven_charts/src/agentic/tools/tool_registry.dart';
import 'package:braven_charts/src/agentic/widgets/chat_interface.dart';
import 'package:braven_charts/src/agentic/widgets/chart_widget.dart';

class FakeProvider extends LLMProvider {
  int _callCount = 0;

  @override
  Future<Message> sendMessage(Conversation conversation) async {
    _callCount++;

    if (_callCount == 1) {
      // First call: Return a message with a tool call to create a chart
      return Message(
        id: 'msg_1',
        role: MessageRole.assistant,
        textContent: 'Creating a line chart for you',
        toolCalls: [
          ToolCall(
            id: 'call_1',
            toolName: 'create_chart',
            arguments: {
              'prompt': 'line chart of power over time',
              'type': 'line',
              'title': 'Test Chart',
              'series': [
                {
                  'id': 'series_1',
                  'name': 'Test Series',
                  'data': [1.0, 2.0, 3.0, 4.0, 5.0],
                }
              ],
            },
          ),
        ],
      );
    } else {
      // Second call (after tool execution): Return final message
      return Message(
        id: 'msg_2',
        role: MessageRole.assistant,
        textContent: 'Here is your line chart!',
      );
    }
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

void main() {
  testWidgets('chat input produces a chart widget', (tester) async {
    final conversation = Conversation(
      id: '00000000-0000-4000-8000-000000000003',
    );
    final agentService = FakeAgentService();

    await tester.pumpWidget(
      MaterialApp(
        home: ChatInterface(
          conversation: conversation,
          agentService: agentService,
        ),
      ),
    );

    // Manually trigger the agent service to process a message
    // This simulates what happens when the user sends a message
    await agentService.processUserMessage('Show me a line chart');

    // Wait for the UI to update
    await tester.pumpAndSettle();

    // The chart should now be visible in the conversation
    expect(find.byType(ChartWidget), findsOneWidget);
  });
}
