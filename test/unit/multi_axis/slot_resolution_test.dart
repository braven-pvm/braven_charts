import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/modules/multi_axis_manager.dart';
import 'package:flutter_test/flutter_test.dart';

LineChartSeries _rightSeries(String id) => LineChartSeries(
      id: id,
      points: const [],
      yAxisConfig: YAxisConfig(position: YAxisPosition.right, label: id),
    );

LineChartSeries _leftSeries(String id) => LineChartSeries(
      id: id,
      points: const [],
      yAxisConfig: YAxisConfig(position: YAxisPosition.left, label: id),
    );

void main() {
  group('MultiAxisManager slot resolution', () {
    late MultiAxisManager manager;

    setUp(() {
      manager = MultiAxisManager();
    });

    test('all axes visible when count <= maxAxesPerSide', () {
      manager.setSeries([_rightSeries('a'), _rightSeries('b'), _rightSeries('c')]);
      manager.setMaxAxesPerSide(3);
      final visible = manager.getVisibleAxes();
      expect(visible.where((a) => a.position == YAxisPosition.right), hasLength(3));
    });

    test('overflow axes are excluded from getVisibleAxes', () {
      manager.setSeries([
        _rightSeries('a'), _rightSeries('b'), _rightSeries('c'),
        _rightSeries('d'), _rightSeries('e'),
      ]);
      manager.setMaxAxesPerSide(3);
      final visible = manager.getVisibleAxes();
      expect(visible.where((a) => a.position == YAxisPosition.right), hasLength(3));
    });

    test('overflowAxisIds returns ids outside the slot cap', () {
      manager.setSeries([
        _rightSeries('a'), _rightSeries('b'), _rightSeries('c'), _rightSeries('d'),
      ]);
      manager.setMaxAxesPerSide(3);
      final overflow = manager.overflowAxisIds;
      // The 4th series' axis should be in overflow
      expect(overflow, hasLength(1));
    });

    test('left and right caps are independent', () {
      manager.setSeries([
        _leftSeries('l1'), _leftSeries('l2'), _leftSeries('l3'), _leftSeries('l4'),
        _rightSeries('r1'), _rightSeries('r2'),
      ]);
      manager.setMaxAxesPerSide(3);
      final visible = manager.getVisibleAxes();
      expect(visible.where((a) => a.position == YAxisPosition.left), hasLength(3));
      expect(visible.where((a) => a.position == YAxisPosition.right), hasLength(2));
    });

    test('applySeriesSelection promotes overflow axis', () {
      final series = [
        _rightSeries('a'), _rightSeries('b'), _rightSeries('c'), _rightSeries('d'),
      ];
      manager.setSeries(series);
      manager.setMaxAxesPerSide(3);

      final overflow = manager.overflowAxisIds;
      expect(overflow, hasLength(1));
      final overflowId = overflow.first;

      // Find a series whose axis is in overflow
      final overflowSeriesId = series
          .firstWhere((s) => s.yAxisConfig!.label == overflowId.replaceAll('_axis', ''))
          .id;

      final result = manager.applySeriesSelection(overflowSeriesId);
      expect(result, isNotNull);
      expect(result!.promotedAxisId, equals(overflowId));
      expect(manager.getVisibleAxes().any((a) => a.id == overflowId), isTrue);
      expect(manager.overflowAxisIds, isNot(contains(overflowId)));
    });

    test('clearSelectionFor in revert mode restores declaration order', () {
      final series = [
        _rightSeries('a'), _rightSeries('b'), _rightSeries('c'), _rightSeries('d'),
      ];
      manager.setSeries(series);
      manager.setMaxAxesPerSide(3);
      manager.setAxisSwapMode(AxisSwapMode.revert);

      final overflow = manager.overflowAxisIds;
      final overflowId = overflow.first;
      final overflowSeriesId = series
          .firstWhere((s) => s.yAxisConfig!.label == overflowId.replaceAll('_axis', ''))
          .id;

      manager.applySeriesSelection(overflowSeriesId);
      expect(manager.getVisibleAxes().any((a) => a.id == overflowId), isTrue);

      manager.clearSelectionFor(overflowSeriesId);
      // After revert, overflow axis should be back in overflow
      expect(manager.overflowAxisIds, contains(overflowId));
      expect(manager.getVisibleAxes().any((a) => a.id == overflowId), isFalse);
    });
  });
}
