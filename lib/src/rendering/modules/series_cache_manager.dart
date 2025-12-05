// Copyright (c) 2025 braven_charts. All rights reserved.
// Series Cache Manager - Extracted from ChartRenderBox

import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show Size, Offset;

import '../../coordinates/chart_transform.dart';
import '../../interaction/core/chart_element.dart';
import '../../elements/series_element.dart';

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
      if (element is SeriesElement) {
        hash = hash * 31 + element.series.points.length;
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
