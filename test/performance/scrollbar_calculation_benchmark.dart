// Copyright (c) 2025 Forcegage PVM. All rights reserved.
// Use of this source code is governed by a BSD-style license.

/// Performance benchmark: ScrollbarController calculations should be <0.1ms (T079).
///
/// This benchmark validates that ScrollbarController calculation methods
/// (calculateHandleSize, calculateHandlePosition, handleToDataRange) execute
/// fast enough to maintain 60 FPS performance (<0.1ms per calculation).
library;

import 'package:braven_charts/src/foundation/foundation.dart' as braven;
import 'package:braven_charts/src/widgets/scrollbar/scrollbar_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScrollbarController Calculation Performance (T079)', () {
    test('calculateHandleSize completes in <0.1ms', () {
      // Setup test parameters
      const dataRangeSpan = 100.0;
      const viewportRangeSpan = 20.0;
      const trackLength = 400.0;
      const minHandleSize = 44.0;

      // Warm up (avoid first-run JIT overhead)
      for (int i = 0; i < 100; i++) {
        ScrollbarController.calculateHandleSize(
          dataRangeSpan,
          viewportRangeSpan,
          trackLength,
          minHandleSize,
        );
      }

      // Measure performance over multiple iterations
      final stopwatch = Stopwatch()..start();
      const iterations = 1000;

      for (int i = 0; i < iterations; i++) {
        ScrollbarController.calculateHandleSize(
          dataRangeSpan,
          viewportRangeSpan,
          trackLength,
          minHandleSize,
        );
      }

      stopwatch.stop();
      final averageTimeMs = stopwatch.elapsedMicroseconds / iterations / 1000;

      // Verify average time is <0.1ms
      expect(averageTimeMs, lessThan(0.1), reason: 'calculateHandleSize should complete in <0.1ms (actual: ${averageTimeMs.toStringAsFixed(4)}ms)');

      print('calculateHandleSize: ${averageTimeMs.toStringAsFixed(4)}ms avg over $iterations iterations');
    });

    test('calculateHandlePosition completes in <0.1ms', () {
      // Setup test parameters
      const scrollOffset = 40.0;
      const dataRangeSpan = 100.0;
      const viewportRangeSpan = 20.0;
      const trackLength = 400.0;
      const minHandleSize = 44.0;

      // Warm up
      for (int i = 0; i < 100; i++) {
        ScrollbarController.calculateHandlePosition(
          scrollOffset,
          dataRangeSpan,
          viewportRangeSpan,
          trackLength,
          minHandleSize,
        );
      }

      // Measure performance
      final stopwatch = Stopwatch()..start();
      const iterations = 1000;

      for (int i = 0; i < iterations; i++) {
        ScrollbarController.calculateHandlePosition(
          scrollOffset,
          dataRangeSpan,
          viewportRangeSpan,
          trackLength,
          minHandleSize,
        );
      }

      stopwatch.stop();
      final averageTimeMs = stopwatch.elapsedMicroseconds / iterations / 1000;

      expect(averageTimeMs, lessThan(0.1),
          reason: 'calculateHandlePosition should complete in <0.1ms (actual: ${averageTimeMs.toStringAsFixed(4)}ms)');

      print('calculateHandlePosition: ${averageTimeMs.toStringAsFixed(4)}ms avg over $iterations iterations');
    });

    test('handleToDataRange completes in <0.1ms', () {
      // Setup test parameters
      const handlePosition = 160.0;
      const dataRangeSpan = 100.0;
      const viewportRangeSpan = 20.0;
      const trackLength = 400.0;
      const handleSize = 80.0;

      // Warm up
      for (int i = 0; i < 100; i++) {
        ScrollbarController.handleToDataRange(
          handlePosition,
          dataRangeSpan,
          viewportRangeSpan,
          trackLength,
          handleSize,
        );
      }

      // Measure performance
      final stopwatch = Stopwatch()..start();
      const iterations = 1000;

      for (int i = 0; i < iterations; i++) {
        ScrollbarController.handleToDataRange(
          handlePosition,
          dataRangeSpan,
          viewportRangeSpan,
          trackLength,
          handleSize,
        );
      }

      stopwatch.stop();
      final averageTimeMs = stopwatch.elapsedMicroseconds / iterations / 1000;

      expect(averageTimeMs, lessThan(0.1), reason: 'handleToDataRange should complete in <0.1ms (actual: ${averageTimeMs.toStringAsFixed(4)}ms)');

      print('handleToDataRange: ${averageTimeMs.toStringAsFixed(4)}ms avg over $iterations iterations');
    });

    test('Combined calculation sequence completes in <0.3ms', () {
      // This simulates the full calculation sequence during a drag update
      const dataRange = braven.DataRange(min: 0, max: 100);
      const viewportRange = braven.DataRange(min: 40, max: 60);
      const trackLength = 400.0;
      const minHandleSize = 44.0;
      const dragDelta = 10.0;

      // Warm up
      for (int i = 0; i < 100; i++) {
        final handleSize = ScrollbarController.calculateHandleSize(
          dataRange.span,
          viewportRange.span,
          trackLength,
          minHandleSize,
        );

        final scrollOffset = viewportRange.min - dataRange.min;
        final handlePosition = ScrollbarController.calculateHandlePosition(
          scrollOffset,
          dataRange.span,
          viewportRange.span,
          trackLength,
          minHandleSize,
        );

        final newHandlePosition = handlePosition + dragDelta;
        ScrollbarController.handleToDataRange(
          newHandlePosition,
          dataRange.span,
          viewportRange.span,
          trackLength,
          handleSize,
        );
      }

      // Measure performance of full sequence
      final stopwatch = Stopwatch()..start();
      const iterations = 1000;

      for (int i = 0; i < iterations; i++) {
        // Calculate current handle size
        final handleSize = ScrollbarController.calculateHandleSize(
          dataRange.span,
          viewportRange.span,
          trackLength,
          minHandleSize,
        );

        // Calculate current handle position
        final scrollOffset = viewportRange.min - dataRange.min;
        final handlePosition = ScrollbarController.calculateHandlePosition(
          scrollOffset,
          dataRange.span,
          viewportRange.span,
          trackLength,
          minHandleSize,
        );

        // Convert new handle position to data range
        final newHandlePosition = handlePosition + dragDelta;
        ScrollbarController.handleToDataRange(
          newHandlePosition,
          dataRange.span,
          viewportRange.span,
          trackLength,
          handleSize,
        );
      }

      stopwatch.stop();
      final averageTimeMs = stopwatch.elapsedMicroseconds / iterations / 1000;

      // Full sequence should be <0.3ms (conservative, allows for all 3 calculations)
      expect(averageTimeMs, lessThan(0.3),
          reason: 'Full calculation sequence should complete in <0.3ms (actual: ${averageTimeMs.toStringAsFixed(4)}ms)');

      print('Combined sequence: ${averageTimeMs.toStringAsFixed(4)}ms avg over $iterations iterations');
    });

    test('Performance remains consistent with varying data ranges', () {
      // Test with different data range sizes to ensure performance is independent of scale
      final testCases = [
        const braven.DataRange(min: 0, max: 100),
        const braven.DataRange(min: 0, max: 1000),
        const braven.DataRange(min: 0, max: 10000),
        const braven.DataRange(min: -5000, max: 5000),
      ];

      for (final dataRange in testCases) {
        final viewportRange = braven.DataRange(min: dataRange.min, max: dataRange.min + dataRange.span * 0.2);
        const trackLength = 400.0;
        const minHandleSize = 44.0;

        final stopwatch = Stopwatch()..start();
        const iterations = 1000;

        for (int i = 0; i < iterations; i++) {
          ScrollbarController.calculateHandleSize(
            dataRange.span,
            viewportRange.span,
            trackLength,
            minHandleSize,
          );
        }

        stopwatch.stop();
        final averageTimeMs = stopwatch.elapsedMicroseconds / iterations / 1000;

        expect(averageTimeMs, lessThan(0.1), reason: 'Performance should remain <0.1ms for dataRange ${dataRange.min}-${dataRange.max}');
      }
    });
  });
}
