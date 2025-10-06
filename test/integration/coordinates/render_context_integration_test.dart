/// Integration Test: RenderContext Extension
///
/// Tests the integration between coordinate transformation system
/// and the Core Rendering Engine's RenderContext. Verifies that:
/// - TransformContext can be constructed from RenderContext
/// - Convenience methods work correctly
/// - Transformations work during rendering pipeline
///
/// Expected: FAIL until T034-T035 implement RenderContext integration
library;

import 'dart:math' show Point;
import 'dart:ui' show Size, Rect;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RenderContext integration', () {
    test('should construct TransformContext from RenderContext', () {
      // Create a RenderContext (from Core Rendering Engine)
      final renderContext = RenderContext(
        size: const Size(800, 600),
        viewport: const Rect.fromLTWH(50, 30, 700, 540),
      );

      // Create TransformContext from it
      final transformContext = TransformContext.fromRenderContext(
        renderContext,
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        series: const [],
      );

      expect(transformContext.widgetSize, equals(renderContext.size));
      expect(transformContext.chartAreaBounds, equals(renderContext.viewport));
      expect(transformContext.viewport.isIdentity(), isTrue,
          reason: 'Default viewport should be identity');
    });

    test('should have RenderContext.transformContext field', () {
      final renderContext = RenderContext(
        size: const Size(800, 600),
        viewport: const Rect.fromLTWH(50, 30, 700, 540),
      );

      // Should have transformContext field (may be null initially)
      expect(() => renderContext.transformContext, returnsNormally,
          reason: 'transformContext field should exist');
    });

    test('should have RenderContext convenience methods', () {
      final renderContext = RenderContext(
        size: const Size(800, 600),
        viewport: const Rect.fromLTWH(50, 30, 700, 540),
      );

      // Should have dataToScreen method
      expect(
        () => renderContext.dataToScreen(const Point(50.0, 0.0)),
        returnsNormally,
        reason: 'dataToScreen method should exist',
      );

      // Should have screenToData method
      expect(
        () => renderContext.screenToData(const Point(400.0, 300.0)),
        returnsNormally,
        reason: 'screenToData method should exist',
      );

      // Should have transformBatch method
      expect(
        () => renderContext.transformBatch(
          [const Point(0.0, 0.0)],
          CoordinateSystem.data,
          CoordinateSystem.screen,
        ),
        returnsNormally,
        reason: 'transformBatch method should exist',
      );
    });

    test('should perform transformations via RenderContext', () {
      final renderContext = RenderContext(
        size: const Size(800, 600),
        viewport: const Rect.fromLTWH(50, 30, 700, 540),
      );

      // Setup transform context
      final transformContext = TransformContext.fromRenderContext(
        renderContext,
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        series: const [],
      );

      // Attach transformer
      final transformer = UniversalCoordinateTransformer();
      renderContext.setTransformer(transformer, transformContext);

      // Use convenience method
      final dataPoint = const Point<double>(50.0, 0.0);
      final screenPoint = renderContext.dataToScreen(dataPoint);

      expect(screenPoint, isNotNull,
          reason: 'Transformation should work via RenderContext');
    });

    test('should validate transformContext exists before transformation', () {
      final renderContext = RenderContext(
        size: const Size(800, 600),
        viewport: const Rect.fromLTWH(50, 30, 700, 540),
      );

      // Try to transform without setting up transformContext
      expect(
        () => renderContext.dataToScreen(const Point(50.0, 0.0)),
        throwsA(isA<StateError>()),
        reason: 'Should throw if transformContext not set',
      );
    });

    test('should support batch transformations via RenderContext', () {
      final renderContext = RenderContext(
        size: const Size(800, 600),
        viewport: const Rect.fromLTWH(50, 30, 700, 540),
      );

      final transformContext = TransformContext.fromRenderContext(
        renderContext,
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        series: const [],
      );

      final transformer = UniversalCoordinateTransformer();
      renderContext.setTransformer(transformer, transformContext);

      // Transform batch
      final dataPoints = [
        const Point<double>(0.0, -50.0),
        const Point<double>(50.0, 0.0),
        const Point<double>(100.0, 50.0),
      ];

      final screenPoints = renderContext.transformBatch(
        dataPoints,
        CoordinateSystem.data,
        CoordinateSystem.screen,
      );

      expect(screenPoints.length, equals(dataPoints.length),
          reason: 'Batch size should match');
      expect(screenPoints.every((p) => p != null), isTrue,
          reason: 'All points should transform');
    });
  });
}
