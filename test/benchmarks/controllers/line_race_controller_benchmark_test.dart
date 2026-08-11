import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('line-race snapshots stay inside the interaction-frame budget', () {
    const seriesCount = 48;
    const frameCount = 240;
    final series = List<LineRaceSeries>.generate(
      seriesCount,
      (index) => LineRaceSeries(
        id: 'series-$index',
        name: 'Series $index',
        color: Color(0xFF2563EB + index % 12),
      ),
      growable: false,
    );
    final frames = List<LineRaceFrame>.generate(
      frameCount,
      (frame) => LineRaceFrame(
        id: 'frame-$frame',
        label: 'Frame $frame',
        x: frame.toDouble(),
        values: {
          for (var seriesIndex = 0; seriesIndex < seriesCount; seriesIndex++)
            'series-$seriesIndex':
                frame * (1 + seriesIndex / seriesCount) + seriesIndex,
        },
      ),
      growable: false,
    );
    final controller = LineRaceController(
      config: LineRaceConfig(series: series, frames: frames),
    )..seekToFrame(frameCount - 1);

    final samples = <int>[];
    for (var iteration = 0; iteration < 40; iteration++) {
      final stopwatch = Stopwatch()..start();
      final snapshot = controller.snapshot;
      expect(snapshot.pointsBySeries, hasLength(seriesCount));
      expect(snapshot.pointsFor('series-0'), hasLength(frameCount));
      stopwatch.stop();
      samples.add(stopwatch.elapsedMicroseconds);
    }
    samples.sort();
    final medianMicros = samples[samples.length ~/ 2];
    final p95Micros = samples[(samples.length * 0.95).floor()];

    // This is deliberately much larger than the maintained ten-series,
    // twenty-round showcase. Snapshot projection must leave enough of a
    // 16.67 ms frame for normal line layout and paint work.
    expect(medianMicros, lessThan(10000));
    expect(p95Micros, lessThan(20000));
  });
}
