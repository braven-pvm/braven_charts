import 'package:braven_charts/legacy/src/widgets/scrollbar/scrollbar_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract test for ScrollbarController.calculateHandleSize()
///
/// CRITICAL: This test MUST FAIL until ScrollbarController is implemented (T015).
/// Following Constitution I (Test-First Development - TDD Red Phase).
///
/// Tests the O(1) ratio formula for handle size calculation:
/// handleSize = max(minSize, trackLength * (viewportRange / totalRange))
///
/// See plan.md Section 2.2 "ScrollbarController (Pure Functions)" for formula.
void main() {
  group('ScrollbarController.calculateHandleSize() - CONTRACT', () {
    test('MUST return minimum size when viewport >= total range', () {
      // ARRANGE: Viewport fully zoomed out (viewport range >= total range)
      const totalRange = 100.0; // Total data range
      const viewportRange = 100.0; // Visible range (no zoom)
      const trackLength = 200.0; // Available scrollbar track space
      const minHandleSize = 20.0; // Minimum handle size (config)

      // ACT: Calculate handle size using O(1) ratio formula
      final result = ScrollbarController.calculateHandleSize(
        totalRange,
        viewportRange,
        trackLength,
        minHandleSize,
      );

      // ASSERT: Should return trackLength (100% of track when viewport >= total)
      // Per FR-010: "Handle size proportional to viewport/total ratio, min 20px"
      expect(result, equals(trackLength));
    });

    test('MUST return proportional size when viewport < total range', () {
      // ARRANGE: Viewport zoomed in 2x (viewport is half of total range)
      const totalRange = 100.0; // Total data range
      const viewportRange = 50.0; // Visible range (50% of total)
      const trackLength = 200.0; // Available scrollbar track space
      const minHandleSize = 20.0; // Minimum handle size

      // ACT: Calculate using formula: trackLength * (viewportRange / totalRange)
      // Expected: 200.0 * (50.0 / 100.0) = 200.0 * 0.5 = 100.0
      final result = ScrollbarController.calculateHandleSize(
        totalRange,
        viewportRange,
        trackLength,
        minHandleSize,
      );

      // ASSERT: Should return 100.0 (half the track length)
      expect(result, equals(100.0));
    });

    test('MUST clamp to minHandleSize when formula yields smaller value', () {
      // ARRANGE: Viewport very zoomed in (0.5% of total range)
      const totalRange = 10000.0; // Large total range
      const viewportRange = 50.0; // Very small viewport (0.5% of total)
      const trackLength = 200.0; // Available scrollbar track space
      const minHandleSize = 20.0; // Minimum handle size

      // ACT: Calculate using formula: 200.0 * (50.0 / 10000.0) = 1.0
      // Expected: Clamped to minHandleSize (20.0) per FR-010
      final result = ScrollbarController.calculateHandleSize(
        totalRange,
        viewportRange,
        trackLength,
        minHandleSize,
      );

      // ASSERT: Should return 20.0 (clamped from 1.0)
      expect(result, equals(20.0));
    });

    test('MUST handle edge case: zero viewport range', () {
      // ARRANGE: Degenerate case (viewport range = 0)
      const totalRange = 100.0;
      const viewportRange = 0.0; // Invalid viewport (should never happen in practice)
      const trackLength = 200.0;
      const minHandleSize = 20.0;

      // ACT: Should handle gracefully (clamp to minHandleSize)
      final result = ScrollbarController.calculateHandleSize(
        totalRange,
        viewportRange,
        trackLength,
        minHandleSize,
      );

      // ASSERT: Should return minHandleSize (defensive programming)
      expect(result, equals(20.0));
    });

    test('MUST handle edge case: zero total range', () {
      // ARRANGE: Degenerate case (total range = 0)
      const totalRange = 0.0; // Invalid total (should never happen)
      const viewportRange = 50.0;
      const trackLength = 200.0;
      const minHandleSize = 20.0;

      // ACT: Should handle gracefully (clamp to minHandleSize)
      final result = ScrollbarController.calculateHandleSize(
        totalRange,
        viewportRange,
        trackLength,
        minHandleSize,
      );

      // ASSERT: Should return minHandleSize (defensive programming)
      expect(result, equals(20.0));
    });

    test('MUST handle edge case: viewport > total range (invalid zoom)', () {
      // ARRANGE: Invalid case (viewport larger than total range)
      const totalRange = 50.0;
      const viewportRange = 100.0; // Viewport exceeds total (defensive case)
      const trackLength = 200.0;
      const minHandleSize = 20.0;

      // ACT: Should clamp to full track length or minHandleSize
      final result = ScrollbarController.calculateHandleSize(
        totalRange,
        viewportRange,
        trackLength,
        minHandleSize,
      );

      // ASSERT: Should return trackLength (ratio > 1.0 means full handle)
      expect(result, equals(200.0));
    });

    test('MUST maintain O(1) performance (< 0.1ms per call)', () {
      // ARRANGE: Performance test data
      const totalRange = 1000000.0; // Large range
      const viewportRange = 50000.0;
      const trackLength = 200.0;
      const minHandleSize = 20.0;
      const iterations = 10000; // 10,000 calls

      // ACT: Measure execution time for 10,000 calls
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        ScrollbarController.calculateHandleSize(
          totalRange,
          viewportRange,
          trackLength,
          minHandleSize,
        );
      }
      stopwatch.stop();

      // ASSERT: Average < 0.1ms per call (performance requirement from plan.md)
      final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;
      expect(avgMicroseconds, lessThan(100)); // 0.1ms = 100 microseconds
    });
  });
}
