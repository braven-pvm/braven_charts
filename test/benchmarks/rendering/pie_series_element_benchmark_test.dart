// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/pie_series_element.dart';
import 'package:flutter/painting.dart';
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

    test('advanced elevation and callouts stay within one frame', () {
      const size = Size(800, 600);
      final series = PieChartSeries.fromMap(
        id: 'pie-advanced',
        unit: 'units',
        values: const {
          'Category 1': 8,
          'Category 2': 9,
          'Category 3': 10,
          'Category 4': 11,
          'Category 5': 12,
          'Category 6': 8,
          'Category 7': 9,
          'Category 8': 10,
          'Category 9': 11,
          'Category 10': 12,
          'Category 11': 8,
          'Category 12': 9,
        },
        pieStyle: const PieChartStyle(sliceGap: 6, cornerRadius: 10),
        dataLabels: const PieDataLabelConfig(
          position: PieDataLabelPosition.outside,
          content: PieDataLabelContent.categoryAndPercentage,
          minimumShare: 0,
          minimumSweepDegrees: 0,
          collisionStrategy: PieDataLabelCollisionStrategy.shiftAndHide,
          calloutStyle: LabelStyle(
            textStyle: TextStyle(color: Color(0xFF1A1A1A), fontSize: 11),
            backgroundColor: Color(0xF2FFFFFF),
            borderColor: Color(0xFF94A3B8),
            borderWidth: 1,
            borderRadius: 8,
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shadowColor: Color(0x331A1A1A),
            shadowBlurRadius: 5,
          ),
        ),
      );
      final theme = ChartTheme.light.copyWith(
        pieChartTheme: const PieChartTheme(
          shadow: PieElevationStyle(
            color: Color(0x401A1A1A),
            blurRadius: 8,
            offset: Offset(0, 4),
            opacity: 0.7,
          ),
          selectedElevation: PieElevationStyle(
            blurRadius: 12,
            spreadRadius: 2,
            opacity: 0.5,
          ),
          animationMode: PieAnimationMode.none,
        ),
      );
      final element = PieSeriesElement(
        series: series,
        size: size,
        theme: theme,
        selectedPointIndices: const {0},
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
        'Pie paint (advanced elevation/callouts, ${series.points.length} '
        'slices): ${averageMilliseconds.toStringAsFixed(3)}ms average',
      );

      expect(averageMilliseconds, lessThan(16.67));
    });
  });
}

void _paint(PieSeriesElement element, Size size) {
  final recorder = PictureRecorder();
  element.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}
