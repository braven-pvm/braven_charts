import 'package:flutter_test/flutter_test.dart';

import 'package:braven_charts/src/agentic/services/chart_history.dart';
import 'package:braven_charts/src/agentic/models/chart_configuration.dart';
import 'package:braven_charts/src/agentic/models/axis_config.dart';
import 'package:braven_charts/src/agentic/models/series_config.dart';

void main() {
  group('ChartHistory', () {
    test('records chart state snapshots', () {
      final history = ChartHistory();
      final chart = ChartConfiguration(
        id: 'test-chart-123',
        type: ChartType.line,
        series: [SeriesConfig(id: 's1', data: [])],
        xAxis: XAxisConfig(label: 'X'),
        yAxes: [YAxisConfig(label: 'Y')],
      );

      history.record(chart);

      expect(history.canUndo, isTrue);
      expect(history.canRedo, isFalse);
    });

    test('undo operation returns to previous state', () {
      final history = ChartHistory();
      final chart1 = ChartConfiguration(
        id: 'test-chart-123',
        type: ChartType.line,
        series: [SeriesConfig(id: 's1', data: [])],
        xAxis: XAxisConfig(label: 'X1'),
        yAxes: [YAxisConfig(label: 'Y1')],
      );
      final chart2 = ChartConfiguration(
        id: 'test-chart-123',
        type: ChartType.line,
        series: [SeriesConfig(id: 's1', data: [])],
        xAxis: XAxisConfig(label: 'X2'),
        yAxes: [YAxisConfig(label: 'Y2')],
      );

      history.record(chart1);
      history.record(chart2);

      final undone = history.undo();

      expect(undone, isNotNull);
      expect(undone!.xAxis!.label, equals('X1'));
    });

    test('redo operation moves forward after undo', () {
      final history = ChartHistory();
      final chart1 = ChartConfiguration(
        id: 'test-chart-123',
        type: ChartType.line,
        series: [SeriesConfig(id: 's1', data: [])],
        xAxis: XAxisConfig(label: 'X1'),
        yAxes: [YAxisConfig(label: 'Y1')],
      );
      final chart2 = ChartConfiguration(
        id: 'test-chart-123',
        type: ChartType.line,
        series: [SeriesConfig(id: 's1', data: [])],
        xAxis: XAxisConfig(label: 'X2'),
        yAxes: [YAxisConfig(label: 'Y2')],
      );

      history.record(chart1);
      history.record(chart2);
      history.undo();

      final redone = history.redo();

      expect(redone, isNotNull);
      expect(redone!.xAxis!.label, equals('X2'));
    });

    test('history depth limit drops oldest when exceeded', () {
      final history = ChartHistory(maxDepth: 20);

      // Record 21 chart states
      for (int i = 0; i < 21; i++) {
        final chart = ChartConfiguration(
          id: 'test-chart-123',
          type: ChartType.line,
          series: [SeriesConfig(id: 's1', data: [])],
          xAxis: XAxisConfig(label: 'X$i'),
          yAxes: [YAxisConfig(label: 'Y$i')],
        );
        history.record(chart);
      }

      // Undo 20 times (should reach the second state, not the first)
      ChartConfiguration? state;
      for (int i = 0; i < 20; i++) {
        state = history.undo();
      }

      expect(state, isNotNull);
      expect(state!.xAxis!.label, equals('X1')); // First state (X0) was dropped
      expect(history.canUndo, isFalse); // Can't undo further
    });

    test('clear history operation removes all states', () {
      final history = ChartHistory();
      final chart = ChartConfiguration(
        id: 'test-chart-123',
        type: ChartType.line,
        series: [SeriesConfig(id: 's1', data: [])],
        xAxis: XAxisConfig(label: 'X'),
        yAxes: [YAxisConfig(label: 'Y')],
      );

      history.record(chart);
      history.clear();

      expect(history.canUndo, isFalse);
      expect(history.canRedo, isFalse);
    });

    test('undo when history empty returns null', () {
      final history = ChartHistory();

      final undone = history.undo();

      expect(undone, isNull);
      expect(history.canUndo, isFalse);
    });

    test('redo when at latest state returns null', () {
      final history = ChartHistory();
      final chart = ChartConfiguration(
        id: 'test-chart-123',
        type: ChartType.line,
        series: [SeriesConfig(id: 's1', data: [])],
        xAxis: XAxisConfig(label: 'X'),
        yAxes: [YAxisConfig(label: 'Y')],
      );

      history.record(chart);

      final redone = history.redo();

      expect(redone, isNull);
      expect(history.canRedo, isFalse);
    });

    test('recording new state after undo clears redo history', () {
      final history = ChartHistory();
      final chart1 = ChartConfiguration(
        id: 'test-chart-123',
        type: ChartType.line,
        series: [SeriesConfig(id: 's1', data: [])],
        xAxis: XAxisConfig(label: 'X1'),
        yAxes: [YAxisConfig(label: 'Y1')],
      );
      final chart2 = ChartConfiguration(
        id: 'test-chart-123',
        type: ChartType.line,
        series: [SeriesConfig(id: 's1', data: [])],
        xAxis: XAxisConfig(label: 'X2'),
        yAxes: [YAxisConfig(label: 'Y2')],
      );
      final chart3 = ChartConfiguration(
        id: 'test-chart-123',
        type: ChartType.line,
        series: [SeriesConfig(id: 's1', data: [])],
        xAxis: XAxisConfig(label: 'X3'),
        yAxes: [YAxisConfig(label: 'Y3')],
      );

      history.record(chart1);
      history.record(chart2);
      history.undo(); // Now at chart1, chart2 is in redo history

      history.record(chart3); // This should clear redo history

      expect(history.canRedo, isFalse);
      expect(history.canUndo, isTrue);
    });

    test('provides current history position', () {
      final history = ChartHistory();
      final chart1 = ChartConfiguration(
        id: 'test-chart-123',
        type: ChartType.line,
        series: [SeriesConfig(id: 's1', data: [])],
        xAxis: XAxisConfig(label: 'X1'),
        yAxes: [YAxisConfig(label: 'Y1')],
      );
      final chart2 = ChartConfiguration(
        id: 'test-chart-123',
        type: ChartType.line,
        series: [SeriesConfig(id: 's1', data: [])],
        xAxis: XAxisConfig(label: 'X2'),
        yAxes: [YAxisConfig(label: 'Y2')],
      );

      expect(history.position, equals(0));

      history.record(chart1);
      expect(history.position, equals(1));

      history.record(chart2);
      expect(history.position, equals(2));

      history.undo();
      expect(history.position, equals(1));
    });

    test('provides total history size', () {
      final history = ChartHistory();
      final chart1 = ChartConfiguration(
        id: 'test-chart-123',
        type: ChartType.line,
        series: [SeriesConfig(id: 's1', data: [])],
        xAxis: XAxisConfig(label: 'X1'),
        yAxes: [YAxisConfig(label: 'Y1')],
      );
      final chart2 = ChartConfiguration(
        id: 'test-chart-123',
        type: ChartType.line,
        series: [SeriesConfig(id: 's1', data: [])],
        xAxis: XAxisConfig(label: 'X2'),
        yAxes: [YAxisConfig(label: 'Y2')],
      );

      expect(history.size, equals(0));

      history.record(chart1);
      expect(history.size, equals(1));

      history.record(chart2);
      expect(history.size, equals(2));

      history.undo();
      expect(history.size, equals(2)); // Size doesn't decrease with undo
    });
  });
}
