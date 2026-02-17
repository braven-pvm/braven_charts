import 'package:flutter_test/flutter_test.dart';

/// Contract test for right edge drag behavior (adjusts viewportMax, left edge anchored).
///
/// T081 [US3] - Tests that dragging the right edge of the scrollbar handle correctly
/// adjusts the viewport maximum (zoom in/out) while keeping the left edge anchored.
///
/// Requirements from FR-011:
/// - Right edge drag LEFT → zoom IN (decrease viewportMax, reduce visible data)
/// - Right edge drag RIGHT → zoom OUT (increase viewportMax, increase visible data)
/// - Left edge of viewport (viewportMin) remains FIXED during right edge drag
/// - MUST enforce minZoomRatio (1% minimum visible data)
/// - MUST enforce maxZoomRatio (100% maximum visible data)
void main() {
  group('ScrollbarRightEdgeResize - CONTRACT', () {
    test(
      'MUST decrease viewportMax when right edge dragged LEFT (zoom in)',
      () {
        // ARRANGE: Initial viewport 0-50 on dataRange 0-100
        const dataMin = 0.0;
        const dataMax = 100.0;
        const initialViewportMin = 0.0;
        const initialViewportMax = 50.0;

        // ACT: Drag right edge left by 10 data units
        const dragDelta = -10.0; // Negative = leftward

        // ASSERT: viewportMax decreases, viewportMin unchanged
        final newViewport = _calculateRightEdgeResize(
          dataMin: dataMin,
          dataMax: dataMax,
          currentViewportMin: initialViewportMin,
          currentViewportMax: initialViewportMax,
          delta: dragDelta,
          minZoomRatio: 0.01,
          maxZoomRatio: 1.0,
        );

        expect(newViewport.min, equals(0.0)); // Unchanged (anchored)
        expect(newViewport.max, equals(40.0)); // Decreased from 50
        expect(newViewport.span, equals(40.0)); // Reduced from 50 (zoomed in)
      },
    );

    test(
      'MUST increase viewportMax when right edge dragged RIGHT (zoom out)',
      () {
        // ARRANGE: Initial viewport 0-50 on dataRange 0-100
        const dataMin = 0.0;
        const dataMax = 100.0;
        const initialViewportMin = 0.0;
        const initialViewportMax = 50.0;

        // ACT: Drag right edge right by 10 data units
        const dragDelta = 10.0; // Positive = rightward

        // ASSERT: viewportMax increases, viewportMin unchanged
        final newViewport = _calculateRightEdgeResize(
          dataMin: dataMin,
          dataMax: dataMax,
          currentViewportMin: initialViewportMin,
          currentViewportMax: initialViewportMax,
          delta: dragDelta,
          minZoomRatio: 0.01,
          maxZoomRatio: 1.0,
        );

        expect(newViewport.min, equals(0.0)); // Unchanged (anchored)
        expect(newViewport.max, equals(60.0)); // Increased from 50
        expect(
          newViewport.span,
          equals(60.0),
        ); // Increased from 50 (zoomed out)
      },
    );

    test('MUST clamp viewportMax at dataMax when dragging too far right', () {
      // ARRANGE: Initial viewport 0-80 on dataRange 0-100
      const dataMin = 0.0;
      const dataMax = 100.0;
      const initialViewportMin = 0.0;
      const initialViewportMax = 80.0;

      // ACT: Drag right edge way past dataMax
      const dragDelta = 50.0; // Would go to 130, but should clamp to 100

      // ASSERT: viewportMax clamped at dataMax
      final newViewport = _calculateRightEdgeResize(
        dataMin: dataMin,
        dataMax: dataMax,
        currentViewportMin: initialViewportMin,
        currentViewportMax: initialViewportMax,
        delta: dragDelta,
        minZoomRatio: 0.01,
        maxZoomRatio: 1.0,
      );

      expect(newViewport.min, equals(0.0)); // Unchanged
      expect(newViewport.max, equals(100.0)); // Clamped at dataMax
    });

    test('MUST enforce minZoomRatio (1% minimum visible data)', () {
      // ARRANGE: Initial viewport 0-50 on dataRange 0-100, minZoomRatio=0.01 (1%)
      const dataMin = 0.0;
      const dataMax = 100.0;
      const initialViewportMin = 0.0;
      const initialViewportMax = 50.0;

      // ACT: Drag right edge left by 50 units (would make viewport 0-0 = 0 span)
      const dragDelta = -50.0;

      // ASSERT: viewportMax clamped to enforce 1% minimum (1 unit span)
      final newViewport = _calculateRightEdgeResize(
        dataMin: dataMin,
        dataMax: dataMax,
        currentViewportMin: initialViewportMin,
        currentViewportMax: initialViewportMax,
        delta: dragDelta,
        minZoomRatio: 0.01, // 1% of 100 = 1 unit minimum
        maxZoomRatio: 1.0,
      );

      expect(newViewport.min, equals(0.0)); // Unchanged
      expect(newViewport.max, equals(1.0)); // Clamped to leave 1 unit visible
      expect(
        newViewport.span,
        greaterThanOrEqualTo(1.0),
      ); // At least 1% visible
    });

    test('MUST enforce maxZoomRatio (100% maximum visible data)', () {
      // ARRANGE: Initial viewport 50-80 on dataRange 0-100, maxZoomRatio=1.0 (100%)
      const dataMin = 0.0;
      const dataMax = 100.0;
      const initialViewportMin = 50.0;
      const initialViewportMax = 80.0;

      // ACT: Drag right edge right by 40 units (would make viewport 50-120 = 70 span)
      // But maxZoomRatio=1.0 means max span = 100 units (entire data range)
      const dragDelta = 40.0;

      // ASSERT: viewportMax clamped to enforce maxZoomRatio
      final newViewport = _calculateRightEdgeResize(
        dataMin: dataMin,
        dataMax: dataMax,
        currentViewportMin: initialViewportMin,
        currentViewportMax: initialViewportMax,
        delta: dragDelta,
        minZoomRatio: 0.01,
        maxZoomRatio: 1.0, // 100% max (no zoom out beyond full range)
      );

      // Since viewportMin=50, and maxZoomRatio=1.0 (100 units),
      // viewportMax should clamp to 150 (50 + 100 = 150), but also clamp to dataMax=100
      expect(newViewport.min, equals(50.0)); // Unchanged
      expect(newViewport.max, equals(100.0)); // Clamped at dataMax
      expect(
        newViewport.span,
        lessThanOrEqualTo(100.0),
      ); // At most 100% visible
    });

    test('MUST keep viewportMin anchored during all right edge drags', () {
      // ARRANGE: Initial viewport 20-70 on dataRange 0-100
      const dataMin = 0.0;
      const dataMax = 100.0;
      const initialViewportMin = 20.0;
      const initialViewportMax = 70.0;

      // ACT: Multiple drag scenarios

      // Drag left (zoom in)
      var newViewport = _calculateRightEdgeResize(
        dataMin: dataMin,
        dataMax: dataMax,
        currentViewportMin: initialViewportMin,
        currentViewportMax: initialViewportMax,
        delta: -15.0,
        minZoomRatio: 0.01,
        maxZoomRatio: 1.0,
      );
      expect(newViewport.min, equals(20.0)); // Unchanged

      // Drag right (zoom out)
      newViewport = _calculateRightEdgeResize(
        dataMin: dataMin,
        dataMax: dataMax,
        currentViewportMin: initialViewportMin,
        currentViewportMax: initialViewportMax,
        delta: 15.0,
        minZoomRatio: 0.01,
        maxZoomRatio: 1.0,
      );
      expect(newViewport.min, equals(20.0)); // Still unchanged
    });

    test('MUST work with negative data ranges', () {
      // ARRANGE: Initial viewport -50 to 0 on dataRange -100 to 100
      const dataMin = -100.0;
      const dataMax = 100.0;
      const initialViewportMin = -50.0;
      const initialViewportMax = 0.0;

      // ACT: Drag right edge right by 30 units (zoom out)
      const dragDelta = 30.0;

      // ASSERT: viewportMax increases
      final newViewport = _calculateRightEdgeResize(
        dataMin: dataMin,
        dataMax: dataMax,
        currentViewportMin: initialViewportMin,
        currentViewportMax: initialViewportMax,
        delta: dragDelta,
        minZoomRatio: 0.01,
        maxZoomRatio: 1.0,
      );

      expect(newViewport.min, equals(-50.0)); // Anchored
      expect(newViewport.max, equals(30.0)); // 0 + 30 = 30
    });
  });
}

/// Data structure representing a viewport range.
class ViewportRange {
  const ViewportRange(this.min, this.max);

  final double min;
  final double max;

  double get span => max - min;
}

/// Calculate new viewport after right edge resize.
///
/// This is the contract being tested - implementation will go in ScrollbarState.
ViewportRange _calculateRightEdgeResize({
  required double dataMin,
  required double dataMax,
  required double currentViewportMin,
  required double currentViewportMax,
  required double
  delta, // Positive = rightward (zoom out), negative = leftward (zoom in)
  required double minZoomRatio, // e.g., 0.01 = 1% minimum visible
  required double maxZoomRatio, // e.g., 1.0 = 100% maximum visible
}) {
  final dataSpan = dataMax - dataMin;

  // Apply delta to viewportMax (left edge anchored)
  var newViewportMax = currentViewportMax + delta;

  // Clamp to data range boundaries
  newViewportMax = newViewportMax.clamp(currentViewportMin, dataMax);

  // Calculate resulting viewport span
  final newSpan = newViewportMax - currentViewportMin;

  // Enforce zoom limits
  final minSpan = dataSpan * minZoomRatio; // Minimum visible span
  final maxSpan = dataSpan * maxZoomRatio; // Maximum visible span

  // If zoomed in too far (span too small), clamp viewportMax
  if (newSpan < minSpan) {
    newViewportMax = currentViewportMin + minSpan;
  }

  // If zoomed out too far (span too large), clamp viewportMax
  if (newSpan > maxSpan) {
    newViewportMax = currentViewportMin + maxSpan;
  }

  // Final clamp to data boundaries
  newViewportMax = newViewportMax.clamp(dataMin, dataMax);

  return ViewportRange(currentViewportMin, newViewportMax);
}
