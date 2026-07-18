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
      expect(line.pathAnimation.entranceTiming, const PathAnimationTiming());
      expect(
        area.pathAnimation.dataUpdateMode,
        PathDataUpdateAnimationMode.none,
      );
      expect(area.pathAnimation.dataUpdateTiming, const PathAnimationTiming());
    });

    test('copyWith, equality, and hashCode include motion configuration', () {
      const motion = PathAnimationStyle(
        entranceMode: PathEntranceAnimationMode.reveal,
        dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
        entranceTiming: PathAnimationTiming(
          delay: Duration(milliseconds: 80),
          duration: Duration(milliseconds: 500),
        ),
        dataUpdateTiming: PathAnimationTiming(
          delay: Duration(milliseconds: 120),
        ),
      );
      const original = LineChartSeries(
        id: 'line',
        points: [ChartDataPoint(x: 0, y: 1)],
      );
      final updated = original.copyWith(pathAnimation: motion);

      expect(updated.pathAnimation, motion);
      expect(updated, isNot(original));
      expect(updated.hashCode, isNot(original.hashCode));
      expect(
        motion.copyWith(
          dataUpdateTiming: const PathAnimationTiming(
            duration: Duration(milliseconds: 240),
          ),
        ),
        isNot(motion),
      );
      expect(motion.toString(), contains('entranceTiming'));
    });
  });

  group('PathAnimationTiming', () {
    test('inherits duration and can clear an explicit override', () {
      const timing = PathAnimationTiming(
        delay: Duration(milliseconds: 80),
        duration: Duration(milliseconds: 500),
      );

      expect(
        timing.copyWith(inheritDuration: true),
        const PathAnimationTiming(delay: Duration(milliseconds: 80)),
      );
      expect(timing.toString(), contains('0:00:00.500000'));
    });
  });
}
