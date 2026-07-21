// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/interaction/core/crosshair_tracker.dart';
import 'package:braven_charts/src/utils/interpolation_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

RangeAreaChartSeries _series({
  LineInterpolation interpolation = LineInterpolation.linear,
  bool connectGaps = false,
  List<RangeAreaDataPoint>? points,
}) => RangeAreaChartSeries(
  id: 'range',
  name: 'Expected interval',
  unit: '°C',
  interpolation: interpolation,
  connectGaps: connectGaps,
  points:
      points ??
      [
        RangeAreaDataPoint(x: 0, low: 0, high: 10),
        RangeAreaDataPoint(x: 10, low: 10, high: 20),
        RangeAreaDataPoint(x: 20, low: 4, high: 16),
      ],
);

void main() {
  test('tracking carries exact low/high values instead of midpoint only', () {
    final state = CrosshairTracker.calculateTrackingState(
      screenX: 50,
      chartBounds: const Rect.fromLTWH(0, 0, 100, 100),
      xMin: 0,
      xMax: 20,
      seriesList: [_series()],
    );

    final tracked = state!.seriesValues.single;
    expect(tracked.x, 10);
    expect(tracked.y, 15);
    expect(tracked.rangeArea!.low, 10);
    expect(tracked.rangeArea!.high, 20);
    expect(tracked.rangeArea!.formattedSpan, '10.00 °C');
  });

  test('tracking uses the renderer interpolation descriptors', () {
    for (final interpolation in LineInterpolation.values) {
      final series = _series(interpolation: interpolation);
      final details = CrosshairTracker.interpolatedRangeAt(
        series: series,
        targetX: 6,
      )!;
      final points = series.intervals;
      final expectedLow = InterpolationGeometry.interpolateYForX(
        points: points,
        startIndex: 0,
        targetX: 6,
        interpolation: interpolation,
        getX: (point) => point.x,
        getY: (point) => point.low!,
        tension: series.tension,
      );
      final expectedHigh = InterpolationGeometry.interpolateYForX(
        points: points,
        startIndex: 0,
        targetX: 6,
        interpolation: interpolation,
        getX: (point) => point.x,
        getY: (point) => point.high!,
        tension: series.tension,
      );

      expect(details.low, closeTo(expectedLow, 1e-9));
      expect(details.high, closeTo(expectedHigh, 1e-9));
      expect(details.midpoint, closeTo((expectedLow + expectedHigh) / 2, 1e-9));
    }
  });

  test('disconnected gap has no interpolated value', () {
    final series = _series(
      points: [
        RangeAreaDataPoint(x: 0, low: 0, high: 10),
        RangeAreaDataPoint.gap(x: 1),
        RangeAreaDataPoint(x: 2, low: 4, high: 14),
      ],
    );

    expect(
      CrosshairTracker.interpolatedRangeAt(series: series, targetX: 1.5),
      isNull,
    );
  });

  test('connectGaps tracks the same joined interval painted by geometry', () {
    final series = _series(
      connectGaps: true,
      points: [
        RangeAreaDataPoint(x: 0, low: 0, high: 10),
        RangeAreaDataPoint.gap(x: 1),
        RangeAreaDataPoint(x: 2, low: 4, high: 14),
      ],
    );

    final details = CrosshairTracker.interpolatedRangeAt(
      series: series,
      targetX: 1,
    )!;
    expect(details.low, 2);
    expect(details.high, 12);
  });

  test('snap mode skips a gap and returns an actual interval', () {
    final state = CrosshairTracker.calculateTrackingState(
      screenX: 50,
      chartBounds: const Rect.fromLTWH(0, 0, 100, 100),
      xMin: 0,
      xMax: 2,
      interpolate: false,
      seriesList: [
        _series(
          points: [
            RangeAreaDataPoint(x: 0, low: 0, high: 10),
            RangeAreaDataPoint.gap(x: 1),
            RangeAreaDataPoint(x: 2, low: 4, high: 14),
          ],
        ),
      ],
    );

    expect(state, isNull, reason: 'an exact gap is intentionally empty');

    final adjacent = CrosshairTracker.calculateTrackingState(
      screenX: 55,
      chartBounds: const Rect.fromLTWH(0, 0, 100, 100),
      xMin: 0,
      xMax: 2,
      interpolate: false,
      seriesList: [
        _series(
          points: [
            RangeAreaDataPoint(x: 0, low: 0, high: 10),
            RangeAreaDataPoint.gap(x: 1),
            RangeAreaDataPoint(x: 2, low: 4, high: 14),
          ],
        ),
      ],
    );
    expect(adjacent!.seriesValues.single.x, 2);
  });
}
