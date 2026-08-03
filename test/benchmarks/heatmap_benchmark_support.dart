// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

/// A deterministic summary of repeated benchmark samples.
final class HeatmapBenchmarkDistribution {
  HeatmapBenchmarkDistribution.fromMicroseconds(Iterable<int> samples)
    : samples = List<int>.of(samples)..sort() {
    if (this.samples.isEmpty) {
      throw ArgumentError.value(samples, 'samples', 'must not be empty');
    }
  }

  final List<int> samples;

  int get medianMicros => samples[samples.length ~/ 2];

  int get p95Micros => samples[(samples.length * 0.95).ceil() - 1];

  int get maximumMicros => samples.last;

  double get medianMillis => medianMicros / 1000;

  double get p95Millis => p95Micros / 1000;

  double get maximumMillis => maximumMicros / 1000;
}

HeatmapBenchmarkDistribution measureHeatmapSync(
  void Function() operation, {
  int warmupIterations = 2,
  int measuredIterations = 12,
}) {
  for (var iteration = 0; iteration < warmupIterations; iteration++) {
    operation();
  }
  final samples = <int>[];
  for (var iteration = 0; iteration < measuredIterations; iteration++) {
    final stopwatch = Stopwatch()..start();
    operation();
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds);
  }
  return HeatmapBenchmarkDistribution.fromMicroseconds(samples);
}

Future<HeatmapBenchmarkDistribution> measureHeatmapAsync(
  Future<void> Function() operation, {
  int warmupIterations = 2,
  int measuredIterations = 12,
}) async {
  for (var iteration = 0; iteration < warmupIterations; iteration++) {
    await operation();
  }
  final samples = <int>[];
  for (var iteration = 0; iteration < measuredIterations; iteration++) {
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    samples.add(stopwatch.elapsedMicroseconds);
  }
  return HeatmapBenchmarkDistribution.fromMicroseconds(samples);
}

void printHeatmapDistribution(
  String label,
  HeatmapBenchmarkDistribution distribution,
) {
  // ignore: avoid_print
  print(
    '$label: median ${distribution.medianMillis.toStringAsFixed(3)}ms; '
    'p95 ${distribution.p95Millis.toStringAsFixed(3)}ms; '
    'max ${distribution.maximumMillis.toStringAsFixed(3)}ms; '
    'n=${distribution.samples.length}',
  );
}
