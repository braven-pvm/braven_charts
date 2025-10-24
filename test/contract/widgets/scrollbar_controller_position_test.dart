import 'package:braven_charts/src/widgets/scrollbar/scrollbar_controller.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contract test for ScrollbarController.calculateHandlePosition()
///
/// CRITICAL: This test MUST FAIL until ScrollbarController is implemented (T015).
/// Following Constitution I (Test-First Development - TDD Red Phase).
///
/// Tests the O(1) ratio formula for handle position calculation:
/// handlePosition = (trackLength - handleSize) * (scrollOffset / maxScrollOffset)
///
/// Where maxScrollOffset = totalRange - viewportRange
///
/// See plan.md Section 2.2 "ScrollbarController (Pure Functions)" for formula.
void main() {
  group('ScrollbarController.calculateHandlePosition() - CONTRACT', () {
    test('MUST return 0.0 when scroll offset is 0 (start of range)', () {
      // ARRANGE: Scrolled to beginning of data range
      const scrollOffset = 0.0; // At the start
      const totalRange = 100.0; // Total data range
      const viewportRange = 50.0; // Visible range (50% of total)
      const trackLength = 200.0; // Available scrollbar track space
      const handleSize = 100.0; // Handle occupies half the track

      // ACT: Calculate handle position using O(1) ratio formula
      // maxScrollOffset = 100.0 - 50.0 = 50.0
      // handlePosition = (200.0 - 100.0) * (0.0 / 50.0) = 100.0 * 0.0 = 0.0
      final result = ScrollbarController.calculateHandlePosition(
        scrollOffset,
        totalRange,
        viewportRange,
        trackLength,
        handleSize,
      );

      // ASSERT: Should return 0.0 (handle at start of track)
      expect(result, equals(0.0));
    });

    test('MUST return max position when scrolled to end of range', () {
      // ARRANGE: Scrolled to end of data range
      const scrollOffset = 50.0; // At the end (maxScrollOffset)
      const totalRange = 100.0; // Total data range
      const viewportRange = 50.0; // Visible range
      const trackLength = 200.0; // Available scrollbar track space
      const handleSize = 100.0; // Handle size

      // ACT: Calculate using formula
      // maxScrollOffset = 100.0 - 50.0 = 50.0
      // handlePosition = (200.0 - 100.0) * (50.0 / 50.0) = 100.0 * 1.0 = 100.0
      final result = ScrollbarController.calculateHandlePosition(
        scrollOffset,
        totalRange,
        viewportRange,
        trackLength,
        handleSize,
      );

      // ASSERT: Should return trackLength - handleSize (100.0)
      expect(result, equals(100.0));
    });

    test('MUST return proportional position for mid-range scroll', () {
      // ARRANGE: Scrolled to middle of range
      const scrollOffset = 25.0; // Halfway through scrollable range
      const totalRange = 100.0;
      const viewportRange = 50.0;
      const trackLength = 200.0;
      const handleSize = 100.0;

      // ACT: Calculate using formula
      // maxScrollOffset = 100.0 - 50.0 = 50.0
      // handlePosition = (200.0 - 100.0) * (25.0 / 50.0) = 100.0 * 0.5 = 50.0
      final result = ScrollbarController.calculateHandlePosition(
        scrollOffset,
        totalRange,
        viewportRange,
        trackLength,
        handleSize,
      );

      // ASSERT: Should return 50.0 (halfway along track)
      expect(result, equals(50.0));
    });

    test('MUST clamp to 0.0 when scroll offset is negative', () {
      // ARRANGE: Invalid negative scroll offset (defensive case)
      const scrollOffset = -10.0; // Invalid (should never happen)
      const totalRange = 100.0;
      const viewportRange = 50.0;
      const trackLength = 200.0;
      const handleSize = 100.0;

      // ACT: Should clamp to 0.0 (defensive programming)
      final result = ScrollbarController.calculateHandlePosition(
        scrollOffset,
        totalRange,
        viewportRange,
        trackLength,
        handleSize,
      );

      // ASSERT: Should return 0.0 (clamped)
      expect(result, equals(0.0));
    });

    test('MUST clamp to max position when scroll offset exceeds range', () {
      // ARRANGE: Scroll offset exceeds maxScrollOffset (defensive case)
      const scrollOffset = 100.0; // Exceeds maxScrollOffset (50.0)
      const totalRange = 100.0;
      const viewportRange = 50.0;
      const trackLength = 200.0;
      const handleSize = 100.0;

      // ACT: Should clamp to trackLength - handleSize
      final result = ScrollbarController.calculateHandlePosition(
        scrollOffset,
        totalRange,
        viewportRange,
        trackLength,
        handleSize,
      );

      // ASSERT: Should return 100.0 (clamped to max position)
      expect(result, equals(100.0));
    });

    test('MUST handle edge case: viewport >= total range (no scroll)', () {
      // ARRANGE: Viewport fully zoomed out (no scrollable range)
      const scrollOffset = 0.0;
      const totalRange = 100.0;
      const viewportRange = 100.0; // Full viewport (no zoom)
      const trackLength = 200.0;
      const handleSize = 200.0; // Full track handle

      // ACT: maxScrollOffset = 0.0 (no scrollable range)
      // Should return 0.0 (handle position at start)
      final result = ScrollbarController.calculateHandlePosition(
        scrollOffset,
        totalRange,
        viewportRange,
        trackLength,
        handleSize,
      );

      // ASSERT: Should return 0.0 (handle fills entire track, position is 0)
      expect(result, equals(0.0));
    });

    test('MUST handle edge case: zero track length', () {
      // ARRANGE: Degenerate case (no track space)
      const scrollOffset = 25.0;
      const totalRange = 100.0;
      const viewportRange = 50.0;
      const trackLength = 0.0; // No track space (should never happen)
      const handleSize = 0.0;

      // ACT: Should return 0.0 (defensive programming)
      final result = ScrollbarController.calculateHandlePosition(
        scrollOffset,
        totalRange,
        viewportRange,
        trackLength,
        handleSize,
      );

      // ASSERT: Should return 0.0
      expect(result, equals(0.0));
    });

    test('MUST maintain O(1) performance (< 0.1ms per call)', () {
      // ARRANGE: Performance test data
      const scrollOffset = 25000.0;
      const totalRange = 1000000.0; // Large range
      const viewportRange = 50000.0;
      const trackLength = 200.0;
      const handleSize = 10.0;
      const iterations = 10000; // 10,000 calls

      // ACT: Measure execution time for 10,000 calls
      final stopwatch = Stopwatch()..start();
      for (int i = 0; i < iterations; i++) {
        ScrollbarController.calculateHandlePosition(
          scrollOffset,
          totalRange,
          viewportRange,
          trackLength,
          handleSize,
        );
      }
      stopwatch.stop();

      // ASSERT: Average < 0.1ms per call (performance requirement)
      final avgMicroseconds = stopwatch.elapsedMicroseconds / iterations;
      expect(avgMicroseconds, lessThan(100)); // 0.1ms = 100 microseconds
    });
  });
}
