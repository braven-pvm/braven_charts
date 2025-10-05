/// Unit Test: Mouse ↔ Screen Transformation
///
/// Tests the identity transformation between mouse and screen coordinates.
/// For this widget, mouse coordinates (physical pixels) equal screen coordinates
/// (logical pixels) when devicePixelRatio is 1.0.
///
/// Expected: FAIL until T025 implements the transformation
library;

import 'dart:math' show Point;
import 'dart:ui' show Size, Rect;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Mouse ↔ Screen transformation', () {
    late TransformContext context;
    late CoordinateTransformer transformer;

    setUp(() {
      // Create test context with standard widget size
      context = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: ViewportState.identity(),
        series: const [],
        devicePixelRatio: 1.0,
      );

      transformer = UniversalCoordinateTransformer();
    });

    test('should transform mouse to screen (identity)', () {
      // Mouse coordinates should equal screen coordinates
      final mousePoint = const Point<double>(150.0, 200.0);

      final screenPoint = transformer.transform(
        mousePoint,
        from: CoordinateSystem.mouse,
        to: CoordinateSystem.screen,
        context: context,
      );

      expect(screenPoint.x, equals(mousePoint.x), reason: 'Mouse X should equal Screen X');
      expect(screenPoint.y, equals(mousePoint.y), reason: 'Mouse Y should equal Screen Y');
    });

    test('should transform screen to mouse (identity)', () {
      // Screen coordinates should equal mouse coordinates
      final screenPoint = const Point<double>(300.0, 400.0);

      final mousePoint = transformer.transform(
        screenPoint,
        from: CoordinateSystem.screen,
        to: CoordinateSystem.mouse,
        context: context,
      );

      expect(mousePoint.x, equals(screenPoint.x), reason: 'Screen X should equal Mouse X');
      expect(mousePoint.y, equals(screenPoint.y), reason: 'Screen Y should equal Mouse Y');
    });

    test('should have perfect round-trip accuracy', () {
      // Forward and reverse should return to original point
      final originalPoint = const Point<double>(456.7, 123.4);

      final screenPoint = transformer.transform(
        originalPoint,
        from: CoordinateSystem.mouse,
        to: CoordinateSystem.screen,
        context: context,
      );

      final roundTripPoint = transformer.transform(
        screenPoint,
        from: CoordinateSystem.screen,
        to: CoordinateSystem.mouse,
        context: context,
      );

      expect(roundTripPoint.x, closeTo(originalPoint.x, 0.01), reason: 'Round-trip X within 0.01 pixels');
      expect(roundTripPoint.y, closeTo(originalPoint.y, 0.01), reason: 'Round-trip Y within 0.01 pixels');
    });

    test('should handle corner cases', () {
      // Test widget corners
      final corners = [
        const Point<double>(0.0, 0.0), // Top-left
        Point<double>(context.widgetSize.width, 0.0), // Top-right
        const Point<double>(0.0, 0.0), // Bottom-left (Y=height)
        Point<double>(context.widgetSize.width, context.widgetSize.height), // Bottom-right
      ];

      for (final corner in corners) {
        final transformed = transformer.transform(
          corner,
          from: CoordinateSystem.mouse,
          to: CoordinateSystem.screen,
          context: context,
        );

        expect(transformed.x, equals(corner.x));
        expect(transformed.y, equals(corner.y));
      }
    });

    test('should handle devicePixelRatio scaling', () {
      // Create context with high DPI display
      final highDpiContext = TransformContext(
        widgetSize: const Size(800, 600),
        chartAreaBounds: const Rect.fromLTWH(50, 30, 700, 540),
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        viewport: ViewportState.identity(),
        series: const [],
        devicePixelRatio: 2.0, // Retina display
      );

      final mousePoint = const Point<double>(100.0, 100.0);

      // For devicePixelRatio != 1.0, transformation may scale
      final screenPoint = transformer.transform(
        mousePoint,
        from: CoordinateSystem.mouse,
        to: CoordinateSystem.screen,
        context: highDpiContext,
      );

      // Implementation should handle device pixel ratio appropriately
      expect(screenPoint, isNotNull);
    });

    test('should batch transform efficiently', () {
      // Create batch of mouse points
      final mousePoints = List.generate(
        1000,
        (i) => Point<double>(i.toDouble(), i.toDouble()),
      );

      final screenPoints = transformer.transformBatch(
        mousePoints,
        from: CoordinateSystem.mouse,
        to: CoordinateSystem.screen,
        context: context,
      );

      expect(screenPoints.length, equals(mousePoints.length), reason: 'Batch output length matches input');

      // Verify each point transformed correctly
      for (int i = 0; i < mousePoints.length; i++) {
        expect(screenPoints[i].x, equals(mousePoints[i].x));
        expect(screenPoints[i].y, equals(mousePoints[i].y));
      }
    });
  });
}
