import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/bar_composition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BarCompositionEngine', () {
    test('rejects mixed bar orientations in one chart', () {
      const vertical = BarChartSeries(
        id: 'vertical',
        points: [ChartDataPoint(x: 0, y: 10)],
        barWidthPercent: 0.7,
      );
      const horizontal = BarChartSeries(
        id: 'horizontal',
        points: [ChartDataPoint(x: 0, y: 10)],
        barWidthPercent: 0.7,
        orientation: BarOrientation.horizontal,
      );

      expect(
        () => BarCompositionEngine.resolve([vertical, horizontal]),
        throwsArgumentError,
      );
    });
    test('keeps grouped series in separate category slots', () {
      final result = BarCompositionEngine.resolve(const [
        BarChartSeries(
          id: 'first',
          points: [ChartDataPoint(x: 0, y: 20)],
          barWidthPercent: 0.8,
        ),
        BarChartSeries(
          id: 'second',
          points: [ChartDataPoint(x: 0, y: 30)],
          barWidthPercent: 0.8,
        ),
      ]);

      expect(result['first']?.index, 0);
      expect(result['second']?.index, 1);
      expect(result['first']?.count, 2);
      expect(result['second']?.count, 2);
    });

    test('overlays named series without changing their values', () {
      final result = BarCompositionEngine.resolve(const [
        BarChartSeries(
          id: 'reference',
          points: [ChartDataPoint(x: 0, y: 80)],
          barWidthPercent: 0.8,
          layoutMode: BarLayoutMode.overlaid,
          groupId: 'comparison',
        ),
        BarChartSeries(
          id: 'actual',
          points: [ChartDataPoint(x: 0, y: 55)],
          barWidthPercent: 0.8,
          layoutMode: BarLayoutMode.overlaid,
          groupId: 'comparison',
          overlayWidthFactor: 0.58,
        ),
      ]);

      expect(result['reference']?.index, 0);
      expect(result['actual']?.index, 0);
      expect(result['reference']?.count, 1);
      expect(result['reference']?.isOverlaid, isTrue);
      expect(result['reference']?.isStacked, isFalse);
      expect(result['actual']?.startValues, isEmpty);
      expect(result['actual']?.endValues, isEmpty);
      expect(result['reference']?.drawTrack, isTrue);
      expect(result['actual']?.drawTrack, isFalse);
    });

    test('places named overlay groups side-by-side', () {
      final result = BarCompositionEngine.resolve(const [
        BarChartSeries(
          id: 'actual-wide',
          points: [ChartDataPoint(x: 0, y: 80)],
          barWidthPercent: 0.8,
          layoutMode: BarLayoutMode.overlaid,
          groupId: 'actual',
        ),
        BarChartSeries(
          id: 'plan-wide',
          points: [ChartDataPoint(x: 0, y: 70)],
          barWidthPercent: 0.8,
          layoutMode: BarLayoutMode.overlaid,
          groupId: 'plan',
        ),
        BarChartSeries(
          id: 'actual-narrow',
          points: [ChartDataPoint(x: 0, y: 55)],
          barWidthPercent: 0.8,
          layoutMode: BarLayoutMode.overlaid,
          groupId: 'actual',
          overlayWidthFactor: 0.55,
        ),
      ]);

      expect(result['actual-wide']?.index, 0);
      expect(result['actual-narrow']?.index, 0);
      expect(result['plan-wide']?.index, 1);
      expect(result.values.every((info) => info.count == 2), isTrue);
    });

    test('stacks positive and negative contributions independently', () {
      final result = BarCompositionEngine.resolve(const [
        BarChartSeries(
          id: 'first',
          points: [ChartDataPoint(x: 0, y: 20), ChartDataPoint(x: 1, y: -10)],
          barWidthPercent: 0.8,
          layoutMode: BarLayoutMode.stacked,
          groupId: 'net',
        ),
        BarChartSeries(
          id: 'second',
          points: [ChartDataPoint(x: 0, y: 30), ChartDataPoint(x: 1, y: -15)],
          barWidthPercent: 0.8,
          layoutMode: BarLayoutMode.stacked,
          groupId: 'net',
        ),
      ]);

      expect(result['first']?.index, 0);
      expect(result['second']?.index, 0);
      expect(result['first']?.count, 1);
      expect(result['first']?.startValueFor(0, -1), 0);
      expect(result['first']?.endValueFor(0, -1), 20);
      expect(result['second']?.startValueFor(0, -1), 20);
      expect(result['second']?.endValueFor(0, -1), 50);
      expect(result['second']?.startValueFor(1, 1), -10);
      expect(result['second']?.endValueFor(1, 1), -25);
      expect(result['first']?.isOuterPoint(0), isFalse);
      expect(result['second']?.isOuterPoint(0), isTrue);
      expect(result['first']?.drawTrack, isTrue);
      expect(result['second']?.drawTrack, isFalse);
    });

    test('places named stacks side-by-side', () {
      final result = BarCompositionEngine.resolve(const [
        BarChartSeries(
          id: 'actual-a',
          points: [ChartDataPoint(x: 0, y: 20)],
          barWidthPercent: 0.8,
          layoutMode: BarLayoutMode.stacked,
          groupId: 'actual',
        ),
        BarChartSeries(
          id: 'plan-a',
          points: [ChartDataPoint(x: 0, y: 30)],
          barWidthPercent: 0.8,
          layoutMode: BarLayoutMode.stacked,
          groupId: 'plan',
        ),
        BarChartSeries(
          id: 'actual-b',
          points: [ChartDataPoint(x: 0, y: 15)],
          barWidthPercent: 0.8,
          layoutMode: BarLayoutMode.stacked,
          groupId: 'actual',
        ),
      ]);

      expect(result['actual-a']?.index, 0);
      expect(result['actual-b']?.index, 0);
      expect(result['plan-a']?.index, 1);
      expect(result.values.every((info) => info.count == 2), isTrue);
    });

    test('normalizes positive and negative sides to one hundred percent', () {
      final result = BarCompositionEngine.resolve(const [
        BarChartSeries(
          id: 'first',
          points: [ChartDataPoint(x: 0, y: 20), ChartDataPoint(x: 1, y: -10)],
          barWidthPercent: 0.8,
          layoutMode: BarLayoutMode.normalizedStacked,
        ),
        BarChartSeries(
          id: 'second',
          points: [ChartDataPoint(x: 0, y: 30), ChartDataPoint(x: 1, y: -30)],
          barWidthPercent: 0.8,
          layoutMode: BarLayoutMode.normalizedStacked,
        ),
      ]);

      expect(result['first']?.percentageFor(0), closeTo(40, 0.001));
      expect(result['second']?.percentageFor(0), closeTo(60, 0.001));
      expect(result['second']?.endValueFor(0, -1), closeTo(100, 0.001));
      expect(result['first']?.percentageFor(1), closeTo(-25, 0.001));
      expect(result['second']?.percentageFor(1), closeTo(-75, 0.001));
      expect(result['second']?.endValueFor(1, 1), closeTo(-100, 0.001));
    });

    test('accumulates waterfall deltas and resolves total columns', () {
      const series = BarChartSeries(
        id: 'bridge',
        points: [
          ChartDataPoint(x: 0, y: 100),
          ChartDataPoint(x: 1, y: -30),
          ChartDataPoint(x: 2, y: 20),
          ChartDataPoint(x: 3, y: 999),
        ],
        barWidthPercent: 0.72,
        layoutMode: BarLayoutMode.waterfall,
        waterfallTotalIndices: {3},
      );

      final info = BarCompositionEngine.resolve(const [series])['bridge']!;

      expect(info.isWaterfall, isTrue);
      expect(info.startValueFor(0, -1), 0);
      expect(info.endValueFor(0, -1), 100);
      expect(info.startValueFor(1, -1), 100);
      expect(info.endValueFor(1, -1), 70);
      expect(info.startValueFor(2, -1), 70);
      expect(info.endValueFor(2, -1), 90);
      expect(info.startValueFor(3, -1), 0);
      expect(info.endValueFor(3, -1), 90);
      expect(series.waterfallDisplayValueFor(1), -30);
      expect(series.waterfallDisplayValueFor(3), 90);
    });

    test('keeps independent waterfall series in side-by-side slots', () {
      final result = BarCompositionEngine.resolve(const [
        BarChartSeries(
          id: 'actual',
          points: [ChartDataPoint(x: 0, y: 100)],
          barWidthPercent: 0.72,
          layoutMode: BarLayoutMode.waterfall,
        ),
        BarChartSeries(
          id: 'plan',
          points: [ChartDataPoint(x: 0, y: 90)],
          barWidthPercent: 0.72,
          layoutMode: BarLayoutMode.waterfall,
        ),
      ]);

      expect(result['actual']?.index, 0);
      expect(result['plan']?.index, 1);
      expect(result.values.every((info) => info.count == 2), isTrue);
    });

    test('rejects invalid waterfall totals and unordered categories', () {
      const wrongLayout = BarChartSeries(
        id: 'wrong-layout',
        points: [ChartDataPoint(x: 0, y: 10)],
        barWidthPercent: 0.72,
        waterfallTotalIndices: {0},
      );
      const invalidIndex = BarChartSeries(
        id: 'invalid-index',
        points: [ChartDataPoint(x: 0, y: 10)],
        barWidthPercent: 0.72,
        layoutMode: BarLayoutMode.waterfall,
        waterfallTotalIndices: {1},
      );
      const unordered = BarChartSeries(
        id: 'unordered',
        points: [ChartDataPoint(x: 1, y: 10), ChartDataPoint(x: 0, y: -2)],
        barWidthPercent: 0.72,
        layoutMode: BarLayoutMode.waterfall,
      );

      expect(
        () => BarCompositionEngine.resolve(const [wrongLayout]),
        throwsArgumentError,
      );
      expect(
        () => BarCompositionEngine.resolve(const [invalidIndex]),
        throwsRangeError,
      );
      expect(
        () => BarCompositionEngine.resolve(const [unordered]),
        throwsArgumentError,
      );
    });
  });
}
