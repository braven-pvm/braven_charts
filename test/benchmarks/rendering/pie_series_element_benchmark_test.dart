// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/pie_series_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PieSeriesElement rendering benchmarks', () {
    for (final labelsVisible in [false, true]) {
      test(
        '${labelsVisible ? 'outside labels' : 'labels disabled'} stays within one frame',
        () {
          const size = Size(800, 600);
          final series = PieChartSeries.fromMap(
            id: labelsVisible ? 'pie-labels' : 'pie-no-labels',
            unit: 'units',
            values: {
              for (var index = 0; index < 24; index++)
                'Category ${index + 1}': 8 + (index % 7),
            },
            dataLabels: PieDataLabelConfig(
              isVisible: labelsVisible,
              position: PieDataLabelPosition.outside,
              content: PieDataLabelContent.categoryAndPercentage,
              minimumShare: 0,
              minimumSweepDegrees: 0,
              collisionStrategy: PieDataLabelCollisionStrategy.shiftAndHide,
            ),
          );
          final element = PieSeriesElement(
            series: series,
            size: size,
            theme: ChartTheme.light,
          );

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
            'Pie paint (${labelsVisible ? 'outside labels' : 'labels disabled'}, '
            '${series.points.length} slices): '
            '${averageMilliseconds.toStringAsFixed(3)}ms average',
          );
          expect(
            averageMilliseconds,
            lessThan(16.67),
            reason:
                'A cached pie element must paint inside the 60fps frame budget.',
          );
        },
      );
    }
  });
}

void _paint(PieSeriesElement element, Size size) {
  final recorder = PictureRecorder();
  element.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}
