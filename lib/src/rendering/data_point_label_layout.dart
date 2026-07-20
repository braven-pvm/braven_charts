// Copyright (c) 2026 braven_charts contributors. All rights reserved.

import 'dart:ui';

import '../models/data_point_label_config.dart';

/// Final placement selected by [DataPointLabelLayoutCoordinator].
class DataPointLabelLayoutResult {
  const DataPointLabelLayoutResult({
    required this.rect,
    required this.candidateIndex,
  });

  final Rect rect;
  final int candidateIndex;
}

/// Coordinates point-label occupancy across every series in one paint pass.
///
/// A fixed-size spatial grid keeps dense collision checks close to linear. The
/// series owns semantic candidate order; this coordinator owns chart-wide
/// edge and overlap policy.
class DataPointLabelLayoutCoordinator {
  DataPointLabelLayoutCoordinator({
    required this.plotBounds,
    this.collisionCellSize = 48,
  }) : assert(collisionCellSize > 0);

  final Rect plotBounds;
  final double collisionCellSize;
  final List<Rect> _occupied = [];
  final Map<(int, int), List<Rect>> _occupiedByCell = {};
  int _collisionComparisonCount = 0;

  List<Rect> get occupiedBounds => List.unmodifiable(_occupied);
  int get collisionComparisonCount => _collisionComparisonCount;

  DataPointLabelLayoutResult? place({
    required List<Rect> candidates,
    required DataPointLabelCollisionPolicy collisionPolicy,
    required double collisionPadding,
    required bool plotEdgeAware,
  }) {
    if (candidates.isEmpty) return null;
    final candidateLimit = switch (collisionPolicy) {
      DataPointLabelCollisionPolicy.reposition => candidates.length,
      _ => 1,
    };

    for (var index = 0; index < candidateLimit; index++) {
      final candidate = candidates[index];
      if (plotEdgeAware &&
          (candidate.left < plotBounds.left ||
              candidate.top < plotBounds.top ||
              candidate.right > plotBounds.right ||
              candidate.bottom > plotBounds.bottom)) {
        continue;
      }
      if (collisionPolicy != DataPointLabelCollisionPolicy.none &&
          _collides(candidate, collisionPadding)) {
        continue;
      }
      return _accept(candidate, index);
    }

    if (collisionPolicy == DataPointLabelCollisionPolicy.none) {
      final rect = plotEdgeAware
          ? _clampToPlot(candidates.first)
          : candidates.first;
      return _accept(rect, 0);
    }
    return null;
  }

  bool _collides(Rect rect, double padding) {
    final padded = rect.inflate(padding);
    final visited = <Rect>{};
    for (final cell in _cellsFor(padded)) {
      for (final other in _occupiedByCell[cell] ?? const <Rect>[]) {
        if (!visited.add(other)) continue;
        _collisionComparisonCount++;
        if (padded.overlaps(other.inflate(padding / 2))) return true;
      }
    }
    return false;
  }

  DataPointLabelLayoutResult _accept(Rect rect, int candidateIndex) {
    _occupied.add(rect);
    for (final cell in _cellsFor(rect)) {
      (_occupiedByCell[cell] ??= []).add(rect);
    }
    return DataPointLabelLayoutResult(
      rect: rect,
      candidateIndex: candidateIndex,
    );
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
}
