/// Unit Test: Data ↔ Viewport Transformation
///
/// Tests zoom and pan transformations between data coordinates and
/// viewport coordinates. The viewport represents the visible subset
/// of data space after zoom/pan operations.
///
/// Expected: FAIL until T025 implements the transformation
library;

import 'dart:math' show Point;
import 'dart:ui' show Size, Rect;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Data ↔ Viewport transformation', () {
    late TransformContext context;
    late UniversalCoordinateTransformer transformer;

    setUp(() {
      transformer = UniversalCoordinateTransformer();
    });

    test('should apply zoom factor correctly (2x zoom)', () {
      // 2x zoom: viewport range is half of data range
      final viewport = const ViewportState(
        xRange: DataRange(min: 25, max: 75), // 50 units (half of 100)
        yRange: DataRange(min: -25, max: 25), // 50 units (half of 100)
        zoomFactor: 2.0,
        panOffset: Point(0.0, 0.0),
      );

      context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: viewport,
        series: const [],
        devicePixelRatio: 1.0,
      );

      // Data point at (50, 0) - center of data range
      final dataPoint = const Point<double>(50.0, 0.0);

      final viewportPoint = transformer.transform(
        dataPoint,
        from: CoordinateSystem.data,
        to: CoordinateSystem.viewport,
        context: context,
      );

      // In viewport space, (50, 0) is at center of visible range
      expect(viewportPoint.x, closeTo(50.0, 0.01), reason: 'Data center maps to viewport center X');
      expect(viewportPoint.y, closeTo(0.0, 0.01), reason: 'Data center maps to viewport center Y');
    });

    test('should apply pan offset correctly', () {
      // Pan 10 units right, 5 units up in data space
      final viewport = const ViewportState(
        xRange: DataRange(min: 10, max: 110), // Shifted right by 10
        yRange: DataRange(min: -45, max: 55), // Shifted up by 5
        zoomFactor: 1.0,
        panOffset: Point(10.0, 5.0),
      );

      context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: viewport,
        series: const [],
        devicePixelRatio: 1.0,
      );

      final dataPoint = const Point<double>(20.0, 10.0);

      final viewportPoint = transformer.transform(
        dataPoint,
        from: CoordinateSystem.data,
        to: CoordinateSystem.viewport,
        context: context,
      );

      // Viewport point should account for pan offset
      expect(viewportPoint.x, closeTo(10.0, 0.01), reason: 'Pan offset applied to X');
      expect(viewportPoint.y, closeTo(5.0, 0.01), reason: 'Pan offset applied to Y');
    });

    test('should handle identity viewport (no zoom/pan)', () {
      context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: ViewportState.identity(),
        series: const [],
        devicePixelRatio: 1.0,
      );

      final dataPoint = const Point<double>(33.5, -12.7);

      final viewportPoint = transformer.transform(
        dataPoint,
        from: CoordinateSystem.data,
        to: CoordinateSystem.viewport,
        context: context,
      );

      // Identity viewport: data == viewport
      expect(viewportPoint.x, closeTo(dataPoint.x, 0.01), reason: 'Identity: data X == viewport X');
      expect(viewportPoint.y, closeTo(dataPoint.y, 0.01), reason: 'Identity: data Y == viewport Y');
    });

    test('should have round-trip accuracy', () {
      final viewport = const ViewportState(
        xRange: DataRange(min: 20, max: 80),
        yRange: DataRange(min: -30, max: 30),
        zoomFactor: 1.5,
        panOffset: Point(5.0, -3.0),
      );

      context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: viewport,
        series: const [],
        devicePixelRatio: 1.0,
      );

      final originalData = const Point<double>(45.0, 12.0);

      // Data → Viewport → Data
      final viewportPoint = transformer.transform(
        originalData,
        from: CoordinateSystem.data,
        to: CoordinateSystem.viewport,
        context: context,
      );

      final roundTripData = transformer.transform(
        viewportPoint,
        from: CoordinateSystem.viewport,
        to: CoordinateSystem.data,
        context: context,
      );

      expect(roundTripData.x, closeTo(originalData.x, 0.01), reason: 'Round-trip X accuracy');
      expect(roundTripData.y, closeTo(originalData.y, 0.01), reason: 'Round-trip Y accuracy');
    });

    test('should handle zoom factor edge cases', () {
      // 0.5x zoom (zoomed out)
      final zoomOutViewport = const ViewportState(
        xRange: DataRange(min: -50, max: 150), // 200 units (2x data range)
        yRange: DataRange(min: -100, max: 100), // 200 units
        zoomFactor: 0.5,
        panOffset: Point(0.0, 0.0),
      );

      context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: zoomOutViewport,
        series: const [],
        devicePixelRatio: 1.0,
      );

      final dataPoint = const Point<double>(50.0, 0.0);
      final viewportPoint = transformer.transform(
        dataPoint,
        from: CoordinateSystem.data,
        to: CoordinateSystem.viewport,
        context: context,
      );

      // Data point should still map correctly in zoomed-out viewport
      expect(viewportPoint.x, isNotNull, reason: 'Zoom out transformation works');
      expect(viewportPoint.y, isNotNull, reason: 'Zoom out transformation works');
    });
  });
}
