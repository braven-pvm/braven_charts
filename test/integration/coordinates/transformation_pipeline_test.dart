/// Integration Test: Full Transformation Pipeline
///
/// Tests end-to-end transformation scenarios in the context of
/// the full rendering pipeline. Verifies:
/// - Data → Screen transformation during rendering
/// - Mouse click → Data coordinate lookup
/// - Annotation positioning (Data → Marker → Screen)
/// - Performance during frame rendering (<1ms for 10K points)
///
/// Expected: FAIL until T036 implements full pipeline integration
library;

import 'dart:math' show Point;
import 'dart:ui' show Size, Rect;

import 'package:braven_charts/legacy/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Full transformation pipeline', () {
    late RenderContext renderContext;
    late CoordinateTransformer transformer;
    late TransformContext transformContext;

    setUp(() {
      // Create rendering pipeline components
      renderContext = RenderContext(
        size: const Size(800, 600),
        viewport: const Rect.fromLTWH(50, 30, 700, 540),
      );

      transformContext = TransformContext.fromRenderContext(
        renderContext,
        xDataRange: const DataRange(min: 0, max: 100),
        yDataRange: const DataRange(min: -50, max: 50),
        series: [
          ChartSeries(
            id: 'test',
            points: List.generate(
              100,
              (i) => ChartDataPoint(
                x: i.toDouble(),
                y: (i - 50).toDouble(),
              ),
            ),
          ),
        ],
      );

      transformer = UniversalCoordinateTransformer();
      renderContext.setTransformer(transformer, transformContext);
    });

    test('should transform data to screen during rendering', () {
      // Simulate data points being rendered
      final dataPoints = [
        const Point<double>(0.0, -50.0), // Data min
        const Point<double>(50.0, 0.0), // Data center
        const Point<double>(100.0, 50.0), // Data max
      ];

      final screenPoints =
          dataPoints.map((p) => renderContext.dataToScreen(p)).toList();

      // All points should be within chart area bounds
      for (final point in screenPoints) {
        expect(point.x, greaterThanOrEqualTo(50.0),
            reason: 'Screen X >= chartArea left');
        expect(point.x, lessThanOrEqualTo(750.0),
            reason: 'Screen X <= chartArea right');
        expect(point.y, greaterThanOrEqualTo(30.0),
            reason: 'Screen Y >= chartArea top');
        expect(point.y, lessThanOrEqualTo(570.0),
            reason: 'Screen Y <= chartArea bottom');
      }
    });

    test('should convert mouse click to data coordinate', () {
      // Simulate mouse click at center of chart area
      final mouseClick = const Point<double>(400.0, 300.0);

      // Mouse → Screen → ChartArea → Data
      final dataCoord = renderContext.screenToData(mouseClick);

      // Click at chart center should map to data center
      expect(dataCoord.x, closeTo(50.0, 1.0),
          reason: 'Click X maps to data center X');
      expect(dataCoord.y, closeTo(0.0, 1.0),
          reason: 'Click Y maps to data center Y');
    });

    test('should position annotations correctly', () {
      // Data point where annotation should appear
      final dataPoint = const Point<double>(75.0, 20.0);

      // Create context with marker offset (tooltip 15px right, 10px up)
      final markerContext = transformContext.withMarkerOffset(
        const Point(15.0, -10.0),
      );

      // Transform data → marker → screen
      final markerPoint = transformer.transform(
        dataPoint,
        from: CoordinateSystem.data,
        to: CoordinateSystem.marker,
        context: markerContext,
      );

      final screenPoint = transformer.transform(
        markerPoint,
        from: CoordinateSystem.marker,
        to: CoordinateSystem.screen,
        context: markerContext,
      );

      // Marker position should be offset from data point position
      final directScreenPoint = transformer.transform(
        dataPoint,
        from: CoordinateSystem.data,
        to: CoordinateSystem.screen,
        context: markerContext,
      );

      // Marker should be shifted by offset
      expect(screenPoint.x, isNot(equals(directScreenPoint.x)),
          reason: 'Marker X offset applied');
      expect(screenPoint.y, isNot(equals(directScreenPoint.y)),
          reason: 'Marker Y offset applied');
    });

    test('should perform batch transformation in <1ms for 10K points', () {
      // Generate 10,000 data points
      final dataPoints = List.generate(
        10000,
        (i) => Point<double>(
          i / 100.0, // X: 0 to 100
          ((i % 100) - 50).toDouble(), // Y: -50 to 50
        ),
      );

      // Measure transformation time
      final stopwatch = Stopwatch()..start();

      final screenPoints = renderContext.transformBatch(
        dataPoints,
        CoordinateSystem.data,
        CoordinateSystem.screen,
      );

      stopwatch.stop();

      // Performance requirement: <1ms for 10K points
      expect(
        stopwatch.elapsedMicroseconds,
        lessThan(1000),
        reason: 'Batch transformation of 10K points must complete in <1ms',
      );

      expect(screenPoints.length, equals(10000),
          reason: 'All points transformed');
    });

    test('should maintain 60 FPS with transformations in rendering loop', () {
      // Simulate rendering frame (16.67ms budget for 60 FPS)
      const frameCount = 100;
      const pointsPerFrame = 1000;

      final frameTimes = <int>[];

      for (var frame = 0; frame < frameCount; frame++) {
        final stopwatch = Stopwatch()..start();

        // Simulate frame rendering: transform points
        final dataPoints = List.generate(
          pointsPerFrame,
          (i) => Point<double>(
            (frame * pointsPerFrame + i) / 100.0 % 100,
            ((i % 100) - 50).toDouble(),
          ),
        );

        renderContext.transformBatch(
          dataPoints,
          CoordinateSystem.data,
          CoordinateSystem.screen,
        );

        stopwatch.stop();
        frameTimes.add(stopwatch.elapsedMicroseconds);
      }

      // Calculate average frame time
      final avgFrameTime =
          frameTimes.reduce((a, b) => a + b) / frameTimes.length;

      // Transformation should use <1% of frame budget (160μs of 16670μs)
      expect(
        avgFrameTime,
        lessThan(160),
        reason:
            'Average transformation time should be <160μs (<1% of frame budget)',
      );
    });

    test('should handle viewport changes during rendering', () {
      // Zoom in 2x
      final zoomedContext = transformContext.withViewport(
        const ViewportState(
          xRange: DataRange(min: 25, max: 75),
          yRange: DataRange(min: -25, max: 25),
          zoomFactor: 2.0,
          panOffset: Point(0.0, 0.0),
        ),
      );

      renderContext.setTransformer(transformer, zoomedContext);

      // Data point that was at center should still be at center
      final dataCenter = const Point<double>(50.0, 0.0);
      final screenPoint = renderContext.dataToScreen(dataCenter);

      // Should still map to chart center
      expect(screenPoint.x, closeTo(400.0, 1.0), reason: 'Zoomed center X');
      expect(screenPoint.y, closeTo(300.0, 1.0), reason: 'Zoomed center Y');
    });

    test('should integrate with viewport culling', () {
      // Create zoomed viewport showing only [25, 75] X range
      final zoomedContext = transformContext.withViewport(
        const ViewportState(
          xRange: DataRange(min: 25, max: 75),
          yRange: DataRange(min: -25, max: 25),
          zoomFactor: 2.0,
          panOffset: Point(0.0, 0.0),
        ),
      );

      // Points outside viewport
      final pointOutside = const Point<double>(10.0, 0.0); // X < 25
      final pointInside = const Point<double>(50.0, 0.0); // X in [25, 75]

      // Check if points are in viewport
      expect(
        zoomedContext.viewport.containsPoint(pointOutside),
        isFalse,
        reason: 'Point outside viewport',
      );

      expect(
        zoomedContext.viewport.containsPoint(pointInside),
        isTrue,
        reason: 'Point inside viewport',
      );
    });
  });
}
