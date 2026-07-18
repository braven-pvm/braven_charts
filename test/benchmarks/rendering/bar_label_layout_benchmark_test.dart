import 'dart:ui';

import 'package:braven_charts/src/models/bar_chart_style.dart';
import 'package:braven_charts/src/rendering/bar_label_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('places 5,000 collision-aware labels within one 60fps frame', () {
    const labelCount = 5000;
    const iterations = 20;

    BarLabelLayoutCoordinator runLayout() {
      final coordinator = BarLabelLayoutCoordinator(
        plotBounds: const Rect.fromLTWH(0, 0, 200000, 120),
        collisionCellSize: 32,
      );
      for (var index = 0; index < labelCount; index++) {
        final result = coordinator.place(
          candidates: [Rect.fromLTWH(index * 36.0, 24, 18, 10)],
          collisionPolicy: BarLabelCollisionPolicy.hide,
          plotEdgeAware: true,
          collisionPadding: 2,
        );
        expect(result, isNotNull);
      }
      return coordinator;
    }

    for (var warmup = 0; warmup < 5; warmup++) {
      runLayout();
    }

    final stopwatch = Stopwatch()..start();
    BarLabelLayoutCoordinator? lastCoordinator;
    for (var iteration = 0; iteration < iterations; iteration++) {
      lastCoordinator = runLayout();
    }
    stopwatch.stop();

    final averageMilliseconds =
        stopwatch.elapsedMicroseconds / iterations / 1000;
    // ignore: avoid_print
    print(
      'Bar label layout ($labelCount labels): '
      '${averageMilliseconds.toStringAsFixed(3)}ms average',
    );
    expect(lastCoordinator!.occupiedBounds, hasLength(labelCount));
    expect(lastCoordinator.collisionComparisonCount, lessThan(labelCount * 3));
    expect(averageMilliseconds, lessThan(16.67));
  });
}
