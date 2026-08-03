// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:ui' as ui;

import 'heatmap_chart_series.dart';
import 'heatmap_color_scale.dart';
import 'heatmap_data_point.dart';
import 'heatmap_viewport_source.dart';

/// Stable presentation metadata for bounded semantic cells mounted beside
/// image-backed Heatmap tiles.
///
/// Raster pixels remain presentation-only. A host opts into exact tooltip,
/// selection, accessibility, table, and Source semantics by attaching a
/// bounded list of canonical [HeatmapDataPoint] values to each tile and by
/// providing this descriptor to the raster viewport controller.
final class HeatmapRasterSemanticDescriptor {
  HeatmapRasterSemanticDescriptor({
    required this.seriesId,
    required this.colorScale,
    this.name,
    this.unit,
    Map<String, dynamic>? metadata,
    this.cellWidth = 1,
    this.cellHeight = 1,
  }) : metadata = metadata == null
           ? null
           : Map<String, dynamic>.unmodifiable(metadata) {
    if (seriesId.trim().isEmpty) {
      throw ArgumentError.value(seriesId, 'seriesId', 'must not be blank');
    }
    if (!cellWidth.isFinite || cellWidth <= 0) {
      throw ArgumentError.value(cellWidth, 'cellWidth', 'must be positive');
    }
    if (!cellHeight.isFinite || cellHeight <= 0) {
      throw ArgumentError.value(cellHeight, 'cellHeight', 'must be positive');
    }
  }

  final String seriesId;
  final String? name;
  final String? unit;
  final Map<String, dynamic>? metadata;
  final HeatmapColorScale colorScale;
  final double cellWidth;
  final double cellHeight;

  /// Builds the canonical bounded series represented by the mounted tiles.
  HeatmapChartSeries buildSeries(Iterable<HeatmapDataPoint> cells) =>
      HeatmapChartSeries(
        id: seriesId,
        name: name,
        unit: unit,
        metadata: metadata,
        points: cells.toList(growable: false),
        colorScale: colorScale,
        cellWidth: cellWidth,
        cellHeight: cellHeight,
        gapFraction: 0,
        borderWidth: 0,
        showInLegend: false,
      );
}

/// A decoded raster resource owned by a Heatmap raster viewport controller.
///
/// The renderer may borrow this resource from an immutable mounted snapshot,
/// but it must never dispose it. A future UI integration can wrap a
/// `dart:ui.Image` without making decode or disposal renderer-owned.
abstract interface class HeatmapRasterResource {
  /// The decoded memory attributed to this resource for cache budgeting.
  int get decodedByteCount;

  /// Releases the decoded resource.
  void dispose();
}

/// A decoded Flutter image that can be painted by the Cartesian raster layer.
///
/// Ownership remains with the creating [HeatmapRasterViewportController]. The
/// renderer borrows [image] only for the duration of paint and never disposes
/// the resource.
final class HeatmapRasterImageResource implements HeatmapRasterResource {
  HeatmapRasterImageResource({required ui.Image image, int? decodedByteCount})
    : _image = image,
      decodedByteCount = decodedByteCount ?? image.width * image.height * 4;

  ui.Image? _image;

  /// The decoded image, while this resource remains controller-owned.
  ui.Image get image {
    final value = _image;
    if (value == null) {
      throw StateError('HeatmapRasterImageResource has been disposed');
    }
    return value;
  }

  @override
  final int decodedByteCount;

  bool get isDisposed => _image == null;

  @override
  void dispose() {
    final value = _image;
    if (value == null) return;
    _image = null;
    value.dispose();
  }
}

/// One ready-to-mount raster tile with exact finite data-space bounds.
final class HeatmapRasterTile {
  HeatmapRasterTile({
    required this.key,
    required this.bounds,
    required this.resource,
    Iterable<HeatmapDataPoint> semanticCells = const <HeatmapDataPoint>[],
    this.revision = 0,
  }) : semanticCells = List<HeatmapDataPoint>.unmodifiable(semanticCells);

  final HeatmapTileKey key;
  final HeatmapViewportBounds bounds;
  final HeatmapRasterResource resource;

  /// Canonical, bounded interaction cells represented by this raster tile.
  ///
  /// These cells may describe exact source samples or honest aggregates with
  /// explicit [HeatmapDataPoint.bounds]. They are never inferred from pixels.
  /// Keeping the list empty makes this tile presentation-only.
  final List<HeatmapDataPoint> semanticCells;

  final int revision;
}

/// Host-owned resolver for decoded Heatmap raster tiles.
///
/// Implementations own transport and decoding. Once a tile is returned, its
/// resource ownership transfers to the requesting raster viewport controller.
abstract interface class HeatmapRasterTileSource {
  HeatmapMatrixDomain get domain;
  int get tileColumnCount;
  int get tileRowCount;

  Future<HeatmapRasterTile> loadTile(HeatmapTileRequest request);
}
