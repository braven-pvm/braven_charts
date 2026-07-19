// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import '../models/chart_data_point.dart';
import '../theming/components/series_theme.dart';

/// Canonical plot-space geometry for one visible Scatter marker.
class ScatterPointGeometry {
  const ScatterPointGeometry({
    required this.pointIndex,
    required this.point,
    required this.center,
    required this.radius,
    required this.width,
    required this.height,
    required this.shape,
    this.rotationRadians = 0,
    this.strokeWidth = 0,
  });

  /// Original index in the source series.
  final int pointIndex;

  final ChartDataPoint point;
  final Offset center;
  final double radius;
  final double width;
  final double height;
  final SeriesMarkerShape shape;
  final double rotationRadians;
  final double strokeWidth;

  Rect get paintBounds {
    final halfWidth = width / 2;
    final halfHeight = height / 2;
    final cosine = math.cos(rotationRadians).abs();
    final sine = math.sin(rotationRadians).abs();
    final extentX = cosine * halfWidth + sine * halfHeight + strokeWidth / 2;
    final extentY = sine * halfWidth + cosine * halfHeight + strokeWidth / 2;
    return Rect.fromLTRB(
      center.dx - extentX,
      center.dy - extentY,
      center.dx + extentX,
      center.dy + extentY,
    );
  }

  Rect hitBounds(double hitSlop) => paintBounds.inflate(math.max(0, hitSlop));
}

/// Immutable two-dimensional data-domain index for Scatter viewport queries.
///
/// Entries are sorted by X for logarithmic range location and retain their
/// original source indices. The smaller X candidate set is then filtered by Y.
class ScatterViewportIndex {
  ScatterViewportIndex(List<ChartDataPoint> points, {bool isXOrdered = false})
    : _entries = <_ScatterViewportEntry>[
        for (var index = 0; index < points.length; index++)
          if (points[index].isValid)
            _ScatterViewportEntry(
              x: points[index].x,
              y: points[index].y,
              pointIndex: index,
            ),
      ] {
    var maximumPointRadius = 0.0;
    for (final point in points) {
      if (!point.isValid) continue;
      final pointStyle = point.pointStyle;
      final markerStyle = pointStyle?.scatterMarkerStyle;
      if (pointStyle?.size == null &&
          markerStyle?.width == null &&
          markerStyle?.height == null &&
          markerStyle?.strokeWidth == null) {
        continue;
      }
      final legacyDiameter = (pointStyle?.size ?? 0) * 2;
      final width = math.max(legacyDiameter, markerStyle?.width ?? 0);
      final height = math.max(legacyDiameter, markerStyle?.height ?? 0);
      final strokeWidth = markerStyle?.strokeWidth ?? 0;
      if (!width.isFinite || !height.isFinite || !strokeWidth.isFinite) {
        continue;
      }
      final radius =
          math.sqrt(width * width + height * height) / 2 + strokeWidth / 2;
      if (radius > maximumPointRadius) maximumPointRadius = radius;
    }
    _maximumPointRadius = maximumPointRadius;
    if (!isXOrdered) {
      _entries.sort((left, right) {
        final byX = left.x.compareTo(right.x);
        return byX != 0 ? byX : left.pointIndex.compareTo(right.pointIndex);
      });
    }
  }

  final List<_ScatterViewportEntry> _entries;
  late final double _maximumPointRadius;

  int get pointCount => _entries.length;

  /// Largest finite point-level marker radius in the indexed source.
  double get maximumPointRadius => _maximumPointRadius;

  /// Returns original point indices whose marker centers fall in the padded
  /// two-dimensional data viewport.
  List<int> pointIndicesForViewport({
    required double minX,
    required double maxX,
    required double minY,
    required double maxY,
    double paddingX = 0,
    double paddingY = 0,
  }) {
    if (_entries.isEmpty) return const [];
    final safeMinX = math.min(minX, maxX) - math.max(0, paddingX);
    final safeMaxX = math.max(minX, maxX) + math.max(0, paddingX);
    final safeMinY = math.min(minY, maxY) - math.max(0, paddingY);
    final safeMaxY = math.max(minY, maxY) + math.max(0, paddingY);
    final start = _lowerBound(safeMinX);
    final end = _upperBound(safeMaxX);
    final result = [
      for (var index = start; index < end; index++)
        if (_entries[index].y >= safeMinY && _entries[index].y <= safeMaxY)
          _entries[index].pointIndex,
    ];
    // Marker overlap and paint order follow the source document, not the
    // internal X sort used to find viewport candidates.
    result.sort();
    return result;
  }

  int _lowerBound(double value) {
    var low = 0;
    var high = _entries.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (_entries[middle].x < value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  int _upperBound(double value) {
    var low = 0;
    var high = _entries.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (_entries[middle].x <= value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }
}

class _ScatterViewportEntry {
  const _ScatterViewportEntry({
    required this.x,
    required this.y,
    required this.pointIndex,
  });

  final double x;
  final double y;
  final int pointIndex;
}
