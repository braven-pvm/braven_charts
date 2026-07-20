// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/polar_column_series_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('512-category Polar Column warm paint stays within one frame', () {
    const size = Size(900, 700);
    final series = PolarColumnChartSeries.fromMap(
      id: 'dense-polar-column',
      unit: 'events',
      values: {
        for (var index = 0; index < 512; index++)
          'Category ${index + 1}': 20 + ((index * 37) % 81),
      },
      polarStyle: const PolarColumnStyle(
        showDataLabels: true,
        maximumVisibleDataLabels: 24,
      ),
    );
    final element = PolarColumnSeriesElement(
      series: series,
      config: const PolarChartConfig(
        angularAxis: PolarCategoryAxisConfig(
          maximumVisibleLabels: 24,
          maximumVisibleGridLines: 72,
        ),
      ),
      size: size,
      theme: ChartTheme.light,
    );

    expect(element.geometry.marks, hasLength(512));
    expect(element.semanticDataHits, hasLength(512));
    expect(element.visibleAngularLabelIndices.length, lessThanOrEqualTo(24));
    expect(element.visibleAngularGridIndices.length, lessThanOrEqualTo(72));
    expect(element.visibleDataLabelIndices.length, lessThanOrEqualTo(24));

    for (var index = 0; index < 10; index++) {
      _paint(element, size);
    }

    const iterations = 100;
    final stopwatch = Stopwatch()..start();
    for (var index = 0; index < iterations; index++) {
      _paint(element, size);
    }
    stopwatch.stop();

    final averageMilliseconds =
        stopwatch.elapsedMicroseconds / iterations / 1000;
    print(
      'Polar Column paint (512 marks, adaptive density): '
      '${averageMilliseconds.toStringAsFixed(3)}ms average',
    );
    expect(
      averageMilliseconds,
      lessThan(16.67),
      reason:
          'A cached dense Polar Column element must paint inside the 60fps '
          'frame budget.',
    );
  });
}

void _paint(PolarColumnSeriesElement element, Size size) {
  final recorder = PictureRecorder();
  element.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}
