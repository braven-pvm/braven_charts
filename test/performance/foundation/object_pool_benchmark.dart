// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:braven_charts/legacy/src/foundation/performance/object_pool.dart';

/// Benchmark for ObjectPool acquire/release performance.
///
/// Target: <100ns per operation (FR-005.3)
/// Test: 10k acquire/release cycles
class ObjectPoolAcquireBenchmark extends BenchmarkBase {
  ObjectPoolAcquireBenchmark() : super('ObjectPool Acquire/Release');

  static const int iterations = 10000;
  late ObjectPool<_TestObject> _pool;

  @override
  void setup() {
    _pool = ObjectPool<_TestObject>(
      factory: () => _TestObject(),
      reset: (obj) {
        obj.x = 0.0;
        obj.y = 0.0;
      },
      maxSize: 100,
    );
    // Warmup to fill pool
    for (int i = 0; i < 100; i++) {
      final obj = _pool.acquire();
      _pool.release(obj);
    }
  }

  @override
  void run() {
    final objects = <_TestObject>[];
    for (int i = 0; i < iterations; i++) {
      objects.add(_pool.acquire());
    }
    for (final obj in objects) {
      _pool.release(obj);
    }
    objects.clear();
  }

  @override
  void teardown() {
    _pool.clear();
    super.teardown();
  }
}

/// Benchmark for ObjectPool with high reuse (simulates real usage).
class ObjectPoolReusePatternBenchmark extends BenchmarkBase {
  ObjectPoolReusePatternBenchmark() : super('ObjectPool Reuse Pattern');

  static const int iterations = 1000;
  late ObjectPool<_TestObject> _pool;

  @override
  void setup() {
    _pool = ObjectPool<_TestObject>(
      factory: () => _TestObject(),
      reset: (obj) {
        obj.x = 0.0;
        obj.y = 0.0;
      },
      maxSize: 50,
    );
  }

  @override
  void run() {
    // Simulates typical usage: acquire 10, release 10, repeat
    for (int cycle = 0; cycle < iterations; cycle++) {
      final objects = <_TestObject>[];
      for (int i = 0; i < 10; i++) {
        objects.add(_pool.acquire());
      }
      for (final obj in objects) {
        _pool.release(obj);
      }
    }
  }

  @override
  void teardown() {
    _pool.clear();
    super.teardown();
  }
}

class _TestObject {
  double x = 0.0;
  double y = 0.0;
}

void main() {
  print('=== ObjectPool Performance Benchmarks ===\n');

  // Run acquire/release benchmark
  final acquireBench = ObjectPoolAcquireBenchmark();
  acquireBench.report();

  final acquireTimeMs = acquireBench.measure();
  final nsPerOperation =
      (acquireTimeMs * 1000000) / (ObjectPoolAcquireBenchmark.iterations * 2);

  print('');
  print('Results (acquire + release):');
  print('  Time:   ${nsPerOperation.toStringAsFixed(1)} ns/operation');
  print('  Target: <100.0 ns/operation');
  print('  Status: ${nsPerOperation < 100.0 ? "✅ PASS" : "❌ FAIL"}');
  print('');

  // Run reuse pattern benchmark
  final reuseBench = ObjectPoolReusePatternBenchmark();
  reuseBench.report();

  final reuseTimeMs = reuseBench.measure();
  final msPerCycle = reuseTimeMs / ObjectPoolReusePatternBenchmark.iterations;

  print('');
  print('Results (10 acquire/release per cycle):');
  print('  Time:   ${msPerCycle.toStringAsFixed(3)} ms/cycle');
  print('  Target: <0.001 ms/cycle (10 ops @ 100ns each)');
  print('  Status: ${msPerCycle < 0.001 ? "✅ PASS" : "❌ FAIL"}');
  print('');

  // Summary
  print('=== Summary ===');
  final allPass = nsPerOperation < 100.0 && msPerCycle < 0.001;
  print('Overall: ${allPass ? "✅ ALL TARGETS MET" : "❌ SOME TARGETS FAILED"}');
}
