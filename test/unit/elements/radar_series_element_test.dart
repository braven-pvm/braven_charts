import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/radar_series_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadarSeriesElement', () {
    test('shares closed profile geometry across paint and semantic hits', () {
      final series = RadarChartSeries.fromMap(
        id: 'allocated',
        name: 'Allocated budget',
        unit: 'k',
        values: const {
          'Sales': 42,
          'Marketing': 18,
          'Development': 35,
          'Support': 22,
          'Technology': 14,
          'Administration': 10,
        },
      );
      final element = RadarSeriesElement(
        series: series,
        config: const RadarChartConfig(),
        size: const Size(420, 360),
        theme: ChartTheme.light,
        selectedPointIndices: const {2},
      );

      expect(element.profile.vertices, hasLength(6));
      expect(element.profile.closedEdges, hasLength(6));
      expect(element.profile.closedEdges.last.endIndex, 0);
      expect(element.profilePath.computeMetrics(), hasLength(1));
      expect(element.semanticDataHits, hasLength(6));

      final hit = element.dataHitForPointIndex(2)!;
      expect(hit.category, 'Development');
      expect(hit.formattedValue, contains('35'));
      expect(hit.isSelected, isTrue);
      expect(element.dataHitAt(hit.plotPosition)?.pointIndex, 2);

      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size(420, 360));
      expect(recorder.endRecording(), isNotNull);
    });

    test('supports polygon and circular web paths on one shared scale', () {
      RadarSeriesElement build(RadarGridShape shape) => RadarSeriesElement(
        series: RadarChartSeries.fromMap(
          id: shape.name,
          values: const {'A': 20, 'B': 40, 'C': 60, 'D': 80},
        ),
        config: RadarChartConfig(
          radialAxis: RadarNumericAxisConfig(
            maximum: 100,
            tickCount: 5,
            gridShape: shape,
          ),
        ),
        size: const Size.square(320),
        theme: ChartTheme.light,
      );

      final polygon = build(RadarGridShape.polygon);
      final circle = build(RadarGridShape.circle);

      expect(polygon.gridRingPaths, hasLength(5));
      expect(circle.gridRingPaths, hasLength(5));
      expect(
        polygon.gridRingPaths.last.getBounds(),
        equals(circle.gridRingPaths.last.getBounds()),
      );
      expect(
        polygon.boundaryPath.computeMetrics().single.length,
        closeTo(
          polygon.gridRingPaths.last.computeMetrics().single.length,
          1e-6,
        ),
      );
      expect(
        circle.boundaryPath.computeMetrics().single.length,
        closeTo(circle.gridRingPaths.last.computeMetrics().single.length, 1e-6),
      );
      expect(
        polygon.boundaryPath.computeMetrics().single.length,
        isNot(closeTo(circle.boundaryPath.computeMetrics().single.length, 1)),
      );
      expect(polygon.numericScale.maximum, 100);
      expect(circle.numericScale.maximum, 100);
    });

    test('thins dense category labels deterministically at large text', () {
      final element = RadarSeriesElement(
        series: RadarChartSeries.fromMap(
          id: 'dense',
          values: {
            for (var index = 0; index < 36; index++)
              'Capability ${index + 1}': 20 + (index % 70),
          },
        ),
        config: const RadarChartConfig(
          categoryAxis: RadarCategoryAxisConfig(maximumVisibleLabels: 10),
        ),
        size: const Size(300, 260),
        theme: ChartTheme.highContrast,
        textScaleFactor: 1.6,
      );

      expect(element.visibleCategoryLabelIndices, isNotEmpty);
      expect(element.visibleCategoryLabelIndices.first, 0);
      expect(element.visibleCategoryLabelIndices.length, lessThanOrEqualTo(10));
      expect(
        element.visibleCategoryLabelIndices,
        orderedEquals(element.visibleCategoryLabelIndices.toSet()),
      );
      expect(element.semanticDataHits, hasLength(36));

      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size(300, 260));
      expect(recorder.endRecording(), isNotNull);
    });

    test('radial entrance grows from the configured numeric baseline', () {
      RadarSeriesElement build(double progress) => RadarSeriesElement(
        series: RadarChartSeries.fromMap(
          id: 'animated',
          values: const {'A': 40, 'B': 60, 'C': 80},
          radarStyle: const RadarSeriesStyle(
            animationMode: RadarAnimationMode.radial,
          ),
        ),
        config: const RadarChartConfig(
          radialAxis: RadarNumericAxisConfig(minimum: 20, maximum: 100),
        ),
        size: const Size.square(320),
        theme: ChartTheme.light,
        revealProgress: progress,
      );

      final start = build(0);
      final middle = build(0.5);
      final end = build(1);

      for (var index = 0; index < start.profile.vertices.length; index++) {
        final startRadius =
            (start.profile.vertices[index] - start.pane.center).distance;
        final middleRadius =
            (middle.profile.vertices[index] - middle.pane.center).distance;
        final endRadius =
            (end.profile.vertices[index] - end.pane.center).distance;
        expect(startRadius, closeTo(0, 1e-6));
        expect(middleRadius, inInclusiveRange(startRadius, endRadius));
        expect(endRadius, greaterThan(middleRadius));
      }
    });

    test('fade entrance preserves final profile geometry', () {
      RadarSeriesElement build(double progress) => RadarSeriesElement(
        series: RadarChartSeries.fromMap(
          id: 'fade',
          values: const {'A': 40, 'B': 60, 'C': 80},
          radarStyle: const RadarSeriesStyle(
            animationMode: RadarAnimationMode.fade,
          ),
        ),
        config: const RadarChartConfig(
          radialAxis: RadarNumericAxisConfig(maximum: 100),
        ),
        size: const Size.square(320),
        theme: ChartTheme.light,
        fadeProgress: progress,
      );

      expect(build(0).profile.vertices, build(1).profile.vertices);
      expect(build(0).fadeProgress, 0);
      expect(build(1).fadeProgress, 1);
    });

    test('paints portable gradients, shadows, and independent web styles', () {
      final element = RadarSeriesElement(
        series: RadarChartSeries.fromMap(
          id: 'styled',
          color: const Color(0xFF2563EB),
          values: const {'A': 40, 'B': 65, 'C': 80, 'D': 55},
          radarStyle: const RadarSeriesStyle(
            fillOpacity: 0.35,
            gradient: RadarGradientStyle(
              type: RadarGradientType.linear,
              startColor: Color(0xFF22D3EE),
              endColor: Color(0xFF7C3AED),
              angleDegrees: 30,
            ),
            shadow: RadarShadowStyle(
              color: Color(0xFF0F172A),
              blurRadius: 12,
              spreadRadius: 2,
              offset: Offset(4, 5),
              opacity: 0.4,
            ),
          ),
        ),
        config: const RadarChartConfig(
          webStyle: RadarWebStyle(
            ringColor: Color(0xFF14B8A6),
            ringWidth: 2,
            ringDashPattern: <double>[3, 2],
            spokeColor: Color(0xFFF97316),
            spokeWidth: 1.5,
            spokeDashPattern: <double>[6, 3],
            boundaryColor: Color(0xFF111827),
            boundaryWidth: 3,
          ),
        ),
        size: const Size.square(360),
        theme: ChartTheme.light,
      );

      final plain = RadarSeriesElement(
        series: RadarChartSeries.fromMap(
          id: 'plain',
          values: const {'A': 40, 'B': 65, 'C': 80, 'D': 55},
        ),
        config: const RadarChartConfig(),
        size: const Size.square(360),
        theme: ChartTheme.light,
      );
      expect(element.pane.outerRadius, lessThan(plain.pane.outerRadius));
      expect(element.gridRingPaths, hasLength(5));
      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size.square(360));
      expect(recorder.endRecording(), isNotNull);
    });

    test('constrains large shadows and labels inside compact panes', () {
      final element = RadarSeriesElement(
        series: RadarChartSeries.fromMap(
          id: 'compact-elevated',
          values: const {
            'Dimension one': 40,
            'Dimension two': 65,
            'Dimension three': 80,
            'Dimension four': 55,
          },
          radarStyle: const RadarSeriesStyle(
            shadow: RadarShadowStyle(
              blurRadius: 30,
              spreadRadius: 10,
              offset: Offset(12, -12),
            ),
          ),
        ),
        config: const RadarChartConfig(
          categoryAxis: RadarCategoryAxisConfig(labelOffset: 28),
        ),
        size: const Size(170, 140),
        theme: ChartTheme.light,
      );

      expect(element.pane.outerRadius, greaterThan(0));
      expect(element.pane.plotBounds.width, greaterThan(0));
      expect(element.pane.plotBounds.height, greaterThan(0));
    });

    test('keeps all-zero profiles finite on the automatic fallback domain', () {
      final element = RadarSeriesElement(
        series: RadarChartSeries.fromMap(
          id: 'zero-profile',
          values: const {'A': 0, 'B': 0, 'C': 0, 'D': 0},
        ),
        config: const RadarChartConfig(),
        size: const Size(220, 180),
        theme: ChartTheme.light,
      );

      expect(element.numericScale.minimum, 0);
      expect(element.numericScale.maximum, 1);
      expect(
        element.profile.vertices.every(
          (vertex) => vertex.dx.isFinite && vertex.dy.isFinite,
        ),
        isTrue,
      );
      expect(
        element.profile.vertices.every(
          (vertex) => (vertex - element.pane.center).distance < 1e-6,
        ),
        isTrue,
      );
    });
  });
}
