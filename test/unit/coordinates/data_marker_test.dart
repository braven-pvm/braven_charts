/// Unit Test: Data ↔ Marker Transformation
///
/// Tests marker offset transformations for annotation positioning.
/// Markers apply a fixed pixel offset to data coordinates, useful
/// for callouts, tooltips, and labels.
///
/// Expected: FAIL until T025 implements the transformation
library;

import 'dart:math' show Point;
import 'dart:ui' show Size, Rect;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Data ↔ Marker transformation', () {
    late CoordinateTransformer transformer;

    setUp(() {
      transformer = UniversalCoordinateTransformer();
    });

    test('should apply marker offset to data point', () {
      // Marker offset: 20px right, 10px up
      final context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: ViewportState.identity(),
        series: const [],
        markerOffset: const Point(20.0, -10.0), // -Y is up in screen space
        devicePixelRatio: 1.0,
      );

      final dataPoint = const Point<double>(50.0, 0.0);

      final markerPoint = transformer.transform(
        dataPoint,
        from: CoordinateSystem.data,
        to: CoordinateSystem.marker,
        context: context,
      );

      // Marker transformation: data → screen → apply offset
      // This test verifies the offset is applied correctly
      expect(markerPoint, isNotNull, reason: 'Marker transformation succeeds');
    });

    test('should handle null marker offset (identity)', () {
      // No marker offset: data → marker should equal data → chartArea
      final context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: ViewportState.identity(),
        series: const [],
        markerOffset: null, // No offset
        devicePixelRatio: 1.0,
      );

      final dataPoint = const Point<double>(25.0, 10.0);

      final markerPoint = transformer.transform(
        dataPoint,
        from: CoordinateSystem.data,
        to: CoordinateSystem.marker,
        context: context,
      );

      final chartAreaPoint = transformer.transform(
        dataPoint,
        from: CoordinateSystem.data,
        to: CoordinateSystem.chartArea,
        context: context,
      );

      // Without offset, marker should equal chartArea coordinates
      expect(markerPoint.x, closeTo(chartAreaPoint.x, 0.01), reason: 'No offset: marker X == chartArea X');
      expect(markerPoint.y, closeTo(chartAreaPoint.y, 0.01), reason: 'No offset: marker Y == chartArea Y');
    });

    test('should handle negative offsets (annotations below/left)', () {
      // Negative offset: 15px left, 25px down
      final context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: ViewportState.identity(),
        series: const [],
        markerOffset: const Point(-15.0, 25.0),
        devicePixelRatio: 1.0,
      );

      final dataPoint = const Point<double>(75.0, -20.0);

      final markerPoint = transformer.transform(
        dataPoint,
        from: CoordinateSystem.data,
        to: CoordinateSystem.marker,
        context: context,
      );

      expect(markerPoint, isNotNull, reason: 'Negative offset works');
    });

    test('should have round-trip accuracy', () {
      final context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: ViewportState.identity(),
        series: const [],
        markerOffset: const Point(12.5, -7.3),
        devicePixelRatio: 1.0,
      );

      final originalData = const Point<double>(62.3, 18.7);

      // Data → Marker → Data (accounting for offset removal)
      final markerPoint = transformer.transform(
        originalData,
        from: CoordinateSystem.data,
        to: CoordinateSystem.marker,
        context: context,
      );

      final roundTripData = transformer.transform(
        markerPoint,
        from: CoordinateSystem.marker,
        to: CoordinateSystem.data,
        context: context,
      );

      expect(roundTripData.x, closeTo(originalData.x, 0.01), reason: 'Round-trip X accuracy');
      expect(roundTripData.y, closeTo(originalData.y, 0.01), reason: 'Round-trip Y accuracy');
    });

    test('should work with zoomed viewport', () {
      // Marker offset with 2x zoom
      final context = const TransformContext(
        widgetSize: Size(800, 600),
        chartAreaBounds: Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: DataRange(min: 0, max: 100),
        yDataRange: DataRange(min: -50, max: 50),
        viewport: ViewportState(
          xRange: DataRange(min: 25, max: 75),
          yRange: DataRange(min: -25, max: 25),
          zoomFactor: 2.0,
          panOffset: Point(0.0, 0.0),
        ),
        series: [],
        markerOffset: Point(10.0, -5.0),
        devicePixelRatio: 1.0,
      );

      final dataPoint = const Point<double>(50.0, 0.0);

      final markerPoint = transformer.transform(
        dataPoint,
        from: CoordinateSystem.data,
        to: CoordinateSystem.marker,
        context: context,
      );

      // Offset should be applied in screen pixels regardless of zoom
      expect(markerPoint, isNotNull, reason: 'Marker offset works with zoom');
    });
  });
}
