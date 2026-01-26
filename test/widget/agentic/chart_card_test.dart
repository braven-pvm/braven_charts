import 'package:braven_charts/src/agentic/models/axis_config.dart';
import 'package:braven_charts/src/agentic/models/chart_configuration.dart';
import 'package:braven_charts/src/agentic/models/conversation.dart';
import 'package:braven_charts/src/agentic/models/message.dart';
import 'package:braven_charts/src/agentic/models/series_config.dart';
import 'package:braven_charts/src/agentic/providers/llm_provider.dart';
import 'package:braven_charts/src/agentic/services/agent_service.dart';
import 'package:braven_charts/src/agentic/tools/tool_registry.dart';
import 'package:braven_charts/src/agentic/widgets/chart_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartCard', () {
    late AgentService agentService;
    late ChartConfiguration testChart;

    setUp(() {
      // Create a mock LLM provider and tool registry
      final mockProvider = _MockLLMProvider();
      final mockRegistry = ToolRegistry();
      agentService = AgentService(
        provider: mockProvider,
        toolRegistry: mockRegistry,
      );

      // Create a test chart configuration
      testChart = ChartConfiguration(
        id: 'test-chart-1',
        type: ChartType.line,
        title: 'Test Chart',
        series: [
          SeriesConfig(
            id: 'series-1',
            name: 'Test Series',
            data: [1, 2, 3],
            yAxisId: 'y1',
          ),
        ],
        xAxis: XAxisConfig(label: 'X Axis'),
        yAxes: [
          YAxisConfig(id: 'y1', label: 'Y Axis', position: AxisPosition.left),
        ],
      );
    });

    testWidgets('displays Edit button in action bar',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartCard(
              chartId: 'test-chart-1',
              chartConfiguration: testChart,
              agentService: agentService,
              child: const Text('Chart Content'),
            ),
          ),
        ),
      );

      // Verify Edit button is visible
      expect(find.byIcon(Icons.edit), findsOneWidget);
      expect(find.byTooltip('Edit Chart'), findsOneWidget);
    });

    testWidgets('Edit button click updates AgentService.currentChart',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartCard(
              chartId: 'test-chart-1',
              chartConfiguration: testChart,
              agentService: agentService,
              child: const Text('Chart Content'),
            ),
          ),
        ),
      );

      // Verify currentChart is initially null
      expect(agentService.currentChart.value, isNull);

      // Tap Edit button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      // Verify currentChart is updated to this chart's configuration
      expect(agentService.currentChart.value, equals(testChart));
      expect(agentService.currentChart.value?.id, equals('test-chart-1'));
    });

    testWidgets('Edit button triggers custom onEdit callback if provided',
        (WidgetTester tester) async {
      bool editCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartCard(
              chartId: 'test-chart-1',
              chartConfiguration: testChart,
              agentService: agentService,
              onEdit: () {
                editCalled = true;
              },
              child: const Text('Chart Content'),
            ),
          ),
        ),
      );

      // Tap Edit button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      // Verify custom callback was called
      expect(editCalled, isTrue);
    });

    testWidgets('ChartCard accepts required chartId parameter',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartCard(
              chartId: 'unique-chart-id',
              chartConfiguration: testChart,
              agentService: agentService,
              child: const Text('Chart Content'),
            ),
          ),
        ),
      );

      // Verify widget builds successfully with chartId parameter
      expect(find.byType(ChartCard), findsOneWidget);
    });

    testWidgets('Multiple ChartCards maintain independent edit contexts',
        (WidgetTester tester) async {
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
        type: ChartType.bar,
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ChartCard(
                  chartId: 'chart-1',
                  chartConfiguration: chart1,
                  agentService: agentService,
                  child: const Text('Chart 1 Content'),
                ),
                ChartCard(
                  chartId: 'chart-2',
                  chartConfiguration: chart2,
                  agentService: agentService,
                  child: const Text('Chart 2 Content'),
                ),
              ],
            ),
          ),
        ),
      );

      // Find both Edit buttons
      final editButtons = find.byIcon(Icons.edit);
      expect(editButtons, findsNWidgets(2));

      // Tap Edit button on first chart
      await tester.tap(editButtons.first);
      await tester.pump();

      // Verify currentChart is set to chart1
      expect(agentService.currentChart.value?.id, equals('chart-1'));
      expect(agentService.currentChart.value?.title, equals('Chart 1'));

      // Tap Edit button on second chart
      await tester.tap(editButtons.last);
      await tester.pump();

      // Verify currentChart is now set to chart2
      expect(agentService.currentChart.value?.id, equals('chart-2'));
      expect(agentService.currentChart.value?.title, equals('Chart 2'));
    });

    testWidgets('Edit button is styled consistently with other action buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChartCard(
              chartId: 'test-chart-1',
              chartConfiguration: testChart,
              agentService: agentService,
              onRefresh: () {},
              onShare: () {},
              child: const Text('Chart Content'),
            ),
          ),
        ),
      );

      // Find all IconButtons in the action bar
      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsNWidgets(3)); // Edit, Refresh, Share

      // Verify all buttons are in the same row (action bar)
      final row = find.ancestor(
        of: find.byIcon(Icons.edit),
        matching: find.byType(Row),
      );
      expect(row, findsOneWidget);

      // Verify Refresh and Share buttons are in the same row
      expect(
        find.descendant(of: row, matching: find.byIcon(Icons.refresh)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: row, matching: find.byIcon(Icons.share)),
        findsOneWidget,
      );
    });

    testWidgets('UI updates immediately when chart configuration changes',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<ChartConfiguration?>(
              valueListenable: agentService.currentChart,
              builder: (context, currentChart, _) {
                return ChartCard(
                  chartId: 'test-chart-1',
                  chartConfiguration: currentChart ?? testChart,
                  agentService: agentService,
                  child: Text(
                    currentChart?.title ?? testChart.title ?? 'No Title',
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initial state
      expect(find.text('Test Chart'), findsOneWidget);

      // Tap Edit button to set currentChart
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pump();

      // Verify currentChart is set
      expect(agentService.currentChart.value, isNotNull);

      // Modify the chart configuration via AgentService
      final modifiedChart = testChart.copyWith(title: 'Modified Chart');
      agentService.currentChart.value = modifiedChart;
      await tester.pump();

      // Verify UI reflects the change immediately
      expect(find.text('Modified Chart'), findsOneWidget);
      expect(find.text('Test Chart'), findsNothing);
    });
  });
}

// Mock LLM Provider for testing
class _MockLLMProvider extends LLMProvider {
  @override
  Future<Message> sendMessage(Conversation conversation) async {
    // Return empty message for testing
    return Message(
      id: 'mock-message',
      role: MessageRole.assistant,
      textContent: 'Mock response',
    );
  }

  @override
  Stream<String> streamMessage(Conversation conversation) async* {
    // Empty stream for testing
  }
}
