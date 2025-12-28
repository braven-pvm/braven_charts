// Copyright (c) 2025 braven_charts. All rights reserved.
// Multi-Axis Manager Module - Extracted from ChartRenderBox

import 'package:flutter/painting.dart';

import '../../coordinates/chart_transform.dart';
import '../../layout/multi_axis_layout.dart';
import '../../models/chart_series.dart';
import '../../models/normalization_mode.dart';
import '../../models/series_axis_binding.dart';
import '../../models/y_axis_config.dart';
import '../../models/y_axis_position.dart';
import '../multi_axis_normalizer.dart';
import '../multi_axis_painter.dart';
import 'crosshair_renderer.dart';

// Re-export DataRange for use by callers
export '../../models/data_range.dart' show DataRange;

/// Manages multi-axis configuration, bounds computation, and rendering.
///
/// This module encapsulates all multi-axis logic:
/// - Effective Y-axis configuration resolution (with caching)
/// - Series-to-axis binding resolution (with caching)
/// - Viewport-aware bounds computation with 5% padding
/// - Axis width calculation via [MultiAxisLayoutDelegate]
/// - Multi-axis painting coordination via [MultiAxisPainter]
/// - Building [MultiAxisInfo] for CrosshairRenderer integration
///
/// **Caching Strategy**:
/// Effective axes and bindings are cached for performance. Cache is
/// invalidated when [setSeries] is called to update the series list.
///
/// **Viewport Awareness** (FR-008):
/// When perSeries normalization is active with zoom/pan, axis bounds
/// are transformed to show the visible data range (not full range),
/// ensuring axis labels update correctly during interaction.
///
/// **Extracted from ChartRenderBox** to reduce class complexity and
/// improve testability of multi-axis logic.
class MultiAxisManager {
  /// Creates a MultiAxisManager instance.
  MultiAxisManager();

  // ============================================================================
  // State
  // ============================================================================

  /// Current normalization mode.
  NormalizationMode? _normalizationMode;

  /// Current series list for axis/binding resolution.
  List<ChartSeries> _series = const [];

  /// Primary Y-axis configuration from the widget.
  ///
  /// This is the widget-level `yAxis` parameter (YAxisConfig type).
  /// When set, it is included in `getEffectiveYAxes()` results, ensuring
  /// widget-level axis configuration is respected for rendering, crosshair, etc.
  YAxisConfig? _primaryYAxisConfig;

  /// Cached effective bindings (invalidated by setSeries).
  List<SeriesAxisBinding>? _cachedEffectiveBindings;

  // ============================================================================
  // Public Getters
  // ============================================================================

  /// Gets the current normalization mode.
  NormalizationMode? get normalizationMode => _normalizationMode;

  /// Gets the current series list.
  List<ChartSeries> get series => _series;

  // ============================================================================
  // Configuration Updates
  // ============================================================================

  /// Sets the normalization mode for multi-axis charts.
  ///
  /// Returns true if the mode changed, false otherwise.
  bool setNormalizationMode(NormalizationMode? mode) {
    if (_normalizationMode == mode) return false;
    _normalizationMode = mode;
    return true;
  }

  /// Sets the data series for multi-axis configuration resolution.
  ///
  /// This invalidates the cached effective axes and bindings.
  /// Returns true if the series changed, false otherwise.
  bool setSeries(List<ChartSeries>? series) {
    final newSeries = series ?? const [];
    if (_series == newSeries) return false;
    _series = newSeries;
    invalidateCache();
    return true;
  }

  /// Sets the primary Y-axis configuration from the widget.
  ///
  /// This is the widget-level `yAxis` parameter (YAxisConfig type).
  /// When set, it will be included in all `getEffectiveYAxes()` calls
  /// throughout the render cycle (layout, paint, crosshair, etc.).
  ///
  /// Returns true if the config changed, false otherwise.
  bool setPrimaryYAxisConfig(YAxisConfig? config) {
    if (_primaryYAxisConfig == config) return false;
    _primaryYAxisConfig = config;
    return true;
  }

  /// Invalidates cached effective bindings.
  ///
  /// Called automatically by [setSeries], but can be called manually
  /// if series properties change without replacing the list.
  void invalidateCache() {
    _cachedEffectiveBindings = null;
  }

  // ============================================================================
  // Multi-Axis Detection
  // ============================================================================

  /// Checks if multi-axis mode is active.
  ///
  /// Multi-axis mode is active when there are two or more Y-axes configured
  /// (derived from inline yAxisConfig on series).
  bool hasMultipleYAxes() {
    final effectiveAxes = getEffectiveYAxes();
    return effectiveAxes.length > 1;
  }

  /// Checks if perSeries normalization is active with multiple axes.
  bool isMultiAxisNormalizationActive() {
    return hasMultipleYAxes() &&
        _normalizationMode == NormalizationMode.perSeries;
  }

  // ============================================================================
  // Effective Axes Resolution
  // ============================================================================

  /// Gets effective Y-axes from primary axis and inline yAxisConfig on series.
  ///
  /// Priority:
  /// 1. Inline yAxisConfig from series (auto-generates ID as "{seriesId}_axis" if empty)
  /// 2. Primary Y-axis parameter (auto-generates ID as "primary_axis" if empty)
  /// 3. Default Y-axis (created when both above are absent)
  ///
  /// The [primaryYAxis] parameter allows the chart widget to provide a primary
  /// Y-axis configuration that will be included in the returned list unless an
  /// axis with the same ID already exists from inline series configs.
  ///
  /// If [primaryYAxis] is not provided, uses the internally stored
  /// [_primaryYAxisConfig] (set via [setPrimaryYAxisConfig]).
  ///
  /// If neither primaryYAxis nor any series has a Y-axis config, a default
  /// left Y-axis is auto-created to ensure the chart always has a Y-axis.
  ///
  /// Results are cached for performance. Cache is invalidated when
  /// [setSeries] is called. Note: primaryYAxis is NOT cached; it must be
  /// provided on each call to ensure correctness.
  List<YAxisConfig> getEffectiveYAxes({YAxisConfig? primaryYAxis}) {
    // Use stored config if parameter not provided
    final effectivePrimaryYAxis = primaryYAxis ?? _primaryYAxisConfig;

    // Start with list from cache or rebuild
    final effectiveAxes = <YAxisConfig>[];
    final axisIds = <String>{};

    // Step 1: Add inline yAxisConfig from series
    for (final series in _series) {
      if (series.yAxisConfig != null) {
        // Generate axis ID: use config's ID if set, otherwise derive from series ID
        final axisId = series.yAxisConfig!.id.isNotEmpty
            ? series.yAxisConfig!.id
            : '${series.id}_axis';

        // Skip if this axis ID already exists
        if (axisIds.contains(axisId)) continue;

        // Add the inline config with the resolved ID
        final resolvedConfig = series.yAxisConfig!.id.isEmpty
            ? series.yAxisConfig!.copyWith(id: axisId)
            : series.yAxisConfig!;

        effectiveAxes.add(resolvedConfig);
        axisIds.add(axisId);
      }
    }

    // Step 2: Add primary Y-axis ONLY if no inline yAxisConfigs were found
    // When series have inline yAxisConfig, the widget-level yAxis is ignored
    // to prevent duplicate/overlapping axes
    if (effectiveAxes.isEmpty && effectivePrimaryYAxis != null) {
      // Auto-generate ID if empty
      final primaryId = effectivePrimaryYAxis.id.isNotEmpty
          ? effectivePrimaryYAxis.id
          : 'primary_axis';

      final resolvedPrimary = effectivePrimaryYAxis.id.isEmpty
          ? effectivePrimaryYAxis.copyWith(id: primaryId)
          : effectivePrimaryYAxis;

      effectiveAxes.add(resolvedPrimary);
      axisIds.add(primaryId);
    }

    // Step 3: Auto-create default Y-axis if still empty
    // Use 'primary_axis' ID to match what getEffectiveBindings() uses for unbound series
    if (effectiveAxes.isEmpty) {
      final defaultAxis = YAxisConfig(
        position: YAxisPosition.left,
      ).copyWith(id: 'primary_axis');
      effectiveAxes.add(defaultAxis);
    }

    return effectiveAxes;
  }

  // ============================================================================
  // Effective Bindings Resolution
  // ============================================================================

  /// Gets effective axis bindings by deriving bindings from series properties.
  ///
  /// Priority:
  /// 1. series.yAxisConfig (inline config) → generates binding with auto ID
  /// 2. series.yAxisId (explicit reference) → generates binding with that ID
  /// 3. Series without yAxisConfig or yAxisId → auto-bind to default/primary axis
  ///
  /// Results are cached for performance. Cache is invalidated when
  /// [setSeries] is called.
  List<SeriesAxisBinding> getEffectiveBindings() {
    // Return cached if available
    if (_cachedEffectiveBindings != null) return _cachedEffectiveBindings!;

    final effectiveBindings = <SeriesAxisBinding>[];

    for (final series in _series) {
      // Priority 1: Inline yAxisConfig
      if (series.yAxisConfig != null) {
        // Generate axis ID: use config's ID if set, otherwise derive from series ID
        final axisId = series.yAxisConfig!.id.isNotEmpty
            ? series.yAxisConfig!.id
            : '${series.id}_axis';

        effectiveBindings.add(SeriesAxisBinding(
          seriesId: series.id,
          yAxisId: axisId,
        ));
        continue;
      }

      // Priority 2: Explicit yAxisId reference
      if (series.yAxisId != null && series.yAxisId!.isNotEmpty) {
        effectiveBindings.add(SeriesAxisBinding(
          seriesId: series.id,
          yAxisId: series.yAxisId!,
        ));
        continue;
      }

      // Priority 3: Auto-bind to primary/default axis
      // Series without explicit axis config should use the default axis
      // to ensure axis bounds are computed from series data
      effectiveBindings.add(SeriesAxisBinding(
        seriesId: series.id,
        yAxisId:
            'primary_axis', // Matches the ID generated for widget-level yAxis
      ));
    }

    // Cache and return
    _cachedEffectiveBindings = effectiveBindings;
    return effectiveBindings;
  }

  // ============================================================================
  // Axis Bounds Computation
  // ============================================================================

  /// Computes axis bounds from series data for multi-axis rendering.
  ///
  /// Returns a map of axis ID to [DataRange] for each axis.
  ///
  /// This method uses effective bindings derived from series.yAxisConfig,
  /// series.yAxisId properties. Series with matching axis configs are
  /// automatically bound to their corresponding axis.
  ///
  /// **Viewport-Aware**: In perSeries normalization mode, when the chart is
  /// zoomed or panned, the bounds are transformed to show the visible data range
  /// (not full range). This ensures axis labels update correctly during
  /// zoom and pan operations.
  ///
  /// **Parameters**:
  /// - [transform]: Current viewport transform (may differ from original when zoomed/panned)
  /// - [originalTransform]: Original transform before zoom/pan (for comparison)
  /// - [forceFullBounds]: If true, always return full data bounds (no viewport transformation).
  ///   Use this for series painting transforms where we need the full range.
  Map<String, DataRange> computeAxisBounds({
    ChartTransform? transform,
    ChartTransform? originalTransform,
    bool forceFullBounds = false,
  }) {
    final bounds = <String, DataRange>{};

    final effectiveAxes = getEffectiveYAxes();
    if (effectiveAxes.isEmpty) return bounds;

    // Compute effective bindings from series
    final effectiveBindings = getEffectiveBindings();

    // Use local variables for null-safety promotion
    final t = transform;
    final ot = originalTransform;

    // Check if series have multi-axis config (inline yAxisConfig or yAxisId)
    // This determines whether the transform is in normalized (0-1) or actual data space
    final hasMultiAxisConfig = _series.any((s) =>
        s.yAxisConfig != null || (s.yAxisId != null && s.yAxisId!.isNotEmpty));

    // For non-normalized modes (none/auto), the transform's Y range IS the actual
    // data viewport. When zoomed, we can use it directly as axis bounds.
    // ALSO: For perSeries WITHOUT multi-axis config, the transform contains actual
    // data values (not normalized 0-1), so use transform bounds directly.
    final isNonNormalizedMode =
        _normalizationMode != NormalizationMode.perSeries;
    final transformHasRealDataValues = isNonNormalizedMode ||
        (_normalizationMode == NormalizationMode.perSeries &&
            !hasMultiAxisConfig);
    final useTransformYBounds = !forceFullBounds &&
        transformHasRealDataValues &&
        t != null &&
        ot != null &&
        (t.dataYMin != ot.dataYMin || t.dataYMax != ot.dataYMax);

    // Check if viewport Y range differs from original (zoom or pan in perSeries mode)
    // In perSeries mode WITH multi-axis config, normalized Y range is 0-1, so if
    // transform differs, we need to adjust axis labels to show visible data range
    // Skip viewport transformation if forceFullBounds is true (for series painting)
    final isViewportTransformed = !forceFullBounds &&
        _normalizationMode == NormalizationMode.perSeries &&
        hasMultiAxisConfig && // Only when transform is in normalized space
        t != null &&
        ot != null &&
        (t.dataYMin != ot.dataYMin || t.dataYMax != ot.dataYMax);

    for (final axis in effectiveAxes) {
      // For non-normalized modes with viewport change, use transform Y bounds directly
      // Do NOT add padding here - the transform represents the exact viewport,
      // and the crosshair uses the same transform for coordinate conversion
      if (useTransformYBounds) {
        bounds[axis.id] = DataRange(
          min: t.dataYMin,
          max: t.dataYMax,
        );
        continue;
      }

      // Use explicit bounds if provided
      if (axis.min != null && axis.max != null) {
        final fullMin = axis.min!;
        final fullMax = axis.max!;

        // Add 5% padding buffer even for explicit bounds
        final explicitRange = fullMax - fullMin;
        final explicitPadding = explicitRange * 0.05;
        final explicitPaddedMin = fullMin - explicitPadding;
        final explicitPaddedMax = fullMax + explicitPadding;

        if (isViewportTransformed) {
          // Transform explicit bounds based on viewport (zoom/pan)
          // Use the buffer range (-0.05 to 1.05) for viewport calculation
          const bufferRange = 1.1;
          final viewportNormMin = (t.dataYMin + 0.05) / bufferRange;
          final viewportNormMax = (t.dataYMax + 0.05) / bufferRange;
          final paddedRange = explicitPaddedMax - explicitPaddedMin;
          bounds[axis.id] = DataRange(
            min: explicitPaddedMin + (viewportNormMin * paddedRange),
            max: explicitPaddedMin + (viewportNormMax * paddedRange),
          );
        } else {
          bounds[axis.id] =
              DataRange(min: explicitPaddedMin, max: explicitPaddedMax);
        }
        continue;
      }

      // Find series bound to this axis and compute bounds from data
      double? minY;
      double? maxY;

      for (final binding in effectiveBindings) {
        if (binding.yAxisId == axis.id) {
          // Find matching series
          for (final series in _series) {
            if (series.id == binding.seriesId) {
              for (final point in series.points) {
                if (minY == null || point.y < minY) minY = point.y;
                if (maxY == null || point.y > maxY) maxY = point.y;
              }
            }
          }
        }
      }

      // Use computed bounds, or fallback to 0-100 if no data
      final fullMin = axis.min ?? minY ?? 0.0;
      final fullMax = axis.max ?? maxY ?? 100.0;

      // Add 5% padding buffer to prevent data points from being cut off at edges
      // This matches the padding used in DataConverter.computeBounds()
      final range = fullMax - fullMin;
      final paddingAmount = range * 0.05;
      final paddedMin = fullMin - paddingAmount;
      final paddedMax = fullMax + paddingAmount;

      if (isViewportTransformed) {
        // Transform computed bounds based on viewport (zoom/pan)
        // The viewport Y range maps to the visible portion of the data
        // Use the buffer range (-0.05 to 1.05) for viewport calculation
        const bufferRange = 1.1; // -0.05 to 1.05
        final viewportNormMin = (t.dataYMin + 0.05) / bufferRange;
        final viewportNormMax = (t.dataYMax + 0.05) / bufferRange;
        final paddedRange = paddedMax - paddedMin;
        bounds[axis.id] = DataRange(
          min: paddedMin + (viewportNormMin * paddedRange),
          max: paddedMin + (viewportNormMax * paddedRange),
        );
      } else {
        bounds[axis.id] = DataRange(min: paddedMin, max: paddedMax);
      }
    }

    return bounds;
  }

  // ============================================================================
  // Axis Width Calculation
  // ============================================================================

  /// Computes widths for each axis based on label content.
  ///
  /// Uses [MultiAxisLayoutDelegate] for consistent width calculation.
  ///
  /// **Parameters**:
  /// - [axisBounds]: Map of axis ID to DataRange (from [computeAxisBounds])
  /// - [labelStyle]: Text style for tick labels (defaults to 11px gray)
  Map<String, double> computeAxisWidths({
    required Map<String, DataRange> axisBounds,
    TextStyle labelStyle =
        const TextStyle(fontSize: 11, color: Color(0xFF666666)),
  }) {
    final effectiveAxes = getEffectiveYAxes();
    if (effectiveAxes.isEmpty) return {};

    // Use MultiAxisLayoutDelegate for consistent width calculation
    const layoutDelegate = MultiAxisLayoutDelegate();
    return layoutDelegate.computeAxisWidths(
      axes: effectiveAxes,
      axisBounds: axisBounds,
      labelStyle: labelStyle,
    );
  }

  // ============================================================================
  // Multi-Axis Painting
  // ============================================================================

  /// Paints multiple Y-axes using [MultiAxisPainter].
  ///
  /// This method computes axis bounds from series data and renders each axis
  /// with appropriate colors and labels.
  ///
  /// **Parameters**:
  /// - [canvas]: Canvas to draw on
  /// - [size]: Total widget size
  /// - [plotArea]: Plot area rectangle (content area excluding margins)
  /// - [transform]: Current viewport transform
  /// - [originalTransform]: Original transform before zoom/pan
  void paintMultipleYAxes({
    required Canvas canvas,
    required Size size,
    required Rect plotArea,
    ChartTransform? transform,
    ChartTransform? originalTransform,
  }) {
    final effectiveAxes = getEffectiveYAxes();
    if (effectiveAxes.isEmpty) return;

    // Compute axis bounds from series data
    final axisBounds = computeAxisBounds(
      transform: transform,
      originalTransform: originalTransform,
    );

    // Use effective bindings for color resolution
    final effectiveBindings = getEffectiveBindings();

    // Create and invoke painter
    final painter = MultiAxisPainter(
      axes: effectiveAxes,
      axisBounds: axisBounds,
      bindings: effectiveBindings,
      series: _series,
    );

    // Paint axes - chartArea is full size, plotArea is content area
    painter.paint(canvas, Offset.zero & size, plotArea);
  }

  // ============================================================================
  // MultiAxisInfo Builder
  // ============================================================================

  /// Builds [MultiAxisInfo] for the CrosshairRenderer module.
  ///
  /// This helper gathers all multi-axis configuration data needed for
  /// crosshair rendering, encapsulated in a [MultiAxisInfo] object.
  ///
  /// **Parameters**:
  /// - [transform]: Current viewport transform
  /// - [originalTransform]: Original transform before zoom/pan
  MultiAxisInfo buildMultiAxisInfo({
    ChartTransform? transform,
    ChartTransform? originalTransform,
  }) {
    final effectiveAxes = getEffectiveYAxes();
    final axisBounds = computeAxisBounds(
      transform: transform,
      originalTransform: originalTransform,
    );
    final axisWidths = computeAxisWidths(axisBounds: axisBounds);
    final effectiveBindings = getEffectiveBindings();

    return MultiAxisInfo(
      effectiveAxes: effectiveAxes,
      axisBounds: axisBounds,
      axisWidths: axisWidths,
      effectiveBindings: effectiveBindings,
      normalizationMode: _normalizationMode,
      series: _series,
    );
  }

  // ============================================================================
  // Normalization Helpers (FR-008)
  // ============================================================================

  /// Normalizes a Y value for multi-axis rendering.
  ///
  /// When charts have series with vastly different Y-ranges (e.g., 0-10 vs 0-1000),
  /// normalization maps all values to 0.0-1.0 range for consistent visual display.
  ///
  /// This method wraps [MultiAxisNormalizer.normalize] for convenience.
  ///
  /// **Parameters**:
  /// - [value]: The original Y data value to normalize
  /// - [seriesMin]: The minimum Y value in this series
  /// - [seriesMax]: The maximum Y value in this series
  ///
  /// **Returns**: Normalized value in 0.0-1.0 range
  double normalizeYValue(double value, double seriesMin, double seriesMax) {
    return MultiAxisNormalizer.normalize(value, seriesMin, seriesMax);
  }

  /// Denormalizes a Y value back to original data coordinates.
  ///
  /// Used for tooltip display and crosshair value labels when multi-axis
  /// normalization is active. Users see original values, not normalized 0.0-1.0 values.
  ///
  /// This method wraps [MultiAxisNormalizer.denormalize] for convenience.
  ///
  /// **Parameters**:
  /// - [normalizedValue]: The normalized value (0.0-1.0)
  /// - [seriesMin]: The minimum Y value in this series
  /// - [seriesMax]: The maximum Y value in this series
  ///
  /// **Returns**: Original data value in series range
  double denormalizeYValue(
      double normalizedValue, double seriesMin, double seriesMax) {
    return MultiAxisNormalizer.denormalize(
        normalizedValue, seriesMin, seriesMax);
  }

  /// Normalizes a value from data space to normalized [0, 1] space.
  ///
  /// This method wraps [MultiAxisNormalizer.normalize] for use in rendering
  /// logic when multiple series with different Y-ranges need to share the
  /// same visual axis.
  ///
  /// **Parameters**:
  /// - [value]: The raw data value to normalize
  /// - [min]: The minimum value of the data range
  /// - [max]: The maximum value of the data range
  ///
  /// **Returns**: A value in the range [0, 1]
  double normalizeValue(double value, double min, double max) {
    return MultiAxisNormalizer.normalize(value, min, max);
  }

  /// Denormalizes a value from normalized [0, 1] space back to data space.
  ///
  /// This method wraps [MultiAxisNormalizer.denormalize] for use in
  /// interaction logic (e.g., tooltips, crosshairs) when converting
  /// visual positions back to original data values.
  ///
  /// **Parameters**:
  /// - [normalizedValue]: A value in [0, 1] range
  /// - [min]: The minimum value of the target data range
  /// - [max]: The maximum value of the target data range
  ///
  /// **Returns**: The original data value corresponding to the normalized position
  double denormalizeValue(double normalizedValue, double min, double max) {
    return MultiAxisNormalizer.denormalize(normalizedValue, min, max);
  }

  // ============================================================================
  // Layout Helpers
  // ============================================================================

  /// Gets total width needed for left-side axes.
  ///
  /// Used for plot area margin calculation.
  ///
  /// **Parameters**:
  /// - [axisWidths]: Map of axis ID to width (from [computeAxisWidths])
  double getTotalLeftAxisWidth(Map<String, double> axisWidths) {
    const layoutDelegate = MultiAxisLayoutDelegate();
    return layoutDelegate.getTotalLeftWidth(getEffectiveYAxes(), axisWidths);
  }

  /// Gets total width needed for right-side axes.
  ///
  /// Used for plot area margin calculation.
  ///
  /// **Parameters**:
  /// - [axisWidths]: Map of axis ID to width (from [computeAxisWidths])
  double getTotalRightAxisWidth(Map<String, double> axisWidths) {
    const layoutDelegate = MultiAxisLayoutDelegate();
    return layoutDelegate.getTotalRightWidth(getEffectiveYAxes(), axisWidths);
  }
}
