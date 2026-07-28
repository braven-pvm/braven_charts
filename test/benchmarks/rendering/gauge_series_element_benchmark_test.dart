// Copyright 2026 Braven Charts
// SPDX-License-Identifier: MIT

// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/gauge_series_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fully decorated Gauge warm paint stays within one frame', () {
    const size = Size(520, 420);
    final series = GaugeChartSeries.needle(
      id: 'benchmark-gauge',
      metric: 'Response latency',
      unit: 'ms',
      value: 184,
      minimum: 0,
      maximum: 300,
      target: const GaugeTarget(value: 120, label: 'Target'),
      thresholds: const [
        GaugeThreshold(value: 200, label: 'Limit'),
        GaugeThreshold(value: 250, label: 'Critical'),
      ],
      zones: [
        for (var index = 0; index < 12; index++)
          GaugeZone(
            from: index * 25,
            to: (index + 1) * 25,
            status: 'Band ${index + 1}',
          ),
      ],
    );
    final element = GaugeSeriesElement(
      series: series,
      config: const GaugeChartConfig(
        tickCount: 12,
        minorTicksPerInterval: 10,
        scale: GaugeScaleStyle(
          tickPosition: GaugeTickPosition.inside,
          labelPosition: GaugeScaleLabelPosition.outside,
        ),
        zones: GaugeZoneStyle(gap: 2, cornerRadius: 2, borderWidth: 1),
        center: GaugeCenterConfig(showTarget: true),
      ),
      size: size,
      theme: ChartTheme.light,
    );

    expect(element.geometry.zones, hasLength(12));
    expect(element.geometry.ticks, hasLength(12 + 11 * 10));
    expect(element.semanticDataHits, hasLength(1));

    for (var index = 0; index < 10; index++) {
      _paint(element, size);
    }

    const iterations = 200;
    final stopwatch = Stopwatch()..start();
    for (var index = 0; index < iterations; index++) {
      _paint(element, size);
    }
    stopwatch.stop();

    final averageMilliseconds =
        stopwatch.elapsedMicroseconds / iterations / 1000;
    print(
      'Gauge paint (12 zones, 122 ticks, 2 references, center labels): '
      '${averageMilliseconds.toStringAsFixed(3)}ms average',
    );
    expect(
      averageMilliseconds,
      lessThan(16.67),
      reason:
          'A fully decorated cached Gauge element must paint inside the '
          '60fps frame budget.',
    );
  });
}

void _paint(GaugeSeriesElement element, Size size) {
  final recorder = PictureRecorder();
  element.paint(Canvas(recorder), size);
  recorder.endRecording().dispose();
}
