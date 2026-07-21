// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/interaction/core/crosshair_tracker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final series = RangeAreaChartSeries(
    id: 'range-performance',
    interpolation: LineInterpolation.monotone,
    points: [
      for (var index = 0; index < 50000; index++)
        RangeAreaDataPoint(
          x: index.toDouble(),
          low: 40 + math.sin(index / 31) * 8,
          high: 60 + math.sin(index / 31) * 8 + math.cos(index / 17) * 3,
        ),
    ],
  );

  test('50,000-interval typed tracking remains below 1 ms at p95', () {
    for (var warmup = 0; warmup < 200; warmup++) {
      _track(series, warmup % 1600);
    }

    final samples = <int>[];
    for (var iteration = 0; iteration < 1000; iteration++) {
      final stopwatch = Stopwatch()..start();
      final state = _track(series, (iteration * 37) % 1600);
      stopwatch.stop();
      expect(state!.seriesValues.single.rangeArea, isNotNull);
      samples.add(stopwatch.elapsedMicroseconds);
    }
    samples.sort();
    final p95 = samples[(samples.length * 0.95).ceil() - 1];
    final median = samples[samples.length ~/ 2];

    // ignore: avoid_print
    print(
      'Range Area tracking (50,000 intervals): '
      'median ${(median / 1000).toStringAsFixed(3)}ms; '
      'p95 ${(p95 / 1000).toStringAsFixed(3)}ms',
    );
    expect(
      p95,
      lessThan(1000),
      reason: 'typed low/high tracking must remain below 1 ms at p95',
    );
  });
}

CrosshairTrackingState? _track(RangeAreaChartSeries series, num screenX) =>
    CrosshairTracker.calculateTrackingState(
      screenX: screenX.toDouble(),
      chartBounds: const Rect.fromLTWH(0, 0, 1600, 900),
      xMin: 0,
      xMax: 49999,
      seriesList: [series],
    );
