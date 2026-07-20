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
    });
  });
}
