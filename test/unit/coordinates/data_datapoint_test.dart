/// Unit Test: Data ↔ DataPoint Transformation
///
/// Tests index-based transformations between data coordinates and
/// series/point index pairs. This allows lookup of actual values
/// from series data and reverse lookup (finding nearest point).
///
/// Expected: FAIL until T025 implements the transformation
library;

import 'dart:math' show Point;
import 'dart:ui' show Size, Rect;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Data ↔ DataPoint transformation', () {
    late TransformContext context;
    late CoordinateTransformer transformer;
    late List<ChartSeries> testSeries;

    setUp(() {
      // Create test series with known data points
      testSeries = [
        ChartSeries(
          id: 'series1',
          points: [
            ChartDataPoint(x: 0.0, y: 10.0),
            ChartDataPoint(x: 25.0, y: 30.0),
            ChartDataPoint(x: 50.0, y: 20.0),
            ChartDataPoint(x: 75.0, y: 40.0),
            ChartDataPoint(x: 100.0, y: 15.0),
          ],
        ),
        ChartSeries(
          id: 'series2',
          points: [
            ChartDataPoint(x: 0.0, y: -10.0),
            ChartDataPoint(x: 50.0, y: 0.0),
            ChartDataPoint(x: 100.0, y: -20.0),
          ],
        ),
      ];

      context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: ViewportState.identity(),
        series: testSeries,
        devicePixelRatio: 1.0,
      );

      transformer = UniversalCoordinateTransformer();
    });

    test('should lookup data value from series/point index', () {
      // DataPoint (0, 2) = series 0, point 2 = (50.0, 20.0)
      final indexPoint = const Point<double>(0.0, 2.0);

      final dataPoint = transformer.transform(
        indexPoint,
        from: CoordinateSystem.dataPoint,
        to: CoordinateSystem.data,
        context: context,
      );

      expect(dataPoint.x, closeTo(50.0, 0.01), reason: 'Series 0, point 2 X value');
      expect(dataPoint.y, closeTo(20.0, 0.01), reason: 'Series 0, point 2 Y value');
    });

    test('should handle multiple series', () {
      // DataPoint (1, 1) = series 1, point 1 = (50.0, 0.0)
      final indexPoint = const Point<double>(1.0, 1.0);

      final dataPoint = transformer.transform(
        indexPoint,
        from: CoordinateSystem.dataPoint,
        to: CoordinateSystem.data,
        context: context,
      );

      expect(dataPoint.x, closeTo(50.0, 0.01), reason: 'Series 1, point 1 X value');
      expect(dataPoint.y, closeTo(0.0, 0.01), reason: 'Series 1, point 1 Y value');
    });

    test('should perform reverse lookup (data → nearest index)', () {
      // Data point (48.0, 22.0) should be closest to series 0, point 2 (50.0, 20.0)
      final dataPoint = const Point<double>(48.0, 22.0);

      final indexPoint = transformer.transform(
        dataPoint,
        from: CoordinateSystem.data,
        to: CoordinateSystem.dataPoint,
        context: context,
      );

      expect(indexPoint.x, closeTo(0.0, 0.01), reason: 'Nearest point is in series 0');
      expect(indexPoint.y, closeTo(2.0, 0.01), reason: 'Nearest point is index 2');
    });

    test('should handle out-of-bounds series index', () {
      // DataPoint (5, 0) - series index out of range
      final invalidIndex = const Point<double>(5.0, 0.0);

      expect(
        () => transformer.transform(
          invalidIndex,
          from: CoordinateSystem.dataPoint,
          to: CoordinateSystem.data,
          context: context,
        ),
        throwsA(isA<RangeError>()),
        reason: 'Should throw on invalid series index',
      );
    });

    test('should handle out-of-bounds point index', () {
      // DataPoint (0, 10) - point index out of range for series 0
      final invalidIndex = const Point<double>(0.0, 10.0);

      expect(
        () => transformer.transform(
          invalidIndex,
          from: CoordinateSystem.dataPoint,
          to: CoordinateSystem.data,
          context: context,
        ),
        throwsA(isA<RangeError>()),
        reason: 'Should throw on invalid point index',
      );
    });

    test('should handle first and last points', () {
      // First point: (0, 0)
      final firstIndex = const Point<double>(0.0, 0.0);
      final firstData = transformer.transform(
        firstIndex,
        from: CoordinateSystem.dataPoint,
        to: CoordinateSystem.data,
        context: context,
      );

      expect(firstData.x, closeTo(0.0, 0.01), reason: 'First point X');
      expect(firstData.y, closeTo(10.0, 0.01), reason: 'First point Y');

      // Last point of series 0: (0, 4)
      final lastIndex = const Point<double>(0.0, 4.0);
      final lastData = transformer.transform(
        lastIndex,
        from: CoordinateSystem.dataPoint,
        to: CoordinateSystem.data,
        context: context,
      );

      expect(lastData.x, closeTo(100.0, 0.01), reason: 'Last point X');
      expect(lastData.y, closeTo(15.0, 0.01), reason: 'Last point Y');
    });
  });
}
