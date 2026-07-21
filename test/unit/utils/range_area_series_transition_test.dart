// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/utils/path_series_transition.dart';
import 'package:braven_charts/src/utils/range_area_series_transition.dart';
import 'package:flutter_test/flutter_test.dart';

RangeAreaChartSeries _range(
  List<RangeAreaDataPoint> points, {
  LineInterpolation interpolation = LineInterpolation.monotone,
}) => RangeAreaChartSeries(
  id: 'band',
  points: points,
  interpolation: interpolation,
  pathAnimation: const PathAnimationStyle(
    dataUpdateMode: PathDataUpdateAnimationMode.interpolate,
  ),
);

void main() {
  test('interpolates x low and high atomically', () {
    final from = _range([
      RangeAreaDataPoint(x: 0, low: 2, high: 8),
      RangeAreaDataPoint(x: 10, low: 4, high: 14),
    ]);
    final to = _range([
      RangeAreaDataPoint(x: 2, low: 6, high: 12),
      RangeAreaDataPoint(x: 12, low: 8, high: 18),
    ]);

    final frame = RangeAreaSeriesTransition.interpolate(
      from: from,
      to: to,
      progress: 0.5,
    );
    expect(frame.intervalAt(0).x, 1);
    expect(frame.intervalAt(0).low, 4);
    expect(frame.intervalAt(0).high, 10);
    expect(frame.intervalAt(0).midpoint, 7);
    expect(
      frame.intervalAt(1).low,
      lessThanOrEqualTo(frame.intervalAt(1).high!),
    );
  });

  test('gap entry and exit never create an inverted interval', () {
    final from = _range([
      RangeAreaDataPoint(x: 0, low: 2, high: 8),
      RangeAreaDataPoint.gap(x: 10),
    ]);
    final to = _range([
      RangeAreaDataPoint.gap(x: 1),
      RangeAreaDataPoint(x: 11, low: 5, high: 15),
    ]);

    for (final progress in [0.0, 0.25, 0.5, 0.75]) {
      final frame = RangeAreaSeriesTransition.interpolate(
        from: from,
        to: to,
        progress: progress,
      );
      for (final point in frame.intervals) {
        if (point.isGap) continue;
        expect(point.low, lessThanOrEqualTo(point.high!));
        expect(point.y, (point.low! + point.high!) / 2);
      }
    }
    expect(
      RangeAreaSeriesTransition.interpolate(from: from, to: to, progress: 1),
      same(to),
    );
  });

  test('shared path transition delegates Range Area frames', () {
    final from = _range([RangeAreaDataPoint(x: 0, low: 2, high: 8)]);
    final to = _range([RangeAreaDataPoint(x: 0, low: 6, high: 14)]);

    expect(PathSeriesTransition.isCompatible(from, to), isTrue);
    final frame = PathSeriesTransition.frame(from: from, to: to, progress: 0.5);
    final series = frame.series as RangeAreaChartSeries;
    expect(series.intervalAt(0).low, 4);
    expect(series.intervalAt(0).high, 11);
    expect(frame.pointMap.targetIndexForRenderIndex(0), 0);
  });
}
