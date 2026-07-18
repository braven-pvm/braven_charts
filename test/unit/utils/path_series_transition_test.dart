import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/utils/path_series_transition.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const fromPoints = [
    ChartDataPoint(x: 0, y: 10, label: 'A'),
    ChartDataPoint(x: 1, y: 20, label: 'B'),
  ];
  const toPoints = [
    ChartDataPoint(x: 0, y: 30, label: 'A'),
    ChartDataPoint(x: 1, y: 40, label: 'B'),
  ];

  group('PathSeriesTransition', () {
    test('interpolates compatible Line geometry at mid-frame', () {
      const from = LineChartSeries(id: 'line', points: fromPoints);
      const to = LineChartSeries(id: 'line', points: toPoints);

      expect(PathSeriesTransition.isCompatible(from, to), isTrue);
      final result =
          PathSeriesTransition.interpolate(from: from, to: to, progress: 0.5)
              as LineChartSeries;

      expect(result.points.map((point) => point.y), [20, 30]);
      expect(result.points.map((point) => point.label), ['A', 'B']);
    });

    test('matches timestamp identity before coordinates', () {
      final first = DateTime.utc(2026, 7, 18, 8);
      final second = DateTime.utc(2026, 7, 18, 9);
      final from = AreaChartSeries(
        id: 'area',
        points: [
          ChartDataPoint(x: 0, y: 10, timestamp: first),
          ChartDataPoint(x: 1, y: 30, timestamp: second),
        ],
      );
      final to = AreaChartSeries(
        id: 'area',
        points: [
          ChartDataPoint(x: 1, y: 20, timestamp: first),
          ChartDataPoint(x: 0, y: 50, timestamp: second),
        ],
      );

      final result =
          PathSeriesTransition.interpolate(from: from, to: to, progress: 0.5)
              as AreaChartSeries;

      expect(result.points.map((point) => point.y), [15, 40]);
    });

    test(
      'keeps index fallback for ordered equal-length coordinate updates',
      () {
        const from = LineChartSeries(
          id: 'line',
          points: [
            ChartDataPoint(x: 0, y: 10),
            ChartDataPoint(x: 1, y: 20),
            ChartDataPoint(x: 2, y: 30),
          ],
        );
        const to = LineChartSeries(
          id: 'line',
          points: [
            ChartDataPoint(x: 0, y: 12),
            ChartDataPoint(x: 1.5, y: 24),
            ChartDataPoint(x: 2, y: 36),
          ],
        );

        final result =
            PathSeriesTransition.interpolate(from: from, to: to, progress: 0.5)
                as LineChartSeries;

        expect(result.points.map((point) => point.x), [0, 1.25, 2]);
        expect(result.points.map((point) => point.y), [11, 22, 33]);
      },
    );

    test('grows an appended point from the retained tail boundary', () {
      const from = LineChartSeries(id: 'line', points: fromPoints);
      const to = LineChartSeries(
        id: 'line',
        points: [
          ...toPoints,
          ChartDataPoint(x: 2, y: 50, label: 'C'),
        ],
      );

      expect(PathSeriesTransition.isCompatible(from, to), isTrue);
      final result =
          PathSeriesTransition.interpolate(from: from, to: to, progress: 0.5)
              as LineChartSeries;

      expect(result.points, hasLength(3));
      expect(result.points.map((point) => point.x), [0, 1, 1.5]);
      expect(result.points.map((point) => point.y), [20, 30, 35]);
      expect(result.points.last.label, 'C');
    });

    test('keeps a removed tail until it collapses into the boundary', () {
      const from = AreaChartSeries(
        id: 'area',
        points: [
          ...fromPoints,
          ChartDataPoint(x: 2, y: 50, label: 'C'),
        ],
      );
      const to = AreaChartSeries(id: 'area', points: toPoints);

      final result =
          PathSeriesTransition.interpolate(from: from, to: to, progress: 0.5)
              as AreaChartSeries;

      expect(result.points, hasLength(3));
      expect(result.points.map((point) => point.x), [0, 1, 1.5]);
      expect(result.points.map((point) => point.y), [20, 30, 45]);
      expect(result.points.last.label, 'C');
      expect(
        PathSeriesTransition.frame(
          from: from,
          to: to,
          progress: 0.5,
        ).targetPointIndices,
        [0, 1, null],
      );
      expect(
        PathSeriesTransition.interpolate(from: from, to: to, progress: 1),
        same(to),
      );
    });

    test('shrinks the old head while growing a rolling-window tail', () {
      const from = LineChartSeries(
        id: 'line',
        points: [
          ChartDataPoint(x: 0, y: 10, label: 'A'),
          ChartDataPoint(x: 1, y: 20, label: 'B'),
          ChartDataPoint(x: 2, y: 30, label: 'C'),
        ],
      );
      const to = LineChartSeries(
        id: 'line',
        points: [
          ChartDataPoint(x: 1, y: 24, label: 'B'),
          ChartDataPoint(x: 2, y: 34, label: 'C'),
          ChartDataPoint(x: 3, y: 44, label: 'D'),
        ],
      );

      final result =
          PathSeriesTransition.interpolate(from: from, to: to, progress: 0.5)
              as LineChartSeries;

      expect(result.points, hasLength(4));
      expect(result.points.map((point) => point.label), ['A', 'B', 'C', 'D']);
      expect(result.points.map((point) => point.x), [0.5, 1, 2, 2.5]);
      expect(result.points.map((point) => point.y), [17, 22, 32, 37]);
    });

    test('maps rolling render points to canonical target indices', () {
      const from = LineChartSeries(
        id: 'line',
        points: [
          ChartDataPoint(x: 0, y: 10, label: 'A'),
          ChartDataPoint(x: 1, y: 20, label: 'B'),
          ChartDataPoint(x: 2, y: 30, label: 'C'),
        ],
      );
      const to = LineChartSeries(
        id: 'line',
        points: [
          ChartDataPoint(x: 1, y: 24, label: 'B'),
          ChartDataPoint(x: 2, y: 34, label: 'C'),
          ChartDataPoint(x: 3, y: 44, label: 'D'),
        ],
      );

      final midpoint = PathSeriesTransition.frame(
        from: from,
        to: to,
        progress: 0.5,
      );
      final completed = PathSeriesTransition.frame(
        from: from,
        to: to,
        progress: 1,
      );

      expect(midpoint.targetPointIndices, [null, 0, 1, 2]);
      expect(midpoint.targetPointCount, 3);
      expect(completed.series, same(to));
      expect(completed.targetPointIndices, [0, 1, 2]);
    });

    test('remaps retained source indices by stable target identity', () {
      const from = AreaChartSeries(
        id: 'area',
        points: [
          ChartDataPoint(x: 0, y: 10, label: 'A'),
          ChartDataPoint(x: 1, y: 20, label: 'B'),
          ChartDataPoint(x: 2, y: 30, label: 'C'),
        ],
      );
      const to = AreaChartSeries(
        id: 'area',
        points: [
          ChartDataPoint(x: 1, y: 24, label: 'B'),
          ChartDataPoint(x: 2, y: 34, label: 'C'),
          ChartDataPoint(x: 3, y: 44, label: 'D'),
        ],
      );

      expect(PathSeriesTransition.targetIndexForSource(from, to, 0), isNull);
      expect(PathSeriesTransition.targetIndexForSource(from, to, 1), 0);
      expect(PathSeriesTransition.targetIndexForSource(from, to, 2), 1);
    });

    test('supports a reverse rolling window at the opposite boundaries', () {
      const from = LineChartSeries(
        id: 'line',
        points: [
          ChartDataPoint(x: 1, y: 20, label: 'B'),
          ChartDataPoint(x: 2, y: 30, label: 'C'),
          ChartDataPoint(x: 3, y: 40, label: 'D'),
        ],
      );
      const to = LineChartSeries(
        id: 'line',
        points: [
          ChartDataPoint(x: 0, y: 10, label: 'A'),
          ChartDataPoint(x: 1, y: 24, label: 'B'),
          ChartDataPoint(x: 2, y: 34, label: 'C'),
        ],
      );

      final frame = PathSeriesTransition.frame(
        from: from,
        to: to,
        progress: 0.5,
      );
      final result = frame.series as LineChartSeries;

      expect(result.points.map((point) => point.label), ['A', 'B', 'C', 'D']);
      expect(result.points.map((point) => point.x), [0.5, 1, 2, 2.5]);
      expect(result.points.map((point) => point.y), [15, 22, 32, 37]);
      expect(frame.targetPointIndices, [0, 1, 2, null]);
    });

    test('inserts an interior Line point from the phase-start path', () {
      const from = LineChartSeries(id: 'line', points: fromPoints);
      const insertedInside = LineChartSeries(
        id: 'line',
        points: [
          ChartDataPoint(x: 0, y: 30, label: 'A'),
          ChartDataPoint(x: 0.5, y: 35, label: 'X'),
          ChartDataPoint(x: 1, y: 40, label: 'B'),
        ],
      );

      expect(PathSeriesTransition.isCompatible(from, insertedInside), isTrue);
      final start = PathSeriesTransition.frame(
        from: from,
        to: insertedInside,
        progress: 0,
      );
      final midpoint = PathSeriesTransition.frame(
        from: from,
        to: insertedInside,
        progress: 0.5,
      );

      expect((start.series as LineChartSeries).points.map((point) => point.y), [
        10,
        15,
        20,
      ]);
      expect(
        (midpoint.series as LineChartSeries).points.map((point) => point.y),
        [20, 25, 30],
      );
      expect(midpoint.targetPointIndices, [0, 1, 2]);
    });

    test('removes an interior Area point onto the target path', () {
      const from = AreaChartSeries(
        id: 'area',
        points: [
          ChartDataPoint(x: 0, y: 10, label: 'A'),
          ChartDataPoint(x: 0.5, y: 50, label: 'X'),
          ChartDataPoint(x: 1, y: 20, label: 'B'),
        ],
      );
      const to = AreaChartSeries(id: 'area', points: toPoints);

      expect(PathSeriesTransition.isCompatible(from, to), isTrue);
      final midpoint = PathSeriesTransition.frame(
        from: from,
        to: to,
        progress: 0.5,
      );
      final result = midpoint.series as AreaChartSeries;

      expect(result.points.map((point) => point.label), ['A', 'X', 'B']);
      expect(result.points.map((point) => point.y), [20, 42.5, 30]);
      expect(midpoint.targetPointIndices, [0, null, 1]);
      expect(PathSeriesTransition.targetIndexForSource(from, to, 1), isNull);
      expect(PathSeriesTransition.targetIndexForSource(from, to, 2), 1);
    });

    test('samples the configured interpolation for an interior insertion', () {
      for (final interpolation in LineInterpolation.values) {
        final from = LineChartSeries(
          id: 'line',
          interpolation: interpolation,
          points: const [
            ChartDataPoint(x: 0, y: 10, label: 'A'),
            ChartDataPoint(x: 1, y: 20, label: 'B'),
            ChartDataPoint(x: 2, y: 10, label: 'C'),
          ],
        );
        final to = from.copyWith(
          points: const [
            ChartDataPoint(x: 0, y: 10, label: 'A'),
            ChartDataPoint(x: 0.5, y: 40, label: 'X'),
            ChartDataPoint(x: 1, y: 20, label: 'B'),
            ChartDataPoint(x: 2, y: 10, label: 'C'),
          ],
        );

        final start =
            PathSeriesTransition.frame(from: from, to: to, progress: 0).series
                as LineChartSeries;

        expect(start.points[1].y, switch (interpolation) {
          LineInterpolation.linear => 15,
          LineInterpolation.stepped => 10,
          LineInterpolation.bezier => closeTo(16.37, 0.01),
          LineInterpolation.monotone => closeTo(17.5, 0.01),
        }, reason: interpolation.name);
      }
    });

    test('supports multiple ordered insertions in one retained segment', () {
      const from = LineChartSeries(id: 'line', points: fromPoints);
      const to = LineChartSeries(
        id: 'line',
        points: [
          ChartDataPoint(x: 0, y: 10, label: 'A'),
          ChartDataPoint(x: 0.25, y: 30, label: 'X'),
          ChartDataPoint(x: 0.75, y: 40, label: 'Y'),
          ChartDataPoint(x: 1, y: 20, label: 'B'),
        ],
      );

      final start = PathSeriesTransition.frame(from: from, to: to, progress: 0);

      expect(PathSeriesTransition.isCompatible(from, to), isTrue);
      expect((start.series as LineChartSeries).points.map((point) => point.y), [
        10,
        12.5,
        17.5,
        20,
      ]);
      expect(start.targetPointIndices, [0, 1, 2, 3]);
    });

    test('rejects mixed interior replacement and retained reordering', () {
      const from = LineChartSeries(
        id: 'line',
        points: [
          ChartDataPoint(x: 0, y: 10, label: 'A'),
          ChartDataPoint(x: 0.33, y: 20, label: 'X'),
          ChartDataPoint(x: 0.66, y: 25, label: 'Z'),
          ChartDataPoint(x: 1, y: 30, label: 'B'),
        ],
      );
      const replacedInside = LineChartSeries(
        id: 'line',
        points: [
          ChartDataPoint(x: 0, y: 15, label: 'A'),
          ChartDataPoint(x: 0.5, y: 25, label: 'Y'),
          ChartDataPoint(x: 1, y: 35, label: 'B'),
        ],
      );
      const reordered = LineChartSeries(
        id: 'line',
        points: [
          ChartDataPoint(x: 1, y: 35, label: 'B'),
          ChartDataPoint(x: 0, y: 15, label: 'A'),
        ],
      );

      expect(PathSeriesTransition.isCompatible(from, replacedInside), isFalse);
      expect(PathSeriesTransition.isCompatible(from, reordered), isFalse);
    });

    test('rejects unbracketed or out-of-segment interior insertion', () {
      const from = LineChartSeries(id: 'line', points: fromPoints);
      const invalidX = LineChartSeries(
        id: 'line',
        points: [
          ChartDataPoint(x: 0, y: 30, label: 'A'),
          ChartDataPoint(x: 2, y: 35, label: 'X'),
          ChartDataPoint(x: 1, y: 40, label: 'B'),
        ],
      );
      const changedInterpolation = LineChartSeries(
        id: 'line',
        points: toPoints,
        interpolation: LineInterpolation.stepped,
      );

      expect(PathSeriesTransition.isCompatible(from, invalidX), isFalse);
      expect(
        PathSeriesTransition.isCompatible(from, changedInterpolation),
        isFalse,
      );
    });

    test('retains the target series when types are incompatible', () {
      const from = LineChartSeries(id: 'series', points: fromPoints);
      const to = AreaChartSeries(id: 'series', points: toPoints);

      expect(
        PathSeriesTransition.interpolate(from: from, to: to, progress: 0.5),
        same(to),
      );
    });
  });
}
