import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/gauge_series_element.dart';
import 'package:braven_charts/src/models/gauge_chart_config.dart';
import 'package:braven_charts/src/models/gauge_chart_series.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GaugeSeriesElement', () {
    test('needle shares one measurement across paint and interaction', () {
      final series = GaugeChartSeries.needle(
        id: 'uptime',
        metric: 'Uptime',
        unit: '%',
        value: 82,
        minimum: 0,
        maximum: 100,
        target: const GaugeTarget(value: 90, label: 'SLO'),
        zones: const [
          GaugeZone(from: 0, to: 60, status: 'At risk', color: Colors.red),
          GaugeZone(from: 60, to: 100, status: 'Healthy', color: Colors.green),
        ],
      );
      final element = GaugeSeriesElement(
        series: series,
        config: const GaugeChartConfig(),
        size: const Size(420, 320),
        theme: ChartTheme.light,
        focusedPointIndices: const {0},
      );

      expect(element.geometry.needle, isNotNull);
      expect(element.geometry.solid, isNull);
      expect(element.semanticDataHits, hasLength(1));
      expect(element.resolvedIndicatorColor, Colors.green);
      final hit = element.dataHitForPointIndex(0)!;
      expect(hit.category, 'Uptime');
      expect(hit.formattedValue, contains('82'));
      expect(
        hit.semanticLabel,
        allOf(
          contains('Uptime'),
          contains('range 0 % to 100 %'),
          contains('Healthy'),
          contains('SLO 90 %'),
        ),
      );
      expect(hit.isActivatable, isFalse);
      expect(hit.semanticLabel, isNot(contains('not selected')));
      expect(hit.isFocused, isTrue);
      expect(element.dataHitAt(hit.plotPosition), isNotNull);

      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size(420, 320));
      expect(recorder.endRecording(), isNotNull);
    });

    test('solid uses an annular progress mark with widened lookup', () {
      final element = GaugeSeriesElement(
        series: GaugeChartSeries.solid(
          id: 'capacity',
          metric: 'Capacity',
          value: 45,
          minimum: 0,
          maximum: 60,
          thresholds: const [GaugeThreshold(value: 50, label: 'Alert')],
        ),
        config: const GaugeChartConfig(
          showTickLabels: false,
          center: GaugeCenterConfig(showTarget: true),
        ),
        size: const Size.square(360),
        theme: ChartTheme.dark,
      );

      expect(element.geometry.solid, isNotNull);
      expect(element.geometry.needle, isNull);
      expect(element.geometry.normalizedProgress, closeTo(0.75, 1e-9));
      expect(element.dataHitAt(element.geometry.tooltipAnchor), isNotNull);
      expect(element.dataHitForPointIndex(1), isNull);

      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size.square(360));
      expect(recorder.endRecording(), isNotNull);
    });

    test('interaction copies preserve high-contrast zone treatment', () {
      final element = GaugeSeriesElement(
        series: GaugeChartSeries.needle(
          id: 'load',
          metric: 'Load',
          value: 72,
          minimum: 0,
          maximum: 100,
          zones: const [
            GaugeZone(from: 0, to: 60, status: 'Healthy'),
            GaugeZone(from: 60, to: 100, status: 'Elevated'),
          ],
        ),
        config: const GaugeChartConfig(),
        size: const Size.square(360),
        theme: ChartTheme.highContrast,
        highContrast: true,
      );

      final hovered = element.copyWith(isHovered: true);
      expect(hovered.highContrast, isTrue);
      expect(hovered.isHovered, isTrue);
    });
  });
}
