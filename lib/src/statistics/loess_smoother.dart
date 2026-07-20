import 'dart:math' as math;

import '../models/chart_data_point.dart';

/// Deterministic locally weighted linear regression for chart trend overlays.
///
/// The implementation uses a tricube distance kernel and optional Tukey
/// bisquare robustness passes. Inputs are sorted, non-finite coordinates are
/// ignored, and very dense datasets are sampled evenly before fitting so a
/// trend annotation cannot accidentally introduce quadratic work over an
/// unbounded source series.
class LoessSmoother {
  const LoessSmoother({
    this.span = 0.5,
    this.robustnessIterations = 2,
    this.sampleCount = 100,
    this.maximumInputPoints = 2048,
  }) : assert(span > 0 && span <= 1),
       assert(robustnessIterations >= 0),
       assert(sampleCount >= 2),
       assert(maximumInputPoints >= 3);

  /// Fraction of fitting points used by each local regression.
  final double span;

  /// Number of residual-based Tukey bisquare reweighting passes.
  final int robustnessIterations;

  /// Number of evenly spaced points emitted across the finite X domain.
  final int sampleCount;

  /// Deterministic upper bound for fitting work on dense input series.
  final int maximumInputPoints;

  /// Returns a smooth finite curve ordered by X.
  List<ChartDataPoint> smooth(Iterable<ChartDataPoint> source) {
    final finite = <_IndexedPoint>[];
    var sourceIndex = 0;
    for (final point in source) {
      if (point.x.isFinite && point.y.isFinite) {
        finite.add(_IndexedPoint(point, sourceIndex));
      }
      sourceIndex++;
    }
    if (finite.length < 2) return const [];
    finite.sort((first, second) {
      final xOrder = first.point.x.compareTo(second.point.x);
      return xOrder != 0
          ? xOrder
          : first.sourceIndex.compareTo(second.sourceIndex);
    });

    final fitPoints = _evenlySample(finite, maximumInputPoints);
    final minimumX = fitPoints.first.point.x;
    final maximumX = fitPoints.last.point.x;
    if (minimumX == maximumX) return const [];

    final neighborhoodSize = math.max(
      2,
      math.min(fitPoints.length, (span * fitPoints.length).ceil()),
    );
    var robustnessWeights = List<double>.filled(fitPoints.length, 1);
    for (var iteration = 0; iteration < robustnessIterations; iteration++) {
      final residuals = <double>[];
      for (var index = 0; index < fitPoints.length; index++) {
        final point = fitPoints[index].point;
        final fitted = _estimate(
          fitPoints,
          point.x,
          neighborhoodSize,
          robustnessWeights,
        );
        residuals.add((point.y - fitted).abs());
      }
      final medianResidual = _median(residuals);
      if (medianResidual <= 1e-12) break;
      final cutoff = 6 * medianResidual;
      robustnessWeights = [
        for (final residual in residuals)
          if (residual >= cutoff)
            0
          else
            math.pow(1 - math.pow(residual / cutoff, 2), 2).toDouble(),
      ];
    }

    final result = <ChartDataPoint>[];
    final step = (maximumX - minimumX) / (sampleCount - 1);
    for (var index = 0; index < sampleCount; index++) {
      final x = index == sampleCount - 1 ? maximumX : minimumX + step * index;
      final y = _estimate(fitPoints, x, neighborhoodSize, robustnessWeights);
      if (y.isFinite) result.add(ChartDataPoint(x: x, y: y));
    }
    return result;
  }

  List<_IndexedPoint> _evenlySample(
    List<_IndexedPoint> points,
    int maximumCount,
  ) {
    if (points.length <= maximumCount) return points;
    return [
      for (var index = 0; index < maximumCount; index++)
        points[((index * (points.length - 1)) / (maximumCount - 1)).round()],
    ];
  }

  double _estimate(
    List<_IndexedPoint> points,
    double targetX,
    int neighborhoodSize,
    List<double> robustnessWeights,
  ) {
    final neighborhood = _neighborhood(points, targetX, neighborhoodSize);
    var maximumDistance = 0.0;
    for (var index = neighborhood.start; index < neighborhood.end; index++) {
      maximumDistance = math.max(
        maximumDistance,
        (points[index].point.x - targetX).abs(),
      );
    }
    if (maximumDistance <= 1e-12) {
      return _localMean(points, neighborhood, robustnessWeights);
    }

    // Keep the outermost member inside the compact-support kernel despite
    // floating-point equality at u == 1.
    final bandwidth = maximumDistance * 1.0000001;
    var sumWeight = 0.0;
    var sumWeightedX = 0.0;
    var sumWeightedY = 0.0;
    var sumWeightedX2 = 0.0;
    var sumWeightedXY = 0.0;
    for (var index = neighborhood.start; index < neighborhood.end; index++) {
      final point = points[index].point;
      final normalizedDistance = ((point.x - targetX).abs() / bandwidth).clamp(
        0.0,
        1.0,
      );
      final tricube = math
          .pow(1 - math.pow(normalizedDistance, 3), 3)
          .toDouble();
      final weight = tricube * robustnessWeights[index];
      if (weight <= 0) continue;
      final centeredX = point.x - targetX;
      sumWeight += weight;
      sumWeightedX += weight * centeredX;
      sumWeightedY += weight * point.y;
      sumWeightedX2 += weight * centeredX * centeredX;
      sumWeightedXY += weight * centeredX * point.y;
    }
    if (sumWeight <= 1e-12) {
      return _localMean(points, neighborhood, const []);
    }
    final denominator = sumWeight * sumWeightedX2 - sumWeightedX * sumWeightedX;
    if (denominator.abs() <= 1e-12) return sumWeightedY / sumWeight;
    return (sumWeightedY * sumWeightedX2 - sumWeightedX * sumWeightedXY) /
        denominator;
  }

  double _localMean(
    List<_IndexedPoint> points,
    _IndexRange neighborhood,
    List<double> robustnessWeights,
  ) {
    var weightedSum = 0.0;
    var weightSum = 0.0;
    for (var index = neighborhood.start; index < neighborhood.end; index++) {
      final weight = robustnessWeights.isEmpty ? 1.0 : robustnessWeights[index];
      weightedSum += points[index].point.y * weight;
      weightSum += weight;
    }
    if (weightSum > 1e-12) return weightedSum / weightSum;
    return points[neighborhood.start].point.y;
  }

  _IndexRange _neighborhood(
    List<_IndexedPoint> points,
    double targetX,
    int count,
  ) {
    var low = 0;
    var high = points.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (points[middle].point.x < targetX) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }

    var left = low - 1;
    var right = low;
    for (var selected = 0; selected < count; selected++) {
      if (left < 0) {
        right++;
      } else if (right >= points.length) {
        left--;
      } else {
        final leftDistance = (points[left].point.x - targetX).abs();
        final rightDistance = (points[right].point.x - targetX).abs();
        if (leftDistance <= rightDistance) {
          left--;
        } else {
          right++;
        }
      }
    }
    return _IndexRange(left + 1, right);
  }

  double _median(List<double> values) {
    final sorted = [...values]..sort();
    final middle = sorted.length >> 1;
    return sorted.length.isOdd
        ? sorted[middle]
        : (sorted[middle - 1] + sorted[middle]) / 2;
  }
}

class _IndexedPoint {
  const _IndexedPoint(this.point, this.sourceIndex);

  final ChartDataPoint point;
  final int sourceIndex;
}

class _IndexRange {
  const _IndexRange(this.start, this.end);

  final int start;
  final int end;
}
