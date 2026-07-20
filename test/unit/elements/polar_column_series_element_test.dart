import 'dart:math' as math;
import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/elements/polar_column_series_element.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PolarColumnSeriesElement', () {
    test('shares geometry across paint, hit testing, and semantic data', () {
      final series = PolarColumnChartSeries.fromMap(
        id: 'polar-column',
        unit: 'tickets',
        values: const {'Search': 64, 'Social': 18, 'Partners': 32},
      );
      final element = PolarColumnSeriesElement(
        series: series,
        config: const PolarChartConfig(),
        size: const Size(360, 300),
        theme: ChartTheme.light,
        selectedPointIndices: const {1},
      );

      expect(element.geometry.marks, hasLength(3));
      expect(element.semanticDataHits, hasLength(3));
      final hit = element.dataHitForPointIndex(1)!;
      expect(hit.category, 'Social');
      expect(hit.formattedValue, contains('18'));
      expect(hit.isSelected, isTrue);
      expect(element.dataHitAt(hit.plotPosition)?.pointIndex, 1);

      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size(360, 300));
      expect(recorder.endRecording(), isNotNull);
    });

    test('Rose preset resolves an area-correct radial scale', () {
      final element = PolarColumnSeriesElement(
        series: PolarColumnChartSeries.rose(
          id: 'rose',
          values: const {'North': 9, 'East': 4, 'South': 1},
        ),
        config: const PolarChartConfig(),
        size: const Size.square(320),
        theme: ChartTheme.light,
      );

      expect(element.numericScale.mode.name, 'areaCorrect');
      expect(
        element.geometry.hitTest(element.geometry.marks.first.tooltipAnchor),
        isNotNull,
      );
    });

    test('compatible layers share one numeric domain and series colors', () {
      final target = PolarColumnSeriesElement(
        series: PolarColumnChartSeries.fromMap(
          id: 'target',
          values: const {'Search': 100, 'Social': 80},
        ),
        config: const PolarChartConfig(),
        size: const Size.square(320),
        theme: ChartTheme.light,
        seriesIndex: 0,
        numericScaleValues: const [100, 80, 64, 48],
        paintAxisLabels: false,
        preferSeriesColor: true,
      );
      final observed = PolarColumnSeriesElement(
        series: PolarColumnChartSeries.fromMap(
          id: 'observed',
          values: const {'Search': 64, 'Social': 48},
        ),
        config: const PolarChartConfig(),
        size: const Size.square(320),
        theme: ChartTheme.light,
        seriesIndex: 1,
        numericScaleValues: const [100, 80, 64, 48],
        paintGrid: false,
        preferSeriesColor: true,
      );

      expect(target.numericScale.maximum, 100);
      expect(observed.numericScale.maximum, 100);
      expect(target.paintGrid, isTrue);
      expect(target.paintAxisLabels, isFalse);
      expect(observed.paintGrid, isFalse);
      expect(observed.paintAxisLabels, isTrue);
      expect(target.resolvedMarkColors.toSet(), {
        ChartTheme.light.seriesTheme.colors[0],
      });
      expect(observed.resolvedMarkColors.toSet(), {
        ChartTheme.light.seriesTheme.colors[1],
      });
    });

    test('thins dense angular labels deterministically at large text', () {
      final element = PolarColumnSeriesElement(
        series: PolarColumnChartSeries.fromMap(
          id: 'dense',
          values: {
            for (var index = 0; index < 16; index++)
              'Category ${index + 1}': 12 + index,
          },
        ),
        config: const PolarChartConfig(),
        size: const Size(280, 240),
        theme: ChartTheme.highContrast,
        textScaleFactor: 1.6,
      );

      expect(element.textScaleFactor, 1.6);
      expect(element.visibleAngularLabelIndices, isNotEmpty);
      expect(element.visibleAngularLabelIndices.first, 0);
      expect(element.visibleAngularLabelIndices.length, lessThan(16));
      expect(element.visibleDataLabelIndices.length, lessThan(16));
      expect(
        element.visibleAngularLabelIndices,
        orderedEquals(element.visibleAngularLabelIndices.toSet()),
      );
      expect(element.semanticDataHits, hasLength(16));
    });

    test('caps only painted density while preserving every mark', () {
      final element = PolarColumnSeriesElement(
        series: PolarColumnChartSeries.fromMap(
          id: 'dense-capped',
          values: {
            for (var index = 0; index < 96; index++)
              'Category ${index + 1}': 40 + (index % 50),
          },
          polarStyle: const PolarColumnStyle(maximumVisibleDataLabels: 6),
        ),
        config: const PolarChartConfig(
          angularAxis: PolarCategoryAxisConfig(
            maximumVisibleLabels: 8,
            maximumVisibleGridLines: 12,
          ),
        ),
        size: const Size(720, 520),
        theme: ChartTheme.light,
      );

      expect(element.geometry.marks, hasLength(96));
      expect(element.semanticDataHits, hasLength(96));
      expect(element.visibleAngularLabelIndices.length, lessThanOrEqualTo(8));
      expect(element.visibleAngularGridIndices.length, lessThanOrEqualTo(12));
      expect(element.visibleDataLabelIndices.length, lessThanOrEqualTo(6));
      expect(element.visibleAngularLabelIndices.first, 0);
      expect(element.visibleAngularGridIndices.first, 0);
    });

    test('keeps zero-valued categories in semantic navigation', () {
      final element = PolarColumnSeriesElement(
        series: PolarColumnChartSeries.fromMap(
          id: 'zero-value',
          unit: 'orders',
          values: const {'Zero': 0, 'Visible': 10},
        ),
        config: const PolarChartConfig(),
        size: const Size.square(320),
        theme: ChartTheme.light,
      );

      expect(element.geometry.marks.first.isVisible, isFalse);
      final semanticHits = element.semanticDataHits.toList();
      expect(semanticHits, hasLength(2));
      expect(semanticHits.first.category, 'Zero');
      expect(semanticHits.first.formattedValue, contains('0 orders'));
      expect(semanticHits.first.semanticBounds.isEmpty, isFalse);
      expect(
        element.dataHitAt(semanticHits.first.plotPosition)?.pointIndex,
        isNot(0),
      );
    });

    test(
      'resolves independent category, value, and radial label positions',
      () {
        PolarColumnSeriesElement build({
          double categoryOffset = 0,
          double dataPosition = 0.5,
          PolarRadialLabelPosition radialPosition =
              PolarRadialLabelPosition.start,
          double radialAngleOffset = 0,
        }) => PolarColumnSeriesElement(
          series: PolarColumnChartSeries.fromMap(
            id: 'labels',
            values: const {'Search': 60, 'Social': 40},
            polarStyle: PolarColumnStyle(dataLabelRadialPosition: dataPosition),
          ),
          config: PolarChartConfig(
            pane: const PolarPaneConfig(
              startAngleDegrees: -90,
              sweepAngleDegrees: 240,
            ),
            angularAxis: PolarCategoryAxisConfig(labelOffset: categoryOffset),
            radialAxis: PolarNumericAxisConfig(
              labelPosition: radialPosition,
              labelAngleOffsetDegrees: radialAngleOffset,
            ),
          ),
          size: const Size.square(360),
          theme: ChartTheme.light,
        );

        final inward = build(dataPosition: 0.25);
        final outward = build(dataPosition: 0.75);
        expect(
          (outward.dataLabelAnchorForPoint(0) - outward.pane.center).distance,
          greaterThan(
            (inward.dataLabelAnchorForPoint(0) - inward.pane.center).distance,
          ),
        );

        final tight = build(categoryOffset: 0);
        final spaced = build(categoryOffset: 24);
        expect(
          (spaced.categoryLabelAnchorForPoint(0) - spaced.pane.center).distance,
          greaterThan(
            (tight.categoryLabelAnchorForPoint(0) - tight.pane.center).distance,
          ),
        );

        final radial = build(
          radialPosition: PolarRadialLabelPosition.middle,
          radialAngleOffset: 15,
        );
        expect(
          radial.resolvedRadialLabelAngle,
          closeTo((-90 + 120 + 15) * math.pi / 180, 1e-9),
        );
      },
    );

    test('paints gradient, elevation, and fade entrance together', () {
      final element = PolarColumnSeriesElement(
        series: PolarColumnChartSeries.fromMap(
          id: 'appearance',
          values: const {'Search': 64, 'Social': 38},
          polarStyle: const PolarColumnStyle(
            gradient: PolarColumnGradientStyle(
              startColor: Color(0xFF22D3EE),
              endColor: Color(0xFF4338CA),
            ),
            shadow: PolarColumnShadowStyle(
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 4),
            ),
            animationMode: PolarColumnAnimationMode.fade,
          ),
        ),
        config: const PolarChartConfig(),
        size: const Size.square(320),
        theme: ChartTheme.dark,
        fadeProgress: 0.45,
      );

      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size.square(320));
      expect(recorder.endRecording(), isNotNull);
      expect(element.fadeProgress, 0.45);
    });

    test('applies the themed dash pattern to Polar grid contours', () {
      final dashedTheme = ChartTheme.light.copyWith(
        gridStyle: ChartTheme.light.gridStyle.copyWith(
          majorDashPattern: const <double>[4, 3],
        ),
      );
      final dashed = PolarColumnSeriesElement(
        series: PolarColumnChartSeries.fromMap(
          id: 'dashed-grid',
          values: const {'North': 12, 'East': 24, 'South': 18},
        ),
        config: const PolarChartConfig(),
        size: const Size.square(320),
        theme: dashedTheme,
      );
      final source = Path()
        ..addOval(Rect.fromCircle(center: const Offset(160, 160), radius: 90));
      final sourceMetrics = source.computeMetrics().toList();
      final dashedMetrics = dashed
          .gridStrokePathForTesting(source)
          .computeMetrics()
          .toList();

      expect(sourceMetrics, hasLength(1));
      expect(dashedMetrics.length, greaterThan(1));
      expect(
        dashedMetrics.fold<double>(0, (total, metric) => total + metric.length),
        lessThan(sourceMetrics.single.length),
      );

      final solid = PolarColumnSeriesElement(
        series: dashed.series,
        config: dashed.config,
        size: dashed.size,
        theme: ChartTheme.light,
      );
      expect(solid.gridStrokePathForTesting(source), same(source));
    });

    test('sweep entrance reveals a full pane in configured order', () {
      final element = PolarColumnSeriesElement(
        series: PolarColumnChartSeries.fromMap(
          id: 'sweep-full',
          values: const {'North': 12, 'East': 24, 'South': 18, 'West': 30},
          polarStyle: const PolarColumnStyle(
            animationMode: PolarColumnAnimationMode.sweep,
          ),
        ),
        config: const PolarChartConfig(),
        size: const Size.square(320),
        theme: ChartTheme.light,
        sweepProgress: 0.25,
      );

      expect(element.isPointRevealedForAnimation(0), isTrue);
      expect(element.isPointRevealedForAnimation(1), isFalse);
      expect(element.isPointRevealedForAnimation(2), isFalse);
      expect(element.isPointRevealedForAnimation(3), isFalse);

      final recorder = PictureRecorder();
      element.paint(Canvas(recorder), const Size.square(320));
      expect(recorder.endRecording(), isNotNull);
    });

    test('sweep entrance respects a partial counter-clockwise pane', () {
      final element = PolarColumnSeriesElement(
        series: PolarColumnChartSeries.fromMap(
          id: 'sweep-partial-counter-clockwise',
          values: const {'Adopt': 12, 'Trial': 24, 'Renew': 18, 'Advocate': 30},
        ),
        config: const PolarChartConfig(
          pane: PolarPaneConfig(
            startAngleDegrees: -30,
            sweepAngleDegrees: 180,
            clockwise: false,
          ),
        ),
        size: const Size.square(320),
        theme: ChartTheme.light,
        sweepProgress: 0.5,
      );

      expect(element.isPointRevealedForAnimation(0), isTrue);
      expect(element.isPointRevealedForAnimation(1), isTrue);
      expect(element.isPointRevealedForAnimation(2), isFalse);
      expect(element.isPointRevealedForAnimation(3), isFalse);
    });

    test('rejects an invalid text scale factor', () {
      expect(
        () => PolarColumnSeriesElement(
          series: PolarColumnChartSeries.fromMap(
            id: 'invalid-scale',
            values: const {'A': 1},
          ),
          config: const PolarChartConfig(),
          size: const Size.square(240),
          theme: ChartTheme.light,
          textScaleFactor: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => PolarColumnSeriesElement(
          series: PolarColumnChartSeries.fromMap(
            id: 'invalid-fade',
            values: const {'A': 1},
          ),
          config: const PolarChartConfig(),
          size: const Size.square(240),
          theme: ChartTheme.light,
          fadeProgress: 1.1,
        ),
        throwsArgumentError,
      );
      expect(
        () => PolarColumnSeriesElement(
          series: PolarColumnChartSeries.fromMap(
            id: 'invalid-sweep',
            values: const {'A': 1},
          ),
          config: const PolarChartConfig(),
          size: const Size.square(240),
          theme: ChartTheme.light,
          sweepProgress: -0.1,
        ),
        throwsArgumentError,
      );
    });
  });
}
