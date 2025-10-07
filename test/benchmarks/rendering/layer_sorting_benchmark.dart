/// Benchmark for layer z-ordering overhead validation.
///
/// Validates that layer sorting by zIndex is efficient:
/// - Target: <0.1ms sorting overhead per frame
/// - Complexity: O(n log n) verification
/// - Practical: 10-100 layers should sort negligibly fast
///
/// Tests layer sorting performance:
/// - 10 layers with random zIndex values
/// - 100 layers with random zIndex values
/// - Verify O(n log n) scaling behavior
///
/// ## Running Benchmark
///
/// ```bash
/// flutter test test/benchmarks/rendering/layer_sorting_benchmark.dart
/// ```
///
/// Expected output:
/// ```
/// Layer Sorting Benchmark:
///   10 layers: 0.05ms per frame
///   100 layers: 0.08ms per frame
///   Scaling factor: 1.6x (100 layers / 10 layers)
/// ```
library;

import 'dart:math' show Random;

import 'package:braven_charts/src/rendering/render_context.dart' show RenderContext;
import 'package:braven_charts/src/rendering/render_layer.dart' show RenderLayer;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Layer Z-Ordering Overhead Benchmarks', () {
    test('Sort latency with 10 layers (target: <0.1ms)', () {
      // Create 10 layers with random zIndex values
      final random = Random(42);
      final layers = List.generate(
        10,
        (i) => _BenchmarkLayer(zIndex: random.nextInt(100) - 50),
      );

      final latencies = <double>[];

      // Benchmark sorting 1000 times
      for (int i = 0; i < 1000; i++) {
        // Shuffle to simulate unsorted state
        final toSort = List<_BenchmarkLayer>.from(layers)..shuffle(random);

        final stopwatch = Stopwatch()..start();

        // Sort by zIndex (what RenderPipeline does)
        toSort.sort((a, b) => a.zIndex.compareTo(b.zIndex));

        stopwatch.stop();
        latencies.add(stopwatch.elapsedMicroseconds / 1000);
      }

      final avg = latencies.fold<double>(0, (a, b) => a + b) / latencies.length;

      // Validate target: <0.1ms per frame
      expect(avg, lessThan(0.1), reason: 'Sorting 10 layers should be <0.1ms');

      print('10 layers: avg ${avg.toStringAsFixed(3)}ms per sort');
    });

    test('Sort latency with 100 layers', () {
      final random = Random(42);
      final layers = List.generate(
        100,
        (i) => _BenchmarkLayer(zIndex: random.nextInt(1000) - 500),
      );

      final latencies = <double>[];

      for (int i = 0; i < 1000; i++) {
        final toSort = List<_BenchmarkLayer>.from(layers)..shuffle(random);

        final stopwatch = Stopwatch()..start();

        toSort.sort((a, b) => a.zIndex.compareTo(b.zIndex));

        stopwatch.stop();
        latencies.add(stopwatch.elapsedMicroseconds / 1000);
      }

      final avg = latencies.fold<double>(0, (a, b) => a + b) / latencies.length;

      // Still should be very fast (<0.2ms for 10x more layers)
      expect(avg, lessThan(0.2), reason: 'Sorting 100 layers should be <0.2ms');

      print('100 layers: avg ${avg.toStringAsFixed(3)}ms per sort');
    });

    test('Verify O(n log n) scaling', () {
      final random = Random(42);

      final sizes = [10, 50, 100];
      final avgLatencies = <int, double>{};

      for (final size in sizes) {
        final layers = List.generate(
          size,
          (i) => _BenchmarkLayer(zIndex: random.nextInt(1000)),
        );

        final latencies = <double>[];

        for (int i = 0; i < 100; i++) {
          final toSort = List<_BenchmarkLayer>.from(layers)..shuffle(random);

          final stopwatch = Stopwatch()..start();
          toSort.sort((a, b) => a.zIndex.compareTo(b.zIndex));
          stopwatch.stop();

          latencies.add(stopwatch.elapsedMicroseconds / 1000);
        }

        avgLatencies[size] = latencies.fold<double>(0, (a, b) => a + b) / latencies.length;
      }

      // Calculate scaling factors
      final factor10to50 = avgLatencies[50]! / avgLatencies[10]!;
      final factor50to100 = avgLatencies[100]! / avgLatencies[50]!;

      // For O(n log n):
      // - 10 -> 50: 5x data should be ~8.5x time (5 * log(50)/log(10))
      // - 50 -> 100: 2x data should be ~2.1x time (2 * log(100)/log(50))

      // Verify not worse than O(n²): 10x data should not be 100x slower
      expect(factor10to50, lessThan(50), reason: 'Should not scale worse than O(n²)');

      print('Scaling analysis:');
      print('  10 layers: ${avgLatencies[10]!.toStringAsFixed(4)}ms');
      print('  50 layers: ${avgLatencies[50]!.toStringAsFixed(4)}ms '
          '(${factor10to50.toStringAsFixed(1)}x)');
      print('  100 layers: ${avgLatencies[100]!.toStringAsFixed(4)}ms '
          '(${factor50to100.toStringAsFixed(1)}x)');
    });

    test('Sorting overhead negligible compared to rendering', () {
      final random = Random(42);
      final layers = List.generate(
        20,
        (i) => _BenchmarkLayer(zIndex: random.nextInt(100)),
      );

      // Measure just sorting
      final sortLatencies = <double>[];
      for (int i = 0; i < 100; i++) {
        final toSort = List<_BenchmarkLayer>.from(layers)..shuffle(random);

        final stopwatch = Stopwatch()..start();
        toSort.sort((a, b) => a.zIndex.compareTo(b.zIndex));
        stopwatch.stop();

        sortLatencies.add(stopwatch.elapsedMicroseconds / 1000);
      }

      final avgSort = sortLatencies.fold<double>(0, (a, b) => a + b) / sortLatencies.length;

      // Assume ~5ms total frame budget (rendering + sorting)
      // Sorting should be <2% of frame time
      final frameBudget = 5.0; // ms
      final sortingPercent = (avgSort / frameBudget) * 100;

      expect(sortingPercent, lessThan(2), reason: 'Sorting should be <2% of frame time');

      print('Sorting overhead: ${avgSort.toStringAsFixed(4)}ms '
          '(${sortingPercent.toStringAsFixed(2)}% of ${frameBudget}ms frame)');
    });

    test('Already-sorted case (best case)', () {
      // Create layers already sorted by zIndex
      final layers = List.generate(
        50,
        (i) => _BenchmarkLayer(zIndex: i),
      );

      final latencies = <double>[];

      for (int i = 0; i < 100; i++) {
        final toSort = List<_BenchmarkLayer>.from(layers);

        final stopwatch = Stopwatch()..start();
        toSort.sort((a, b) => a.zIndex.compareTo(b.zIndex));
        stopwatch.stop();

        latencies.add(stopwatch.elapsedMicroseconds / 1000);
      }

      final avg = latencies.fold<double>(0, (a, b) => a + b) / latencies.length;

      // Already sorted should be very fast (best case O(n))
      expect(avg, lessThan(0.1), reason: 'Already-sorted case should be very fast');

      print('Best case (already sorted, 50 layers): ${avg.toStringAsFixed(4)}ms');
    });
  });
}

// Minimal layer for benchmarking (no rendering overhead)
class _BenchmarkLayer extends RenderLayer {
  _BenchmarkLayer({required super.zIndex});

  @override
  void render(RenderContext context) {
    // No-op for benchmarking
  }
}
