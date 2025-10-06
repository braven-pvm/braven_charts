/// Benchmarks for theme switching performance.
///
/// Measures theme switch time and cache invalidation performance.
/// Target: <100ms theme switch time (FR-009)
library;

import 'dart:ui';

import 'package:braven_charts/src/foundation/performance/object_pool.dart';
import 'package:braven_charts/src/foundation/performance/viewport_culler.dart';
import 'package:braven_charts/src/rendering/performance_monitor.dart';
import 'package:braven_charts/src/rendering/render_context.dart';
import 'package:braven_charts/src/rendering/text_layout_cache.dart';
import 'package:braven_charts/src/theming/chart_theme.dart';
import 'package:braven_charts/src/theming/extensions/render_context_theme_extension.dart';
import 'package:flutter/material.dart' show TextPainter;

void main() {
  print('=== Theme Switching Benchmark ===\n');

  // Setup
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);
  final context = RenderContext(
    canvas: canvas,
    size: const Size(1920, 1080),
    viewport: const Rect.fromLTWH(0, 0, 1920, 1080),
    culler: const ViewportCuller(),
    paintPool: ObjectPool<Paint>(factory: () => Paint(), reset: (p) {}),
    pathPool: ObjectPool<Path>(factory: () => Path(), reset: (p) => p.reset()),
    textPainterPool: ObjectPool<TextPainter>(
      factory: () => TextPainter(textDirection: TextDirection.ltr),
      reset: (tp) {},
    ),
    textCache: LinkedHashMapTextLayoutCache(),
    performanceMonitor: StopwatchPerformanceMonitor(),
  );

  // Warm up
  context.applyTheme(ChartTheme.defaultLight);
  context.updateTheme(ChartTheme.defaultDark);

  print('Benchmark 1: Initial theme application (cold cache)');
  _benchmarkInitialApplication(context);
  print('');

  print('Benchmark 2: Theme switching (identical theme - no change)');
  _benchmarkIdenticalSwitch(context);
  print('');

  print('Benchmark 3: Theme switching (light to dark)');
  _benchmarkLightToDark(context);
  print('');

  print('Benchmark 4: Theme switching (between similar themes)');
  _benchmarkSimilarThemes(context);
  print('');

  print('Benchmark 5: Theme switching (completely different themes)');
  _benchmarkDifferentThemes(context);
  print('');

  print('Benchmark 6: Rapid theme switching (stress test)');
  _benchmarkRapidSwitching(context);
  print('');

  print('=== Performance Summary ===');
  print('Target: <100ms per theme switch');
  print(_allBenchmarksPassed ? 'All benchmarks PASSED' : 'Some benchmarks FAILED');
}

bool _allBenchmarksPassed = true;

void _benchmarkInitialApplication(RenderContext context) {
  const iterations = 1000;
  final sw = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    context.applyTheme(ChartTheme.defaultLight);
  }

  sw.stop();
  final avgMs = sw.elapsedMicroseconds / iterations / 1000;

  print('  Iterations: $iterations');
  print('  Total time: ${sw.elapsedMilliseconds}ms');
  print('  Average: ${avgMs.toStringAsFixed(3)}ms');
  print('  Status: ${avgMs < 100 ? "PASS" : "FAIL"}');

  if (avgMs >= 100) _allBenchmarksPassed = false;
}

void _benchmarkIdenticalSwitch(RenderContext context) {
  context.applyTheme(ChartTheme.defaultLight);

  const iterations = 10000;
  final sw = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    context.updateTheme(ChartTheme.defaultLight);
  }

  sw.stop();
  final avgMs = sw.elapsedMicroseconds / iterations / 1000;

  print('  Iterations: $iterations');
  print('  Total time: ${sw.elapsedMilliseconds}ms');
  print('  Average: ${avgMs.toStringAsFixed(3)}ms');
  print('  Status: ${avgMs < 100 ? "PASS" : "FAIL"}');

  if (avgMs >= 100) _allBenchmarksPassed = false;
}

void _benchmarkLightToDark(RenderContext context) {
  const iterations = 1000;
  final sw = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    if (i % 2 == 0) {
      context.updateTheme(ChartTheme.defaultLight);
    } else {
      context.updateTheme(ChartTheme.defaultDark);
    }
  }

  sw.stop();
  final avgMs = sw.elapsedMicroseconds / iterations / 1000;

  print('  Iterations: $iterations');
  print('  Total time: ${sw.elapsedMilliseconds}ms');
  print('  Average: ${avgMs.toStringAsFixed(3)}ms');
  print('  Status: ${avgMs < 100 ? "PASS" : "FAIL"}');

  if (avgMs >= 100) _allBenchmarksPassed = false;
}

void _benchmarkSimilarThemes(RenderContext context) {
  final theme1 = ChartTheme.defaultLight;
  final theme2 = ChartTheme.defaultLight.copyWith(
    backgroundColor: const Color(0xFFF5F5F5),
  );

  const iterations = 1000;
  final sw = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    if (i % 2 == 0) {
      context.updateTheme(theme1);
    } else {
      context.updateTheme(theme2);
    }
  }

  sw.stop();
  final avgMs = sw.elapsedMicroseconds / iterations / 1000;

  print('  Iterations: $iterations');
  print('  Total time: ${sw.elapsedMilliseconds}ms');
  print('  Average: ${avgMs.toStringAsFixed(3)}ms');
  print('  Status: ${avgMs < 100 ? "PASS" : "FAIL"}');

  if (avgMs >= 100) _allBenchmarksPassed = false;
}

void _benchmarkDifferentThemes(RenderContext context) {
  const iterations = 1000;
  final themes = [
    ChartTheme.defaultLight,
    ChartTheme.defaultDark,
    ChartTheme.vibrant,
    ChartTheme.corporateBlue,
    ChartTheme.minimal,
  ];

  final sw = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    context.updateTheme(themes[i % themes.length]);
  }

  sw.stop();
  final avgMs = sw.elapsedMicroseconds / iterations / 1000;

  print('  Iterations: $iterations');
  print('  Total time: ${sw.elapsedMilliseconds}ms');
  print('  Average: ${avgMs.toStringAsFixed(3)}ms');
  print('  Status: ${avgMs < 100 ? "PASS" : "FAIL"}');

  if (avgMs >= 100) _allBenchmarksPassed = false;
}

void _benchmarkRapidSwitching(RenderContext context) {
  const iterations = 5000;
  final themes = [
    ChartTheme.defaultLight,
    ChartTheme.defaultDark,
  ];

  final sw = Stopwatch()..start();

  for (var i = 0; i < iterations; i++) {
    context.updateTheme(themes[i % 2]);
  }

  sw.stop();
  final avgMs = sw.elapsedMicroseconds / iterations / 1000;

  print('  Iterations: $iterations (rapid alternation)');
  print('  Total time: ${sw.elapsedMilliseconds}ms');
  print('  Average: ${avgMs.toStringAsFixed(3)}ms');
  print('  Status: ${avgMs < 100 ? "PASS" : "FAIL"}');

  if (avgMs >= 100) _allBenchmarksPassed = false;
}
