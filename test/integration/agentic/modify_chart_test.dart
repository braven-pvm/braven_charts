// @orchestra-task: 16
@Tags(['tdd-red'])
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/models/chart_configuration.dart';
import 'package:braven_charts/src/agentic/services/chart_history.dart';
import 'package:braven_charts/src/agentic/services/data_store.dart';
import 'package:braven_charts/src/agentic/tools/create_chart_tool.dart';
import 'package:braven_charts/src/agentic/tools/modify_chart_tool.dart';
import 'package:braven_charts/src/agentic/tools/add_annotation_tool.dart';

void main() {
  group('In-Place Chart Modification Integration', () {
    late DataStore<ChartConfiguration> chartStore;
    late ChartHistory history;

    setUp(() {
      chartStore = DataStore<ChartConfiguration>();
      history = ChartHistory();
    });

    test('chart modifications update same instance without recreation', () async {
      // Create initial chart
      final createTool = CreateChartTool();
      final initialChart = await createTool.execute({
        'prompt': 'Show me a line chart of power over time',
        'dataset': {
          'columns': ['time', 'power'],
          'rows': [
            {'time': 0, 'power': 120},
            {'time': 1, 'power': 140},
            {'time': 2, 'power': 160},
          ],
        },
      }) as ChartConfiguration;

      final chartId = chartStore.store(initialChart);
      history.record(initialChart);

      expect(initialChart.id, isNotNull);
      expect(initialChart.type, equals(ChartType.line));
      expect(initialChart.series, isNotEmpty);

      // Modify chart properties (color, line width)
      final modifyTool = ModifyChartTool();
      final modifiedChart = await modifyTool.execute({
        'chartId': chartId,
        'properties': {
          'color': '#FF0000',
          'lineWidth': 3.0,
        },
      }) as ChartConfiguration;

      history.record(modifiedChart);

      // Verify SAME chart instance was updated (chartId unchanged)
      expect(modifiedChart.id, equals(initialChart.id));
      expect(modifiedChart.series.first.color, equals('#FF0000'));
      expect(modifiedChart.series.first.lineWidth, equals(3.0));
      expect(modifiedChart.type, equals(ChartType.line)); // Other props preserved

      // Add annotation
      final annotationTool = AddAnnotationTool();
      final annotatedChart = await annotationTool.execute({
        'chartId': chartId,
        'annotationType': 'referenceLine',
        'orientation': 'horizontal',
        'value': 150.0,
        'label': 'Target Power',
      }) as ChartConfiguration;

      history.record(annotatedChart);

      // Verify annotation was added to the same chart
      expect(annotatedChart.id, equals(initialChart.id));
      expect(annotatedChart.annotations, isNotEmpty);
      expect(annotatedChart.annotations.first.type, equals('referenceLine'));
      expect(annotatedChart.annotations.first.value, equals(150.0));

      // Verify chart history tracks all modifications
      expect(history.canUndo, isTrue);
      expect(history.size, equals(3)); // initial + 2 modifications

      // Test undo to previous state (with color/width but no annotation)
      final undoneChart = history.undo();
      expect(undoneChart, isNotNull);
      expect(undoneChart!.id, equals(initialChart.id));
      expect(undoneChart.series.first.color, equals('#FF0000'));
      expect(undoneChart.annotations, isEmpty);

      // Test redo to restore annotation
      final redoneChart = history.redo();
      expect(redoneChart, isNotNull);
      expect(redoneChart!.id, equals(initialChart.id));
      expect(redoneChart.annotations, isNotEmpty);
    });

    test('multiple sequential modifications preserve chart identity', () async {
      // Create initial chart
      final createTool = CreateChartTool();
      final initialChart = await createTool.execute({
        'prompt': 'Create a bar chart',
        'dataset': {
          'columns': ['category', 'value'],
          'rows': [
            {'category': 'A', 'value': 10},
            {'category': 'B', 'value': 20},
          ],
        },
      }) as ChartConfiguration;

      final originalId = initialChart.id;
      history.record(initialChart);

      // Apply multiple modifications in sequence
      final modifyTool = ModifyChartTool();

      // Modification 1: Change color
      final mod1 = await modifyTool.execute({
        'chartId': originalId,
        'properties': {'color': '#00FF00'},
      }) as ChartConfiguration;
      history.record(mod1);
      expect(mod1.id, equals(originalId));

      // Modification 2: Change theme
      final mod2 = await modifyTool.execute({
        'chartId': originalId,
        'properties': {'theme': 'dark'},
      }) as ChartConfiguration;
      history.record(mod2);
      expect(mod2.id, equals(originalId));

      // Modification 3: Update axis labels
      final mod3 = await modifyTool.execute({
        'chartId': originalId,
        'properties': {
          'xAxis': {'label': 'Categories'},
          'yAxis': {'label': 'Values'},
        },
      }) as ChartConfiguration;
      history.record(mod3);
      expect(mod3.id, equals(originalId));

      // Verify all modifications maintained the same chart ID
      expect(history.size, equals(4)); // initial + 3 modifications

      // Undo all modifications
      history.undo(); // Back to mod2
      history.undo(); // Back to mod1
      final backToInitial = history.undo(); // Back to initial
      expect(backToInitial, isNotNull);
      expect(backToInitial!.id, equals(originalId));
    });

    test('chart modification with annotation maintains consistency', () async {
      // Create chart
      final createTool = CreateChartTool();
      final chart = await createTool.execute({
        'prompt': 'Power chart',
        'dataset': {
          'columns': ['time', 'power'],
          'rows': [
            {'time': 0, 'power': 200},
            {'time': 1, 'power': 250},
          ],
        },
      }) as ChartConfiguration;

      final chartId = chart.id;
      history.record(chart);

      // Add multiple annotations
      final annotationTool = AddAnnotationTool();

      final withLine = await annotationTool.execute({
        'chartId': chartId,
        'annotationType': 'referenceLine',
        'orientation': 'horizontal',
        'value': 225.0,
      }) as ChartConfiguration;
      history.record(withLine);

      final withZone = await annotationTool.execute({
        'chartId': chartId,
        'annotationType': 'zone',
        'orientation': 'horizontal',
        'minValue': 200.0,
        'maxValue': 250.0,
      }) as ChartConfiguration;
      history.record(withZone);

      // Verify both annotations exist and chart ID is consistent
      expect(withZone.id, equals(chartId));
      expect(withZone.annotations.length, greaterThanOrEqualTo(2));

      // Modify chart style after adding annotations
      final modifyTool = ModifyChartTool();
      final styled = await modifyTool.execute({
        'chartId': chartId,
        'properties': {'color': '#0000FF'},
      }) as ChartConfiguration;
      history.record(styled);

      // Verify annotations are preserved after style modification
      expect(styled.id, equals(chartId));
      expect(styled.annotations.length, greaterThanOrEqualTo(2));
      expect(styled.series.first.color, equals('#0000FF'));

      // Test history navigation
      expect(history.canUndo, isTrue);
      final undone = history.undo(); // Back to withZone (before style change)
      expect(undone, isNotNull);
      expect(undone!.id, equals(chartId));
      expect(undone.annotations.length, greaterThanOrEqualTo(2));
    });

    test('chart modification fails gracefully with invalid chartId', () async {
      final modifyTool = ModifyChartTool();

      expect(
        () => modifyTool.execute({
          'chartId': 'non-existent-chart-id',
          'properties': {'color': '#FF0000'},
        }),
        throwsA(isA<Exception>()),
      );
    });

    test('annotation addition fails gracefully with invalid chartId', () async {
      final annotationTool = AddAnnotationTool();

      expect(
        () => annotationTool.execute({
          'chartId': 'non-existent-chart-id',
          'annotationType': 'referenceLine',
          'value': 100.0,
        }),
        throwsA(isA<Exception>()),
      );
    });
  });
}
