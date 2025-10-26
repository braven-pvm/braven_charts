import 'package:flutter_test/flutter_test.dart';

/// Contract test for left edge drag behavior (adjusts viewportMin, right edge anchored).
///
/// T080 [US3] - Tests that dragging the left edge of the scrollbar handle correctly
/// adjusts the viewport minimum (zoom in/out) while keeping the right edge anchored.
///
/// Requirements from FR-011:
/// - Left edge drag RIGHT → zoom IN (increase viewportMin, reduce visible data)
/// - Left edge drag LEFT → zoom OUT (decrease viewportMin, increase visible data)
/// - Right edge of viewport (viewportMax) remains FIXED during left edge drag
/// - MUST enforce minZoomRatio (1% minimum visible data)
/// - MUST enforce maxZoomRatio (100% maximum visible data)
void main() {
  group('ScrollbarLeftEdgeResize - CONTRACT', () {
    test('MUST increase viewportMin when left edge dragged RIGHT (zoom in)', () {
      // ARRANGE: Initial viewport 0-50 on dataRange 0-100
      const dataMin = 0.0;
      const dataMax = 100.0;
      const initialViewportMin = 0.0;
      const initialViewportMax = 50.0;
      
      // ACT: Drag left edge right by 10 data units
      const dragDelta = 10.0; // Positive = rightward
      
      // ASSERT: viewportMin increases, viewportMax unchanged
      final newViewport = _calculateLeftEdgeResize(
        dataMin: dataMin,
        dataMax: dataMax,
        currentViewportMin: initialViewportMin,
        currentViewportMax: initialViewportMax,
        delta: dragDelta,
        minZoomRatio: 0.01,
        maxZoomRatio: 1.0,
      );
      
      expect(newViewport.min, equals(10.0)); // Increased from 0
      expect(newViewport.max, equals(50.0)); // Unchanged (anchored)
      expect(newViewport.span, equals(40.0)); // Reduced from 50 (zoomed in)
    });

    test('MUST decrease viewportMin when left edge dragged LEFT (zoom out)', () {
      // ARRANGE: Initial viewport 20-50 on dataRange 0-100
      const dataMin = 0.0;
      const dataMax = 100.0;
      const initialViewportMin = 20.0;
      const initialViewportMax = 50.0;
      
      // ACT: Drag left edge left by 10 data units
      const dragDelta = -10.0; // Negative = leftward
      
      // ASSERT: viewportMin decreases, viewportMax unchanged
      final newViewport = _calculateLeftEdgeResize(
        dataMin: dataMin,
        dataMax: dataMax,
        currentViewportMin: initialViewportMin,
        currentViewportMax: initialViewportMax,
        delta: dragDelta,
        minZoomRatio: 0.01,
        maxZoomRatio: 1.0,
      );
      
      expect(newViewport.min, equals(10.0)); // Decreased from 20
      expect(newViewport.max, equals(50.0)); // Unchanged (anchored)
      expect(newViewport.span, equals(40.0)); // Increased from 30 (zoomed out)
    });

    test('MUST clamp viewportMin at dataMin when dragging too far left', () {
      // ARRANGE: Initial viewport 10-50 on dataRange 0-100
      const dataMin = 0.0;
      const dataMax = 100.0;
      const initialViewportMin = 10.0;
      const initialViewportMax = 50.0;
      
      // ACT: Drag left edge way past dataMin
      const dragDelta = -50.0; // Would go to -40, but should clamp to 0
      
      // ASSERT: viewportMin clamped at dataMin
      final newViewport = _calculateLeftEdgeResize(
        dataMin: dataMin,
        dataMax: dataMax,
        currentViewportMin: initialViewportMin,
        currentViewportMax: initialViewportMax,
        delta: dragDelta,
        minZoomRatio: 0.01,
        maxZoomRatio: 1.0,
      );
      
      expect(newViewport.min, equals(0.0)); // Clamped at dataMin
      expect(newViewport.max, equals(50.0)); // Unchanged
    });

    test('MUST enforce minZoomRatio (1% minimum visible data)', () {
      // ARRANGE: Initial viewport 0-50 on dataRange 0-100, minZoomRatio=0.01 (1%)
      const dataMin = 0.0;
      const dataMax = 100.0;
      const initialViewportMin = 0.0;
      const initialViewportMax = 50.0;
      
      // ACT: Drag left edge right by 50 units (would make viewport 50-50 = 0 span)
      const dragDelta = 50.0;
      
      // ASSERT: viewportMin clamped to enforce 1% minimum (1 unit span)
      final newViewport = _calculateLeftEdgeResize(
        dataMin: dataMin,
        dataMax: dataMax,
        currentViewportMin: initialViewportMin,
        currentViewportMax: initialViewportMax,
        delta: dragDelta,
        minZoomRatio: 0.01, // 1% of 100 = 1 unit minimum
        maxZoomRatio: 1.0,
      );
      
      expect(newViewport.min, equals(49.0)); // Clamped to leave 1 unit visible
      expect(newViewport.max, equals(50.0)); // Unchanged
      expect(newViewport.span, greaterThanOrEqualTo(1.0)); // At least 1% visible
    });

    test('MUST enforce maxZoomRatio (100% maximum visible data)', () {
      // ARRANGE: Initial viewport 20-50 on dataRange 0-100, maxZoomRatio=1.0 (100%)
      const dataMin = 0.0;
      const dataMax = 100.0;
      const initialViewportMin = 20.0;
      const initialViewportMax = 50.0;
      
      // ACT: Drag left edge left by 30 units (would make viewport -10 to 50 = 60 span)
      // But maxZoomRatio=1.0 means max span = 100 units (entire data range)
      const dragDelta = -30.0;
      
      // ASSERT: viewportMin clamped to enforce maxZoomRatio
      final newViewport = _calculateLeftEdgeResize(
        dataMin: dataMin,
        dataMax: dataMax,
        currentViewportMin: initialViewportMin,
        currentViewportMax: initialViewportMax,
        delta: dragDelta,
        minZoomRatio: 0.01,
        maxZoomRatio: 1.0, // 100% max (no zoom out beyond full range)
      );
      
      // Since viewportMax=50, and maxZoomRatio=1.0 (100 units), 
      // viewportMin should clamp to -50 (50 - 100 = -50), but also clamp to dataMin=0
      expect(newViewport.min, equals(0.0)); // Clamped at dataMin
      expect(newViewport.max, equals(50.0)); // Unchanged
      expect(newViewport.span, lessThanOrEqualTo(100.0)); // At most 100% visible
    });

    test('MUST keep viewportMax anchored during all left edge drags', () {
      // ARRANGE: Initial viewport 30-80 on dataRange 0-100
      const dataMin = 0.0;
      const dataMax = 100.0;
      const initialViewportMin = 30.0;
      const initialViewportMax = 80.0;
      
      // ACT: Multiple drag scenarios
      
      // Drag right (zoom in)
      var newViewport = _calculateLeftEdgeResize(
        dataMin: dataMin,
        dataMax: dataMax,
        currentViewportMin: initialViewportMin,
        currentViewportMax: initialViewportMax,
        delta: 15.0,
        minZoomRatio: 0.01,
        maxZoomRatio: 1.0,
      );
      expect(newViewport.max, equals(80.0)); // Unchanged
      
      // Drag left (zoom out)
      newViewport = _calculateLeftEdgeResize(
        dataMin: dataMin,
        dataMax: dataMax,
        currentViewportMin: initialViewportMin,
        currentViewportMax: initialViewportMax,
        delta: -15.0,
        minZoomRatio: 0.01,
        maxZoomRatio: 1.0,
      );
      expect(newViewport.max, equals(80.0)); // Still unchanged
    });

    test('MUST work with negative data ranges', () {
      // ARRANGE: Initial viewport -50 to 0 on dataRange -100 to 100
      const dataMin = -100.0;
      const dataMax = 100.0;
      const initialViewportMin = -50.0;
      const initialViewportMax = 0.0;
      
      // ACT: Drag left edge right by 20 units (zoom in)
      const dragDelta = 20.0;
      
      // ASSERT: viewportMin increases toward viewportMax
      final newViewport = _calculateLeftEdgeResize(
        dataMin: dataMin,
        dataMax: dataMax,
        currentViewportMin: initialViewportMin,
        currentViewportMax: initialViewportMax,
        delta: dragDelta,
        minZoomRatio: 0.01,
        maxZoomRatio: 1.0,
      );
      
      expect(newViewport.min, equals(-30.0)); // -50 + 20 = -30
      expect(newViewport.max, equals(0.0)); // Anchored
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

/// Calculate new viewport after left edge resize.
///
/// This is the contract being tested - implementation will go in ScrollbarState.
ViewportRange _calculateLeftEdgeResize({
  required double dataMin,
  required double dataMax,
  required double currentViewportMin,
  required double currentViewportMax,
  required double delta, // Positive = rightward (zoom in), negative = leftward (zoom out)
  required double minZoomRatio, // e.g., 0.01 = 1% minimum visible
  required double maxZoomRatio, // e.g., 1.0 = 100% maximum visible
}) {
  final dataSpan = dataMax - dataMin;
  
  // Apply delta to viewportMin (right edge anchored)
  var newViewportMin = currentViewportMin + delta;
  
  // Clamp to data range boundaries
  newViewportMin = newViewportMin.clamp(dataMin, currentViewportMax);
  
  // Calculate resulting viewport span
  final newSpan = currentViewportMax - newViewportMin;
  
  // Enforce zoom limits
  final minSpan = dataSpan * minZoomRatio; // Minimum visible span
  final maxSpan = dataSpan * maxZoomRatio; // Maximum visible span
  
  // If zoomed in too far (span too small), clamp viewportMin
  if (newSpan < minSpan) {
    newViewportMin = currentViewportMax - minSpan;
  }
  
  // If zoomed out too far (span too large), clamp viewportMin
  if (newSpan > maxSpan) {
    newViewportMin = currentViewportMax - maxSpan;
  }
  
  // Final clamp to data boundaries
  newViewportMin = newViewportMin.clamp(dataMin, dataMax);
  
  return ViewportRange(newViewportMin, currentViewportMax);
}
