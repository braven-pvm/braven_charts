import 'package:braven_agent/src/models/chart_configuration.dart';
import 'package:braven_agent/src/models/enums.dart';
import 'package:braven_agent/src/tools/create_chart_tool.dart';
import 'package:braven_agent/src/tools/modify_chart_tool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Chart Modification Integration', () {
    // Helper to extract ChartConfiguration from ToolResult
    ChartConfiguration getChartFromOutput(dynamic data) {
      if (data is ChartConfiguration) {
        return data;
      }
      throw Exception('ToolResult data is not ChartConfiguration: $data');
    }

    test('Scenario 1: Create -> Modify Title -> Verify', () async {
      // 1. Create initial chart
      final createTool = CreateChartTool();
      final createInput = {
        'prompt': 'Create a line chart for sales',
        'type': 'line',
        'title': 'Initial Sales',
        'series': [
          {
            'id': 'sales',
            'data': [
              {'x': 1, 'y': 100}
            ]
          }
        ]
      };

      final createResult = await createTool.execute(createInput);
      expect(createResult.isError, isFalse, reason: 'Create chart failed');

      var activeChart = getChartFromOutput(createResult.data);
      expect(activeChart.title, equals('Initial Sales'));

      // 2. Modify title
      final modifyTool = ModifyChartTool(
        getActiveChart: () => activeChart,
      );

      final modifyInput = {
        'modifications': {'title': 'Updated Sales Figures'}
      };

      final modifyResult = await modifyTool.execute(modifyInput);
      expect(modifyResult.isError, isFalse, reason: 'Modify chart failed');

      activeChart = getChartFromOutput(modifyResult.data);
      expect(activeChart.title, equals('Updated Sales Figures'));
    });

    test('Scenario 2: Create -> Add Series -> Verify', () async {
      final createTool = CreateChartTool();
      var activeChart = getChartFromOutput((await createTool.execute({
        'prompt': 'Chart with 1 series',
        'series': [
          {
            'id': 's1',
            'data': [
              {'x': 0, 'y': 0}
            ]
          }
        ]
      }))
          .data);

      expect(activeChart.series.length, equals(1));

      final modifyTool = ModifyChartTool(getActiveChart: () => activeChart);
      final modifyResult = await modifyTool.execute({
        'modifications': {
          'add': {
            'series': [
              {
                'id': 's2',
                'data': [
                  {'x': 1, 'y': 1}
                ]
              }
            ]
          }
        }
      });
      expect(modifyResult.isError, isFalse, reason: 'Add series failed');

      activeChart = getChartFromOutput(modifyResult.data);
      expect(activeChart.series.length, equals(2));
      expect(activeChart.series.map((s) => s.id), containsAll(['s1', 's2']));
    });

    test('Scenario 3: Create -> Remove Series -> Verify', () async {
      final createTool = CreateChartTool();
      var activeChart = getChartFromOutput((await createTool.execute({
        'prompt': 'Chart with 2 series',
        'series': [
          {
            'id': 's1',
            'data': [
              {'x': 0, 'y': 0}
            ]
          },
          {
            'id': 's2',
            'data': [
              {'x': 0, 'y': 0}
            ]
          }
        ]
      }))
          .data);

      expect(activeChart.series.length, equals(2));

      final modifyTool = ModifyChartTool(getActiveChart: () => activeChart);
      final modifyResult = await modifyTool.execute({
        'modifications': {
          'remove': {
            'series': ['s1']
          }
        }
      });
      expect(modifyResult.isError, isFalse, reason: 'Remove series failed');

      activeChart = getChartFromOutput(modifyResult.data);
      expect(activeChart.series.length, equals(1));
      expect(activeChart.series.first.id, equals('s2'));
    });

    test('Scenario 4: Create -> Modify Data Points -> Verify', () async {
      final createTool = CreateChartTool();
      var activeChart = getChartFromOutput((await createTool.execute({
        'prompt': 'Chart data',
        'series': [
          {
            'id': 's1',
            'data': [
              {'x': 1, 'y': 10}
            ]
          }
        ]
      }))
          .data);

      expect(activeChart.series.first.data.first.y, equals(10.0));

      final modifyTool = ModifyChartTool(getActiveChart: () => activeChart);
      final modifyResult = await modifyTool.execute({
        'modifications': {
          'update': {
            'series': [
              {
                'id': 's1',
                'data': [
                  {'x': 1, 'y': 20},
                  {'x': 2, 'y': 30}
                ]
              }
            ]
          }
        }
      });
      expect(modifyResult.isError, isFalse,
          reason: 'Update series data failed');

      activeChart = getChartFromOutput(modifyResult.data);
      final series = activeChart.series.firstWhere((s) => s.id == 's1');
      expect(series.data.length, equals(2));
      expect(series.data[0].y, equals(20.0));
      expect(series.data[1].y, equals(30.0));
    });

    test('Scenario 5: Create -> Modify Axes -> Verify', () async {
      // This scenario tests functionality that might not be fully implemented yet,
      // which fits the "Red" phase requirement if it fails.

      final createTool = CreateChartTool();
      var activeChart = getChartFromOutput((await createTool.execute({
        'prompt': 'Chart axes',
        'series': [
          {
            'id': 's1',
            'data': [
              {'x': 0, 'y': 0}
            ]
          }
        ]
      }))
          .data);

      // Initial state might have default or null axes depending on CreateChartTool logic.
      // We don't check initial state strictly, just the modification.

      final modifyTool = ModifyChartTool(getActiveChart: () => activeChart);
      final modifyResult = await modifyTool.execute({
        'modifications': {
          'xAxis': {'label': 'New X Label', 'unit': 'seconds'},
          'yAxes': [
            {'id': 'y1', 'label': 'Sales', 'unit': 'USD'}
          ]
        }
      });
      expect(modifyResult.isError, isFalse,
          reason: 'Modify axes failed (execution error)');

      activeChart = getChartFromOutput(modifyResult.data);

      // These assertions should fail if ModifyChartTool ignores axes
      expect(activeChart.xAxis, isNotNull,
          reason: 'XAxis should not be null after update');
      expect(activeChart.xAxis?.label, equals('New X Label'));
      expect(activeChart.xAxis?.unit, equals('seconds'));

      expect(activeChart.yAxes, isNotEmpty,
          reason: 'YAxes should not be empty after update');
      expect(activeChart.yAxes.first.label, equals('Sales'));
      expect(activeChart.yAxes.first.unit, equals('USD'));
    });

    test('Scenario 6: Create -> Modify Series Type -> Verify', () async {
      final createTool = CreateChartTool();
      var activeChart = getChartFromOutput((await createTool.execute({
        'prompt': 'Line chart',
        'series': [
          {
            'id': 's1',
            'type': 'line',
            'data': [
              {'x': 0, 'y': 0}
            ]
          }
        ]
      }))
          .data);

      expect(activeChart.series.first.type, equals(ChartType.line));

      final modifyTool = ModifyChartTool(getActiveChart: () => activeChart);
      final modifyResult = await modifyTool.execute({
        'modifications': {
          'update': {
            'series': [
              {'id': 's1', 'type': 'bar'}
            ]
          }
        }
      });
      expect(modifyResult.isError, isFalse, reason: 'Modify type failed');

      activeChart = getChartFromOutput(modifyResult.data);
      expect(activeChart.series.first.type, equals(ChartType.bar));
    });

    test('Scenario 7: Create -> Modify Color -> Verify ID Preserved', () async {
      final createTool = CreateChartTool();
      var activeChart = getChartFromOutput((await createTool.execute({
        'prompt': 'Chart for color change',
        'series': [
          {
            'id': 's1',
            'color': '#000000',
            'data': [
              {'x': 0, 'y': 0}
            ]
          }
        ]
      }))
          .data);

      final originalId = activeChart.id;
      expect(originalId, isNotNull);
      expect(activeChart.series.first.color, equals('#000000'));

      final modifyTool = ModifyChartTool(getActiveChart: () => activeChart);
      final modifyResult = await modifyTool.execute({
        'modifications': {
          'update': {
            'series': [
              {'id': 's1', 'color': '#FF0000'}
            ]
          }
        }
      });
      expect(modifyResult.isError, isFalse, reason: 'Modify color failed');

      activeChart = getChartFromOutput(modifyResult.data);
      expect(activeChart.id, equals(originalId));
      expect(activeChart.series.first.color, equals('#FF0000'));
    });
  });
}
