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

    test('solid paints both portable gradient directions', () {
      for (final type in GaugeGradientType.values) {
        final element = GaugeSeriesElement(
          series: GaugeChartSeries.solid(
            id: 'gradient-${type.name}',
            metric: 'Capacity',
            value: 45,
            minimum: 0,
            maximum: 60,
            color: Colors.teal,
            style: SolidGaugeStyle(gradient: GaugeGradientStyle(type: type)),
          ),
          config: const GaugeChartConfig(showTickLabels: false),
          size: const Size.square(360),
          theme: ChartTheme.light,
        );

        final recorder = PictureRecorder();
        element.paint(Canvas(recorder), const Size.square(360));
        expect(recorder.endRecording(), isNotNull);
      }
    });

    test('sweep gradient is safe at zero entrance progress', () {
      final element = GaugeSeriesElement(
        series: GaugeChartSeries.solid(
          id: 'gradient-zero',
          metric: 'Readiness',
          value: 72,
          minimum: 0,
          maximum: 100,
          style: const SolidGaugeStyle(
            gradient: GaugeGradientStyle(type: GaugeGradientType.sweep),
          ),
        ),
        config: const GaugeChartConfig(),
        size: const Size.square(320),
        theme: ChartTheme.light,
        revealProgress: 0,
      );
      final recorder = PictureRecorder();

      expect(
        () => element.paint(Canvas(recorder), const Size.square(320)),
        returnsNormally,
      );
      expect(recorder.endRecording(), isNotNull);
    });

    test('labels remain paintable when tick marks are hidden', () {
      final element = GaugeSeriesElement(
        series: GaugeChartSeries.needle(
          id: 'labels-only',
          metric: 'Quality',
          value: 72,
          minimum: 0,
          maximum: 100,
        ),
        config: const GaugeChartConfig(showTicks: false, showTickLabels: true),
        size: const Size.square(320),
        theme: ChartTheme.light,
      );
      final recorder = PictureRecorder();

      expect(
        () => element.paint(Canvas(recorder), const Size.square(320)),
        returnsNormally,
      );
      expect(recorder.endRecording(), isNotNull);
    });

    test('large scale and reference offsets reserve additional pane space', () {
      final series = GaugeChartSeries.needle(
        id: 'reserved-label-space',
        metric: 'Readiness',
        value: 72,
        minimum: 0,
        maximum: 100,
        target: const GaugeTarget(value: 85, label: 'Release target'),
      );
      final compact = GaugeSeriesElement(
        series: series,
        config: const GaugeChartConfig(),
        size: const Size.square(360),
        theme: ChartTheme.light,
      );
      final spacious = GaugeSeriesElement(
        series: series,
        config: const GaugeChartConfig(
          scale: GaugeScaleStyle(labelOffset: 42, labelMaxWidth: 96),
          references: GaugeReferenceStyle(
            outerLineOffset: 20,
            labelOffset: 32,
            labelMaxWidth: 120,
            showLabelPanel: true,
            panelPadding: 8,
          ),
        ),
        size: const Size.square(360),
        theme: ChartTheme.light,
      );

      expect(spacious.pane.outerRadius, lessThan(compact.pane.outerRadius));
    });

    test('zero label offset clears the arc by the measured text extent', () {
      final element = GaugeSeriesElement(
        series: GaugeChartSeries.solid(
          id: 'zero-offset',
          metric: 'Availability',
          unit: '%',
          value: 99.9,
          minimum: 99,
          maximum: 100,
        ),
        config: const GaugeChartConfig(
          pane: PolarPaneConfig(
            startAngleDegrees: -150,
            sweepAngleDegrees: 300,
            innerRadiusFactor: 0.42,
            outerRadiusFactor: 0.9,
          ),
          scale: GaugeScaleStyle(
            labelStyle: PolarLabelStyle(fontSize: 20),
            labelOffset: 0,
          ),
        ),
        size: const Size(720, 520),
        theme: ChartTheme.light,
      );

      for (final bounds in element.resolvedTickLabelBounds) {
        final nearestPoint = Offset(
          element.pane.center.dx.clamp(bounds.left, bounds.right),
          element.pane.center.dy.clamp(bounds.top, bounds.bottom),
        );
        expect(
          (nearestPoint - element.pane.center).distance,
          greaterThanOrEqualTo(element.pane.outerRadius - 0.01),
        );
      }
    });

    test(
      'dense labels resolve collisions and full-circle seam duplication',
      () {
        final element = GaugeSeriesElement(
          series: GaugeChartSeries.needle(
            id: 'dense-scale',
            metric: 'Load',
            unit: '%',
            value: 60,
            minimum: 0,
            maximum: 100,
          ),
          config: const GaugeChartConfig(
            pane: PolarPaneConfig(
              startAngleDegrees: -90,
              sweepAngleDegrees: 360,
              innerRadiusFactor: 0.45,
              outerRadiusFactor: 0.86,
            ),
            tickCount: 12,
            scale: GaugeScaleStyle(
              labelStyle: PolarLabelStyle(fontSize: 18),
              labelOffset: 0,
            ),
          ),
          size: const Size.square(360),
          theme: ChartTheme.light,
        );

        final labels = element.resolvedTickLabelBounds;
        expect(labels.length, lessThan(12));
        for (var left = 0; left < labels.length; left++) {
          for (var right = left + 1; right < labels.length; right++) {
            expect(
              labels[left].inflate(2).overlaps(labels[right].inflate(2)),
              isFalse,
            );
          }
        }
      },
    );

    test('reference labels take priority over colliding scale labels', () {
      final element = GaugeSeriesElement(
        series: GaugeChartSeries.needle(
          id: 'reference-collision',
          metric: 'Capacity',
          unit: '%',
          value: 64,
          minimum: 0,
          maximum: 100,
          target: const GaugeTarget(value: 80, label: 'SLO'),
          thresholds: const [GaugeThreshold(value: 81, label: 'Alert')],
        ),
        config: const GaugeChartConfig(
          pane: PolarPaneConfig(
            startAngleDegrees: 0,
            sweepAngleDegrees: 180,
            innerRadiusFactor: 0.5,
            outerRadiusFactor: 0.88,
          ),
          scale: GaugeScaleStyle(
            labelStyle: PolarLabelStyle(fontSize: 20),
            labelOffset: 0,
          ),
          references: GaugeReferenceStyle(labelOffset: 0),
        ),
        size: const Size(640, 420),
        theme: ChartTheme.light,
      );

      final references = element.resolvedReferenceLabelBounds;
      final ticks = element.resolvedTickLabelBounds;
      expect(references, isNotEmpty);
      for (final reference in references) {
        for (final tick in ticks) {
          expect(reference.inflate(2).overlaps(tick.inflate(2)), isFalse);
        }
      }
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
