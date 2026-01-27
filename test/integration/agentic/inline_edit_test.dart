// @orchestra-task: 25
@Tags(['tdd-red'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/models/axis_config.dart';
import 'package:braven_charts/src/agentic/models/chart_configuration.dart';
import 'package:braven_charts/src/agentic/models/conversation.dart';
import 'package:braven_charts/src/agentic/models/message.dart';
import 'package:braven_charts/src/agentic/models/series_config.dart';
import 'package:braven_charts/src/agentic/providers/llm_provider.dart';
import 'package:braven_charts/src/agentic/services/agent_service.dart';
import 'package:braven_charts/src/agentic/tools/tool_registry.dart';
import 'package:braven_charts/src/agentic/widgets/inline_chat.dart';

void main() {
  testWidgets('inline chat edits only the linked chart', (tester) async {
    final chart1 = ChartConfiguration(
      id: 'chart-1',
      type: ChartType.line,
      title: 'Chart 1',
      series: [
        SeriesConfig(
          id: 'series-1',
          name: 'Series 1',
          data: [1, 2, 3],
          yAxisId: 'y1',
        ),
      ],
      yAxes: [
        YAxisConfig(id: 'y1', label: 'Y1', position: AxisPosition.left),
      ],
    );

    final chart2 = ChartConfiguration(
      id: 'chart-2',
      type: ChartType.line,
      title: 'Chart 2',
      series: [
        SeriesConfig(
          id: 'series-2',
          name: 'Series 2',
          data: [4, 5, 6],
          yAxisId: 'y2',
        ),
      ],
      yAxes: [
        YAxisConfig(id: 'y2', label: 'Y2', position: AxisPosition.left),
      ],
    );

    final chartStates = ValueNotifier<Map<String, ChartConfiguration>>({
      'chart-1': chart1,
      'chart-2': chart2,
    });

    final agentService = _TestAgentService(
      provider: _StubProvider(),
      toolRegistry: ToolRegistry(),
      chartStates: chartStates,
    );

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
      'Make this line red',
    );
    await tester.tap(find.byKey(const Key('inline_chat_send_chart-1')));
    await tester.pump();

    final updatedChart1 = chartStates.value['chart-1'];
    final updatedChart2 = chartStates.value['chart-2'];

    expect(updatedChart1?.title, equals('Chart 1 (updated)'));
    expect(updatedChart2?.title, equals('Chart 2'));
  });
}

class _TestAgentService extends AgentService {
  _TestAgentService({
    required super.provider,
    required super.toolRegistry,
    required this.chartStates,
  });

  final ValueNotifier<Map<String, ChartConfiguration>> chartStates;
  String? lastScopedChartId;

  @override
  Future<void> processUserMessage(String content) async {
    lastScopedChartId = currentChart.value?.id;
    if (lastScopedChartId == null) {
      return;
    }

    final existing = chartStates.value[lastScopedChartId!];
    if (existing == null) {
      return;
    }

    final updated = existing.copyWith(
      title: '${existing.title ?? ''} (updated)',
    );
    chartStates.value = Map<String, ChartConfiguration>.from(chartStates.value)
      ..[lastScopedChartId!] = updated;
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
