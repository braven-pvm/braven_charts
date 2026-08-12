// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/radar_series_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('12-profile x 64-category Radar paint stays within one frame', () {
    const size = Size(900, 700);
    const profileCount = 12;
    const categoryCount = 64;
    final categories = List<String>.generate(
      categoryCount,
      (index) => 'Capability ${index + 1}',
    );
    final elements = <RadarSeriesElement>[
      for (var profileIndex = 0; profileIndex < profileCount; profileIndex++)
        RadarSeriesElement(
          series: RadarChartSeries.fromMap(
            id: 'radar-profile-$profileIndex',
            values: {
              for (final (categoryIndex, category) in categories.indexed)
                category: 10 + ((categoryIndex * 17 + profileIndex * 11) % 91),
            },
            radarStyle: const RadarSeriesStyle(
              fillOpacity: 0.08,
              showMarkers: false,
              showDataLabels: false,
            ),
          ),
          config: const RadarChartConfig(
            categoryAxis: RadarCategoryAxisConfig(
              showLabels: false,
              maximumVisibleLabels: 24,
            ),
            radialAxis: RadarNumericAxisConfig(maximum: 100, showLabels: false),
          ),
          size: size,
          theme: ChartTheme.light,
        ),
    ];

    expect(elements, hasLength(profileCount));
    expect(
      elements.expand((element) => element.semanticDataHits),
      hasLength(profileCount * categoryCount),
    );

    for (var index = 0; index < 10; index++) {
      _paint(elements, size);
    }

    const iterations = 100;
    final stopwatch = Stopwatch()..start();
    for (var index = 0; index < iterations; index++) {
      _paint(elements, size);
    }
    stopwatch.stop();

    final averageMilliseconds =
        stopwatch.elapsedMicroseconds / iterations / 1000;
    print(
      'Radar paint (12 profiles x 64 categories): '
      '${averageMilliseconds.toStringAsFixed(3)}ms average',
    );
    expect(
      averageMilliseconds,
      lessThan(16.67),
      reason:
          'A cached 12-profile x 64-category Radar composition must paint '
          'inside the 60fps frame budget.',
    );
  });
}

void _paint(List<RadarSeriesElement> elements, Size size) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  for (final element in elements) {
    element.paint(canvas, size);
  }
  recorder.endRecording().dispose();
}
