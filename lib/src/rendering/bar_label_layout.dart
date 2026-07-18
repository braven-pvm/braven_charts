// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

import '../models/bar_chart_style.dart';
import 'bar_geometry.dart';

/// Places an outside-end label beyond the visible value mark.
///
/// This deliberately consumes canonical [BarGeometry] rather than recreating
/// mark dimensions in the label painter. It therefore tracks both ordinary
/// bar ends and variable-radius lollipop markers.
Rect resolveBarOutsideEndLabelRect({
  required BarGeometry geometry,
  required Size labelSize,
  required double padding,
}) {
  final valueEndBounds = geometry.valueEndVisualBounds;
  if (geometry.orientation == BarOrientation.horizontal) {
    final valueEndIsRight = geometry.valueEndX >= geometry.baselineX;
    return Rect.fromLTWH(
      valueEndIsRight
          ? valueEndBounds.right + padding
          : valueEndBounds.left - padding - labelSize.width,
      valueEndBounds.center.dy - labelSize.height / 2,
      labelSize.width,
      labelSize.height,
    );
  }

  final valueEndIsTop = geometry.valueEndY <= geometry.baselineY;
  return Rect.fromLTWH(
    valueEndBounds.center.dx - labelSize.width / 2,
    valueEndIsTop
        ? valueEndBounds.top - padding - labelSize.height
        : valueEndBounds.bottom + padding,
    labelSize.width,
    labelSize.height,
  );
}

/// Final placement selected by [BarLabelLayoutCoordinator].
class BarLabelLayoutResult {
  const BarLabelLayoutResult({required this.rect, required this.displaced});

  final Rect rect;
  final bool displaced;
}

/// Coordinates label boxes across every bar series in one paint pass.
///
/// Series are still responsible for choosing semantically useful candidates;
/// this coordinator provides the chart-wide occupied-space contract that a
/// per-series painter cannot otherwise see.
class BarLabelLayoutCoordinator {
  BarLabelLayoutCoordinator({
    required this.plotBounds,
    this.collisionCellSize = 48,
  }) : assert(collisionCellSize > 0, 'Collision cell size must be positive');

  final Rect plotBounds;
  final double collisionCellSize;
  final List<Rect> _occupied = [];
  final Map<(int, int), List<Rect>> _occupiedByCell = {};
  int _collisionComparisonCount = 0;

  List<Rect> get occupiedBounds => List.unmodifiable(_occupied);

  /// Number of exact rectangle comparisons performed by this coordinator.
  ///
  /// Exposed for diagnostics and benchmarks. Dense layouts should grow close
  /// to linearly instead of comparing every label with every prior label.
  int get collisionComparisonCount => _collisionComparisonCount;

  BarLabelLayoutResult? place({
    required List<Rect> candidates,
    required BarLabelCollisionPolicy collisionPolicy,
    required bool plotEdgeAware,
    required double collisionPadding,
    Offset displacementDirection = Offset.zero,
    double displacementStep = 0,
    int maximumDisplacements = 4,
  }) {
    if (candidates.isEmpty) return null;

    final candidateLimit = collisionPolicy == BarLabelCollisionPolicy.hide
        ? 1
        : candidates.length;
    for (var index = 0; index < candidateLimit; index++) {
      final candidate = candidates[index];
      if (!_fitsPlot(candidate, plotEdgeAware)) continue;
      if (collisionPolicy != BarLabelCollisionPolicy.none &&
          _collides(candidate, collisionPadding)) {
        continue;
      }
      return _accept(candidate, displaced: index > 0);
    }

    if (collisionPolicy == BarLabelCollisionPolicy.none) {
      final rect = plotEdgeAware
          ? _clampToPlot(candidates.first)
          : candidates.first;
      return _accept(rect, displaced: rect != candidates.first);
    }

    if (collisionPolicy == BarLabelCollisionPolicy.reposition &&
        displacementDirection != Offset.zero &&
        displacementStep > 0) {
      final origin = candidates.last;
      for (var attempt = 1; attempt <= maximumDisplacements; attempt++) {
        final candidate = origin.shift(
          displacementDirection * (displacementStep * attempt),
        );
        if (!_fitsPlot(candidate, plotEdgeAware) ||
            _collides(candidate, collisionPadding)) {
          continue;
        }
        return _accept(candidate, displaced: true);
      }
    }

    return null;
  }

  bool _fitsPlot(Rect rect, bool plotEdgeAware) =>
      !plotEdgeAware ||
      (rect.left >= plotBounds.left &&
          rect.top >= plotBounds.top &&
          rect.right <= plotBounds.right &&
          rect.bottom <= plotBounds.bottom);

  bool _collides(Rect rect, double padding) {
    final padded = rect.inflate(padding / 2);
    final visited = <Rect>{};
    for (final cell in _cellsFor(rect.inflate(padding))) {
      for (final other in _occupiedByCell[cell] ?? const <Rect>[]) {
        if (!visited.add(other)) continue;
        _collisionComparisonCount++;
        if (padded.overlaps(other.inflate(padding / 2))) return true;
      }
    }
    return false;
  }

  BarLabelLayoutResult _accept(Rect rect, {required bool displaced}) {
    _occupied.add(rect);
    for (final cell in _cellsFor(rect)) {
      (_occupiedByCell[cell] ??= []).add(rect);
    }
    return BarLabelLayoutResult(rect: rect, displaced: displaced);
  }

  Iterable<(int, int)> _cellsFor(Rect rect) sync* {
    final left = ((rect.left - plotBounds.left) / collisionCellSize).floor();
    final right = ((rect.right - plotBounds.left) / collisionCellSize).floor();
    final top = ((rect.top - plotBounds.top) / collisionCellSize).floor();
    final bottom = ((rect.bottom - plotBounds.top) / collisionCellSize).floor();
    for (var x = left; x <= right; x++) {
      for (var y = top; y <= bottom; y++) {
        yield (x, y);
      }
    }
  }

  Rect _clampToPlot(Rect rect) {
    final dx = rect.left < plotBounds.left
        ? plotBounds.left - rect.left
        : rect.right > plotBounds.right
        ? plotBounds.right - rect.right
        : 0.0;
    final dy = rect.top < plotBounds.top
        ? plotBounds.top - rect.top
        : rect.bottom > plotBounds.bottom
        ? plotBounds.bottom - rect.bottom
        : 0.0;
    return rect.shift(Offset(dx, dy));
  }
}
