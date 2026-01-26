// @orchestra-task: 16
@Tags(['tdd-red'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/tools/modify_chart_tool.dart';
import 'package:braven_charts/src/agentic/tools/llm_tool.dart';
import 'package:braven_charts/src/agentic/models/chart_configuration.dart';

void main() {
  group('ModifyChartTool', () {
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
      final ModifyChartTool tool = ModifyChartTool();

      final result = await tool.execute({
        'chartId': 'test-chart-123',
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
      final ModifyChartTool tool = ModifyChartTool();

      final result = await tool.execute({
        'chartId': 'test-chart-123',
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
      expect(config.xAxis.label, equals('Time (seconds)'));
      expect(config.xAxis.min, equals(0));
      expect(config.xAxis.max, equals(3600));
      expect(config.yAxes.first.label, equals('Power (W)'));
    });

    test('modifies legend and grid visibility', () async {
      final ModifyChartTool tool = ModifyChartTool();

      final result = await tool.execute({
        'chartId': 'test-chart-123',
        'properties': {
          'legend': {'visible': false},
          'grid': {'visible': false},
        },
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect(config.legend.visible, isFalse);
      expect(config.grid.visible, isFalse);
    });

    test('applies theme changes to existing chart', () async {
      final ModifyChartTool tool = ModifyChartTool();

      final result = await tool.execute({
        'chartId': 'test-chart-123',
        'properties': {
          'theme': 'dark',
        },
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect(config.theme, equals('dark'));
    });

    test('validates required chartId parameter', () async {
      final ModifyChartTool tool = ModifyChartTool();

      expect(
        () => tool.execute({
          'properties': {'color': '#FF0000'},
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('validates property names', () async {
      final ModifyChartTool tool = ModifyChartTool();

      expect(
        () => tool.execute({
          'chartId': 'test-chart-123',
          'properties': {
            'invalidProperty': 'value',
          },
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('returns updated chart with same chartId', () async {
      final ModifyChartTool tool = ModifyChartTool();

      final result = await tool.execute({
        'chartId': 'test-chart-123',
        'properties': {
          'color': '#00FF00',
        },
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect(config.id, equals('test-chart-123'));
    });
  });
}
