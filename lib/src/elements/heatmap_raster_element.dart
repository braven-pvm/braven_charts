// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'dart:ui';

import '../controllers/heatmap_raster_viewport_controller.dart';
import '../coordinates/chart_transform.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/element_types.dart';
import '../models/heatmap_raster_viewport_source.dart';

/// Non-interactive background element for ready-to-paint Heatmap raster tiles.
///
/// The element performs only source-to-plot geometry and paint. Loading,
/// decoding, cache policy, publication, and disposal remain controller-owned.
final class HeatmapRasterElement
    implements ChartElement, CartesianTransformElement {
  HeatmapRasterElement({
    required this.snapshot,
    required ChartTransform transform,
    this.opacity = 1,
    this.filterQuality = FilterQuality.low,
  }) : assert(opacity >= 0 && opacity <= 1),
       _transform = transform;

  final HeatmapRasterViewportSnapshot snapshot;
  final double opacity;
  final FilterQuality filterQuality;
  ChartTransform _transform;

  @override
  String get id => '__heatmap_raster_tiles__';

  @override
  Rect get bounds {
    Rect? result;
    for (final tile in snapshot.mountedTiles) {
      final tileRect = _plotRect(tile);
      if (tileRect == null) continue;
      result = result == null ? tileRect : result.expandToInclude(tileRect);
    }
    return result ?? Rect.zero;
  }

  @override
  ChartElementType get elementType => ChartElementType.backgroundInteraction;

  @override
  int get priority => ElementPriority.backgroundInteraction;

  @override
  int get renderOrder => RenderOrder.rasterTile;

  @override
  bool get isSelected => false;

  @override
  bool get isHovered => false;

  @override
  bool get isSelectable => false;

  @override
  bool get isDraggable => false;

  @override
  bool hitTest(Offset position) => false;

  @override
  void updateTransform(ChartTransform transform) => _transform = transform;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final paint = Paint()
      ..filterQuality = filterQuality
      ..color = Color.fromRGBO(255, 255, 255, opacity);
    final visible = Offset.zero & size;
    for (final tile in snapshot.mountedTiles) {
      final resource = tile.resource;
      if (resource is! HeatmapRasterImageResource || resource.isDisposed) {
        continue;
      }
      final destination = _plotRect(tile);
      if (destination == null || !destination.overlaps(visible)) continue;
      final image = resource.image;
      final source = Rect.fromLTWH(
        0,
        0,
        image.width.toDouble(),
        image.height.toDouble(),
      );
      canvas.drawImageRect(image, source, destination, paint);
    }
  }

  Rect? _plotRect(HeatmapRasterTile tile) {
    final bounds = tile.bounds;
    final corners = <Offset>[
      _transform.dataToPlot(bounds.minimumX, bounds.minimumY),
      _transform.dataToPlot(bounds.minimumX, bounds.maximumY),
      _transform.dataToPlot(bounds.maximumX, bounds.minimumY),
      _transform.dataToPlot(bounds.maximumX, bounds.maximumY),
    ];
    if (corners.any((point) => !point.dx.isFinite || !point.dy.isFinite)) {
      return null;
    }
    final xs = corners.map((point) => point.dx);
    final ys = corners.map((point) => point.dy);
    final rect = Rect.fromLTRB(
      xs.reduce((a, b) => a < b ? a : b),
      ys.reduce((a, b) => a < b ? a : b),
      xs.reduce((a, b) => a > b ? a : b),
      ys.reduce((a, b) => a > b ? a : b),
    );
    return rect.isEmpty ? null : rect;
  }

  @override
  void onSelect() {}

  @override
  void onDeselect() {}

  @override
  void onHoverEnter() {}

  @override
  void onHoverExit() {}

  @override
  ChartElement copyWith({bool? isHovered, bool? isSelected}) => this;
}
