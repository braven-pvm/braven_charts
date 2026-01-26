import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/tools/modify_chart_tool.dart';
import 'package:braven_charts/src/agentic/tools/llm_tool.dart';
import 'package:braven_charts/src/agentic/models/chart_configuration.dart';
import 'package:braven_charts/src/agentic/models/series_config.dart';
import 'package:braven_charts/src/agentic/services/data_store.dart';

void main() {
  group('ModifyChartTool', () {
    late DataStore<ChartConfiguration> dataStore;
    late String testChartId;

    setUp(() {
      dataStore = DataStore<ChartConfiguration>();
      // Create a test chart with an ID and store it
      testChartId = 'test-chart-id';
      final testChart = ChartConfiguration(
        id: testChartId,
        type: ChartType.line,
        series: [
          SeriesConfig(
            id: 'series-1',
            name: 'Test Series',
            data: [
              {'x': 0, 'y': 100},
              {'x': 1, 'y': 200},
            ],
          ),
        ],
      );
      dataStore.store(testChart, id: testChartId);
    });

    test('exposes name, description, and input schema', () {
      final LLMTool tool = ModifyChartTool();

      expect(tool.name, isNotEmpty);
      expect(tool.description, isNotEmpty);
      expect(tool.inputSchema, isNotEmpty);
      expect(tool.inputSchema['type'], equals('object'));
      expect(tool.inputSchema['properties'], isA<Map>());
      expect(tool.inputSchema['required'], contains('chartId'));
    });

    test('modifies visual properties of existing chart', () async {
      final ModifyChartTool tool = ModifyChartTool(dataStore: dataStore);

      final result = await tool.execute({
        'chartId': testChartId,
        'properties': {
          'color': '#FF0000',
          'lineWidth': 3.0,
          'dashPattern': [5, 3],
        },
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect(config.series.first.color, equals('#FF0000'));
      expect(config.series.first.lineWidth, equals(3.0));
      expect(config.series.first.dashPattern, equals([5, 3]));
    });

    test('updates axis properties without recreating chart', () async {
      final ModifyChartTool tool = ModifyChartTool(dataStore: dataStore);

      final result = await tool.execute({
        'chartId': testChartId,
        'properties': {
          'xAxis': {
            'label': 'Time (seconds)',
            'min': 0,
            'max': 3600,
          },
          'yAxis': {
            'label': 'Power (W)',
            'min': 0,
            'max': 500,
          },
        },
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect(config.xAxis?.label, equals('Time (seconds)'));
      expect(config.xAxis?.min, equals(0));
      expect(config.xAxis?.max, equals(3600));
      expect(config.yAxes.first.label, equals('Power (W)'));
    });

    test('modifies legend and grid visibility', () async {
      final ModifyChartTool tool = ModifyChartTool(dataStore: dataStore);

      final result = await tool.execute({
        'chartId': testChartId,
        'properties': {
          'legend': {'visible': false},
          'grid': {'visible': false},
        },
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect((config.legend as Map)['visible'], isFalse);
      expect((config.grid as Map)['visible'], isFalse);
    });

    test('applies theme changes to existing chart', () async {
      final ModifyChartTool tool = ModifyChartTool(dataStore: dataStore);

      final result = await tool.execute({
        'chartId': testChartId,
        'properties': {
          'theme': 'dark',
        },
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect(config.theme, equals('dark'));
    });

    test('validates required chartId parameter', () async {
      final ModifyChartTool tool = ModifyChartTool(dataStore: dataStore);

      expect(
        () => tool.execute({
          'properties': {'color': '#FF0000'},
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validates property names', () async {
      final ModifyChartTool tool = ModifyChartTool(dataStore: dataStore);

      expect(
        () => tool.execute({
          'chartId': testChartId,
          'properties': {
            'invalidProperty': 'value',
          },
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('returns updated chart with same chartId', () async {
      final ModifyChartTool tool = ModifyChartTool(dataStore: dataStore);

      final result = await tool.execute({
        'chartId': testChartId,
        'properties': {
          'color': '#00FF00',
        },
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect(config.id, equals(testChartId));
    });
  });
}
