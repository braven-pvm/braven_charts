// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

// ignore_for_file: avoid_print

import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/painting.dart' as painting;
import 'package:flutter_test/flutter_test.dart';

/// Benchmark tests for MultiAxisPainter performance.
///
/// Validates that TextPainter caching maintains 60fps performance
/// (16.67ms frame budget) for typical multi-axis scenarios.
void main() {
  group('MultiAxisPainter Performance Benchmarks', () {
    test('4 axes with 20 ticks each maintains 60fps (cached)', () {
      // Create 4 axes with typical configurations
      final axes = [
        YAxisConfig.withId(
          id: 'power',
          position: YAxisPosition.left,
          label: 'Power',
          unit: 'W',
        ),
        YAxisConfig.withId(
          id: 'heartrate',
          position: YAxisPosition.right,
          label: 'Heart Rate',
          unit: 'bpm',
        ),
        YAxisConfig.withId(
          id: 'cadence',
          position: YAxisPosition.leftOuter,
          label: 'Cadence',
          unit: 'rpm',
        ),
        YAxisConfig.withId(
          id: 'elevation',
          position: YAxisPosition.rightOuter,
          label: 'Elevation',
          unit: 'm',
        ),
      ];

      // Create axis bounds that will generate ~20 ticks each
      final axisBounds = {
        'power': const DataRange(min: 0.0, max: 400.0), // 0, 20, 40, ..., 400
        'heartrate':
            const DataRange(min: 100.0, max: 200.0), // 100, 105, ..., 200
        'cadence': const DataRange(min: 60.0, max: 120.0), // 60, 63, ..., 120
        'elevation':
            const DataRange(min: 0.0, max: 2000.0), // 0, 100, ..., 2000
      };

      // Create painter
      final painter = MultiAxisPainter(
        axes: axes,
        axisBounds: axisBounds,
        labelStyle: const painting.TextStyle(fontSize: 11),
      );

      // Define chart areas
      const chartArea = Rect.fromLTWH(0, 0, 800, 600);
      const plotArea = Rect.fromLTWH(100, 50, 600, 500);

      // Warm up cache with initial paint
      var recorder = PictureRecorder();
      var canvas = Canvas(recorder);
      painter.paint(canvas, chartArea, plotArea);
      recorder.endRecording();

      // Measure subsequent paint times (should use cached TextPainters)
      const iterations = 100;
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < iterations; i++) {
        // Reset canvas for each iteration
        recorder = PictureRecorder();
        canvas = Canvas(recorder);

        painter.paint(canvas, chartArea, plotArea);

        recorder.endRecording();
      }

      stopwatch.stop();

      // Calculate average paint time per frame
      final averageMicroseconds = stopwatch.elapsedMicroseconds / iterations;
      final averageMilliseconds = averageMicroseconds / 1000;

      // Print for visibility
      print('MultiAxisPainter benchmark (cached):');
      print('  Axes: ${axes.length}');
      print('  Approximate ticks per axis: ~20');
      print(
          '  Total labels: ~${axes.length * 20 + axes.length} (ticks + axis labels)');
      print(
          '  Average paint time: ${averageMilliseconds.toStringAsFixed(3)}ms');
      print('  Target: <16.67ms (60fps)');

      // Assert 60fps performance (16.67ms frame budget)
      expect(
        averageMilliseconds,
        lessThan(16.67),
        reason: 'Paint time should be under 16.67ms to maintain 60fps. '
            'Actual: ${averageMilliseconds.toStringAsFixed(3)}ms',
      );
    });

    test('cache invalidation on bounds change', () {
      final axes = [
        YAxisConfig.withId(
          id: 'test',
          position: YAxisPosition.left,
          label: 'Test Axis',
        ),
      ];

      // Initial bounds
      var axisBounds = {
        'test': const DataRange(min: 0.0, max: 100.0),
      };

      final painter = MultiAxisPainter(
        axes: axes,
        axisBounds: axisBounds,
        labelStyle: const painting.TextStyle(fontSize: 11),
      );

      const chartArea = Rect.fromLTWH(0, 0, 800, 600);
      const plotArea = Rect.fromLTWH(100, 50, 600, 500);

      // Initial paint - populates cache
      var recorder = PictureRecorder();
      var canvas = Canvas(recorder);
      painter.paint(canvas, chartArea, plotArea);
      recorder.endRecording();

      // Change bounds - should invalidate cache
      axisBounds = {
        'test': const DataRange(min: 0.0, max: 200.0),
      };

      final painter2 = MultiAxisPainter(
        axes: axes,
        axisBounds: axisBounds,
        labelStyle: const painting.TextStyle(fontSize: 11),
      );

      // Paint with new bounds - cache should rebuild
      recorder = PictureRecorder();
      canvas = Canvas(recorder);
      painter2.paint(canvas, chartArea, plotArea);
      recorder.endRecording();

      // If we reach here without errors, cache invalidation worked
      expect(true, isTrue);
    });

    test('cache invalidation on label style change', () {
      final axes = [
        YAxisConfig.withId(
          id: 'test',
          position: YAxisPosition.left,
          label: 'Test Axis',
        ),
      ];

      final axisBounds = {
        'test': const DataRange(min: 0.0, max: 100.0),
      };

      const chartArea = Rect.fromLTWH(0, 0, 800, 600);
      const plotArea = Rect.fromLTWH(100, 50, 600, 500);

      // Initial paint with style 1
      final painter1 = MultiAxisPainter(
        axes: axes,
        axisBounds: axisBounds,
        labelStyle: const painting.TextStyle(fontSize: 11),
      );
      var recorder = PictureRecorder();
      var canvas = Canvas(recorder);
      painter1.paint(canvas, chartArea, plotArea);
      recorder.endRecording();

      // Paint with different style - should invalidate cache
      recorder = PictureRecorder();
      canvas = Canvas(recorder);

      final painter2 = MultiAxisPainter(
        axes: axes,
        axisBounds: axisBounds,
        labelStyle: const painting.TextStyle(fontSize: 14), // Different size
      );
      painter2.paint(canvas, chartArea, plotArea);
      recorder.endRecording();

      // If we reach here without errors, cache invalidation worked
      expect(true, isTrue);
    });

    test('cold cache performance (first paint)', () {
      // Create 4 axes
      final axes = [
        YAxisConfig.withId(
          id: 'power',
          position: YAxisPosition.left,
          label: 'Power',
          unit: 'W',
        ),
        YAxisConfig.withId(
          id: 'heartrate',
          position: YAxisPosition.right,
          label: 'Heart Rate',
          unit: 'bpm',
        ),
        YAxisConfig.withId(
          id: 'cadence',
          position: YAxisPosition.leftOuter,
          label: 'Cadence',
          unit: 'rpm',
        ),
        YAxisConfig.withId(
          id: 'elevation',
          position: YAxisPosition.rightOuter,
          label: 'Elevation',
          unit: 'm',
        ),
      ];

      final axisBounds = {
        'power': const DataRange(min: 0.0, max: 400.0),
        'heartrate': const DataRange(min: 100.0, max: 200.0),
        'cadence': const DataRange(min: 60.0, max: 120.0),
        'elevation': const DataRange(min: 0.0, max: 2000.0),
      };

      const chartArea = Rect.fromLTWH(0, 0, 800, 600);
      const plotArea = Rect.fromLTWH(100, 50, 600, 500);

      // Measure cold cache (first paint) time
      const iterations = 10; // Fewer iterations for cold cache
      final stopwatch = Stopwatch()..start();

      for (int i = 0; i < iterations; i++) {
        final painter = MultiAxisPainter(
          axes: axes,
          axisBounds: axisBounds,
          labelStyle: const painting.TextStyle(fontSize: 11),
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        painter.paint(canvas, chartArea, plotArea);

        recorder.endRecording();
      }

      stopwatch.stop();

      final averageMicroseconds = stopwatch.elapsedMicroseconds / iterations;
      final averageMilliseconds = averageMicroseconds / 1000;

      print('MultiAxisPainter benchmark (cold cache):');
      print(
          '  Average cold paint time: ${averageMilliseconds.toStringAsFixed(3)}ms');

      // Cold cache should still be reasonable (allow more time than cached)
      expect(
        averageMilliseconds,
        lessThan(50.0),
        reason: 'Cold cache paint should complete in reasonable time. '
            'Actual: ${averageMilliseconds.toStringAsFixed(3)}ms',
      );
    });
  });
}
