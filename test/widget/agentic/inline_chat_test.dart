import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/models/chart_configuration.dart';
import 'package:braven_charts/src/agentic/models/series_config.dart';
import 'package:braven_charts/src/agentic/models/axis_config.dart';
import 'package:braven_charts/src/agentic/models/conversation.dart';
import 'package:braven_charts/src/agentic/models/message.dart';
import 'package:braven_charts/src/agentic/providers/llm_provider.dart';
import 'package:braven_charts/src/agentic/services/agent_service.dart';
import 'package:braven_charts/src/agentic/tools/tool_registry.dart';
import 'package:braven_charts/src/agentic/widgets/inline_chat.dart';

void main() {
  group('InlineChat (scoped)', () {
    late AgentService agentService;
    late ChartConfiguration chart1;
    late ChartConfiguration chart2;

    setUp(() {
      agentService = AgentService(
        provider: _StubProvider(),
        toolRegistry: ToolRegistry(),
      );

      chart1 = ChartConfiguration(
        id: 'chart-1',
        type: ChartType.line,
        title: 'Chart 1',
        series: [
          SeriesConfig(
            id: 'series-1',
            name: 'Series 1',
            data: [1, 2, 3],
            yAxisConfig: YAxisConfig(
              id: 'y1',
              label: 'Y1',
              position: AxisPosition.left,
            ),
          ),
        ],
      );

      chart2 = ChartConfiguration(
        id: 'chart-2',
        type: ChartType.line,
        title: 'Chart 2',
        series: [
          SeriesConfig(
            id: 'series-2',
            name: 'Series 2',
            data: [4, 5, 6],
            yAxisConfig: YAxisConfig(
              id: 'y2',
              label: 'Y2',
              position: AxisPosition.left,
            ),
          ),
        ],
      );
    });

    testWidgets('renders inline chat scoped to chartId', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              InlineChat(
                chartId: 'chart-1',
                chartConfiguration: chart1,
                agentService: agentService,
              ),
              InlineChat(
                chartId: 'chart-2',
                chartConfiguration: chart2,
                agentService: agentService,
              ),
            ],
          ),
        ),
      );

      expect(find.byKey(const Key('inline_chat_chart-1')), findsOneWidget);
      expect(find.byKey(const Key('inline_chat_chart-2')), findsOneWidget);
    });

    testWidgets('sending message stays scoped to chartId', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Column(
            children: [
              InlineChat(
                chartId: 'chart-1',
                chartConfiguration: chart1,
                agentService: agentService,
              ),
              InlineChat(
                chartId: 'chart-2',
                chartConfiguration: chart2,
                agentService: agentService,
              ),
            ],
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('inline_chat_input_chart-1')),
        'Make it red',
      );
      await tester.tap(find.byKey(const Key('inline_chat_send_chart-1')));
      await tester.pump();

      expect(
        find.descendant(
          of: find.byKey(const Key('inline_chat_history_chart-1')),
          matching: find.text('Make it red'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(const Key('inline_chat_history_chart-2')),
          matching: find.text('Make it red'),
        ),
        findsNothing,
      );
    });

    testWidgets('preserves chat history across collapse/expand',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: _InlineChatToggleHarness(
            agentService: agentService,
            chart: chart1,
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const Key('inline_chat_input_chart-1')),
        'Keep this message',
      );
      await tester.tap(find.byKey(const Key('inline_chat_send_chart-1')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('inline_chat_toggle')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('inline_chat_toggle')));
      await tester.pump();

      expect(find.text('Keep this message'), findsOneWidget);
    });
  });
}

class _InlineChatToggleHarness extends StatefulWidget {
  const _InlineChatToggleHarness({
    required this.agentService,
    required this.chart,
  });

  final AgentService agentService;
  final ChartConfiguration chart;

  @override
  State<_InlineChatToggleHarness> createState() =>
      _InlineChatToggleHarnessState();
}

class _InlineChatToggleHarnessState extends State<_InlineChatToggleHarness> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          key: const Key('inline_chat_toggle'),
          onPressed: () => setState(() => _expanded = !_expanded),
          child: Text(_expanded ? 'Collapse' : 'Expand'),
        ),
        if (_expanded)
          InlineChat(
            chartId: widget.chart.id ?? 'chart-1',
            chartConfiguration: widget.chart,
            agentService: widget.agentService,
          ),
      ],
    );
  }
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
