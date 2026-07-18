import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PathAnimationStyle', () {
    test('defaults keep existing Line and Area series static', () {
      const point = ChartDataPoint(x: 0, y: 1);
      const line = LineChartSeries(id: 'line', points: [point]);
      const area = AreaChartSeries(id: 'area', points: [point]);

      expect(line.pathAnimation, const PathAnimationStyle());
      expect(area.pathAnimation, const PathAnimationStyle());
      expect(line.pathAnimation.entranceMode, PathEntranceAnimationMode.none);
      expect(
        area.pathAnimation.dataUpdateMode,
        PathDataUpdateAnimationMode.none,
      );
    });

    test('copyWith, equality, and hashCode include motion configuration', () {
      const motion = PathAnimationStyle(
        entranceMode: PathEntranceAnimationMode.reveal,
        dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
      );
      const original = LineChartSeries(
        id: 'line',
        points: [ChartDataPoint(x: 0, y: 1)],
      );
      final updated = original.copyWith(pathAnimation: motion);

      expect(updated.pathAnimation, motion);
      expect(updated, isNot(original));
      expect(updated.hashCode, isNot(original.hashCode));
    });
  });
}
