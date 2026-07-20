// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts_example/showcase/data/scatter_point_generator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generator is deterministic, bounded, and X ordered', () {
    const config = ScatterPointGeneratorConfig(
      pointCount: 500,
      xCenter: 40,
      yCenter: 70,
      xSpread: 30,
      ySpread: 50,
      correlation: 0.55,
      outlierFraction: 0.08,
      seed: 31,
      distribution: ScatterPointDistribution.clustered,
    );

    final first = ScatterPointGenerator.generate(config);
    final second = ScatterPointGenerator.generate(config);

    expect(first, hasLength(500));
    expect(
      first.map((point) => (point.x, point.y)),
      orderedEquals(second.map((point) => (point.x, point.y))),
    );
    expect(first.every((point) => point.x >= 25 && point.x <= 55), isTrue);
    expect(first.every((point) => point.y >= 45 && point.y <= 95), isTrue);
    expect(
      first.indexed
          .skip(1)
          .every((entry) => first[entry.$1 - 1].x <= entry.$2.x),
      isTrue,
    );
  });

  test('seed and series index generate distinct repeatable cohorts', () {
    const config = ScatterPointGeneratorConfig(pointCount: 40, seed: 9);

    final base = ScatterPointGenerator.generate(config);
    final nextSeed = ScatterPointGenerator.generate(config.copyWith(seed: 10));
    final nextSeries = ScatterPointGenerator.generate(config, seriesIndex: 1);

    expect(
      base.map((point) => point.y),
      isNot(orderedEquals(nextSeed.map((point) => point.y))),
    );
    expect(
      base.map((point) => point.y),
      isNot(orderedEquals(nextSeries.map((point) => point.y))),
    );
    expect(
      ScatterPointGenerator.generate(
        config,
        seriesIndex: 1,
      ).map((point) => (point.x, point.y)),
      orderedEquals(nextSeries.map((point) => (point.x, point.y))),
    );
  });

  test('correlation control changes the generated relationship direction', () {
    const base = ScatterPointGeneratorConfig(
      pointCount: 2000,
      outlierFraction: 0,
      seed: 7,
    );

    final positive = ScatterPointGenerator.generate(
      base.copyWith(correlation: 0.9),
    );
    final negative = ScatterPointGenerator.generate(
      base.copyWith(correlation: -0.9),
    );

    expect(_covarianceSign(positive), 1);
    expect(_covarianceSign(negative), -1);
  });
}

int _covarianceSign(Iterable<ChartDataPoint> points) {
  final values = points.toList();
  final meanX =
      values.fold<double>(0, (sum, point) => sum + point.x) / values.length;
  final meanY =
      values.fold<double>(0, (sum, point) => sum + point.y) / values.length;
  final covariance = values.fold<double>(
    0,
    (sum, point) => sum + (point.x - meanX) * (point.y - meanY),
  );
  return covariance.sign.toInt();
}
