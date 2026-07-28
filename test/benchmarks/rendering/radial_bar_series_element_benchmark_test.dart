// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/radial_bar_series_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('512-track Radial Bar fills stay within one frame', () {
    const size = Size(900, 700);
    for (final (name, gradient) in <(String, RadialBarGradientStyle?)>[
      ('solid', null),
      (
        'arc gradient',
        const RadialBarGradientStyle(type: RadialBarGradientType.sweep),
      ),
      (
        'track gradient',
        const RadialBarGradientStyle(type: RadialBarGradientType.radial),
      ),
    ]) {
      final series = RadialBarChartSeries.fromMap(
        id: 'dense-radial-bar-$name',
        unit: '%',
        values: {
          for (var index = 0; index < 512; index++)
            'Category ${index + 1}': 20 + ((index * 37) % 81),
        },
        radialBarStyle: RadialBarStyle(
          showDataLabels: false,
          gradient: gradient,
        ),
      );
      final element = RadialBarSeriesElement(
        series: series,
        config: const RadialBarChartConfig(
          trackGap: 2,
          showCategoryLabels: false,
          showScaleLabels: false,
          showGridLines: false,
        ),
        size: size,
        theme: ChartTheme.light,
      );

      expect(element.geometry.marks, hasLength(512));
      expect(element.semanticDataHits, hasLength(512));

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
        'Radial Bar paint (512 tracks, $name, labels hidden): '
        '${averageMilliseconds.toStringAsFixed(3)}ms average',
      );
      expect(
        averageMilliseconds,
        lessThan(16.67),
        reason:
            'A cached dense Radial Bar element with $name must paint inside '
            'the 60fps frame budget.',
      );
    }
  });
}

void _paint(RadialBarSeriesElement element, Size size) {
  final recorder = PictureRecorder();
  element.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}
