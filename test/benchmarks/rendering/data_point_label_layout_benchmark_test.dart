import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/data_point_label_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('places 5,000 collision-aware point labels within one frame', () {
    const labelCount = 5000;
    const iterations = 20;

    DataPointLabelLayoutCoordinator runLayout() {
      final coordinator = DataPointLabelLayoutCoordinator(
        plotBounds: const Rect.fromLTWH(0, 0, 200000, 120),
        collisionCellSize: 32,
      );
      for (var index = 0; index < labelCount; index++) {
        final result = coordinator.place(
          candidates: [Rect.fromLTWH(index * 36.0, 24, 24, 12)],
          collisionPolicy: DataPointLabelCollisionPolicy.hide,
          collisionPadding: 2,
          plotEdgeAware: true,
        );
        expect(result, isNotNull);
      }
      return coordinator;
    }

    for (var warmup = 0; warmup < 5; warmup++) {
      runLayout();
    }
    final stopwatch = Stopwatch()..start();
    DataPointLabelLayoutCoordinator? latest;
    for (var iteration = 0; iteration < iterations; iteration++) {
      latest = runLayout();
    }
    stopwatch.stop();
    final averageMs = stopwatch.elapsedMicroseconds / iterations / 1000;
    // ignore: avoid_print
    print(
      'Point label layout ($labelCount labels): '
      '${averageMs.toStringAsFixed(3)}ms average; '
      '${latest!.collisionComparisonCount} exact comparisons',
    );
    expect(averageMs, lessThan(16.67));
  });
}
