// @orchestra-task: 8
@Tags(['tdd-red'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/tools/llm_tool.dart';
import 'package:braven_charts/src/agentic/models/chart_configuration.dart';

class CreateChartTool extends LLMTool {
  @override
  String get name => '';

  @override
  String get description => '';

  @override
  Map<String, dynamic> get inputSchema => {};

  @override
  Future<dynamic> execute(Map<String, dynamic> args) async => null;
}

@Tags(['tdd-red'])
void main() {
  group('CreateChartTool', () {
    test('exposes name, description, and input schema', () {
      final LLMTool tool = CreateChartTool();

      expect(tool.name, isNotEmpty);
      expect(tool.description, isNotEmpty);
      expect(tool.inputSchema, isNotEmpty);
      expect(tool.inputSchema['type'], equals('object'));
      expect(tool.inputSchema['properties'], isA<Map>());
    });

    test('converts natural language into a ChartConfiguration', () async {
      final CreateChartTool tool = CreateChartTool();

      final result = await tool.execute({
        'prompt': 'Show me a line chart of power over time',
        'dataset': {
          'columns': ['time', 'power'],
          'rows': [
            {'time': 0, 'power': 120},
            {'time': 1, 'power': 140},
          ],
        },
      });

      expect(result, isA<ChartConfiguration>());
      final config = result as ChartConfiguration;
      expect(config.type, ChartType.line);
      expect(config.series, isNotEmpty);
      expect(config.xAxis, isNotNull);
      expect(config.yAxes, isNotEmpty);
    });

    test('returns an error for unsupported chart types', () async {
      final CreateChartTool tool = CreateChartTool();

      expect(
        () => tool.execute({
          'prompt': 'Create a waterfall chart of power over time',
          'dataset': {
            'columns': ['time', 'power'],
            'rows': [
              {'time': 0, 'power': 120},
            ],
          },
        }),
        throwsA(isA<Exception>()),
      );
    });
  });
}
