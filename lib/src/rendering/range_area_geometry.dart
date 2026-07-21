// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import '../coordinates/chart_transform.dart';
import '../models/chart_series.dart';
import '../models/range_area_data_point.dart';
import '../utils/interpolation_geometry.dart';

/// Source-index range that can contribute to a Range Area X viewport.
class RangeAreaVisibleRange {
  const RangeAreaVisibleRange(this.start, this.endExclusive);

  final int start;
  final int endExclusive;

  int get length => endExclusive - start;
  bool get isEmpty => length == 0;
}

/// Immutable ordered-X index used by Range Area viewport queries.
class RangeAreaViewportIndex {
  RangeAreaViewportIndex(List<RangeAreaDataPoint> points)
    : points = List<RangeAreaDataPoint>.unmodifiable(points) {
    double? previousX;
    for (var index = 0; index < points.length; index++) {
      final x = points[index].x;
      if (!x.isFinite) {
        throw ArgumentError.value(x, 'points[$index].x', 'must be finite');
      }
      if (previousX != null && x <= previousX) {
        throw ArgumentError.value(
          x,
          'points[$index].x',
          'must be strictly greater than points[${index - 1}].x ($previousX)',
        );
      }
      previousX = x;
    }
  }

  final List<RangeAreaDataPoint> points;

  RangeAreaVisibleRange visibleRange({
    required double xMin,
    required double xMax,
    int overscanPoints = 1,
  }) {
    if (!xMin.isFinite || !xMax.isFinite || xMax < xMin) {
      throw ArgumentError('Viewport X bounds must be finite and ordered');
    }
    if (overscanPoints < 0) {
      throw ArgumentError.value(
        overscanPoints,
        'overscanPoints',
        'must be non-negative',
      );
    }
    if (points.isEmpty || xMax < points.first.x || xMin > points.last.x) {
      return const RangeAreaVisibleRange(0, 0);
    }

    final firstVisible = _lowerBound(xMin);
    final afterVisible = _upperBound(xMax);
    final start = math.max(0, firstVisible - overscanPoints);
    final end = math.min(points.length, afterVisible + overscanPoints);
    return RangeAreaVisibleRange(start, end);
  }

  int _lowerBound(double value) {
    var low = 0;
    var high = points.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (points[middle].x < value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  int _upperBound(double value) {
    var low = 0;
    var high = points.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (points[middle].x <= value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }
}

/// One valid Range Area point projected into plot coordinates.
class RangeAreaScreenPoint {
  const RangeAreaScreenPoint({
    required this.sourceIndex,
    required this.point,
    required this.upper,
    required this.lower,
  });

  final int sourceIndex;
  final RangeAreaDataPoint point;
  final Offset upper;
  final Offset lower;
}

/// Geometry for one contiguous visible interval run.
class RangeAreaGeometryRun {
  RangeAreaGeometryRun({
    required List<RangeAreaScreenPoint> points,
    required this.fillPath,
    required this.upperPath,
    required this.lowerPath,
    required this.sidePath,
    required List<PathInterpolationSegment> upperSegments,
    required List<PathInterpolationSegment> lowerSegments,
  }) : points = List<RangeAreaScreenPoint>.unmodifiable(points),
       upperSegments = List<PathInterpolationSegment>.unmodifiable(
         upperSegments,
       ),
       lowerSegments = List<PathInterpolationSegment>.unmodifiable(
         lowerSegments,
       );

  final List<RangeAreaScreenPoint> points;
  final Path fillPath;
  final Path upperPath;
  final Path lowerPath;
  final Path sidePath;
  final List<PathInterpolationSegment> upperSegments;
  final List<PathInterpolationSegment> lowerSegments;

  List<int> get sourcePointIndices =>
      List<int>.unmodifiable(points.map((point) => point.sourceIndex));

  Rect get paintBounds => fillPath.getBounds();
}

/// Builds native Range Area paths without theme, widget, or canvas state.
abstract final class RangeAreaGeometryEngine {
  static List<RangeAreaGeometryRun> resolve({
    required RangeAreaViewportIndex index,
    required ChartTransform transform,
    required LineInterpolation interpolation,
    double tension = 0.25,
    bool connectGaps = false,
    int overscanPoints = 1,
  }) {
    if (!tension.isFinite || tension < 0 || tension > 1) {
      throw ArgumentError.value(
        tension,
        'tension',
        'must be finite and between 0 and 1',
      );
    }
    final visible = index.visibleRange(
      xMin: transform.dataXMin,
      xMax: transform.dataXMax,
      overscanPoints: overscanPoints,
    );
    if (visible.isEmpty) return const [];

    final runs = <List<RangeAreaScreenPoint>>[];
    var current = <RangeAreaScreenPoint>[];
    for (
      var sourceIndex = visible.start;
      sourceIndex < visible.endExclusive;
      sourceIndex++
    ) {
      final point = index.points[sourceIndex];
      if (point.isGap) {
        if (!connectGaps && current.isNotEmpty) {
          runs.add(current);
          current = <RangeAreaScreenPoint>[];
        }
        continue;
      }
      current.add(
        RangeAreaScreenPoint(
          sourceIndex: sourceIndex,
          point: point,
          upper: transform.dataToPlot(point.x, point.high!),
          lower: transform.dataToPlot(point.x, point.low!),
        ),
      );
    }
    if (current.isNotEmpty) runs.add(current);

    return List<RangeAreaGeometryRun>.unmodifiable([
      for (final run in runs)
        _buildRun(points: run, interpolation: interpolation, tension: tension),
    ]);
  }

  static RangeAreaGeometryRun _buildRun({
    required List<RangeAreaScreenPoint> points,
    required LineInterpolation interpolation,
    required double tension,
  }) {
    final upperSegments = InterpolationGeometry.segmentsFor(
      points: points,
      interpolation: interpolation,
      getX: (point) => point.upper.dx,
      getY: (point) => point.upper.dy,
      tension: tension,
    );
    final lowerSegments = InterpolationGeometry.segmentsFor(
      points: points,
      interpolation: interpolation,
      getX: (point) => point.lower.dx,
      getY: (point) => point.lower.dy,
      tension: tension,
    );

    final upperPath = Path()
      ..moveTo(points.first.upper.dx, points.first.upper.dy);
    for (final segment in upperSegments) {
      segment.appendForward(upperPath);
    }

    final lowerPath = Path()
      ..moveTo(points.first.lower.dx, points.first.lower.dy);
    for (final segment in lowerSegments) {
      segment.appendForward(lowerPath);
    }

    final fillPath = Path()
      ..moveTo(points.first.upper.dx, points.first.upper.dy);
    for (final segment in upperSegments) {
      segment.appendForward(fillPath);
    }
    fillPath.lineTo(points.last.lower.dx, points.last.lower.dy);
    for (final segment in lowerSegments.reversed) {
      segment.appendReverse(fillPath);
    }
    fillPath.close();

    final sidePath = Path()
      ..moveTo(points.first.upper.dx, points.first.upper.dy)
      ..lineTo(points.first.lower.dx, points.first.lower.dy);
    if (points.length > 1) {
      sidePath
        ..moveTo(points.last.upper.dx, points.last.upper.dy)
        ..lineTo(points.last.lower.dx, points.last.lower.dy);
    }

    return RangeAreaGeometryRun(
      points: points,
      fillPath: fillPath,
      upperPath: upperPath,
      lowerPath: lowerPath,
      sidePath: sidePath,
      upperSegments: upperSegments,
      lowerSegments: lowerSegments,
    );
  }
}
