// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import '../models/heatmap_data_point.dart';

/// The bounded result of a Heatmap viewport query.
///
/// [pointIndices] retain source-series identity and paint order. The diagnostic
/// counts make it possible to assert that a small viewport does not inspect
/// the complete source matrix.
class HeatmapViewportQuery {
  const HeatmapViewportQuery({
    required this.pointIndices,
    required this.visitedRowCount,
    required this.visitedCellCount,
  });

  final List<int> pointIndices;
  final int visitedRowCount;
  final int visitedCellCount;
}

/// Immutable two-dimensional data-domain index for Heatmap cells.
///
/// Cells are grouped into ordered Y rows, then ordered by X inside each row.
/// Viewport and pointer queries locate both dimensions with binary search.
/// Sparse matrices therefore pay only for intersecting rows and cells, while
/// dense regular matrices avoid scanning the complete source document.
class HeatmapViewportIndex {
  HeatmapViewportIndex(
    List<HeatmapDataPoint> cells, {
    required this.cellWidth,
    required this.cellHeight,
  }) : _rows = _buildRows(cells),
       _irregularIndex = _HeatmapBoundsIndex.fromCells(cells) {
    if (!cellWidth.isFinite || cellWidth <= 0) {
      throw ArgumentError.value(
        cellWidth,
        'cellWidth',
        'must be finite and greater than zero',
      );
    }
    if (!cellHeight.isFinite || cellHeight <= 0) {
      throw ArgumentError.value(
        cellHeight,
        'cellHeight',
        'must be finite and greater than zero',
      );
    }
  }

  final double cellWidth;
  final double cellHeight;
  final List<_HeatmapRow> _rows;
  final _HeatmapBoundsIndex? _irregularIndex;

  int get rowCount => _rows.length;

  int get cellCount {
    var count = 0;
    for (final row in _rows) {
      count += row.entries.length;
    }
    return count + (_irregularIndex?.cellCount ?? 0);
  }

  /// Number of cells using explicit per-point rectangles.
  int get irregularCellCount => _irregularIndex?.cellCount ?? 0;

  /// Returns source indices for cells that can affect the visible viewport.
  ///
  /// One full cell of overscan is included on every edge by default. This
  /// keeps partially visible rounded cells and borders stable while panning.
  HeatmapViewportQuery queryViewport({
    required double minX,
    required double maxX,
    required double minY,
    required double maxY,
    int overscanCellCount = 1,
  }) {
    if (overscanCellCount < 0) {
      throw ArgumentError.value(
        overscanCellCount,
        'overscanCellCount',
        'must be non-negative',
      );
    }
    if (_rows.isEmpty && _irregularIndex == null) {
      return const HeatmapViewportQuery(
        pointIndices: [],
        visitedRowCount: 0,
        visitedCellCount: 0,
      );
    }

    final orderedMinX = math.min(minX, maxX);
    final orderedMaxX = math.max(minX, maxX);
    final orderedMinY = math.min(minY, maxY);
    final orderedMaxY = math.max(minY, maxY);
    final xPadding = cellWidth * (overscanCellCount + 0.5);
    final yPadding = cellHeight * (overscanCellCount + 0.5);
    final rowStart = _lowerRowBound(orderedMinY - yPadding);
    final rowEnd = _upperRowBound(orderedMaxY + yPadding);
    final pointIndices = <int>[];
    var visitedCellCount = 0;

    for (var rowIndex = rowStart; rowIndex < rowEnd; rowIndex++) {
      final row = _rows[rowIndex];
      final entryStart = row.lowerBound(orderedMinX - xPadding);
      final entryEnd = row.upperBound(orderedMaxX + xPadding);
      visitedCellCount += entryEnd - entryStart;
      for (var entryIndex = entryStart; entryIndex < entryEnd; entryIndex++) {
        pointIndices.add(row.entries[entryIndex].pointIndex);
      }
    }

    final irregularQuery = _irregularIndex?.queryRect(
      minX: orderedMinX - cellWidth * overscanCellCount,
      maxX: orderedMaxX + cellWidth * overscanCellCount,
      minY: orderedMinY - cellHeight * overscanCellCount,
      maxY: orderedMaxY + cellHeight * overscanCellCount,
    );
    if (irregularQuery != null) {
      pointIndices.addAll(irregularQuery.pointIndices);
      visitedCellCount += irregularQuery.visitedCellCount;
    }

    // Internal ordering is spatial; all public identities and overlap order
    // remain the immutable source-series order.
    pointIndices.sort();
    return HeatmapViewportQuery(
      pointIndices: List<int>.unmodifiable(pointIndices),
      visitedRowCount: rowEnd - rowStart,
      visitedCellCount: visitedCellCount,
    );
  }

  /// Returns source indices whose data-space cell bounds contain [position].
  ///
  /// More than one result is possible when host-supplied keyed cells overlap.
  /// Results use source order; callers can reverse them for topmost paint hit.
  List<int> pointIndicesAt(Offset position) {
    if ((_rows.isEmpty && _irregularIndex == null) ||
        !position.dx.isFinite ||
        !position.dy.isFinite) {
      return const [];
    }
    final halfWidth = cellWidth / 2;
    final halfHeight = cellHeight / 2;
    final rowStart = _lowerRowBound(position.dy - halfHeight);
    final rowEnd = _upperRowBound(position.dy + halfHeight);
    final result = <int>[];
    for (var rowIndex = rowStart; rowIndex < rowEnd; rowIndex++) {
      final row = _rows[rowIndex];
      final entryStart = row.lowerBound(position.dx - halfWidth);
      final entryEnd = row.upperBound(position.dx + halfWidth);
      for (var entryIndex = entryStart; entryIndex < entryEnd; entryIndex++) {
        result.add(row.entries[entryIndex].pointIndex);
      }
    }
    result.addAll(_irregularIndex?.pointIndicesAt(position) ?? const []);
    result.sort();
    return List<int>.unmodifiable(result);
  }

  int _lowerRowBound(double value) {
    var low = 0;
    var high = _rows.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (_rows[middle].y < value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  int _upperRowBound(double value) {
    var low = 0;
    var high = _rows.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (_rows[middle].y <= value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  static List<_HeatmapRow> _buildRows(List<HeatmapDataPoint> cells) {
    final rows = <double, List<_HeatmapEntry>>{};
    for (var pointIndex = 0; pointIndex < cells.length; pointIndex++) {
      final cell = cells[pointIndex];
      if (!cell.isValid || cell.bounds != null) continue;
      rows
          .putIfAbsent(cell.y, () => <_HeatmapEntry>[])
          .add(_HeatmapEntry(x: cell.x, pointIndex: pointIndex));
    }
    final result = <_HeatmapRow>[
      for (final MapEntry(key: y, value: entries) in rows.entries)
        _HeatmapRow(y: y, entries: entries),
    ]..sort((left, right) => left.y.compareTo(right.y));
    return List<_HeatmapRow>.unmodifiable(result);
  }
}

class _HeatmapBoundsQuery {
  const _HeatmapBoundsQuery({
    required this.pointIndices,
    required this.visitedCellCount,
  });

  final List<int> pointIndices;
  final int visitedCellCount;
}

/// A secondary immutable interval tree for the opt-in irregular-cell path.
///
/// The regular row index above remains untouched when no point has explicit
/// bounds. Nodes are ordered by minimum X and retain the maximum X extent of
/// their subtree, allowing viewport and point queries to prune both sides.
class _HeatmapBoundsIndex {
  _HeatmapBoundsIndex._(this.root, this.cellCount);

  factory _HeatmapBoundsIndex.fromEntries(List<_HeatmapBoundsEntry> entries) {
    entries.sort((left, right) {
      final byMinimum = left.bounds.xMinimum.compareTo(right.bounds.xMinimum);
      return byMinimum != 0
          ? byMinimum
          : left.pointIndex.compareTo(right.pointIndex);
    });
    return _HeatmapBoundsIndex._(
      _HeatmapBoundsNode.build(entries, 0, entries.length),
      entries.length,
    );
  }

  static _HeatmapBoundsIndex? fromCells(List<HeatmapDataPoint> cells) {
    final entries = <_HeatmapBoundsEntry>[];
    for (var pointIndex = 0; pointIndex < cells.length; pointIndex++) {
      final cell = cells[pointIndex];
      final bounds = cell.bounds;
      if (!cell.isValid || bounds == null) continue;
      entries.add(_HeatmapBoundsEntry(pointIndex: pointIndex, bounds: bounds));
    }
    return entries.isEmpty ? null : _HeatmapBoundsIndex.fromEntries(entries);
  }

  final _HeatmapBoundsNode? root;
  final int cellCount;

  _HeatmapBoundsQuery queryRect({
    required double minX,
    required double maxX,
    required double minY,
    required double maxY,
  }) {
    final indices = <int>[];
    final visited = _MutableCount();
    root?.queryRect(
      minX: minX,
      maxX: maxX,
      minY: minY,
      maxY: maxY,
      pointIndices: indices,
      visited: visited,
    );
    return _HeatmapBoundsQuery(
      pointIndices: indices,
      visitedCellCount: visited.value,
    );
  }

  List<int> pointIndicesAt(Offset position) {
    final indices = <int>[];
    root?.queryPoint(position, indices);
    return indices;
  }
}

class _HeatmapBoundsNode {
  _HeatmapBoundsNode({
    required this.entry,
    required this.left,
    required this.right,
  }) : maximumX = math.max(
         entry.bounds.xMaximum,
         math.max(
           left?.maximumX ?? double.negativeInfinity,
           right?.maximumX ?? double.negativeInfinity,
         ),
       ),
       minimumX = math.min(
         entry.bounds.xMinimum,
         math.min(
           left?.minimumX ?? double.infinity,
           right?.minimumX ?? double.infinity,
         ),
       );

  static _HeatmapBoundsNode? build(
    List<_HeatmapBoundsEntry> entries,
    int start,
    int end,
  ) {
    if (start >= end) return null;
    final middle = (start + end) >> 1;
    return _HeatmapBoundsNode(
      entry: entries[middle],
      left: build(entries, start, middle),
      right: build(entries, middle + 1, end),
    );
  }

  final _HeatmapBoundsEntry entry;
  final _HeatmapBoundsNode? left;
  final _HeatmapBoundsNode? right;
  final double maximumX;
  final double minimumX;

  void queryRect({
    required double minX,
    required double maxX,
    required double minY,
    required double maxY,
    required List<int> pointIndices,
    required _MutableCount visited,
  }) {
    if (left != null && left!.maximumX >= minX && left!.minimumX <= maxX) {
      left!.queryRect(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        pointIndices: pointIndices,
        visited: visited,
      );
    }
    if (entry.bounds.xMinimum <= maxX) {
      visited.value++;
      if (entry.bounds.xMaximum >= minX &&
          entry.bounds.yMinimum <= maxY &&
          entry.bounds.yMaximum >= minY) {
        pointIndices.add(entry.pointIndex);
      }
      if (right != null && right!.maximumX >= minX && right!.minimumX <= maxX) {
        right!.queryRect(
          minX: minX,
          maxX: maxX,
          minY: minY,
          maxY: maxY,
          pointIndices: pointIndices,
          visited: visited,
        );
      }
    }
  }

  void queryPoint(Offset position, List<int> pointIndices) {
    if (left != null &&
        left!.maximumX >= position.dx &&
        left!.minimumX <= position.dx) {
      left!.queryPoint(position, pointIndices);
    }
    if (entry.bounds.xMinimum <= position.dx) {
      if (entry.bounds.contains(position.dx, position.dy)) {
        pointIndices.add(entry.pointIndex);
      }
      if (right != null &&
          right!.maximumX >= position.dx &&
          right!.minimumX <= position.dx) {
        right!.queryPoint(position, pointIndices);
      }
    }
  }
}

class _HeatmapBoundsEntry {
  const _HeatmapBoundsEntry({required this.pointIndex, required this.bounds});

  final int pointIndex;
  final HeatmapCellBounds bounds;
}

class _MutableCount {
  int value = 0;
}

class _HeatmapRow {
  _HeatmapRow({required this.y, required List<_HeatmapEntry> entries})
    : entries = List<_HeatmapEntry>.unmodifiable(
        entries..sort((left, right) {
          final byX = left.x.compareTo(right.x);
          return byX != 0 ? byX : left.pointIndex.compareTo(right.pointIndex);
        }),
      );

  final double y;
  final List<_HeatmapEntry> entries;

  int lowerBound(double value) {
    var low = 0;
    var high = entries.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (entries[middle].x < value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }

  int upperBound(double value) {
    var low = 0;
    var high = entries.length;
    while (low < high) {
      final middle = (low + high) >> 1;
      if (entries[middle].x <= value) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low;
  }
}

class _HeatmapEntry {
  const _HeatmapEntry({required this.x, required this.pointIndex});

  final double x;
  final int pointIndex;
}
