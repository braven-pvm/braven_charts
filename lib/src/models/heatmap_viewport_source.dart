// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'heatmap_data_point.dart';

/// The finite data-space rectangle covered by a regular Heatmap matrix.
final class HeatmapViewportBounds {
  const HeatmapViewportBounds({
    required this.minimumX,
    required this.maximumX,
    required this.minimumY,
    required this.maximumY,
  });

  final double minimumX;
  final double maximumX;
  final double minimumY;
  final double maximumY;

  double get width => maximumX - minimumX;
  double get height => maximumY - minimumY;

  bool get isEmpty => maximumX <= minimumX || maximumY <= minimumY;

  void validate({String parameterName = 'viewport'}) {
    if (!minimumX.isFinite || !maximumX.isFinite) {
      throw ArgumentError.value(this, parameterName, 'X bounds must be finite');
    }
    if (!minimumY.isFinite || !maximumY.isFinite) {
      throw ArgumentError.value(this, parameterName, 'Y bounds must be finite');
    }
    if (isEmpty) {
      throw ArgumentError.value(
        this,
        parameterName,
        'minimum bounds must be less than maximum bounds',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapViewportBounds &&
          other.minimumX == minimumX &&
          other.maximumX == maximumX &&
          other.minimumY == minimumY &&
          other.maximumY == maximumY;

  @override
  int get hashCode => Object.hash(minimumX, maximumX, minimumY, maximumY);

  @override
  String toString() =>
      'HeatmapViewportBounds(x: $minimumX..$maximumX, '
      'y: $minimumY..$maximumY)';
}

/// A host request for the cells around one visible Heatmap viewport.
final class HeatmapViewportRequest extends HeatmapViewportBounds {
  const HeatmapViewportRequest({
    required super.minimumX,
    required super.maximumX,
    required super.minimumY,
    required super.maximumY,
  });

  /// Creates a typed request from `InteractionConfig.onViewportChanged`.
  factory HeatmapViewportRequest.fromVisibleBounds(
    Map<String, double> visibleBounds,
  ) {
    double read(String key) {
      final value = visibleBounds[key];
      if (value == null) {
        throw ArgumentError.value(
          visibleBounds,
          'visibleBounds',
          'must contain $key',
        );
      }
      return value;
    }

    return HeatmapViewportRequest(
      minimumX: read('minX'),
      maximumX: read('maxX'),
      minimumY: read('minY'),
      maximumY: read('maxY'),
    );
  }
}

/// A finite regular matrix whose cells are addressed by row and column.
///
/// [xOrigin] and [yOrigin] are the data coordinates of the first cell centre.
/// [fullBounds] include the complete extents of the edge cells and are suitable
/// for explicit `XAxisConfig` and `YAxisConfig` bounds.
final class HeatmapMatrixDomain {
  HeatmapMatrixDomain({
    required this.columnCount,
    required this.rowCount,
    this.xOrigin = 0,
    this.yOrigin = 0,
    this.cellWidth = 1,
    this.cellHeight = 1,
  }) {
    if (columnCount <= 0) {
      throw ArgumentError.value(columnCount, 'columnCount', 'must be positive');
    }
    if (rowCount <= 0) {
      throw ArgumentError.value(rowCount, 'rowCount', 'must be positive');
    }
    if (!xOrigin.isFinite || !yOrigin.isFinite) {
      throw ArgumentError('Heatmap matrix origins must be finite');
    }
    if (!cellWidth.isFinite || cellWidth <= 0) {
      throw ArgumentError.value(cellWidth, 'cellWidth', 'must be positive');
    }
    if (!cellHeight.isFinite || cellHeight <= 0) {
      throw ArgumentError.value(cellHeight, 'cellHeight', 'must be positive');
    }
  }

  final int columnCount;
  final int rowCount;
  final double xOrigin;
  final double yOrigin;
  final double cellWidth;
  final double cellHeight;

  int get cellCount => columnCount * rowCount;

  double xForColumn(int column) {
    _validateIndex(column, columnCount, 'column');
    return xOrigin + column * cellWidth;
  }

  double yForRow(int row) {
    _validateIndex(row, rowCount, 'row');
    return yOrigin + row * cellHeight;
  }

  /// Resolves the stable tile containing one regular-matrix cell.
  HeatmapTileKey tileKeyForCell(
    int column,
    int row, {
    required int tileColumnCount,
    required int tileRowCount,
  }) {
    _validateIndex(column, columnCount, 'column');
    _validateIndex(row, rowCount, 'row');
    _validateTileDimensions(tileColumnCount, tileRowCount);
    return HeatmapTileKey(
      column: column ~/ tileColumnCount,
      row: row ~/ tileRowCount,
    );
  }

  late final HeatmapViewportBounds fullBounds = HeatmapViewportBounds(
    minimumX: xOrigin - cellWidth / 2,
    maximumX: xOrigin + (columnCount - 0.5) * cellWidth,
    minimumY: yOrigin - cellHeight / 2,
    maximumY: yOrigin + (rowCount - 0.5) * cellHeight,
  );

  /// Resolves a clamped row-major tile set for [viewport].
  List<HeatmapTileKey> tileKeysFor(
    HeatmapViewportBounds viewport, {
    required int tileColumnCount,
    required int tileRowCount,
    int overscanColumns = 0,
    int overscanRows = 0,
    int? maximumTileCount,
  }) {
    viewport.validate();
    _validateTileDimensions(tileColumnCount, tileRowCount);
    if (overscanColumns < 0 || overscanRows < 0) {
      throw ArgumentError('Heatmap overscan counts must be non-negative');
    }
    if (maximumTileCount != null && maximumTileCount <= 0) {
      throw ArgumentError.value(
        maximumTileCount,
        'maximumTileCount',
        'must be positive when provided',
      );
    }
    if (!_intersects(viewport, fullBounds)) return const [];

    final columnStart =
        (_firstIndex(viewport.minimumX, origin: xOrigin, extent: cellWidth) -
                overscanColumns)
            .clamp(0, columnCount - 1);
    final columnEnd =
        (_lastIndex(viewport.maximumX, origin: xOrigin, extent: cellWidth) +
                overscanColumns)
            .clamp(0, columnCount - 1);
    final rowStart =
        (_firstIndex(viewport.minimumY, origin: yOrigin, extent: cellHeight) -
                overscanRows)
            .clamp(0, rowCount - 1);
    final rowEnd =
        (_lastIndex(viewport.maximumY, origin: yOrigin, extent: cellHeight) +
                overscanRows)
            .clamp(0, rowCount - 1);

    final firstColumnTile = columnStart ~/ tileColumnCount;
    final lastColumnTile = columnEnd ~/ tileColumnCount;
    final firstRowTile = rowStart ~/ tileRowCount;
    final lastRowTile = rowEnd ~/ tileRowCount;
    final requestedTileCount =
        (lastColumnTile - firstColumnTile + 1) *
        (lastRowTile - firstRowTile + 1);
    if (maximumTileCount != null && requestedTileCount > maximumTileCount) {
      throw StateError(
        'Heatmap viewport requires $requestedTileCount tiles, exceeding the '
        'configured limit of $maximumTileCount',
      );
    }
    return List<HeatmapTileKey>.unmodifiable([
      for (var rowTile = firstRowTile; rowTile <= lastRowTile; rowTile++)
        for (
          var columnTile = firstColumnTile;
          columnTile <= lastColumnTile;
          columnTile++
        )
          HeatmapTileKey(column: columnTile, row: rowTile),
    ]);
  }

  /// Creates the bounded half-open source range for [key].
  HeatmapTileRequest tileRequestFor(
    HeatmapTileKey key, {
    required int tileColumnCount,
    required int tileRowCount,
  }) {
    _validateTileDimensions(tileColumnCount, tileRowCount);
    if (key.column < 0 || key.row < 0) {
      throw ArgumentError.value(
        key,
        'key',
        'tile indices must be non-negative',
      );
    }
    final columnStart = key.column * tileColumnCount;
    final rowStart = key.row * tileRowCount;
    if (columnStart >= columnCount || rowStart >= rowCount) {
      throw ArgumentError.value(key, 'key', 'falls outside the matrix domain');
    }
    return HeatmapTileRequest(
      key: key,
      columnStart: columnStart,
      columnEndExclusive: (columnStart + tileColumnCount).clamp(0, columnCount),
      rowStart: rowStart,
      rowEndExclusive: (rowStart + tileRowCount).clamp(0, rowCount),
    );
  }

  bool containsPointInTile(HeatmapDataPoint point, HeatmapTileRequest tile) {
    final column = _coordinateIndex(
      point.x,
      origin: xOrigin,
      extent: cellWidth,
    );
    final row = _coordinateIndex(point.y, origin: yOrigin, extent: cellHeight);
    return column != null &&
        row != null &&
        column >= tile.columnStart &&
        column < tile.columnEndExclusive &&
        row >= tile.rowStart &&
        row < tile.rowEndExclusive;
  }

  static int _firstIndex(
    double minimum, {
    required double origin,
    required double extent,
  }) => ((minimum - (origin - extent / 2)) / extent).floor();

  static int _lastIndex(
    double maximum, {
    required double origin,
    required double extent,
  }) => ((maximum - (origin - extent / 2)) / extent).ceil() - 1;

  static int? _coordinateIndex(
    double coordinate, {
    required double origin,
    required double extent,
  }) {
    final normalized = (coordinate - origin) / extent;
    final index = normalized.round();
    return (normalized - index).abs() <= 0.000001 ? index : null;
  }

  static bool _intersects(
    HeatmapViewportBounds left,
    HeatmapViewportBounds right,
  ) =>
      left.maximumX > right.minimumX &&
      left.minimumX < right.maximumX &&
      left.maximumY > right.minimumY &&
      left.minimumY < right.maximumY;

  static void _validateIndex(int index, int count, String name) {
    if (index < 0 || index >= count) {
      throw RangeError.range(index, 0, count - 1, name);
    }
  }

  static void _validateTileDimensions(int columns, int rows) {
    if (columns <= 0 || rows <= 0) {
      throw ArgumentError('Heatmap tile dimensions must be positive');
    }
  }
}

/// Stable identity for one regular matrix tile.
final class HeatmapTileKey implements Comparable<HeatmapTileKey> {
  const HeatmapTileKey({required this.column, required this.row});

  final int column;
  final int row;

  @override
  int compareTo(HeatmapTileKey other) {
    final rowOrder = row.compareTo(other.row);
    return rowOrder != 0 ? rowOrder : column.compareTo(other.column);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapTileKey && other.column == column && other.row == row;

  @override
  int get hashCode => Object.hash(column, row);

  @override
  String toString() => 'HeatmapTileKey(column: $column, row: $row)';
}

/// One bounded half-open tile request in source matrix indices.
final class HeatmapTileRequest {
  HeatmapTileRequest({
    required this.key,
    required this.columnStart,
    required this.columnEndExclusive,
    required this.rowStart,
    required this.rowEndExclusive,
  }) {
    if (columnStart < 0 || columnEndExclusive <= columnStart) {
      throw ArgumentError('Heatmap tile column range must be positive');
    }
    if (rowStart < 0 || rowEndExclusive <= rowStart) {
      throw ArgumentError('Heatmap tile row range must be positive');
    }
  }

  final HeatmapTileKey key;
  final int columnStart;
  final int columnEndExclusive;
  final int rowStart;
  final int rowEndExclusive;

  int get columnCount => columnEndExclusive - columnStart;
  int get rowCount => rowEndExclusive - rowStart;
  int get maximumCellCount => columnCount * rowCount;
}

/// Immutable cells returned for one [HeatmapTileRequest].
final class HeatmapTile {
  HeatmapTile({required this.key, required List<HeatmapDataPoint> cells})
    : cells = List<HeatmapDataPoint>.unmodifiable(cells);

  final HeatmapTileKey key;
  final List<HeatmapDataPoint> cells;
}

/// Host-owned asynchronous source for a finite regular Heatmap matrix.
abstract interface class HeatmapTileSource {
  HeatmapMatrixDomain get domain;
  int get tileColumnCount;
  int get tileRowCount;

  Future<HeatmapTile> loadTile(HeatmapTileRequest request);
}

/// One typed change to a host-owned regular Heatmap matrix.
sealed class HeatmapMutation {
  const HeatmapMutation();
}

/// Inserts or replaces the cell at [column], [row].
final class HeatmapCellUpsert extends HeatmapMutation {
  const HeatmapCellUpsert({
    required this.column,
    required this.row,
    required this.cell,
  });

  final int column;
  final int row;
  final HeatmapDataPoint cell;
}

/// Removes the cell at [column], [row] from sparse matrix residency.
final class HeatmapCellRemoval extends HeatmapMutation {
  const HeatmapCellRemoval({required this.column, required this.row});

  final int column;
  final int row;
}

/// Invalidates one complete source tile and reloads it when visible.
final class HeatmapTileInvalidation extends HeatmapMutation {
  const HeatmapTileInvalidation(this.key);

  final HeatmapTileKey key;
}

/// An ordered, immutable batch applied after the host updates its tile source.
final class HeatmapMutationBatch {
  HeatmapMutationBatch({
    required this.revision,
    required List<HeatmapMutation> mutations,
  }) : mutations = List<HeatmapMutation>.unmodifiable(mutations) {
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision', 'must be non-negative');
    }
    if (mutations.isEmpty) {
      throw ArgumentError.value(mutations, 'mutations', 'must not be empty');
    }
  }

  final int revision;
  final List<HeatmapMutation> mutations;
}
