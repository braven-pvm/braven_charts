// Copyright (c) 2025 braven_charts. All rights reserved.
// Series Cache Manager - Extracted from ChartRenderBox

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show Size, Offset;

import '../../coordinates/chart_transform.dart';
import '../../interaction/core/chart_element.dart';
import '../../models/axis_scale_type.dart';

/// Callback type for painting series elements.
///
/// This allows the caller (ChartRenderBox) to provide custom painting logic
/// that handles multi-axis transforms and other complex logic.
typedef SeriesPainter = void Function(ui.Canvas canvas, Size size);

/// Manages GPU-accelerated Picture caching for series layer rendering.
///
/// This class handles the caching of series elements as a Flutter Picture,
/// which provides significant performance benefits during hover and interaction
/// events where the underlying data hasn't changed.
///
/// **Performance Benefits**:
/// - Saves ~17ms per frame during hover (at 5 series x 1000 points)
/// - Enables 60fps interaction with large datasets
/// - Memory footprint: ~170KB for typical chart
///
/// **Cache Invalidation**:
/// The cache is invalidated when:
/// - Data changes (series added/removed/updated)
/// - Transform changes (pan/zoom operations complete)
/// - Theme changes (visual appearance updated)
///
/// The cache is NOT invalidated for:
/// - Crosshair hover events
/// - Box selection drag
/// - Annotation drag
class SeriesCacheManager {
  /// Cached rendering of series layer as a Picture.
  ui.Picture? _cachedPicture;

  /// Flag indicating if the cache needs regeneration.
  bool _isDirty = true;

  /// Transform state when cache was last generated.
  ChartTransform? _cachedTransform;

  /// Transform used to record coordinates inside [_cachedPicture].
  ///
  /// This normally matches [_cachedTransform]. A caller may deliberately
  /// record an overscanned picture for a smaller viewport, however, so the
  /// two transforms must remain distinct.
  ChartTransform? _pictureTransform;

  /// Hash of series data when cache was last generated.
  int _cachedSeriesHash = 0;

  /// Whether the cache is dirty and needs regeneration.
  bool get isDirty => _isDirty;

  /// Returns the cached Picture if valid, null otherwise.
  ui.Picture? get cachedPicture => _cachedPicture;

  /// Marks the cache as dirty, requiring regeneration on next paint.
  void invalidate() {
    _isDirty = true;
  }

  /// Disposes the cached Picture to free GPU memory.
  ///
  /// Must be called when the cache manager is no longer needed
  /// to prevent memory leaks.
  void dispose() {
    _cachedPicture?.dispose();
    _cachedPicture = null;
    _cachedTransform = null;
    _pictureTransform = null;
  }

  /// Whether the current clean picture can be mapped to [currentTransform].
  ///
  /// This is intentionally a low-level cache primitive. Callers remain
  /// responsible for limiting transformed reuse to series whose interaction
  /// preview is safe (currently dense Heatmaps only).
  bool canDrawForTransform({
    required List<ChartElement> elements,
    required ChartTransform? currentTransform,
  }) {
    final pictureTransform = _pictureTransform;
    if (_cachedPicture == null ||
        _isDirty ||
        currentTransform == null ||
        pictureTransform == null ||
        currentTransform.transposed ||
        pictureTransform.transposed ||
        currentTransform.xScaleType != pictureTransform.xScaleType ||
        currentTransform.yScaleType != pictureTransform.yScaleType ||
        currentTransform.xLogBase != pictureTransform.xLogBase ||
        currentTransform.yLogBase != pictureTransform.yLogBase ||
        currentTransform.invertY != pictureTransform.invertY ||
        _calculateSeriesHash(elements) != _cachedSeriesHash) {
      return false;
    }

    // Affine picture reuse is exact only for the linear coordinate mapping.
    // Time axes use that same mapping in ChartTransform.
    if (currentTransform.xScaleType == AxisScaleType.log ||
        currentTransform.yScaleType == AxisScaleType.log) {
      return false;
    }

    const epsilon = 1e-9;
    return currentTransform.dataXMin >= pictureTransform.dataXMin - epsilon &&
        currentTransform.dataXMax <= pictureTransform.dataXMax + epsilon &&
        currentTransform.dataYMin >= pictureTransform.dataYMin - epsilon &&
        currentTransform.dataYMax <= pictureTransform.dataYMax + epsilon;
  }

  /// Draws the cached picture mapped into [currentTransform].
  ///
  /// Returns false when the cached picture is not compatible with the target
  /// transform or does not contain its full data viewport.
  bool drawForTransform({
    required ui.Canvas canvas,
    required List<ChartElement> elements,
    required ChartTransform? currentTransform,
  }) {
    if (!canDrawForTransform(
      elements: elements,
      currentTransform: currentTransform,
    )) {
      return false;
    }

    final target = currentTransform!;
    final source = _pictureTransform!;
    final scaleX =
        (target.plotWidth / target.dataXRange) /
        (source.plotWidth / source.dataXRange);
    final scaleY =
        (target.plotHeight / target.dataYRange) /
        (source.plotHeight / source.dataYRange);
    final translateX =
        (source.dataXMin - target.dataXMin) *
        target.plotWidth /
        target.dataXRange;
    final translateY = target.invertY
        ? (target.dataYMax - source.dataYMax) *
              target.plotHeight /
              target.dataYRange
        : (source.dataYMin - target.dataYMin) *
              target.plotHeight /
              target.dataYRange;

    canvas.save();
    canvas.translate(translateX, translateY);
    canvas.scale(scaleX, scaleY);
    canvas.drawPicture(_cachedPicture!);
    canvas.restore();
    return true;
  }

  /// Checks if the cache is valid and can be reused.
  ///
  /// Cache is valid if:
  /// 1. Cache exists (_cachedPicture != null)
  /// 2. Cache is not marked dirty (_isDirty == false)
  /// 3. Series data hash hasn't changed
  /// 4. Transform hasn't changed
  bool isValid({
    required List<ChartElement> elements,
    required ChartTransform? currentTransform,
  }) {
    if (_cachedPicture == null || _isDirty) {
      return false;
    }

    // An overscanned interaction picture must always be mapped through
    // drawForTransform(), even when the viewport that requested it has not
    // changed since recording.
    if (_pictureTransform != _cachedTransform) {
      return false;
    }

    // Check if series data changed
    final currentHash = _calculateSeriesHash(elements);
    if (currentHash != _cachedSeriesHash) {
      return false;
    }

    // Check if transform changed
    if (_transformChanged(currentTransform)) {
      return false;
    }

    return true;
  }

  /// Generates a new cached Picture using the provided painter callback.
  ///
  /// This method creates a GPU-accelerated Picture by recording all series
  /// rendering commands into a PictureRecorder.
  ///
  /// **Parameters**:
  /// - elements: All chart elements (for hash calculation)
  /// - plotAreaSize: Size of the plot area for rendering
  /// - currentTransform: Current coordinate transform
  /// - painter: Callback that paints the series elements
  ///
  /// **Returns**: New cached Picture ready for drawing
  ui.Picture generatePicture({
    required List<ChartElement> elements,
    required Size plotAreaSize,
    required ChartTransform? currentTransform,
    ChartTransform? pictureTransform,
    required SeriesPainter painter,
  }) {
    // Dispose old picture before creating new one
    _cachedPicture?.dispose();

    // Create recorder with plot area bounds
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    // Clip to plot area bounds to prevent rendering outside cache region
    canvas.clipRect(Offset.zero & plotAreaSize);

    // Let the caller paint the series (handles multi-axis transforms, etc.)
    painter(canvas, plotAreaSize);

    // End recording to produce Picture
    final picture = recorder.endRecording();

    // Update cache metadata
    _cachedPicture = picture;
    _cachedSeriesHash = _calculateSeriesHash(elements);
    _cachedTransform = currentTransform?.copyWith();
    _pictureTransform = (pictureTransform ?? currentTransform)?.copyWith();
    _isDirty = false;

    return picture;
  }

  /// Calculates a hash of the current series data for change detection.
  int _calculateSeriesHash(List<ChartElement> elements) {
    // Simple hash based on element count and types
    // More sophisticated hashing could include data ranges
    int hash = elements.length;
    for (final element in elements) {
      hash = hash * 31 + element.id.hashCode;
      if (element is DataSeriesElement) {
        hash = hash * 31 + element.pointCount;
      }
    }
    return hash;
  }

  /// Checks if the transform has changed since cache was generated.
  bool _transformChanged(ChartTransform? currentTransform) {
    if (currentTransform == null && _cachedTransform == null) {
      return false;
    }
    if (currentTransform == null || _cachedTransform == null) {
      return true;
    }

    // Compare data ranges (this is what affects rendering)
    return currentTransform.dataXMin != _cachedTransform!.dataXMin ||
        currentTransform.dataXMax != _cachedTransform!.dataXMax ||
        currentTransform.dataYMin != _cachedTransform!.dataYMin ||
        currentTransform.dataYMax != _cachedTransform!.dataYMax;
  }
}
