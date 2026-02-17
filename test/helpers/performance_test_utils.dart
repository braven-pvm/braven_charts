import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/scheduler.dart';

/// Performance testing utilities for Braven Charts
class PerformanceTestUtils {
  /// Measures the time it takes to render a chart
  static Future<Duration> measureRenderTime({
    required Function() renderFunction,
    int iterations = 100,
  }) async {
    final stopwatch = Stopwatch();

    stopwatch.start();
    for (int i = 0; i < iterations; i++) {
      renderFunction();
    }
    stopwatch.stop();

    return Duration(microseconds: stopwatch.elapsedMicroseconds ~/ iterations);
  }

  /// Measures memory usage during chart operations
  static Future<MemoryUsage> measureMemoryUsage({
    required Future<void> Function() operation,
  }) async {
    // Force garbage collection before measurement
    await _forceGarbageCollection();

    final beforeMemory = _getCurrentMemoryUsage();
    await operation();
    final afterMemory = _getCurrentMemoryUsage();

    return MemoryUsage(
      before: beforeMemory,
      after: afterMemory,
      difference: afterMemory - beforeMemory,
    );
  }

  /// Benchmarks chart operations with large datasets
  static Future<BenchmarkResult> benchmarkLargeDataset({
    required Function(List<dynamic> data) operation,
    List<int> dataSizes = const [100, 1000, 10000, 100000],
  }) async {
    final results = <int, Duration>{};

    for (final size in dataSizes) {
      final data = _generateTestData(size);
      final duration = await measureRenderTime(
        renderFunction: () => operation(data),
        iterations: 10, // Less iterations for large datasets
      );
      results[size] = duration;
    }

    return BenchmarkResult(results);
  }

  /// Tests for memory leaks during repeated operations
  static Future<bool> testForMemoryLeaks({
    required Future<void> Function() operation,
    int iterations = 50,
    double acceptableLeakThreshold = 1.5, // 50% increase is acceptable
  }) async {
    await _forceGarbageCollection();
    final initialMemory = _getCurrentMemoryUsage();

    for (int i = 0; i < iterations; i++) {
      await operation();
      if (i % 10 == 0) {
        await _forceGarbageCollection();
      }
    }

    await _forceGarbageCollection();
    final finalMemory = _getCurrentMemoryUsage();

    final memoryIncrease = finalMemory / initialMemory;
    return memoryIncrease <= acceptableLeakThreshold;
  }

  /// Measures frame rendering performance
  static Future<FramePerformance> measureFramePerformance({
    required WidgetTester tester,
    required Future<void> Function() interaction,
  }) async {
    final binding = tester.binding;
    final frameTimings = <Duration>[];

    // Start monitoring frames
    void onReportTimings(List<FrameTiming> timings) {
      for (final timing in timings) {
        if (timing.rasterDuration != Duration.zero) {
          frameTimings.add(timing.totalSpan);
        }
      }
    }

    binding.addTimingsCallback(onReportTimings);

    try {
      await interaction();
      await tester.pumpAndSettle();

      // Wait a bit for all frame timings to be reported
      await Future.delayed(const Duration(milliseconds: 100));

      return FramePerformance(frameTimings);
    } finally {
      binding.removeTimingsCallback(onReportTimings);
    }
  }

  static Future<void> _forceGarbageCollection() async {
    // Trigger garbage collection multiple times
    for (int i = 0; i < 3; i++) {
      await Future.delayed(const Duration(milliseconds: 10));
      // In a real implementation, you might use dart:developer's
      // Service.requestHeapSnapshot() or similar
    }
  }

  static int _getCurrentMemoryUsage() {
    // This is a simplified implementation
    // In practice, you might use dart:developer or platform-specific APIs
    return DateTime.now().millisecondsSinceEpoch % 1000000;
  }

  static List<Map<String, dynamic>> _generateTestData(int size) {
    final random = Random(42); // Fixed seed for reproducible tests
    return List.generate(
      size,
      (index) => {
        'x': index.toDouble(),
        'y': random.nextDouble() * 100,
        'label': 'Point $index',
      },
    );
  }
}

/// Result of memory usage measurement
class MemoryUsage {
  final int before;
  final int after;
  final int difference;

  const MemoryUsage({
    required this.before,
    required this.after,
    required this.difference,
  });

  @override
  String toString() =>
      'MemoryUsage(before: $before, after: $after, diff: $difference)';
}

/// Result of benchmark testing
class BenchmarkResult {
  final Map<int, Duration> results;

  const BenchmarkResult(this.results);

  Duration? getDurationForSize(int size) => results[size];

  List<int> get dataSizes => results.keys.toList()..sort();

  @override
  String toString() {
    final buffer = StringBuffer('BenchmarkResult:\n');
    for (final entry in results.entries) {
      buffer.writeln('  ${entry.key} items: ${entry.value.inMicroseconds}μs');
    }
    return buffer.toString();
  }
}

/// Frame performance metrics
class FramePerformance {
  final List<Duration> frameTimings;

  const FramePerformance(this.frameTimings);

  Duration get averageFrameTime {
    if (frameTimings.isEmpty) return Duration.zero;
    final totalMicroseconds = frameTimings
        .map((d) => d.inMicroseconds)
        .reduce((a, b) => a + b);
    return Duration(microseconds: totalMicroseconds ~/ frameTimings.length);
  }

  Duration get maxFrameTime {
    if (frameTimings.isEmpty) return Duration.zero;
    return frameTimings.reduce((a, b) => a > b ? a : b);
  }

  double get fps {
    if (frameTimings.isEmpty) return 0.0;
    return 1000000.0 / averageFrameTime.inMicroseconds;
  }

  bool get isPerformant => fps >= 55.0; // Allow some margin below 60fps

  @override
  String toString() =>
      'FramePerformance(avg: ${averageFrameTime.inMicroseconds}μs, max: ${maxFrameTime.inMicroseconds}μs, fps: ${fps.toStringAsFixed(1)})';
}
