import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('bar-race ranking stays below the interaction-frame budget', () {
    const categoryCount = 2000;
    const frameCount = 80;
    final categories = List<BarRaceCategory>.generate(
      categoryCount,
      (index) => BarRaceCategory(
        id: 'category-$index',
        label: 'Category $index',
        color: Color(0xFF2563EB + index % 12),
      ),
      growable: false,
    );
    final frames = List<BarRaceFrame>.generate(
      frameCount,
      (frame) => BarRaceFrame(
        id: 'frame-$frame',
        label: '$frame',
        values: {
          for (var category = 0; category < categoryCount; category++)
            'category-$category': ((category * 37 + frame * 101) % 10000)
                .toDouble(),
        },
      ),
      growable: false,
    );
    final controller = BarRaceController(
      config: BarRaceConfig(
        categories: categories,
        frames: frames,
        topCount: 20,
        axisRange: BarRaceAxisRange.fixed,
      ),
    );

    final samples = <int>[];
    for (var iteration = 0; iteration < frameCount; iteration++) {
      controller.seekToFrame(iteration);
      final stopwatch = Stopwatch()..start();
      expect(controller.rankedValues, hasLength(20));
      expect(controller.effectiveAxisMaximum, greaterThan(0));
      stopwatch.stop();
      samples.add(stopwatch.elapsedMicroseconds);
    }
    samples.sort();
    final medianMicros = samples[samples.length ~/ 2];
    final p95Micros = samples[(samples.length * 0.95).floor()];

    // Ranking is the only non-paint work on a new frame. Keep even a
    // deliberately oversized 2,000-category source below the 5 ms layout
    // budget on the benchmark host. Revisited frames use the bounded cache.
    expect(medianMicros, lessThan(5000));
    expect(p95Micros, lessThan(10000));

    controller.seekToFrame(frameCount - 1);
    final cached = controller.rankedValues;
    expect(identical(controller.rankedValues, cached), isTrue);
  });
}
