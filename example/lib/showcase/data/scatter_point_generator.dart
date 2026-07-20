// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/foundation.dart';

/// The source distribution used by [ScatterPointGenerator].
enum ScatterPointDistribution { uniform, normal, clustered }

/// Deterministic inputs for generating representative Scatter observations.
@immutable
class ScatterPointGeneratorConfig {
  const ScatterPointGeneratorConfig({
    this.pointCount = 250,
    this.xCenter = 50,
    this.yCenter = 50,
    this.xSpread = 80,
    this.ySpread = 60,
    this.correlation = 0.65,
    this.outlierFraction = 0.04,
    this.seed = 17,
    this.distribution = ScatterPointDistribution.normal,
  }) : assert(pointCount > 0),
       assert(xCenter > double.negativeInfinity && xCenter < double.infinity),
       assert(yCenter > double.negativeInfinity && yCenter < double.infinity),
       assert(xSpread >= 0 && xSpread < double.infinity),
       assert(ySpread >= 0 && ySpread < double.infinity),
       assert(correlation >= -1 && correlation <= 1),
       assert(outlierFraction >= 0 && outlierFraction <= 1);

  final int pointCount;
  final double xCenter;
  final double yCenter;
  final double xSpread;
  final double ySpread;
  final double correlation;
  final double outlierFraction;
  final int seed;
  final ScatterPointDistribution distribution;

  ScatterPointGeneratorConfig copyWith({
    int? pointCount,
    double? xCenter,
    double? yCenter,
    double? xSpread,
    double? ySpread,
    double? correlation,
    double? outlierFraction,
    int? seed,
    ScatterPointDistribution? distribution,
  }) {
    return ScatterPointGeneratorConfig(
      pointCount: pointCount ?? this.pointCount,
      xCenter: xCenter ?? this.xCenter,
      yCenter: yCenter ?? this.yCenter,
      xSpread: xSpread ?? this.xSpread,
      ySpread: ySpread ?? this.ySpread,
      correlation: correlation ?? this.correlation,
      outlierFraction: outlierFraction ?? this.outlierFraction,
      seed: seed ?? this.seed,
      distribution: distribution ?? this.distribution,
    );
  }
}

/// Produces bounded, X-ordered Scatter points for repeatable visual testing.
abstract final class ScatterPointGenerator {
  static List<ChartDataPoint> generate(
    ScatterPointGeneratorConfig config, {
    int seriesIndex = 0,
  }) {
    final random = math.Random(config.seed + seriesIndex * 104729);
    final points = <(int, ChartDataPoint)>[];
    final residualScale = math.sqrt(
      math.max(0, 1 - config.correlation * config.correlation),
    );

    for (var index = 0; index < config.pointCount; index++) {
      final xUnit = _sampleX(random, config.distribution);
      final residual = _boundedGaussian(random);
      final predicted = config.correlation * xUnit;
      var yUnit = (predicted + residualScale * residual).clamp(-1.0, 1.0);

      if (random.nextDouble() < config.outlierFraction) {
        final oppositeSign = predicted >= 0 ? -1.0 : 1.0;
        yUnit = oppositeSign * (0.78 + random.nextDouble() * 0.22);
      }

      points.add((
        index,
        ChartDataPoint(
          x: config.xCenter + xUnit * config.xSpread / 2,
          y: config.yCenter + yUnit * config.ySpread / 2,
        ),
      ));
    }

    points.sort((left, right) {
      final byX = left.$2.x.compareTo(right.$2.x);
      return byX != 0 ? byX : left.$1.compareTo(right.$1);
    });
    return [for (final entry in points) entry.$2];
  }

  static double _sampleX(
    math.Random random,
    ScatterPointDistribution distribution,
  ) {
    return switch (distribution) {
      ScatterPointDistribution.uniform => random.nextDouble() * 2 - 1,
      ScatterPointDistribution.normal => _boundedGaussian(random),
      ScatterPointDistribution.clustered =>
        ((random.nextBool() ? -0.55 : 0.55) + _boundedGaussian(random) * 0.18)
            .clamp(-1.0, 1.0),
    };
  }

  static double _boundedGaussian(math.Random random) {
    final first = 1 - random.nextDouble();
    final second = random.nextDouble();
    final gaussian =
        math.sqrt(-2 * math.log(first)) * math.cos(2 * math.pi * second);
    return (gaussian / 3).clamp(-1.0, 1.0);
  }
}
