// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Series Rendering

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart'
    show
        FontWeight,
        LinearGradient,
        TextAlign,
        TextDirection,
        TextPainter,
        TextSpan,
        TextStyle;

import '../coordinates/chart_transform.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/data_hit.dart';
import '../interaction/core/coordinator.dart';
import '../interaction/core/element_types.dart';
import '../models/bar_group_info.dart';
import '../models/bar_chart_style.dart';
import '../models/candlestick_chart_series.dart';
import '../models/candlestick_chart_style.dart';
import '../models/candlestick_interaction_details.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/scatter_marker_style.dart'
    show ScatterCategoryStyle, ScatterJitterConfig;
import '../models/scatter_render_config.dart';
import '../models/data_point_label_config.dart';
import '../models/series_inline_label_config.dart';
import '../rendering/bar_geometry.dart';
import '../rendering/bar_bullet_painter.dart';
import '../rendering/bar_label_layout.dart';
import '../rendering/bar_pattern_painter.dart';
import '../rendering/candlestick_geometry.dart';
import '../rendering/data_point_label_layout.dart';
import '../rendering/scatter_binning.dart';
import '../rendering/scatter_geometry.dart';
import '../rendering/scatter_clustering.dart';
import '../rendering/scatter_density.dart';
import '../rendering/scatter_marker_path.dart';
import '../theming/components/series_theme.dart';
import '../theming/components/candlestick_theme.dart';
import '../utils/dashed_path.dart';
import '../utils/interpolation_geometry.dart';
import '../utils/path_series_transition.dart';

List<double> _dashPatternFor(ChartSeries series) => switch (series) {
  LineChartSeries() => series.dashPattern,
  AreaChartSeries() => series.dashPattern,
  _ => const [],
};

bool _dashPatternsEqual(List<double> first, List<double> second) {
  if (identical(first, second)) return true;
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}

class _ResolvedScatterMarkerStyle {
  const _ResolvedScatterMarkerStyle({
    required this.shape,
    required this.fillColor,
    required this.strokeColor,
    required this.strokeWidth,
    required this.opacity,
    required this.width,
    required this.height,
    required this.rotationRadians,
  });

  final SeriesMarkerShape shape;
  final Color? fillColor;
  final Color? strokeColor;
  final double strokeWidth;
  final double opacity;
  final double width;
  final double height;
  final double rotationRadians;

  double get boundingRadius =>
      math.sqrt(width * width + height * height) / 2 + strokeWidth / 2;
}

class _ResolvedCandlestickVisual {
  const _ResolvedCandlestickVisual({
    required this.fillColor,
    required this.borderColor,
    required this.wickColor,
  });

  final Color fillColor;
  final Color borderColor;
  final Color wickColor;
}

class _CandlestickPaintBatch {
  _CandlestickPaintBatch({
    required this.fillPath,
    required this.borderPath,
    required this.wickPath,
    required this.fillPaint,
    required this.borderPaint,
    required this.wickPaint,
  });

  final Path fillPath;
  final Path borderPath;
  final Path wickPath;
  final Paint fillPaint;
  final Paint borderPaint;
  final Paint wickPaint;
}

// =============================================================================
// Style Region for Segment Stroke Batching
// =============================================================================

/// Represents a continuous region of same-styled segments for batched rendering.
///
/// When segment styles are used, the series line is divided into regions
/// where each region has consistent styling (color + stroke width + pattern).
/// This enables efficient batched rendering with minimal drawPath() calls.
class _StyleRegion {
  const _StyleRegion({
    required this.startIndex,
    required this.endIndex,
    required this.color,
    required this.strokeWidth,
    required this.dashPattern,
  });

  /// Index of first point in region (segment starts here).
  final int startIndex;

  /// Index of last point in region (segment ends here, inclusive).
  final int endIndex;

  /// Effective color for this region.
  final Color color;

  /// Effective stroke width for this region.
  final double strokeWidth;

  /// Effective dash pattern for this region. Empty means a solid stroke.
  final List<double> dashPattern;

  /// Number of segments in this region.
  int get segmentCount => endIndex - startIndex;
}

/// Analyzes points to find continuous style regions for batched rendering.
///
/// Returns a list of regions where each region has consistent styling.
/// Adjacent points with the same effective style are grouped together,
/// minimizing the number of drawPath() calls needed.
///
/// **Performance**: O(n) single pass through points.
List<_StyleRegion> _analyzeStyleRegions(
  List<ChartDataPoint> points,
  Color defaultColor,
  double defaultStrokeWidth,
  List<double> defaultDashPattern,
) {
  if (points.length < 2) return [];

  final regions = <_StyleRegion>[];
  int regionStart = 0;

  // Get effective style for first segment (from first point)
  Color currentColor = points[0].segmentStyle?.color ?? defaultColor;
  double currentWidth =
      points[0].segmentStyle?.strokeWidth ?? defaultStrokeWidth;
  List<double> currentDashPattern =
      points[0].segmentStyle?.dashPattern ?? defaultDashPattern;

  // Iterate through points, detecting style changes
  // Note: We check points[i] for segment i→i+1's style
  for (int i = 1; i < points.length - 1; i++) {
    final style = points[i].segmentStyle;
    final pointColor = style?.color ?? defaultColor;
    final pointWidth = style?.strokeWidth ?? defaultStrokeWidth;
    final pointDashPattern = style?.dashPattern ?? defaultDashPattern;

    // Check if style changed at this point
    if (pointColor != currentColor ||
        pointWidth != currentWidth ||
        !_dashPatternsEqual(pointDashPattern, currentDashPattern)) {
      // Close current region (ends at point i, inclusive)
      regions.add(
        _StyleRegion(
          startIndex: regionStart,
          endIndex: i,
          color: currentColor,
          strokeWidth: currentWidth,
          dashPattern: currentDashPattern,
        ),
      );

      // Start new region from this point
      regionStart = i;
      currentColor = pointColor;
      currentWidth = pointWidth;
      currentDashPattern = pointDashPattern;
    }
  }

  // Close final region (always ends at last point)
  regions.add(
    _StyleRegion(
      startIndex: regionStart,
      endIndex: points.length - 1,
      color: currentColor,
      strokeWidth: currentWidth,
      dashPattern: currentDashPattern,
    ),
  );

  return regions;
}

// =============================================================================
// Series Element
// =============================================================================

/// Wraps a ChartSeries as a ChartElement for the interaction system.
///
/// **Purpose**: Bridge ChartSeries data model to ChartElement interface so
/// series can participate in spatial indexing and hit testing.
///
/// **Rendering**: Converts data points to plot space and renders as line/area/scatter.
///
/// **Interactions**:
/// - Selectable: Click to select entire series
/// - Hoverable: Hover to highlight series
/// - Not draggable: Series lines are stationary (datapoints can be dragged separately)
class SeriesElement implements DataHitElement {
  SeriesElement({
    required this.series,
    required this.transform,
    this.isSelected = false,
    this.isHovered = false,
    this.seriesTheme,
    this.candlestickTheme = CandlestickTheme.light,
    this.seriesIndex = 0,
    this.coordinator,
    this.barGroupInfo,
    this.focusedPointIndices = const {},
    this.selectedPointIndices = const {},
    this.pointFocusColor,
    this.pointSelectionColor,
    this.fontFamily,
    this.hasAnySelectedPoints = false,
    this.revealProgress = 1,
    this.pathPointMap,
    this.textDirection = TextDirection.ltr,
    @Deprecated('Use seriesTheme instead') double? strokeWidth,
    @Deprecated('Use seriesTheme instead') Color? themeColor,
  }) : _deprecatedStrokeWidth = strokeWidth,
       _deprecatedThemeColor = themeColor,
       _currentTransform = transform {
    _computeBounds();
  }

  @override
  ChartSeries series; // Made mutable for updateSeries()
  final ChartTransform transform; // Initial transform for bounds computation
  ChartTransform _currentTransform; // Current transform for painting

  /// Effective transform used by the current paint and interaction pass.
  ///
  /// Scatter tracking uses this rather than the construction transform so
  /// nearest-point lookup remains correct after zoom, pan, and per-series
  /// multi-axis normalization.
  ChartTransform get currentTransform => _currentTransform;

  /// Maps a data coordinate through the transform currently used for paint.
  ///
  /// Crosshair overlays use this to align synchronized local-value guides
  /// without recomputing axis bounds or rebuilding series geometry.
  Offset dataToCurrentPlot(double x, double y) =>
      _currentTransform.dataToPlot(x, y);
  final SeriesTheme? seriesTheme;
  final CandlestickTheme candlestickTheme;
  @override
  final int seriesIndex;

  @override
  int get pointCount => pathPointMap?.targetPointCount ?? series.points.length;
  final ChartInteractionCoordinator? coordinator;

  /// Point indices receiving transient linked focus from another surface.
  final Set<int> focusedPointIndices;

  /// Point indices receiving durable linked selection from another surface.
  final Set<int> selectedPointIndices;

  final Color? pointFocusColor;
  final Color? pointSelectionColor;

  /// Font family inherited from the chart typography theme.
  final String? fontFamily;

  /// Whether any point in the chart is durably selected.
  ///
  /// Bar series use this to de-emphasize non-selected bars consistently across
  /// series without coupling the renderer to widget state.
  final bool hasAnySelectedPoints;

  /// Ambient reading direction used by canvas value labels.
  final TextDirection textDirection;

  /// Leading-edge reveal progress for Line, Area, and Candlestick series.
  final double revealProgress;

  /// Canonical point identities for temporary Line/Area transition geometry.
  final PathSeriesPointMap? pathPointMap;

  bool get _supportsReveal =>
      series is LineChartSeries ||
      series is AreaChartSeries ||
      series is CandlestickChartSeries;

  double get _effectiveRevealProgress =>
      _supportsReveal ? revealProgress.clamp(0.0, 1.0) : 1;

  double get _revealEdge =>
      _currentTransform.plotWidth * _effectiveRevealProgress;

  int? _targetIndexForRenderIndex(int renderIndex) {
    final pointMap = pathPointMap;
    return pointMap == null
        ? renderIndex
        : pointMap.targetIndexForRenderIndex(renderIndex);
  }

  int? _renderIndexForTargetIndex(int targetIndex) {
    final pointMap = pathPointMap;
    return pointMap == null
        ? targetIndex
        : pointMap.renderIndexForTargetIndex(targetIndex);
  }

  /// Bar group positioning metadata (only used for BarChartSeries).
  ///
  /// When multiple bar series share the same X-values, this metadata is used
  /// to calculate horizontal offsets so bars appear side-by-side rather than
  /// overlapping. Null for non-bar series.
  final BarGroupInfo? barGroupInfo;

  // Deprecated fields for backward compatibility
  final double? _deprecatedStrokeWidth;
  final Color? _deprecatedThemeColor;

  // Get effective stroke width: series-explicit > theme > deprecated > default
  // Series properties take precedence when explicitly set on the series
  double get strokeWidth {
    // Check if series has strokeWidth property (LineChartSeries, AreaChartSeries)
    if (series is LineChartSeries) {
      return (series as LineChartSeries).strokeWidth;
    }
    if (series is AreaChartSeries) {
      return (series as AreaChartSeries).strokeWidth;
    }
    // Fall back to theme for series types without explicit strokeWidth
    return seriesTheme?.lineWidthAt(seriesIndex) ??
        _deprecatedStrokeWidth ??
        2.0;
  }

  // Get effective color: series-explicit > deprecated > theme > default
  // Series color takes precedence when explicitly set
  Color get themeColor {
    // Series explicit color takes priority
    if (series.color != null) {
      return series.color!;
    }
    // Fall back to deprecated parameter, then theme, then default
    return _deprecatedThemeColor ??
        seriesTheme?.colorAt(seriesIndex) ??
        const Color(0xFF2196F3);
  }

  // Get effective marker size: series-explicit > theme > default
  double get markerSize {
    // Check if series has dataPointMarkerRadius property
    if (series is LineChartSeries) {
      return (series as LineChartSeries).dataPointMarkerRadius;
    }
    if (series is AreaChartSeries) {
      return (series as AreaChartSeries).dataPointMarkerRadius;
    }
    if (series is ScatterChartSeries) {
      return (series as ScatterChartSeries).markerRadius;
    }
    // Fall back to theme for series types without explicit marker size
    return seriesTheme?.markerSizeAt(seriesIndex) ?? 6.0;
  }

  // Get effective marker shape from theme or default
  SeriesMarkerShape get markerShape =>
      seriesTheme?.markerShapeAt(seriesIndex) ?? SeriesMarkerShape.circle;

  /// Update the current transform before painting (for real-time pan/zoom).
  /// This allows path caching to work - transform stored at construction stays fixed,
  /// but _currentTransform updates on every paint.
  ///
  /// IMPORTANT: If Y bounds change (perSeries normalization mode), bounds are
  /// recomputed so QuadTree hit detection works correctly.
  void updateTransform(ChartTransform newTransform) {
    final transformChanged =
        _currentTransform.dataXMin != newTransform.dataXMin ||
        _currentTransform.dataXMax != newTransform.dataXMax ||
        _currentTransform.dataYMin != newTransform.dataYMin ||
        _currentTransform.dataYMax != newTransform.dataYMax ||
        _currentTransform.plotWidth != newTransform.plotWidth ||
        _currentTransform.plotHeight != newTransform.plotHeight;

    _currentTransform = newTransform;

    if (transformChanged) {
      _clearResolvedBarGeometry();
      _clearResolvedScatterGeometry();
      _clearResolvedCandlestickGeometry();
      _computeBounds();
    }
  }

  /// Update the series data without recreating the element.
  /// This preserves the path cache, avoiding expensive Bezier regeneration.
  /// Only invalidates cache if the point count changed significantly.
  ///
  /// [skipBoundsComputation] should be true for streaming updates where
  /// bounds are tracked externally (in StreamingBuffer). This avoids
  /// expensive O(n) iteration through all points on every frame.
  void updateSeries(
    ChartSeries newSeries, {
    bool skipBoundsComputation = true,
  }) {
    // Check if we need to invalidate path cache
    final pointCountChanged = newSeries.points.length != series.points.length;
    final dashPatternChanged = !_dashPatternsEqual(
      _dashPatternFor(series),
      _dashPatternFor(newSeries),
    );

    series = newSeries;
    _barViewportIndex = null;
    _scatterViewportIndex = null;
    _candlestickViewportIndex = null;
    _clearResolvedBarGeometry();
    _clearResolvedScatterGeometry();
    _clearResolvedCandlestickGeometry();

    // PERFORMANCE: Skip bounds computation for streaming updates.
    // Streaming elements use pre-computed bounds from StreamingBuffer
    // and aren't added to QuadTree, so bounds aren't needed.
    if (!skipBoundsComputation) {
      _computeBounds();
    }

    // Invalidate cache only if geometry changed significantly
    if (pointCountChanged || dashPatternChanged) {
      _invalidateAllCaches();
    }
    // Always clear label cache — label config may have changed
    _labelPainterCache.clear();
  }

  /// Invalidates all cached rendering data.
  /// Call when series data changes or segment styles are modified.
  void _invalidateAllCaches() {
    _cachedPath = null;
    _cachedStrokePath = null;
    _cachedTransformedPoints = null;
    _cachedOriginalIndices = null;
    _cachedHasSegmentOverrides = null;
    _barViewportIndex = null;
    _clearResolvedBarGeometry();
    _scatterViewportIndex = null;
    _clearResolvedScatterGeometry();
    _candlestickViewportIndex = null;
    _clearResolvedCandlestickGeometry();
    _labelPainterCache.clear();
  }

  /// Disposes cached resources. Call when this element is no longer needed.
  void dispose() {
    for (final tp in _labelPainterCache.values) {
      tp.dispose();
    }
    _labelPainterCache.clear();
  }

  @override
  final bool isSelected;

  @override
  final bool isHovered;

  late Rect _bounds;

  // Cache the rendered path to avoid recalculating on every paint
  Path? _cachedPath;
  Path? _cachedStrokePath;
  List<Offset>? _cachedTransformedPoints;
  List<int>?
  _cachedOriginalIndices; // Maps visible point index → original series.points index
  late ChartTransform _cachedTransform;

  // Segment color caching - fast-path check result
  bool? _cachedHasSegmentOverrides;

  // TextPainter cache for data-point labels — keyed by formatted text string
  final Map<String, TextPainter> _labelPainterCache = {};
  BarViewportIndex? _barViewportIndex;
  List<BarGeometry>? _barGeometries;
  Map<int, BarGeometry> _barGeometryByPointIndex = const {};
  Map<(int, int), List<BarGeometry>> _barHitGeometryByCell = const {};
  int _barHitComparisonCount = 0;
  BarLabelLayoutCoordinator? _barLabelLayoutCoordinator;
  ScatterViewportIndex? _scatterViewportIndex;
  List<ScatterPointGeometry>? _scatterGeometries;
  Map<int, ScatterPointGeometry> _scatterGeometryByPointIndex = const {};
  List<Offset>? _scatterUniformCenters;
  Path? _scatterUniformMarkerPath;
  Map<(int, int), List<ScatterPointGeometry>> _scatterHitGeometryByCell =
      const {};
  ScatterClusterLayout? _scatterClusterLayout;
  Map<(int, int), List<ScatterClusterGeometry>>
  _scatterClusterHitGeometryByCell = const {};
  Map<(int, int), List<ScatterPointGeometry>>
  _scatterClusterPointHitGeometryByCell = const {};
  ScatterBinLayout? _scatterBinLayout;
  Map<(int, int), List<ScatterBinGeometry>> _scatterBinHitGeometryByCell =
      const {};
  ScatterDensityLayout? _scatterDensityLayout;
  double _resolvedScatterMaxRadius = 0;
  double? _resolvedScatterMagnitudeMaximum;
  double? _resolvedScatterColorMinimum;
  double? _resolvedScatterColorMaximum;
  double? _resolvedScatterOpacityMinimum;
  double? _resolvedScatterOpacityMaximum;
  int _scatterHitComparisonCount = 0;
  CandlestickViewportIndex? _candlestickViewportIndex;
  List<CandlestickGeometry>? _candlestickGeometries;
  Map<int, CandlestickGeometry> _candlestickGeometryByPointIndex = const {};
  List<_CandlestickPaintBatch>? _candlestickUniformPaintBatches;
  bool? _candlestickHasPointOverrides;
  int _candlestickHitComparisonCount = 0;
  DataPointLabelLayoutCoordinator? _dataPointLabelLayoutCoordinator;
  List<Rect> _visibleScatterLabelBounds = const [];

  static const double _barHitCellSize = 48;
  static const double _scatterHitCellSize = 48;

  /// Number of bar geometries materialized for the current viewport.
  int get visibleBarGeometryCount => _resolveBarGeometries().length;

  /// Original series indices represented by the current virtualized geometry.
  List<int> get visibleBarPointIndices => [
    for (final geometry in _resolveBarGeometries()) geometry.pointIndex,
  ];

  /// Exact rectangle comparisons performed by indexed bar hit testing.
  int get barHitComparisonCount => _barHitComparisonCount;

  /// Number of Scatter marker geometries materialized for the viewport.
  int get visibleScatterGeometryCount => _resolveScatterGeometries().length;

  /// Markers materialized after the active Scatter dense-data strategy.
  int get visibleScatterRenderedMarkerCount {
    final currentSeries = series;
    if (currentSeries is ScatterChartSeries &&
        currentSeries.renderMode == ScatterRenderMode.clusters) {
      return _resolveScatterClusterLayout().renderedMarkerCount;
    }
    if (currentSeries is ScatterChartSeries &&
        _isScatterBinMode(currentSeries.renderMode)) {
      return _resolveScatterBinLayout().renderedMarkerCount;
    }
    if (currentSeries is ScatterChartSeries &&
        currentSeries.renderMode == ScatterRenderMode.density) {
      return _resolveScatterDensityLayout().contours.length;
    }
    return visibleScatterGeometryCount;
  }

  /// Source observations represented by visible screen-space clusters.
  int get visibleScatterClusteredPointCount =>
      _resolveScatterClusterLayout().clusteredPointCount;

  /// Source observations represented by visible rectangular or hexagonal bins.
  int get visibleScatterBinnedPointCount =>
      _resolveScatterBinLayout().binnedPointCount;

  /// Original source indices represented by visible Scatter geometries.
  List<int> get visibleScatterPointIndices => [
    for (final geometry in _resolveScatterGeometries()) geometry.pointIndex,
  ];

  /// Exact marker-distance comparisons performed by the latest Scatter hit.
  int get scatterHitComparisonCount => _scatterHitComparisonCount;

  /// Number of Candlestick geometries materialized for the current viewport.
  int get visibleCandlestickGeometryCount =>
      _resolveCandlestickGeometries().length;

  /// Original source indices represented by visible candle geometry.
  List<int> get visibleCandlestickPointIndices => [
    for (final geometry in _resolveCandlestickGeometries()) geometry.pointIndex,
  ];

  /// Exact geometry comparisons made by the most recent candle hit test.
  int get candlestickHitComparisonCount => _candlestickHitComparisonCount;

  /// Label rectangles accepted by the latest Scatter paint pass.
  List<Rect> get visibleScatterLabelBounds => _visibleScatterLabelBounds;

  /// Shares one occupied-label registry across every bar series paint pass.
  void setBarLabelLayoutCoordinator(BarLabelLayoutCoordinator? coordinator) {
    _barLabelLayoutCoordinator = coordinator;
  }

  /// Shares one occupied-label registry across every point series paint pass.
  void setDataPointLabelLayoutCoordinator(
    DataPointLabelLayoutCoordinator? coordinator,
  ) {
    _dataPointLabelLayoutCoordinator = coordinator;
  }

  List<BarGeometry> _resolveBarGeometries() {
    final cached = _barGeometries;
    if (cached != null) return cached;
    final currentSeries = series;
    if (currentSeries is! BarChartSeries) return const [];
    var viewportIndex = _barViewportIndex;
    if (viewportIndex == null) {
      currentSeries.validateRangeConfiguration();
      viewportIndex = BarViewportIndex(
        currentSeries.points,
        isXOrdered:
            currentSeries.isXOrdered ||
            currentSeries.layoutMode == BarLayoutMode.waterfall,
      );
      _barViewportIndex = viewportIndex;
    }
    final effectiveTransform = _currentTransform.copyWith(
      transposed: currentSeries.orientation == BarOrientation.horizontal,
    );
    final categorySpacing = viewportIndex.categorySpacingPixels(
      effectiveTransform,
    );
    final passiveCategoryFactor = math.max(
      1,
      math.max(
        currentSeries.targetMarkerStyle.lengthFactor,
        currentSeries.errorBarStyle.capLengthFactor,
      ),
    );
    final passiveCategoryExtent = math.max(
      currentSeries.maxWidth *
          viewportIndex.maximumSizeMultiplier *
          passiveCategoryFactor,
      (currentSeries.lollipopStyle?.headRadius ?? 0) * 2,
    );
    final paddingPixels =
        math.max(categorySpacing, passiveCategoryExtent) + currentSeries.barGap;
    final pointIndices = viewportIndex.pointIndicesForViewport(
      minX: effectiveTransform.dataXMin,
      maxX: effectiveTransform.dataXMax,
      paddingData: paddingPixels / effectiveTransform.pixelsPerDataX,
      adjacentPointCount: currentSeries.layoutMode == BarLayoutMode.waterfall
          ? 1
          : 0,
    );
    final geometries = BarGeometryEngine.layout(
      series: currentSeries,
      transform: _currentTransform,
      groupInfo: barGroupInfo,
      pointIndices: pointIndices,
      categorySpacingPixels: categorySpacing,
      validate: false,
    );
    _barGeometries = geometries;
    _indexResolvedBarGeometry(geometries);
    return geometries;
  }

  List<ScatterPointGeometry> _resolveScatterGeometries() {
    final cached = _scatterGeometries;
    if (cached != null) return cached;
    final scatter = series;
    if (scatter is! ScatterChartSeries) return const [];

    var viewportIndex = _scatterViewportIndex;
    if (viewportIndex == null) {
      viewportIndex = ScatterViewportIndex(
        scatter.points,
        isXOrdered: scatter.isXOrdered,
      );
      _scatterViewportIndex = viewportIndex;
    }

    // Scatter exposes an explicit series-level radius, so it takes precedence
    // over the ambient theme. The previous inverse precedence made runtime
    // marker controls update their model and label without changing geometry.
    final seriesMarker = _scatterMarkerStyleAt(scatter, -1);
    final maximumRadius = math.max(
      math.max(seriesMarker.boundingRadius, viewportIndex.maximumPointRadius),
      scatter.sizeEncoding?.maximumRadius ?? 0,
    );
    final jitter = scatter.jitter;
    final jitterSeriesSeed = jitter.isEnabled
        ? _stableScatterJitterSeriesSeed(scatter.id, jitter.seed)
        : 0;
    _resolvedScatterMaxRadius = maximumRadius;
    final pointIndices = viewportIndex.pointIndicesForViewport(
      minX: _currentTransform.dataXMin,
      maxX: _currentTransform.dataXMax,
      minY: _currentTransform.dataYMin,
      maxY: _currentTransform.dataYMax,
      paddingX:
          (maximumRadius + jitter.xAmplitude) * _currentTransform.dataPerPixelX,
      paddingY:
          (maximumRadius + jitter.yAmplitude) * _currentTransform.dataPerPixelY,
    );
    final plotBounds = Rect.fromLTWH(
      0,
      0,
      _currentTransform.plotWidth,
      _currentTransform.plotHeight,
    );
    final geometries = <ScatterPointGeometry>[];
    for (final pointIndex in pointIndices) {
      final point = scatter.points[pointIndex];
      if (!_scatterPointIsRenderable(scatter, pointIndex)) continue;
      final rawCenter = _currentTransform.dataToPlot(point.x, point.y);
      final center = jitter.isEnabled
          ? rawCenter +
                _scatterJitterOffset(jitter, jitterSeriesSeed, pointIndex)
          : rawCenter;
      if (!center.dx.isFinite || !center.dy.isFinite) continue;
      final marker = _scatterMarkerStyleAt(scatter, pointIndex);
      final geometry = ScatterPointGeometry(
        pointIndex: pointIndex,
        point: point,
        center: center,
        radius: marker.boundingRadius,
        width: marker.width,
        height: marker.height,
        shape: marker.shape,
        rotationRadians: marker.rotationRadians,
        strokeWidth: marker.strokeWidth,
      );
      if (geometry.paintBounds.overlaps(plotBounds) ||
          plotBounds.contains(geometry.center)) {
        geometries.add(geometry);
      }
    }

    final byCell = <(int, int), List<ScatterPointGeometry>>{};
    for (final geometry in geometries) {
      final clipped = geometry.hitBounds(4).intersect(plotBounds);
      if (clipped.isEmpty) continue;
      final minCellX = (clipped.left / _scatterHitCellSize).floor();
      final maxCellX = (clipped.right / _scatterHitCellSize).floor();
      final minCellY = (clipped.top / _scatterHitCellSize).floor();
      final maxCellY = (clipped.bottom / _scatterHitCellSize).floor();
      for (var cellX = minCellX; cellX <= maxCellX; cellX++) {
        for (var cellY = minCellY; cellY <= maxCellY; cellY++) {
          byCell.putIfAbsent((cellX, cellY), () => []).add(geometry);
        }
      }
    }
    _scatterHitGeometryByCell = byCell;
    _scatterGeometries = geometries;
    _scatterGeometryByPointIndex = {
      for (final geometry in geometries) geometry.pointIndex: geometry,
    };
    _scatterUniformCenters = [
      for (final geometry in geometries) geometry.center,
    ];
    return geometries;
  }

  List<CandlestickGeometry> _resolveCandlestickGeometries() {
    final cached = _candlestickGeometries;
    if (cached != null) return cached;
    final candleSeries = series;
    if (candleSeries is! CandlestickChartSeries) return const [];

    var viewportIndex = _candlestickViewportIndex;
    if (viewportIndex == null) {
      viewportIndex = CandlestickViewportIndex(candleSeries.candles);
      _candlestickViewportIndex = viewportIndex;
      _candlestickHasPointOverrides = candleSeries.candles.any(
        (point) => point.candlestickStyle != null,
      );
    }
    var geometries = CandlestickGeometryEngine.resolve(
      index: viewportIndex,
      transform: _currentTransform,
      style: candleSeries.candlestickStyle,
    );
    if (_effectiveRevealProgress < 1) {
      geometries = geometries
          .where((geometry) => geometry.centerX <= _revealEdge)
          .toList(growable: false);
    }
    _candlestickGeometries = geometries;
    _candlestickGeometryByPointIndex = {
      for (final geometry in geometries) geometry.pointIndex: geometry,
    };
    return geometries;
  }

  void _clearResolvedScatterGeometry() {
    _scatterGeometries = null;
    _scatterGeometryByPointIndex = const {};
    _scatterUniformCenters = null;
    _scatterUniformMarkerPath = null;
    _scatterHitGeometryByCell = const {};
    _scatterClusterLayout = null;
    _scatterClusterHitGeometryByCell = const {};
    _scatterClusterPointHitGeometryByCell = const {};
    _scatterBinLayout = null;
    _scatterBinHitGeometryByCell = const {};
    _scatterDensityLayout = null;
    _resolvedScatterMaxRadius = 0;
    _resolvedScatterMagnitudeMaximum = null;
    _resolvedScatterColorMinimum = null;
    _resolvedScatterColorMaximum = null;
    _resolvedScatterOpacityMinimum = null;
    _resolvedScatterOpacityMaximum = null;
    _scatterHitComparisonCount = 0;
  }

  void _clearResolvedCandlestickGeometry() {
    _candlestickGeometries = null;
    _candlestickGeometryByPointIndex = const {};
    _candlestickUniformPaintBatches = null;
    _candlestickHitComparisonCount = 0;
  }

  CandlestickGeometry? candlestickGeometryForPoint(int pointIndex) {
    if (series is! CandlestickChartSeries || pointIndex < 0) return null;
    _resolveCandlestickGeometries();
    return _candlestickGeometryByPointIndex[pointIndex];
  }

  CandlestickGeometry? candlestickGeometryAt(
    Offset position, {
    double hitSlop = 4,
  }) {
    final geometries = _resolveCandlestickGeometries();
    if (geometries.isEmpty) return null;
    var low = 0;
    var high = geometries.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (geometries[middle].centerX < position.dx) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    final start = math.max(0, low - 2);
    final end = math.min(geometries.length, low + 3);
    _candlestickHitComparisonCount = 0;

    for (var index = start; index < end; index++) {
      _candlestickHitComparisonCount++;
      final geometry = geometries[index];
      if (geometry.bodyRRect.contains(position)) return geometry;
    }
    for (var index = start; index < end; index++) {
      _candlestickHitComparisonCount++;
      final geometry = geometries[index];
      if (geometry.hitBounds.inflate(hitSlop).contains(position)) {
        return geometry;
      }
    }
    return null;
  }

  ScatterClusterLayout _resolveScatterClusterLayout() {
    final cached = _scatterClusterLayout;
    if (cached != null) return cached;
    final currentSeries = series;
    if (currentSeries is! ScatterChartSeries ||
        currentSeries.renderMode != ScatterRenderMode.clusters) {
      return const ScatterClusterLayout(
        clusters: [],
        unclusteredPoints: [],
        sourcePointCount: 0,
      );
    }
    final layout = ScatterClusterEngine.layout(
      geometries: _resolveScatterGeometries(),
      config: currentSeries.clusterConfig,
    );
    _scatterClusterHitGeometryByCell = _indexScatterClusters(layout.clusters);
    _scatterClusterPointHitGeometryByCell = _indexScatterPoints(
      layout.unclusteredPoints,
    );
    _scatterClusterLayout = layout;
    return layout;
  }

  ScatterBinLayout _resolveScatterBinLayout() {
    final cached = _scatterBinLayout;
    if (cached != null) return cached;
    final currentSeries = series;
    if (currentSeries is! ScatterChartSeries ||
        !_isScatterBinMode(currentSeries.renderMode)) {
      return const ScatterBinLayout(
        bins: [],
        sourcePointCount: 0,
        filteredPointCount: 0,
      );
    }
    final layout = ScatterBinEngine.layout(
      geometries: _resolveScatterGeometries(),
      mode: currentSeries.renderMode,
      config: currentSeries.binConfig,
    );
    _scatterBinHitGeometryByCell = _indexScatterBins(layout.bins);
    _scatterBinLayout = layout;
    return layout;
  }

  ScatterDensityLayout _resolveScatterDensityLayout() {
    final cached = _scatterDensityLayout;
    if (cached != null) return cached;
    final currentSeries = series;
    if (currentSeries is! ScatterChartSeries ||
        currentSeries.renderMode != ScatterRenderMode.density) {
      return ScatterDensityEngine.layout(
        geometries: const [],
        plotSize: Size(
          _currentTransform.plotWidth,
          _currentTransform.plotHeight,
        ),
        config: const ScatterDensityConfig(),
      );
    }
    final layout = ScatterDensityEngine.layout(
      geometries: _resolveScatterGeometries(),
      plotSize: Size(_currentTransform.plotWidth, _currentTransform.plotHeight),
      config: currentSeries.densityConfig,
    );
    _scatterDensityLayout = layout;
    return layout;
  }

  Map<(int, int), List<ScatterClusterGeometry>> _indexScatterClusters(
    List<ScatterClusterGeometry> geometries,
  ) {
    final result = <(int, int), List<ScatterClusterGeometry>>{};
    for (final geometry in geometries) {
      final bounds = geometry.hitBounds(4);
      final minCellX = (bounds.left / _scatterHitCellSize).floor();
      final maxCellX = (bounds.right / _scatterHitCellSize).floor();
      final minCellY = (bounds.top / _scatterHitCellSize).floor();
      final maxCellY = (bounds.bottom / _scatterHitCellSize).floor();
      for (var cellX = minCellX; cellX <= maxCellX; cellX++) {
        for (var cellY = minCellY; cellY <= maxCellY; cellY++) {
          result.putIfAbsent((cellX, cellY), () => []).add(geometry);
        }
      }
    }
    return result;
  }

  Map<(int, int), List<ScatterPointGeometry>> _indexScatterPoints(
    List<ScatterPointGeometry> geometries,
  ) {
    final result = <(int, int), List<ScatterPointGeometry>>{};
    for (final geometry in geometries) {
      final bounds = geometry.hitBounds(4);
      final minCellX = (bounds.left / _scatterHitCellSize).floor();
      final maxCellX = (bounds.right / _scatterHitCellSize).floor();
      final minCellY = (bounds.top / _scatterHitCellSize).floor();
      final maxCellY = (bounds.bottom / _scatterHitCellSize).floor();
      for (var cellX = minCellX; cellX <= maxCellX; cellX++) {
        for (var cellY = minCellY; cellY <= maxCellY; cellY++) {
          result.putIfAbsent((cellX, cellY), () => []).add(geometry);
        }
      }
    }
    return result;
  }

  Map<(int, int), List<ScatterBinGeometry>> _indexScatterBins(
    List<ScatterBinGeometry> geometries,
  ) {
    final result = <(int, int), List<ScatterBinGeometry>>{};
    for (final geometry in geometries) {
      final bounds = geometry.paintBounds.inflate(4);
      final minCellX = (bounds.left / _scatterHitCellSize).floor();
      final maxCellX = (bounds.right / _scatterHitCellSize).floor();
      final minCellY = (bounds.top / _scatterHitCellSize).floor();
      final maxCellY = (bounds.bottom / _scatterHitCellSize).floor();
      for (var cellX = minCellX; cellX <= maxCellX; cellX++) {
        for (var cellY = minCellY; cellY <= maxCellY; cellY++) {
          result.putIfAbsent((cellX, cellY), () => []).add(geometry);
        }
      }
    }
    return result;
  }

  bool _isScatterBinMode(ScatterRenderMode mode) =>
      mode == ScatterRenderMode.rectangularBins ||
      mode == ScatterRenderMode.hexbin;

  ScatterPointGeometry? scatterGeometryForPoint(int pointIndex) {
    _resolveScatterGeometries();
    return _scatterGeometryByPointIndex[pointIndex];
  }

  void _clearResolvedBarGeometry() {
    _barGeometries = null;
    _barGeometryByPointIndex = const {};
    _barHitGeometryByCell = const {};
    _barHitComparisonCount = 0;
  }

  void _indexResolvedBarGeometry(List<BarGeometry> geometries) {
    _barGeometryByPointIndex = {
      for (final geometry in geometries) geometry.pointIndex: geometry,
    };
    final cells = <(int, int), List<BarGeometry>>{};
    final plotBounds = Rect.fromLTWH(
      0,
      0,
      _currentTransform.plotWidth,
      _currentTransform.plotHeight,
    );
    for (final geometry in geometries) {
      final bounds = geometry.hitBounds.intersect(plotBounds);
      if (bounds.isEmpty) continue;
      final left = (bounds.left / _barHitCellSize).floor();
      final right = (bounds.right / _barHitCellSize).floor();
      final top = (bounds.top / _barHitCellSize).floor();
      final bottom = (bounds.bottom / _barHitCellSize).floor();
      for (var x = left; x <= right; x++) {
        for (var y = top; y <= bottom; y++) {
          (cells[(x, y)] ??= []).add(geometry);
        }
      }
    }
    _barHitGeometryByCell = cells;
    _barHitComparisonCount = 0;
  }

  /// Returns the canonical rendered geometry for a bar point, when available.
  ///
  /// Crosshair markers and other interaction overlays use this instead of
  /// transforming the raw Y value, which would be incorrect for stacks.
  BarGeometry? barGeometryForPoint(int pointIndex) {
    if (series is! BarChartSeries || pointIndex < 0) return null;
    _resolveBarGeometries();
    return _barGeometryByPointIndex[pointIndex];
  }

  /// Returns the topmost bar geometry whose interaction bounds contain [point].
  BarGeometry? barGeometryAt(Offset point) {
    if (series is! BarChartSeries) return null;
    _resolveBarGeometries();
    final cell = (
      (point.dx / _barHitCellSize).floor(),
      (point.dy / _barHitCellSize).floor(),
    );
    for (final geometry
        in (_barHitGeometryByCell[cell] ?? const <BarGeometry>[]).reversed) {
      _barHitComparisonCount++;
      if (geometry.hitBounds.contains(point)) return geometry;
    }
    return null;
  }

  /// Compute bounding box that encompasses all data points (with stroke padding).
  ///
  /// Uses _currentTransform for coordinate conversion so bounds are correct
  /// in perSeries normalization mode where each series has different Y bounds.
  void _computeBounds() {
    if (series.isEmpty) {
      _bounds = Rect.zero;
      return;
    }

    if (series is BarChartSeries || series is CandlestickChartSeries) {
      // Bar points are virtualized by category viewport. Keep the series
      // eligible for plot-level hit routing without materializing every bar
      // merely to compute one aggregate element rectangle.
      _bounds = Rect.fromLTWH(
        0,
        0,
        _currentTransform.plotWidth,
        _currentTransform.plotHeight,
      );
      return;
    }

    if (series case final ScatterChartSeries scatter) {
      var viewportIndex = _scatterViewportIndex;
      if (viewportIndex == null) {
        viewportIndex = ScatterViewportIndex(
          scatter.points,
          isXOrdered: scatter.isXOrdered,
        );
        _scatterViewportIndex = viewportIndex;
      }
      if (viewportIndex.pointCount == 0) {
        _bounds = Rect.zero;
        return;
      }
      final padding =
          math.max(
            math.max(
              _scatterMarkerStyleAt(scatter, -1).boundingRadius,
              viewportIndex.maximumPointRadius,
            ),
            math.max(
              scatter.sizeEncoding?.maximumRadius ?? 0.0,
              scatter.renderMode == ScatterRenderMode.clusters
                  ? scatter.clusterConfig.maximumRadius
                  : _isScatterBinMode(scatter.renderMode)
                  ? scatter.binConfig.cellSize / 2
                  : 0.0,
            ),
          ) +
          math.max(scatter.jitter.xAmplitude, scatter.jitter.yAmplitude);
      // Scatter manages exact point bounds through its viewport and hit index.
      // Keep the aggregate element eligible across the plot without rescanning
      // every source point whenever the viewport transform changes.
      _bounds = Rect.fromLTRB(
        -padding,
        -padding,
        _currentTransform.plotWidth + padding,
        _currentTransform.plotHeight + padding,
      );
      return;
    }

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;
    var validPointCount = 0;

    for (var index = 0; index < series.points.length; index++) {
      final point = series.points[index];
      if (!point.isValid) continue;
      // Use _currentTransform for perSeries normalization support
      final plotPos = _currentTransform.dataToPlot(point.x, point.y);
      if (!plotPos.dx.isFinite || !plotPos.dy.isFinite) continue;
      validPointCount++;
      minX = plotPos.dx < minX ? plotPos.dx : minX;
      maxX = plotPos.dx > maxX ? plotPos.dx : maxX;
      minY = plotPos.dy < minY ? plotPos.dy : minY;
      maxY = plotPos.dy > maxY ? plotPos.dy : maxY;
    }

    if (validPointCount == 0) {
      _bounds = Rect.zero;
      return;
    }

    final padding = strokeWidth / 2;
    _bounds = Rect.fromLTRB(
      minX - padding,
      minY - padding,
      maxX + padding,
      maxY + padding,
    );
  }

  @override
  String get id => series.id;

  @override
  Rect get bounds {
    if (_effectiveRevealProgress >= 1) return _bounds;
    return _bounds.intersect(
      Rect.fromLTRB(0, -double.maxFinite, _revealEdge, double.maxFinite),
    );
  }

  @override
  ChartElementType get elementType => ChartElementType.series;

  @override
  int get priority => ElementPriority.forType(elementType);

  @override
  // Series render in data layer
  int get renderOrder => RenderOrder.series;

  @override
  bool get isSelectable => true;

  @override
  bool get isDraggable => false;

  @override
  bool hitTest(Offset position) {
    if (series.isEmpty) return false;
    if (_supportsReveal && position.dx > _revealEdge) return false;

    if (series is BarChartSeries) {
      return barGeometryAt(position) != null;
    }

    if (series is CandlestickChartSeries) {
      return candlestickGeometryAt(position) != null;
    }

    if (series is ScatterChartSeries) {
      return _scatterDataHitAt(position, maxDistance: 0, markerHitSlop: 4) !=
          null;
    }

    // For line series: check if position is near any line segment
    // For scatter: check if near any point
    // For now: simple line segment hit testing
    final threshold = strokeWidth * 2; // Hit detection tolerance

    for (int i = 0; i < series.points.length - 1; i++) {
      final p1 = series.points[i];
      final p2 = series.points[i + 1];

      // CRITICAL: Use _currentTransform, not transform!
      // In perSeries normalization mode, _currentTransform has the correct
      // per-series Y bounds (set via updateTransform before hit testing).
      // Using the initial 'transform' would use global Y bounds, causing
      // hit detection to fail when series have different Y scales.
      final plotP1 = _currentTransform.dataToPlot(p1.x, p1.y);
      final plotP2 = _currentTransform.dataToPlot(p2.x, p2.y);

      final distance = _distanceToLineSegment(position, plotP1, plotP2);
      if (distance <= threshold) {
        return true;
      }
    }

    return false;
  }

  @override
  ChartDataHit? dataHitAt(Offset position, {double maxDistance = 20}) {
    final source = series;
    if (source is LineChartSeries && !source.showDataPointMarkers) return null;
    if (source is AreaChartSeries && !source.showDataPointMarkers) return null;
    if (source is BarChartSeries) {
      final geometry = barGeometryAt(position);
      return geometry == null ? null : _barDataHit(geometry);
    }
    if (source is CandlestickChartSeries) {
      final geometry = candlestickGeometryAt(
        position,
        hitSlop: math.min(12, math.max(4, maxDistance)),
      );
      return geometry == null ? null : _candlestickDataHit(geometry);
    }
    if (source is ScatterChartSeries) {
      return _scatterDataHitAt(position, maxDistance: maxDistance);
    }

    ChartDataHit? nearest;
    var nearestDistance = maxDistance;
    for (
      var renderIndex = 0;
      renderIndex < source.points.length;
      renderIndex++
    ) {
      final hit = _dataHitForRenderPointIndex(renderIndex);
      if (hit == null) continue;
      final distance = (position - hit.plotPosition).distance;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = hit;
      }
    }
    return nearest;
  }

  ChartDataHit? _scatterDataHitAt(
    Offset position, {
    required double maxDistance,
    double markerHitSlop = 0,
  }) {
    final currentSeries = series as ScatterChartSeries;
    if (currentSeries.renderMode == ScatterRenderMode.clusters) {
      return _scatterClusterDataHitAt(
        position,
        maxDistance: maxDistance,
        markerHitSlop: markerHitSlop,
      );
    }
    if (_isScatterBinMode(currentSeries.renderMode)) {
      return _scatterBinDataHitAt(
        position,
        maxDistance: maxDistance,
        markerHitSlop: markerHitSlop,
      );
    }
    if (currentSeries.renderMode == ScatterRenderMode.density) {
      return _scatterDensityDataHitAt(position);
    }
    final geometries = _resolveScatterGeometries();
    final searchRadius = maxDistance.isFinite
        ? math.max(maxDistance, _resolvedScatterMaxRadius + markerHitSlop)
        : double.infinity;
    final candidates = _scatterCandidatesNear(
      position,
      geometries,
      searchRadius,
    );
    ChartDataHit? nearest;
    var nearestDistance = double.infinity;
    _scatterHitComparisonCount = 0;
    for (final geometry in candidates) {
      _scatterHitComparisonCount++;
      final hit = _dataHitForRenderPointIndex(geometry.pointIndex);
      if (hit == null) continue;
      final distance = (position - hit.plotPosition).distance;
      final markerContains = scatterMarkerContains(
        position: position,
        center: geometry.center,
        radius: geometry.radius,
        shape: geometry.shape,
        hitSlop: markerHitSlop,
        width: geometry.width,
        height: geometry.height,
        rotationRadians: geometry.rotationRadians,
      );
      if ((distance <= maxDistance || markerContains) &&
          (distance < nearestDistance ||
              (distance == nearestDistance &&
                  (nearest == null ||
                      geometry.pointIndex < nearest.pointIndex)))) {
        nearestDistance = distance;
        nearest = hit;
      }
    }
    return nearest;
  }

  ChartDataHit? _scatterClusterDataHitAt(
    Offset position, {
    required double maxDistance,
    double markerHitSlop = 0,
  }) {
    final layout = _resolveScatterClusterLayout();
    final searchRadius = maxDistance.isFinite
        ? math.max(
            maxDistance,
            (series as ScatterChartSeries).clusterConfig.maximumRadius +
                markerHitSlop,
          )
        : double.infinity;
    final minCellX = searchRadius.isFinite
        ? ((position.dx - searchRadius) / _scatterHitCellSize).floor()
        : -0x3fffffff;
    final maxCellX = searchRadius.isFinite
        ? ((position.dx + searchRadius) / _scatterHitCellSize).floor()
        : 0x3fffffff;
    final minCellY = searchRadius.isFinite
        ? ((position.dy - searchRadius) / _scatterHitCellSize).floor()
        : -0x3fffffff;
    final maxCellY = searchRadius.isFinite
        ? ((position.dy + searchRadius) / _scatterHitCellSize).floor()
        : 0x3fffffff;
    final clusters = <int, ScatterClusterGeometry>{};
    final points = <int, ScatterPointGeometry>{};
    if (searchRadius.isFinite) {
      for (var cellX = minCellX; cellX <= maxCellX; cellX++) {
        for (var cellY = minCellY; cellY <= maxCellY; cellY++) {
          for (final cluster
              in _scatterClusterHitGeometryByCell[(cellX, cellY)] ??
                  const <ScatterClusterGeometry>[]) {
            clusters[cluster.representativePointIndex] = cluster;
          }
          for (final point
              in _scatterClusterPointHitGeometryByCell[(cellX, cellY)] ??
                  const <ScatterPointGeometry>[]) {
            points[point.pointIndex] = point;
          }
        }
      }
    } else {
      for (final cluster in layout.clusters) {
        clusters[cluster.representativePointIndex] = cluster;
      }
      for (final point in layout.unclusteredPoints) {
        points[point.pointIndex] = point;
      }
    }

    ChartDataHit? nearest;
    var nearestDistance = double.infinity;
    _scatterHitComparisonCount = 0;
    for (var index = 0; index < layout.clusters.length; index++) {
      final cluster = layout.clusters[index];
      if (!clusters.containsKey(cluster.representativePointIndex)) continue;
      _scatterHitComparisonCount++;
      final distance = (position - cluster.center).distance;
      if ((distance <= maxDistance ||
              distance <= cluster.radius + markerHitSlop) &&
          distance < nearestDistance) {
        nearestDistance = distance;
        nearest = _scatterDataHitForCluster(cluster, index, layout);
      }
    }
    final orderedPointIndices = points.keys.toList()..sort();
    for (final pointIndex in orderedPointIndices) {
      final geometry = points[pointIndex]!;
      _scatterHitComparisonCount++;
      final distance = (position - geometry.center).distance;
      final contains = scatterMarkerContains(
        position: position,
        center: geometry.center,
        radius: geometry.radius,
        shape: geometry.shape,
        hitSlop: markerHitSlop,
        width: geometry.width,
        height: geometry.height,
        rotationRadians: geometry.rotationRadians,
      );
      if ((distance <= maxDistance || contains) && distance < nearestDistance) {
        nearestDistance = distance;
        nearest = _dataHitForRenderPointIndex(pointIndex);
      }
    }
    return nearest;
  }

  ChartDataHit _scatterDataHitForCluster(
    ScatterClusterGeometry cluster,
    int clusterIndex,
    ScatterClusterLayout layout,
  ) {
    final currentSeries = series as ScatterChartSeries;
    final representative =
        currentSeries.points[cluster.representativePointIndex];
    final unit = currentSeries.unit == null || currentSeries.unit!.isEmpty
        ? ''
        : ' ${currentSeries.unit}';
    return ChartDataHit(
      seriesId: currentSeries.id,
      pointIndex: cluster.representativePointIndex,
      sourcePointIndices: cluster.sourcePointIndices,
      plotPosition: cluster.center,
      semanticBounds: cluster.hitBounds(4),
      point: representative,
      category: '${cluster.pointCount} observations',
      formattedValue: '${cluster.dataCentroid.dy.toStringAsFixed(2)}$unit',
      formattedXValue: cluster.dataCentroid.dx.toStringAsFixed(2),
      formattedXRange: _formatScatterClusterRange(cluster.dataXRange),
      formattedYRange: _formatScatterClusterRange(
        cluster.dataYRange,
        suffix: unit,
      ),
      markerColor: currentSeries.color ?? themeColor,
      ordinal: clusterIndex + 1,
      count: layout.renderedMarkerCount,
      isSelected: cluster.sourcePointIndices.every(
        selectedPointIndices.contains,
      ),
      isFocused: cluster.sourcePointIndices.any(focusedPointIndices.contains),
    );
  }

  String _formatScatterClusterRange(
    ({double minimum, double maximum}) range, {
    String suffix = '',
  }) {
    final minimum = range.minimum.toStringAsFixed(2);
    final maximum = range.maximum.toStringAsFixed(2);
    return range.minimum == range.maximum
        ? '$minimum$suffix'
        : '$minimum–$maximum$suffix';
  }

  ChartDataHit? _scatterBinDataHitAt(
    Offset position, {
    required double maxDistance,
    double markerHitSlop = 0,
  }) {
    final layout = _resolveScatterBinLayout();
    final currentSeries = series as ScatterChartSeries;
    final searchRadius = maxDistance.isFinite
        ? math.max(
            maxDistance,
            currentSeries.binConfig.cellSize / 2 + markerHitSlop,
          )
        : double.infinity;
    final candidates = <int, ScatterBinGeometry>{};
    if (searchRadius.isFinite) {
      final minCellX = ((position.dx - searchRadius) / _scatterHitCellSize)
          .floor();
      final maxCellX = ((position.dx + searchRadius) / _scatterHitCellSize)
          .floor();
      final minCellY = ((position.dy - searchRadius) / _scatterHitCellSize)
          .floor();
      final maxCellY = ((position.dy + searchRadius) / _scatterHitCellSize)
          .floor();
      for (var cellX = minCellX; cellX <= maxCellX; cellX++) {
        for (var cellY = minCellY; cellY <= maxCellY; cellY++) {
          for (final bin
              in _scatterBinHitGeometryByCell[(cellX, cellY)] ??
                  const <ScatterBinGeometry>[]) {
            candidates[bin.representativePointIndex] = bin;
          }
        }
      }
    } else {
      for (final bin in layout.bins) {
        candidates[bin.representativePointIndex] = bin;
      }
    }

    ChartDataHit? nearest;
    var nearestDistance = double.infinity;
    _scatterHitComparisonCount = 0;
    for (var index = 0; index < layout.bins.length; index++) {
      final bin = layout.bins[index];
      if (!candidates.containsKey(bin.representativePointIndex)) continue;
      _scatterHitComparisonCount++;
      final distance = (position - bin.center).distance;
      if ((bin.contains(position, hitSlop: markerHitSlop) ||
              distance <= maxDistance) &&
          distance < nearestDistance) {
        nearestDistance = distance;
        nearest = _scatterDataHitForBin(bin, index, layout);
      }
    }
    return nearest;
  }

  ChartDataHit _scatterDataHitForBin(
    ScatterBinGeometry bin,
    int binIndex,
    ScatterBinLayout layout,
  ) {
    final currentSeries = series as ScatterChartSeries;
    final config = currentSeries.binConfig;
    final representative = currentSeries.points[bin.representativePointIndex];
    final unit = currentSeries.unit == null || currentSeries.unit!.isEmpty
        ? ''
        : ' ${currentSeries.unit}';
    final shapeLabel = currentSeries.renderMode == ScatterRenderMode.hexbin
        ? 'hexagonal bin'
        : 'rectangular bin';
    final observationLabel = bin.pointCount == 1
        ? '1 observation'
        : '${bin.pointCount} observations';
    return ChartDataHit(
      seriesId: currentSeries.id,
      pointIndex: bin.representativePointIndex,
      sourcePointIndices: bin.sourcePointIndices,
      plotPosition: bin.center,
      semanticBounds: bin.paintBounds.inflate(4),
      point: representative,
      category: '$observationLabel · $shapeLabel',
      formattedValue: '${bin.dataCentroid.dy.toStringAsFixed(2)}$unit',
      formattedXValue: bin.dataCentroid.dx.toStringAsFixed(2),
      markerColor: currentSeries.color ?? themeColor,
      aggregateValue: bin.aggregateValue,
      formattedAggregateValue: _formatScatterBinAggregate(
        bin.aggregateValue,
        config,
        currentSeries,
      ),
      aggregateLabel: _scatterBinAggregateLabel(config, currentSeries),
      aggregateSampleCount: bin.aggregateSampleCount,
      ordinal: binIndex + 1,
      count: layout.renderedMarkerCount,
      isSelected: bin.sourcePointIndices.every(selectedPointIndices.contains),
      isFocused: bin.sourcePointIndices.any(focusedPointIndices.contains),
    );
  }

  ChartDataHit? _scatterDensityDataHitAt(Offset position) {
    final currentSeries = series as ScatterChartSeries;
    final config = currentSeries.densityConfig;
    final layout = _resolveScatterDensityLayout();
    final relativeDensity = layout.relativeDensityAt(position);
    if (relativeDensity < config.minimumDensity) return null;

    final sourceRadius = config.bandwidth * 2;
    final nearby =
        _scatterCandidatesNear(
            position,
            _resolveScatterGeometries(),
            sourceRadius,
          ).where((geometry) {
            return (geometry.center - position).distance <= sourceRadius;
          }).toList()
          ..sort((left, right) => left.pointIndex.compareTo(right.pointIndex));
    if (nearby.isEmpty) return null;

    var xTotal = 0.0;
    var yTotal = 0.0;
    for (final geometry in nearby) {
      xTotal += geometry.point.x;
      yTotal += geometry.point.y;
    }
    final sourceIndices = [for (final geometry in nearby) geometry.pointIndex];
    final representative = nearby.first;
    final unit = currentSeries.unit == null || currentSeries.unit!.isEmpty
        ? ''
        : ' ${currentSeries.unit}';
    final ordinal = math.max(
      1,
      layout.contours.indexWhere(
            (contour) => relativeDensity <= contour.relativeDensity,
          ) +
          1,
    );
    return ChartDataHit(
      seriesId: currentSeries.id,
      pointIndex: representative.pointIndex,
      sourcePointIndices: sourceIndices,
      plotPosition: position,
      semanticBounds: layout.sampleBoundsAt(position),
      point: representative.point,
      category: nearby.length == 1
          ? '1 nearby observation · density region'
          : '${nearby.length} nearby observations · density region',
      formattedValue: '${(yTotal / nearby.length).toStringAsFixed(2)}$unit',
      formattedXValue: (xTotal / nearby.length).toStringAsFixed(2),
      markerColor: currentSeries.color ?? themeColor,
      aggregateValue: relativeDensity,
      formattedAggregateValue: '${(relativeDensity * 100).toStringAsFixed(1)}%',
      aggregateLabel: 'Relative density',
      aggregateSampleCount: nearby.length,
      ordinal: math.min(ordinal, math.max(1, layout.contours.length)),
      count: math.max(1, layout.contours.length),
      isSelected: sourceIndices.every(selectedPointIndices.contains),
      isFocused: sourceIndices.any(focusedPointIndices.contains),
    );
  }

  List<ScatterPointGeometry> _scatterCandidatesNear(
    Offset position,
    List<ScatterPointGeometry> geometries,
    double searchRadius,
  ) {
    if (!searchRadius.isFinite) return geometries;
    final minCellX = ((position.dx - searchRadius) / _scatterHitCellSize)
        .floor();
    final maxCellX = ((position.dx + searchRadius) / _scatterHitCellSize)
        .floor();
    final minCellY = ((position.dy - searchRadius) / _scatterHitCellSize)
        .floor();
    final maxCellY = ((position.dy + searchRadius) / _scatterHitCellSize)
        .floor();
    final seen = <int>{};
    final result = <ScatterPointGeometry>[];
    for (var cellX = minCellX; cellX <= maxCellX; cellX++) {
      for (var cellY = minCellY; cellY <= maxCellY; cellY++) {
        for (final geometry
            in _scatterHitGeometryByCell[(cellX, cellY)] ??
                const <ScatterPointGeometry>[]) {
          if (seen.add(geometry.pointIndex)) result.add(geometry);
        }
      }
    }
    return result;
  }

  _ResolvedScatterMarkerStyle _scatterMarkerStyleAt(
    ScatterChartSeries scatter,
    int pointIndex,
  ) {
    final pointStyle = pointIndex >= 0
        ? scatter.points[pointIndex].pointStyle
        : null;
    final pointMarker = pointStyle?.scatterMarkerStyle;
    final seriesMarker = scatter.markerStyle;
    final bubbleRadius = pointIndex >= 0
        ? _scatterBubbleRadius(scatter, pointIndex)
        : null;
    final explicitPointRadius = pointStyle?.size;
    final legacyRadius =
        explicitPointRadius ?? bubbleRadius ?? scatter.markerRadius;
    final safeRadius = legacyRadius.isFinite && legacyRadius >= 0
        ? legacyRadius
        : 0.0;
    final fallbackDiameter = safeRadius * 2;
    final usesDataOrPointSize =
        explicitPointRadius != null || bubbleRadius != null;
    final width = _safeNonNegative(
      pointMarker?.width ??
          (usesDataOrPointSize ? fallbackDiameter : seriesMarker?.width) ??
          fallbackDiameter,
    );
    final height = _safeNonNegative(
      pointMarker?.height ??
          (usesDataOrPointSize ? fallbackDiameter : seriesMarker?.height) ??
          fallbackDiameter,
    );
    final strokeWidth = _safeNonNegative(
      pointMarker?.strokeWidth ?? seriesMarker?.strokeWidth ?? 0,
    );
    final opacity = _safeUnit(
      pointMarker?.opacity ??
          (pointIndex >= 0
              ? _scatterEncodedOpacity(scatter, pointIndex)
              : null) ??
          seriesMarker?.opacity ??
          1,
    );
    final rotationDegrees =
        pointMarker?.rotationDegrees ?? seriesMarker?.rotationDegrees ?? 0;
    final rotationRadians = rotationDegrees.isFinite
        ? rotationDegrees * math.pi / 180
        : 0.0;
    return _ResolvedScatterMarkerStyle(
      shape:
          pointStyle?.scatterMarkerShape ??
          (pointIndex >= 0
              ? _scatterCategoryStyle(scatter, pointIndex)?.shape
              : null) ??
          scatter.markerShape,
      fillColor:
          pointMarker?.fillColor ??
          pointStyle?.color ??
          (pointIndex >= 0
              ? _scatterCategoryStyle(scatter, pointIndex)?.color
              : null) ??
          (pointIndex >= 0
              ? _scatterEncodedColor(scatter, pointIndex)
              : null) ??
          seriesMarker?.fillColor,
      strokeColor: pointMarker?.strokeColor ?? seriesMarker?.strokeColor,
      strokeWidth: strokeWidth,
      opacity: opacity,
      width: width,
      height: height,
      rotationRadians: rotationRadians,
    );
  }

  ScatterCategoryStyle? _scatterCategoryStyle(
    ScatterChartSeries scatter,
    int pointIndex,
  ) => scatter.categoryEncoding?.styleFor(
    scatter.points[pointIndex].categoryValue,
  );

  int _stableScatterJitterSeriesSeed(String seriesId, int seed) {
    var hash = (0x811C9DC5 ^ seed) & 0xFFFFFFFF;
    for (final codeUnit in seriesId.codeUnits) {
      // Multiplication by 31 stays exactly representable for this masked
      // 32-bit value on both the Dart VM and JavaScript targets.
      hash = (hash * 31 + codeUnit) & 0xFFFFFFFF;
    }
    return hash;
  }

  Offset _scatterJitterOffset(
    ScatterJitterConfig jitter,
    int seriesSeed,
    int pointIndex,
  ) => Offset(
    jitter.xAmplitude *
        _stableScatterJitterUnit(seriesSeed, pointIndex, 0xA511E9B3),
    jitter.yAmplitude *
        _stableScatterJitterUnit(seriesSeed, pointIndex, 0x63D83595),
  );

  double _stableScatterJitterUnit(
    int seriesSeed,
    int pointIndex,
    int axisSalt,
  ) {
    // Feed every source-index and axis-salt byte through a small, portable
    // 32-bit hash before the xorshift avalanche. XORing the raw point index
    // directly leaves adjacent indices highly correlated, which made duplicate
    // observations technically distinct but visually almost coincident.
    // Multiplication by 31 remains exactly representable on JavaScript while
    // the 32-bit mask keeps VM and web output identical.
    var value = seriesSeed;
    for (var shift = 0; shift < 32; shift += 8) {
      value = (value * 31 + ((pointIndex >>> shift) & 0xFF)) & 0xFFFFFFFF;
      value = (value * 31 + ((axisSalt >>> shift) & 0xFF)) & 0xFFFFFFFF;
    }
    value ^= (value << 13) & 0xFFFFFFFF;
    value ^= value >>> 17;
    value ^= (value << 5) & 0xFFFFFFFF;
    final normalized = (value & 0xFFFFFFFF) / 0xFFFFFFFF;
    return normalized * 2 - 1;
  }

  Color? _scatterEncodedColor(ScatterChartSeries scatter, int pointIndex) {
    final encoding = scatter.colorEncoding;
    if (encoding == null) return null;
    if (_resolvedScatterColorMinimum == null ||
        _resolvedScatterColorMaximum == null) {
      var minimum = encoding.minimumValue ?? double.infinity;
      var maximum = encoding.maximumValue ?? double.negativeInfinity;
      if (encoding.minimumValue == null || encoding.maximumValue == null) {
        for (final point in scatter.points) {
          final value = point.colorValue;
          if (value == null || !value.isFinite) continue;
          if (encoding.minimumValue == null && value < minimum) {
            minimum = value;
          }
          if (encoding.maximumValue == null && value > maximum) {
            maximum = value;
          }
        }
      }
      if (!minimum.isFinite && maximum.isFinite) minimum = maximum;
      if (!maximum.isFinite && minimum.isFinite) maximum = minimum;
      if (!minimum.isFinite || !maximum.isFinite) {
        minimum = 0;
        maximum = 0;
      }
      _resolvedScatterColorMinimum = minimum;
      _resolvedScatterColorMaximum = maximum;
    }
    return encoding.colorFor(
      scatter.points[pointIndex].colorValue,
      resolvedMinimumValue: _resolvedScatterColorMinimum!,
      resolvedMaximumValue: _resolvedScatterColorMaximum!,
    );
  }

  double? _scatterEncodedOpacity(ScatterChartSeries scatter, int pointIndex) {
    final encoding = scatter.opacityEncoding;
    if (encoding == null) return null;
    if (_resolvedScatterOpacityMinimum == null ||
        _resolvedScatterOpacityMaximum == null) {
      var minimum = encoding.minimumValue ?? double.infinity;
      var maximum = encoding.maximumValue ?? double.negativeInfinity;
      if (encoding.minimumValue == null || encoding.maximumValue == null) {
        for (final point in scatter.points) {
          final value = point.opacityValue;
          if (value == null || !value.isFinite) continue;
          if (encoding.minimumValue == null && value < minimum) {
            minimum = value;
          }
          if (encoding.maximumValue == null && value > maximum) {
            maximum = value;
          }
        }
      }
      if (!minimum.isFinite && maximum.isFinite) minimum = maximum;
      if (!maximum.isFinite && minimum.isFinite) maximum = minimum;
      if (!minimum.isFinite || !maximum.isFinite) {
        minimum = 0;
        maximum = 0;
      }
      _resolvedScatterOpacityMinimum = minimum;
      _resolvedScatterOpacityMaximum = maximum;
    }
    return encoding.opacityFor(
      scatter.points[pointIndex].opacityValue,
      resolvedMinimumValue: _resolvedScatterOpacityMinimum!,
      resolvedMaximumValue: _resolvedScatterOpacityMaximum!,
    );
  }

  bool _scatterPointIsRenderable(ScatterChartSeries scatter, int pointIndex) {
    if (scatter.points[pointIndex].pointStyle?.size != null) return true;
    if (scatter.sizeEncoding == null) return true;
    final magnitude = scatter.points[pointIndex].magnitude;
    return magnitude != null && magnitude.isFinite && magnitude >= 0;
  }

  double? _scatterBubbleRadius(ScatterChartSeries scatter, int pointIndex) {
    final encoding = scatter.sizeEncoding;
    if (encoding == null) return null;
    final magnitude = scatter.points[pointIndex].magnitude;
    if (magnitude == null || !magnitude.isFinite || magnitude < 0) return null;
    var maximum = _resolvedScatterMagnitudeMaximum;
    if (maximum == null) {
      maximum = encoding.minimumValue;
      for (final point in scatter.points) {
        final value = point.magnitude;
        if (value != null && value.isFinite && value >= 0 && value > maximum!) {
          maximum = value;
        }
      }
      _resolvedScatterMagnitudeMaximum = maximum;
    }
    return encoding.radiusFor(magnitude, resolvedMaximumValue: maximum!);
  }

  double _safeNonNegative(double value) =>
      value.isFinite && value >= 0 ? value : 0;

  double _safeUnit(double value) => value.isFinite ? value.clamp(0, 1) : 1;

  @override
  ChartDataHit? dataHitForPointIndex(int pointIndex) {
    if (series is BarChartSeries) {
      final geometry = barGeometryForPoint(pointIndex);
      if (geometry != null) return _barDataHit(geometry);
    }
    if (series is CandlestickChartSeries) {
      final geometry = candlestickGeometryForPoint(pointIndex);
      if (geometry != null) return _candlestickDataHit(geometry);
    }
    final renderIndex = _renderIndexForTargetIndex(pointIndex);
    if (renderIndex == null) return null;
    final currentSeries = series;
    if (currentSeries is ScatterChartSeries &&
        currentSeries.renderMode == ScatterRenderMode.clusters) {
      final layout = _resolveScatterClusterLayout();
      for (var index = 0; index < layout.clusters.length; index++) {
        final cluster = layout.clusters[index];
        if (cluster.sourcePointIndices.contains(renderIndex)) {
          return _scatterDataHitForCluster(cluster, index, layout);
        }
      }
    }
    if (currentSeries is ScatterChartSeries &&
        _isScatterBinMode(currentSeries.renderMode)) {
      final layout = _resolveScatterBinLayout();
      for (var index = 0; index < layout.bins.length; index++) {
        final bin = layout.bins[index];
        if (bin.sourcePointIndices.contains(renderIndex)) {
          return _scatterDataHitForBin(bin, index, layout);
        }
      }
    }
    if (currentSeries is ScatterChartSeries &&
        currentSeries.renderMode == ScatterRenderMode.density) {
      _resolveScatterGeometries();
      final geometry = _scatterGeometryByPointIndex[renderIndex];
      if (geometry != null) return _scatterDensityDataHitAt(geometry.center);
    }
    return _dataHitForRenderPointIndex(renderIndex);
  }

  /// Resolves visible Scatter data whose rendered marker centers fall inside
  /// [plotRect].
  ///
  /// The query reuses the marker-cell index built for precise hover hits, so a
  /// brush does not scan the complete source series on every pointer move.
  List<ChartDataHit> scatterDataHitsInPlotRect(Rect plotRect) {
    if (series is! ScatterChartSeries || plotRect.isEmpty) return const [];
    return _scatterDataHitsInPlotBounds(plotRect, contains: plotRect.contains);
  }

  /// Resolves visible Scatter data whose rendered marker centers fall inside
  /// the closed [plotPolygon].
  ///
  /// Candidate lookup is bounded by the polygon bounds before the exact path
  /// containment check, keeping free-form lasso feedback responsive.
  List<ChartDataHit> scatterDataHitsInPlotPolygon(List<Offset> plotPolygon) {
    if (series is! ScatterChartSeries || plotPolygon.length < 3) {
      return const [];
    }
    final path = Path()..addPolygon(plotPolygon, true);
    final bounds = path.getBounds();
    if (bounds.isEmpty) return const [];
    return _scatterDataHitsInPlotBounds(bounds, contains: path.contains);
  }

  List<ChartDataHit> _scatterDataHitsInPlotBounds(
    Rect bounds, {
    required bool Function(Offset center) contains,
  }) {
    _resolveScatterGeometries();
    if (_scatterHitGeometryByCell.isEmpty) return const [];

    final minCellX = (bounds.left / _scatterHitCellSize).floor();
    final maxCellX = (bounds.right / _scatterHitCellSize).floor();
    final minCellY = (bounds.top / _scatterHitCellSize).floor();
    final maxCellY = (bounds.bottom / _scatterHitCellSize).floor();
    final candidates = <int, ScatterPointGeometry>{};
    for (var cellX = minCellX; cellX <= maxCellX; cellX++) {
      for (var cellY = minCellY; cellY <= maxCellY; cellY++) {
        for (final geometry
            in _scatterHitGeometryByCell[(cellX, cellY)] ?? const []) {
          candidates[geometry.pointIndex] = geometry;
        }
      }
    }

    final pointIndices = candidates.keys.toList()..sort();
    return [
      for (final pointIndex in pointIndices)
        if (contains(candidates[pointIndex]!.center))
          ?_dataHitForRenderPointIndex(pointIndex),
    ];
  }

  ChartDataHit _barDataHit(BarGeometry geometry) {
    final point = geometry.point;
    return ChartDataHit(
      seriesId: series.id,
      pointIndex: geometry.pointIndex,
      plotPosition: geometry.valueEndPoint,
      semanticBounds: geometry.hitBounds,
      point: point,
      formattedValue:
          '${point.y.toStringAsFixed(2)}${series.unit == null || series.unit!.isEmpty ? '' : ' ${series.unit}'}',
      ordinal: geometry.pointIndex + 1,
      count: pointCount,
      isSelected: selectedPointIndices.contains(geometry.pointIndex),
      isFocused: focusedPointIndices.contains(geometry.pointIndex),
    );
  }

  ChartDataHit _candlestickDataHit(CandlestickGeometry geometry) {
    final point = geometry.point;
    final visual = _resolveCandlestickVisual(
      series as CandlestickChartSeries,
      point.direction,
      pointStyle: point.candlestickStyle,
    );
    return ChartDataHit(
      seriesId: series.id,
      pointIndex: geometry.pointIndex,
      plotPosition: geometry.bodyRect.center,
      semanticBounds: geometry.hitBounds,
      point: point,
      formattedValue:
          '${point.close.toStringAsFixed(2)}${series.unit == null || series.unit!.isEmpty ? '' : ' ${series.unit}'}',
      candlestick: CandlestickInteractionDetails.fromPoint(
        point,
        unit: series.unit,
      ),
      markerColor: visual.borderColor,
      ordinal: geometry.pointIndex + 1,
      count: pointCount,
      isSelected: selectedPointIndices.contains(geometry.pointIndex),
      isFocused: focusedPointIndices.contains(geometry.pointIndex),
    );
  }

  ChartDataHit? _dataHitForRenderPointIndex(int renderIndex) {
    if (renderIndex < 0 || renderIndex >= series.points.length) return null;
    final targetIndex = _targetIndexForRenderIndex(renderIndex);
    if (targetIndex == null) return null;
    if (targetIndex < 0 || targetIndex >= pointCount) return null;
    final point = series.points[renderIndex];
    if (!point.isValid) return null;
    final position = _currentTransform.dataToPlot(point.x, point.y);
    if (_supportsReveal && position.dx > _revealEdge) return null;
    final scatter = series is ScatterChartSeries
        ? series as ScatterChartSeries
        : null;
    final rawMagnitude = scatter?.sizeEncoding == null ? null : point.magnitude;
    final magnitude =
        rawMagnitude != null && rawMagnitude.isFinite && rawMagnitude >= 0
        ? rawMagnitude
        : null;
    final rawColorValue = scatter?.colorEncoding == null
        ? null
        : point.colorValue;
    final colorValue = rawColorValue != null && rawColorValue.isFinite
        ? rawColorValue
        : null;
    final rawOpacityValue = scatter?.opacityEncoding == null
        ? null
        : point.opacityValue;
    final opacityValue = rawOpacityValue != null && rawOpacityValue.isFinite
        ? rawOpacityValue
        : null;
    final scatterGeometry = scatter == null
        ? null
        : scatterGeometryForPoint(renderIndex);
    return ChartDataHit(
      seriesId: series.id,
      pointIndex: targetIndex,
      plotPosition: scatterGeometry?.center ?? position,
      semanticBounds:
          scatterGeometry?.hitBounds(4) ??
          Rect.fromCircle(center: position, radius: 24),
      point: point,
      formattedValue:
          '${point.y.toStringAsFixed(2)}${series.unit == null || series.unit!.isEmpty ? '' : ' ${series.unit}'}',
      formattedXValue: scatter == null ? null : point.x.toStringAsFixed(2),
      radiusValue: magnitude,
      formattedRadiusValue: magnitude == null
          ? null
          : scatter!.sizeEncoding!.format(magnitude),
      radiusLabel: magnitude == null ? null : scatter!.sizeEncoding!.label,
      colorValue: colorValue,
      formattedColorValue: colorValue == null
          ? null
          : scatter!.colorEncoding!.formatForInteraction(colorValue),
      colorLabel: colorValue == null ? null : scatter!.colorEncoding!.label,
      opacityValue: opacityValue,
      formattedOpacityValue: opacityValue == null
          ? null
          : scatter!.opacityEncoding!.format(opacityValue),
      opacityLabel: opacityValue == null
          ? null
          : scatter!.opacityEncoding!.label,
      categoryValue:
          scatter?.categoryEncoding?.labelFor(point.categoryValue) ??
          point.categoryValue,
      categoryLabel: point.categoryValue == null
          ? null
          : scatter?.categoryEncoding?.label,
      markerOpacity: scatter == null
          ? point.pointStyle?.scatterMarkerStyle?.opacity
          : _scatterMarkerStyleAt(scatter, renderIndex).opacity,
      markerColor: scatter == null
          ? point.pointStyle?.color
          : _scatterMarkerStyleAt(scatter, renderIndex).fillColor,
      ordinal: targetIndex + 1,
      count: pointCount,
      isSelected: selectedPointIndices.contains(targetIndex),
      isFocused: focusedPointIndices.contains(targetIndex),
    );
  }

  @override
  Iterable<ChartDataHit> get semanticDataHits sync* {
    if (series is! CandlestickChartSeries) return;
    for (final geometry in _resolveCandlestickGeometries()) {
      yield _candlestickDataHit(geometry);
    }
  }

  /// Calculate distance from point to line segment.
  double _distanceToLineSegment(Offset point, Offset segStart, Offset segEnd) {
    final dx = segEnd.dx - segStart.dx;
    final dy = segEnd.dy - segStart.dy;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      // Degenerate segment (point)
      return (point - segStart).distance;
    }

    // Project point onto line segment (clamped to [0, 1])
    final t =
        ((point.dx - segStart.dx) * dx + (point.dy - segStart.dy) * dy) /
        lengthSquared;
    final clampedT = t.clamp(0.0, 1.0);

    // Find closest point on segment
    final closest = Offset(
      segStart.dx + clampedT * dx,
      segStart.dy + clampedT * dy,
    );

    return (point - closest).distance;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    final reveal = _effectiveRevealProgress;
    if (reveal <= 0) return;
    if (reveal < 1) {
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(0, 0, size.width * reveal, size.height));
    }

    // Use theme color from getter (theme -> deprecated -> series -> default)
    final baseColor = themeColor;

    // Use exhaustive pattern matching on sealed type (Dart 3.0)
    switch (series) {
      case LineChartSeries():
        _paintLineSeries(canvas, series as LineChartSeries, baseColor);
        break;
      case BarChartSeries():
        _paintBarSeries(canvas, series as BarChartSeries, baseColor);
        break;
      case ScatterChartSeries():
        _paintScatterSeries(canvas, series as ScatterChartSeries, baseColor);
        break;
      case AreaChartSeries():
        _paintAreaSeries(canvas, series as AreaChartSeries, baseColor);
        break;
      case CandlestickChartSeries():
        _paintCandlestickSeries(canvas, series as CandlestickChartSeries);
        break;
    }
    _paintLinkedPoints(canvas, baseColor);
    if (reveal < 1) canvas.restore();
  }

  void _paintLinkedPoints(Canvas canvas, Color baseColor) {
    if (focusedPointIndices.isEmpty && selectedPointIndices.isEmpty) return;
    if (series is BarChartSeries) {
      _paintLinkedBars(canvas, baseColor);
      return;
    }
    if (series is ScatterChartSeries) {
      _paintLinkedScatter(canvas);
      return;
    }
    if (series is CandlestickChartSeries) {
      _paintLinkedCandlesticks(canvas);
      return;
    }
    final focusPaint = Paint()
      ..color = pointFocusColor ?? const Color(0xFF616161)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final selectionFill = Paint()
      ..color = pointSelectionColor ?? const Color(0x4D2196F3)
      ..style = PaintingStyle.fill;
    final selectionBorder = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    final pointFill = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    for (final index in selectedPointIndices) {
      final renderIndex = _renderIndexForTargetIndex(index);
      if (renderIndex == null) continue;
      if (renderIndex < 0 || renderIndex >= series.points.length) continue;
      final point = series.points[renderIndex];
      if (!point.isValid) continue;
      final offset = _currentTransform.dataToPlot(point.x, point.y);
      canvas.drawCircle(offset, markerSize + 5, selectionFill);
      canvas.drawCircle(offset, markerSize + 3, selectionBorder);
      canvas.drawCircle(offset, math.max(2, markerSize * 0.5), pointFill);
    }
    for (final index in focusedPointIndices) {
      final renderIndex = _renderIndexForTargetIndex(index);
      if (renderIndex == null) continue;
      if (renderIndex < 0 || renderIndex >= series.points.length) continue;
      final point = series.points[renderIndex];
      if (!point.isValid) continue;
      final offset = _currentTransform.dataToPlot(point.x, point.y);
      canvas.drawCircle(offset, markerSize + 7, focusPaint);
    }
  }

  void _paintLinkedScatter(Canvas canvas) {
    final currentSeries = series as ScatterChartSeries;
    final interaction = currentSeries.interactionStyle;
    final selectionColor =
        interaction.selectionColor ??
        pointSelectionColor ??
        const Color(0xFF2563EB);
    final focusColor =
        interaction.focusColor ?? pointFocusColor ?? const Color(0xFF334155);

    for (final pointIndex in selectedPointIndices) {
      final geometry = scatterGeometryForPoint(pointIndex);
      if (geometry == null) continue;
      final path = _scatterStatePath(
        geometry,
        scale: interaction.selectionScale,
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = selectionColor.withValues(
            alpha: interaction.selectionOpacity,
          )
          ..style = PaintingStyle.fill,
      );
      if (interaction.selectionStrokeWidth > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..color = selectionColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = interaction.selectionStrokeWidth,
        );
      }
    }

    for (final pointIndex in focusedPointIndices) {
      final geometry = scatterGeometryForPoint(pointIndex);
      if (geometry == null) continue;
      final path = _scatterStatePath(geometry, gap: interaction.focusGap);
      if (interaction.focusStrokeWidth > 0) {
        canvas.drawPath(
          path,
          Paint()
            ..color = focusColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = interaction.focusStrokeWidth,
        );
      }
    }
  }

  void _paintLinkedCandlesticks(Canvas canvas) {
    final selection = Paint()
      ..color = (pointSelectionColor ?? candlestickTheme.selectionColor)
          .withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;
    final selectionBorder = Paint()
      ..color = pointSelectionColor ?? candlestickTheme.selectionColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final focus = Paint()
      ..color = pointFocusColor ?? candlestickTheme.focusColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final pointIndex in selectedPointIndices) {
      final geometry = candlestickGeometryForPoint(pointIndex);
      if (geometry == null) continue;
      final rect = geometry.bodyRect.inflate(4);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        selection,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(3)),
        selectionBorder,
      );
    }
    for (final pointIndex in focusedPointIndices) {
      final geometry = candlestickGeometryForPoint(pointIndex);
      if (geometry == null) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          geometry.bodyRect.inflate(6),
          const Radius.circular(4),
        ),
        focus,
      );
    }
  }

  void _paintCandlestickSeries(
    Canvas canvas,
    CandlestickChartSeries candleSeries,
  ) {
    final geometries = _resolveCandlestickGeometries();
    if (geometries.isEmpty) return;
    canvas.save();
    canvas.clipRect(
      Rect.fromLTWH(
        0,
        0,
        _currentTransform.plotWidth,
        _currentTransform.plotHeight,
      ),
    );
    if (_candlestickHasPointOverrides == true) {
      for (final geometry in geometries) {
        _paintCandlestickGeometry(canvas, candleSeries, geometry);
      }
    } else {
      final batches = _candlestickUniformPaintBatches ??=
          _buildCandlestickPaintBatches(candleSeries, geometries);
      for (final batch in batches) {
        if (batch.fillPaint.color.a > 0) {
          canvas.drawPath(batch.fillPath, batch.fillPaint);
        }
        if (candleSeries.candlestickStyle.showBodyBorder &&
            candleSeries.candlestickStyle.bodyBorderWidth > 0) {
          canvas.drawPath(batch.borderPath, batch.borderPaint);
        }
        if (candleSeries.candlestickStyle.showWicks &&
            candleSeries.candlestickStyle.wickWidth > 0) {
          canvas.drawPath(batch.wickPath, batch.wickPaint);
        }
      }
    }
    canvas.restore();
  }

  List<_CandlestickPaintBatch> _buildCandlestickPaintBatches(
    CandlestickChartSeries candleSeries,
    List<CandlestickGeometry> geometries,
  ) {
    final batches = <CandlestickDirection, _CandlestickPaintBatch>{};
    for (final direction in CandlestickDirection.values) {
      final visual = _resolveCandlestickVisual(candleSeries, direction);
      batches[direction] = _CandlestickPaintBatch(
        fillPath: Path(),
        borderPath: Path(),
        wickPath: Path(),
        fillPaint: Paint()
          ..color = visual.fillColor
          ..style = PaintingStyle.fill,
        borderPaint: Paint()
          ..color = visual.borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = candleSeries.candlestickStyle.bodyBorderWidth,
        wickPaint: Paint()
          ..color = visual.wickColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = candleSeries.candlestickStyle.wickWidth
          ..strokeCap = StrokeCap.square,
      );
    }
    for (final geometry in geometries) {
      final batch = batches[geometry.direction]!;
      batch.fillPath.addRRect(geometry.bodyRRect);
      batch.borderPath.addRRect(geometry.bodyRRect);
      batch.wickPath
        ..moveTo(geometry.upperWickStart.dx, geometry.upperWickStart.dy)
        ..lineTo(geometry.upperWickEnd.dx, geometry.upperWickEnd.dy)
        ..moveTo(geometry.lowerWickStart.dx, geometry.lowerWickStart.dy)
        ..lineTo(geometry.lowerWickEnd.dx, geometry.lowerWickEnd.dy);
    }
    return [
      for (final direction in CandlestickDirection.values) batches[direction]!,
    ];
  }

  void _paintCandlestickGeometry(
    Canvas canvas,
    CandlestickChartSeries candleSeries,
    CandlestickGeometry geometry,
  ) {
    final visual = _resolveCandlestickVisual(
      candleSeries,
      geometry.direction,
      pointStyle: geometry.point.candlestickStyle,
    );
    final style = candleSeries.candlestickStyle;
    if (visual.fillColor.a > 0) {
      canvas.drawRRect(
        geometry.bodyRRect,
        Paint()
          ..color = visual.fillColor
          ..style = PaintingStyle.fill,
      );
    }
    if (style.showBodyBorder && style.bodyBorderWidth > 0) {
      canvas.drawRRect(
        geometry.bodyRRect,
        Paint()
          ..color = visual.borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.bodyBorderWidth,
      );
    }
    if (style.showWicks && style.wickWidth > 0) {
      final wickPaint = Paint()
        ..color = visual.wickColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.wickWidth
        ..strokeCap = StrokeCap.square;
      canvas
        ..drawLine(geometry.upperWickStart, geometry.upperWickEnd, wickPaint)
        ..drawLine(geometry.lowerWickStart, geometry.lowerWickEnd, wickPaint);
    }
  }

  _ResolvedCandlestickVisual _resolveCandlestickVisual(
    CandlestickChartSeries candleSeries,
    CandlestickDirection direction, {
    CandlestickPointStyle? pointStyle,
  }) {
    final style = candleSeries.candlestickStyle;
    final theme = candlestickTheme;
    final themeFill = switch (direction) {
      CandlestickDirection.rising => theme.risingBodyFillColor,
      CandlestickDirection.falling => theme.fallingBodyFillColor,
      CandlestickDirection.doji => theme.dojiBodyFillColor,
    };
    final seriesFill = switch (direction) {
      CandlestickDirection.rising => style.risingBodyFillColor,
      CandlestickDirection.falling => style.fallingBodyFillColor,
      CandlestickDirection.doji => style.dojiBodyFillColor,
    };
    final border = switch (direction) {
      CandlestickDirection.rising =>
        style.risingBorderColor ?? theme.risingBorderColor,
      CandlestickDirection.falling =>
        style.fallingBorderColor ?? theme.fallingBorderColor,
      CandlestickDirection.doji =>
        style.dojiBorderColor ?? theme.dojiBorderColor,
    };
    final wick = switch (direction) {
      CandlestickDirection.rising =>
        style.risingWickColor ?? theme.risingWickColor,
      CandlestickDirection.falling =>
        style.fallingWickColor ?? theme.fallingWickColor,
      CandlestickDirection.doji => style.dojiWickColor ?? theme.dojiWickColor,
    };
    final isHollowRising =
        direction == CandlestickDirection.rising &&
        style.bodyFillMode == CandlestickBodyFillMode.hollowRising;
    return _ResolvedCandlestickVisual(
      fillColor:
          pointStyle?.bodyFillColor ??
          (isHollowRising
              ? const Color(0x00000000)
              : (seriesFill ?? themeFill)),
      borderColor: pointStyle?.borderColor ?? border,
      wickColor: pointStyle?.wickColor ?? wick,
    );
  }

  Path _scatterStatePath(
    ScatterPointGeometry geometry, {
    double scale = 1,
    double gap = 0,
  }) {
    final width = geometry.width * scale + gap * 2;
    final height = geometry.height * scale + gap * 2;
    final path = Path();
    addScatterMarkerPath(
      path,
      center: geometry.center,
      radius: math.max(width, height) / 2,
      shape: geometry.shape,
      width: width,
      height: height,
      rotationRadians: geometry.rotationRadians,
    );
    return path;
  }

  void _paintLinkedBars(Canvas canvas, Color baseColor) {
    final currentSeries = series as BarChartSeries;
    final interaction = currentSeries.barStyle.interaction;
    final focusPaint = Paint()
      ..color =
          interaction.focusColor ?? pointFocusColor ?? const Color(0xFF424242)
      ..style = PaintingStyle.stroke
      ..strokeWidth = interaction.focusBorderWidth;
    final selectionFill = Paint()
      ..color =
          (interaction.selectionColor ??
                  pointSelectionColor ??
                  const Color(0xFF2196F3))
              .withValues(alpha: interaction.selectionOpacity)
      ..style = PaintingStyle.fill;
    final selectionBorder = Paint()
      ..color = interaction.selectionColor ?? pointSelectionColor ?? baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = interaction.selectionBorderWidth;

    for (final geometry in _resolveBarGeometries()) {
      final lollipop = currentSeries.lollipopStyle;
      final headCenter = geometry.lollipopHeadCenter;
      if (lollipop != null && headCenter != null) {
        if (selectedPointIndices.contains(geometry.pointIndex)) {
          canvas.drawCircle(headCenter, lollipop.headRadius + 3, selectionFill);
          canvas.drawCircle(
            headCenter,
            lollipop.headRadius + 3,
            selectionBorder,
          );
        }
        if (focusedPointIndices.contains(geometry.pointIndex)) {
          canvas.drawCircle(
            headCenter,
            lollipop.headRadius + interaction.focusGap,
            focusPaint,
          );
        }
        continue;
      }
      if (selectedPointIndices.contains(geometry.pointIndex)) {
        canvas.drawRRect(geometry.rrect, selectionFill);
        canvas.drawRRect(geometry.rrect.inflate(2), selectionBorder);
      }
      if (focusedPointIndices.contains(geometry.pointIndex)) {
        canvas.drawRRect(
          geometry.rrect.inflate(interaction.focusGap),
          focusPaint,
        );
      }
    }
  }

  /// Paints transient hover and press feedback for a bar point.
  ///
  /// This is called from the uncached overlay layer so pointer movement never
  /// forces the expensive series picture to be regenerated.
  void paintBarInteractionOverlay(
    Canvas canvas, {
    int? hoveredPointIndex,
    int? pressedPointIndex,
  }) {
    final currentSeries = series;
    if (currentSeries is! BarChartSeries) return;
    final interaction = currentSeries.barStyle.interaction;

    final activeIndex = pressedPointIndex ?? hoveredPointIndex;
    if (activeIndex == null) return;
    final geometry = barGeometryForPoint(activeIndex);
    if (geometry == null) return;
    final barColor = _resolvedBarColor(currentSeries, geometry, themeColor);
    final lollipop = currentSeries.lollipopStyle;
    final headCenter = geometry.lollipopHeadCenter;

    if (lollipop != null && headCenter != null) {
      if (pressedPointIndex != null) {
        canvas.drawCircle(
          headCenter,
          lollipop.headRadius + 2,
          Paint()
            ..color = interaction.pressedColor.withValues(
              alpha: interaction.pressedOpacity,
            )
            ..style = PaintingStyle.fill,
        );
        return;
      }
      final hoverColor =
          interaction.hoverColor ??
          (barColor.computeLuminance() > 0.45
              ? const Color(0xFF111827)
              : const Color(0xFFFFFFFF));
      canvas.drawCircle(
        headCenter,
        lollipop.headRadius + 2,
        Paint()
          ..color = hoverColor.withValues(alpha: interaction.hoverOpacity)
          ..style = PaintingStyle.fill,
      );
      if (interaction.hoverBorderWidth > 0) {
        canvas.drawCircle(
          headCenter,
          lollipop.headRadius + interaction.hoverBorderWidth / 2,
          Paint()
            ..color = hoverColor.withValues(alpha: 0.82)
            ..style = PaintingStyle.stroke
            ..strokeWidth = interaction.hoverBorderWidth,
        );
      }
      return;
    }

    if (pressedPointIndex != null) {
      canvas.drawRRect(
        geometry.rrect,
        Paint()
          ..color = interaction.pressedColor.withValues(
            alpha: interaction.pressedOpacity,
          )
          ..style = PaintingStyle.fill,
      );
      return;
    }

    final hoverColor =
        interaction.hoverColor ??
        (barColor.computeLuminance() > 0.45
            ? const Color(0xFF111827)
            : const Color(0xFFFFFFFF));
    canvas.drawRRect(
      geometry.rrect,
      Paint()
        ..color = hoverColor.withValues(alpha: interaction.hoverOpacity)
        ..style = PaintingStyle.fill,
    );
    if (interaction.hoverBorderWidth > 0) {
      canvas.drawRRect(
        geometry.rrect.inflate(interaction.hoverBorderWidth / 2),
        Paint()
          ..color = hoverColor.withValues(alpha: 0.82)
          ..style = PaintingStyle.stroke
          ..strokeWidth = interaction.hoverBorderWidth,
      );
    }
  }

  /// Paints transient hover and press feedback for a Scatter point.
  ///
  /// The overlay reuses the point's effective shape, dimensions, and rotation
  /// while leaving the cached base-series picture untouched.
  void paintScatterInteractionOverlay(
    Canvas canvas, {
    int? hoveredPointIndex,
    int? pressedPointIndex,
  }) {
    final currentSeries = series;
    if (currentSeries is! ScatterChartSeries) return;
    final activeIndex = pressedPointIndex ?? hoveredPointIndex;
    if (activeIndex == null) return;
    if (currentSeries.renderMode == ScatterRenderMode.clusters) {
      final layout = _resolveScatterClusterLayout();
      ScatterClusterGeometry? activeCluster;
      for (final cluster in layout.clusters) {
        if (cluster.sourcePointIndices.contains(activeIndex)) {
          activeCluster = cluster;
          break;
        }
      }
      if (activeCluster != null) {
        final interaction = currentSeries.interactionStyle;
        canvas.drawCircle(
          activeCluster.center,
          activeCluster.radius *
              (pressedPointIndex != null
                  ? interaction.pressedScale
                  : interaction.hoverScale),
          Paint()
            ..color = pressedPointIndex != null
                ? interaction.pressedColor.withValues(
                    alpha: interaction.pressedOpacity,
                  )
                : (interaction.hoverColor ?? currentSeries.color ?? themeColor)
            ..style = pressedPointIndex != null
                ? PaintingStyle.fill
                : PaintingStyle.stroke
            ..strokeWidth = interaction.hoverStrokeWidth,
        );
        return;
      }
    }
    if (_isScatterBinMode(currentSeries.renderMode)) {
      final layout = _resolveScatterBinLayout();
      ScatterBinGeometry? activeBin;
      for (final bin in layout.bins) {
        if (bin.sourcePointIndices.contains(activeIndex)) {
          activeBin = bin;
          break;
        }
      }
      if (activeBin != null) {
        final interaction = currentSeries.interactionStyle;
        canvas.drawPath(
          activeBin.path,
          Paint()
            ..color = pressedPointIndex != null
                ? interaction.pressedColor.withValues(
                    alpha: interaction.pressedOpacity,
                  )
                : (interaction.hoverColor ?? currentSeries.color ?? themeColor)
            ..style = pressedPointIndex != null
                ? PaintingStyle.fill
                : PaintingStyle.stroke
            ..strokeWidth = interaction.hoverStrokeWidth,
        );
        return;
      }
    }
    final geometry = scatterGeometryForPoint(activeIndex);
    if (geometry == null) return;
    final interaction = currentSeries.interactionStyle;
    final style = _scatterMarkerStyleAt(currentSeries, activeIndex);
    final pointColor = style.fillColor ?? currentSeries.color ?? themeColor;

    if (pressedPointIndex != null) {
      canvas.drawPath(
        _scatterStatePath(geometry, scale: interaction.pressedScale),
        Paint()
          ..color = interaction.pressedColor.withValues(
            alpha: interaction.pressedOpacity,
          )
          ..style = PaintingStyle.fill,
      );
      return;
    }

    if (interaction.hoverStrokeWidth <= 0) return;
    canvas.drawPath(
      _scatterStatePath(geometry, scale: interaction.hoverScale),
      Paint()
        ..color = interaction.hoverColor ?? pointColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = interaction.hoverStrokeWidth,
    );
  }

  void _paintLineSeries(
    Canvas canvas,
    LineChartSeries series,
    Color baseColor,
  ) {
    // FAST PATH CHECK: If any segment has style overrides, use multi-style rendering
    // This check is cached to avoid O(n) scan on every paint
    if (_hasSegmentOverrides(series)) {
      _paintLineSeriesMultiStyle(canvas, series, baseColor);
      return;
    }

    // FAST PATH: Single color rendering (original optimized code)
    _paintLineSeriesSingleColor(canvas, series, baseColor);
  }

  /// Checks if series has any segment style overrides (cached for performance).
  bool _hasSegmentOverrides(LineChartSeries series) {
    // Return cached value if available
    if (_cachedHasSegmentOverrides != null) {
      return _cachedHasSegmentOverrides!;
    }

    // O(n) scan, but only done once and cached
    _cachedHasSegmentOverrides = series.points.any(
      (p) => p.segmentStyle != null,
    );
    return _cachedHasSegmentOverrides!;
  }

  /// Original single-color line rendering (fast path).
  void _paintLineSeriesSingleColor(
    Canvas canvas,
    LineChartSeries series,
    Color baseColor,
  ) {
    // Interaction opacity composes with the explicit marker opacity.
    final opacity = isSelected
        ? 1.0
        : isHovered
        ? 0.8
        : 0.7;
    // Use theme-based stroke width with selection multiplier
    final effectiveStrokeWidth = isSelected ? strokeWidth * 1.5 : strokeWidth;

    final paint = Paint()
      ..color = baseColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = effectiveStrokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Check if we need to regenerate the path (transform changed or no cache)
    final needsRegeneration =
        _cachedPath == null || _cachedTransform != _currentTransform;

    if (needsRegeneration) {
      // PERFORMANCE OPTIMIZATION: Only process points within visible viewport
      // During streaming with 500+ points but only 100 visible, this saves 80% of work
      final visiblePoints = <ChartDataPoint>[];
      final visibleIndices =
          <int>[]; // Track original indices for hover matching
      final xMin = _currentTransform.dataXMin;
      final xMax = _currentTransform.dataXMax;

      // Use a margin based on the visible range to ensure edge rendering is correct
      // at all zoom levels. 10% of visible range ensures lines connect properly.
      final xSpan = xMax - xMin;
      final margin = xSpan * 0.1;

      // Find the first visible point index using binary search for efficiency
      int startIdx = 0;
      int endIdx = series.points.length;

      // Binary search for first point >= xMin - margin
      int lo = 0, hi = series.points.length;
      while (lo < hi) {
        final mid = (lo + hi) >> 1;
        if (series.points[mid].x < xMin - margin) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      // Include one point before for line continuity
      startIdx = lo > 0 ? lo - 1 : 0;

      // Binary search for first point > xMax + margin
      lo = startIdx;
      hi = series.points.length;
      while (lo < hi) {
        final mid = (lo + hi) >> 1;
        if (series.points[mid].x <= xMax + margin) {
          lo = mid + 1;
        } else {
          hi = mid;
        }
      }
      // Include one point after for line continuity
      endIdx = lo < series.points.length ? lo + 1 : series.points.length;

      // Collect visible points
      for (int idx = startIdx; idx < endIdx; idx++) {
        visiblePoints.add(series.points[idx]);
        visibleIndices.add(idx);
      }

      // If no visible points, skip rendering
      if (visiblePoints.isEmpty) {
        _cachedPath = Path();
        _cachedTransformedPoints = [];
        _cachedOriginalIndices = [];
        _cachedTransform = _currentTransform;
        return;
      }

      // PRE-TRANSFORM visible points ONCE to avoid redundant calculations
      final transformedPoints = visiblePoints
          .map((p) => _currentTransform.dataToPlot(p.x, p.y))
          .toList();

      final path = Path();
      path.moveTo(transformedPoints[0].dx, transformedPoints[0].dy);

      InterpolationGeometry.addPathSegments<Offset>(
        path: path,
        points: transformedPoints,
        interpolation: series.interpolation,
        getX: (point) => point.dx,
        getY: (point) => point.dy,
        tension: series.tension,
      );

      // Cache the generated path, transformed points, original indices, and transform
      _cachedPath = path;
      _cachedStrokePath = null;
      _cachedTransformedPoints = transformedPoints;
      _cachedOriginalIndices = visibleIndices;
      _cachedTransform = _currentTransform;
    }

    // Apply the pattern after interpolation so every curve mode shares the
    // same measured dash spacing. The derived path is cached with its source.
    final strokePath = series.dashPattern.isEmpty
        ? _cachedPath!
        : _cachedStrokePath ??= createDashedPath(
            _cachedPath!,
            series.dashPattern,
          );

    // Paint using the cached path (no regeneration on hover!)
    if (series.lineGlow > 0) {
      final glowPaint = Paint()
        ..color = baseColor.withAlpha(60)
        ..strokeWidth = effectiveStrokeWidth + series.lineGlow * 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, series.lineGlow);
      canvas.drawPath(strokePath, glowPaint);
    }
    canvas.drawPath(strokePath, paint);

    // Draw data point markers if enabled (use cached transforms!)
    if (series.showDataPointMarkers && _cachedTransformedPoints != null) {
      // Series-specific dataPointMarkerRadius takes precedence over theme
      final effectiveMarkerSize = series.dataPointMarkerRadius;
      _paintDataPointMarkers(
        canvas,
        _cachedTransformedPoints!,
        _cachedOriginalIndices,
        effectiveMarkerSize,
        baseColor,
      );
    }

    _paintSeriesInlineLabel(
      canvas,
      series,
      _cachedTransformedPoints ?? [],
      baseColor,
    );
  }

  /// Multi-style line rendering with per-segment color/width overrides.
  ///
  /// This method handles series with segment style overrides by:
  /// 1. Analyzing points to find continuous style regions
  /// 2. Batching consecutive same-style segments
  /// 3. Rendering each region with its own path/paint
  ///
  /// **Performance**: Regions are cached. Bezier tangents use full point context
  /// for smooth curves at color boundaries.
  void _paintLineSeriesMultiStyle(
    Canvas canvas,
    LineChartSeries series,
    Color baseColor,
  ) {
    final opacity = _getOpacity();
    final effectiveStrokeWidth = isSelected ? strokeWidth * 1.5 : strokeWidth;

    // Filter to visible points (same optimization as single-color path)
    final visiblePoints = <ChartDataPoint>[];
    final visibleIndices = <int>[]; // Track original indices for style lookup
    final xMin = _currentTransform.dataXMin;
    final xMax = _currentTransform.dataXMax;

    // Use a margin based on the visible range to ensure edge rendering is correct
    // at all zoom levels. 10% of visible range ensures lines connect properly.
    final xSpan = xMax - xMin;
    final margin = xSpan * 0.1;

    // Find the first visible point index using binary search for efficiency
    int startIdx = 0;
    int endIdx = series.points.length;

    // Binary search for first point >= xMin - margin
    int lo = 0, hi = series.points.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (series.points[mid].x < xMin - margin) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    // Include one point before for line continuity
    startIdx = lo > 0 ? lo - 1 : 0;

    // Binary search for first point > xMax + margin
    lo = startIdx;
    hi = series.points.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (series.points[mid].x <= xMax + margin) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    // Include one point after for line continuity
    endIdx = lo < series.points.length ? lo + 1 : series.points.length;

    // Collect visible points
    for (int i = startIdx; i < endIdx; i++) {
      visiblePoints.add(series.points[i]);
      visibleIndices.add(i);
    }

    if (visiblePoints.length < 2) return;

    // Pre-transform ALL visible points once
    final transformedPoints = visiblePoints
        .map((p) => _currentTransform.dataToPlot(p.x, p.y))
        .toList();

    // Analyze style regions (uses visible points, not full series)
    final regions = _analyzeStyleRegions(
      visiblePoints,
      baseColor,
      effectiveStrokeWidth,
      series.dashPattern,
    );

    // Paint each region
    for (final region in regions) {
      final regionPath = _buildRegionPath(
        transformedPoints,
        region.startIndex,
        region.endIndex,
        series.interpolation,
        series.tension,
      );
      final strokePath = createDashedPath(regionPath, region.dashPattern);

      final paint = Paint()
        ..color = region.color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = region.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (series.lineGlow > 0) {
        final glowPaint = Paint()
          ..color = region.color.withAlpha(60)
          ..strokeWidth = region.strokeWidth + series.lineGlow * 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, series.lineGlow);
        canvas.drawPath(strokePath, glowPaint);
      }
      canvas.drawPath(strokePath, paint);
    }

    // Draw data point markers if enabled
    if (series.showDataPointMarkers) {
      // Series-specific dataPointMarkerRadius takes precedence over theme
      final effectiveMarkerSize = series.dataPointMarkerRadius;
      _paintDataPointMarkers(
        canvas,
        transformedPoints,
        visibleIndices,
        effectiveMarkerSize,
        baseColor,
      );
    }

    _paintSeriesInlineLabel(canvas, series, transformedPoints, baseColor);
  }

  /// Builds a path for a single style region.
  ///
  /// Uses full [allPoints] array for bezier tangent context, but only adds
  /// segments within [startIndex] to [endIndex] range.
  Path _buildRegionPath(
    List<Offset> allPoints,
    int startIndex,
    int endIndex,
    LineInterpolation interpolation,
    double tension,
  ) {
    final path = Path();

    // Move to first point in region
    path.moveTo(allPoints[startIndex].dx, allPoints[startIndex].dy);

    InterpolationGeometry.addPathSegments<Offset>(
      path: path,
      points: allPoints,
      interpolation: interpolation,
      getX: (point) => point.dx,
      getY: (point) => point.dy,
      startIndex: startIndex + 1,
      endIndex: endIndex,
      tension: tension,
    );
    return path;
  }

  /// Gets the current opacity based on selection/hover state.
  double _getOpacity() {
    return isSelected
        ? 1.0
        : isHovered
        ? 0.8
        : 0.7;
  }

  void _paintScatterSeries(
    Canvas canvas,
    ScatterChartSeries series,
    Color baseColor,
  ) {
    // Use theme-based opacity values: selected=1.0, hovered=0.8, normal=0.7
    final interactionOpacity = series.opacityEncoding != null
        ? 1.0
        : isSelected
        ? 1.0
        : isHovered
        ? 0.8
        : 0.7;
    // Use theme marker size if available, otherwise series-specific size
    final geometries = _resolveScatterGeometries();
    _visibleScatterLabelBounds = const [];
    if (geometries.isEmpty) return;
    if (series.renderMode == ScatterRenderMode.clusters) {
      _paintScatterClusters(canvas, series, baseColor, interactionOpacity);
      return;
    }
    if (_isScatterBinMode(series.renderMode)) {
      _paintScatterBins(canvas, series, baseColor, interactionOpacity);
      return;
    }
    if (series.renderMode == ScatterRenderMode.density) {
      _paintScatterDensity(canvas, series, baseColor, interactionOpacity);
      if (!series.densityConfig.showPoints) return;
    }

    // Check visible points only; offscreen overrides cannot affect this paint.
    final hasOverrides =
        hasAnySelectedPoints ||
        series.sizeEncoding != null ||
        series.colorEncoding != null ||
        series.opacityEncoding != null ||
        series.categoryEncoding != null ||
        geometries.any((g) => g.point.pointStyle != null);

    final uniformStyle = _scatterMarkerStyleAt(series, -1);
    if (!hasOverrides &&
        uniformStyle.shape == SeriesMarkerShape.circle &&
        uniformStyle.width == uniformStyle.height &&
        uniformStyle.strokeWidth == 0) {
      // FAST PATH: one native canvas operation for all uniform markers. A
      // round-capped point stroke has the same circular footprint as the
      // previous drawCircle loop while avoiding one draw call per point.
      final radius = uniformStyle.width / 2;
      if (radius > 0) {
        final pointPaint = Paint()
          ..color = (uniformStyle.fillColor ?? baseColor).withValues(
            alpha: interactionOpacity * uniformStyle.opacity,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 2
          ..strokeCap = StrokeCap.round;
        canvas.drawPoints(
          PointMode.points,
          _scatterUniformCenters ??
              [for (final geometry in geometries) geometry.center],
          pointPaint,
        );
      }
    } else if (!hasOverrides) {
      final markerPath = _scatterUniformMarkerPath ??= _buildScatterMarkerPath(
        geometries,
        uniformStyle.shape,
      );
      _paintScatterMarkerPath(
        canvas,
        markerPath,
        uniformStyle,
        baseColor,
        interactionOpacity,
      );
    } else {
      // STYLED PATH: Per-point styling.
      for (final geometry in geometries) {
        final markerPath = Path();
        addScatterMarkerPath(
          markerPath,
          center: geometry.center,
          radius: geometry.radius,
          width: geometry.width,
          height: geometry.height,
          rotationRadians: geometry.rotationRadians,
          shape: geometry.shape,
        );
        _paintScatterMarkerPath(
          canvas,
          markerPath,
          _scatterMarkerStyleAt(series, geometry.pointIndex),
          baseColor,
          hasAnySelectedPoints &&
                  !selectedPointIndices.contains(geometry.pointIndex)
              ? interactionOpacity * series.interactionStyle.dimmedOpacity
              : interactionOpacity,
        );
      }
    }
    _paintScatterPointLabels(canvas, series, geometries, baseColor);
  }

  void _paintScatterDensity(
    Canvas canvas,
    ScatterChartSeries series,
    Color baseColor,
    double interactionOpacity,
  ) {
    final layout = _resolveScatterDensityLayout();
    final config = series.densityConfig;
    final densityRange = math.max(0.000001, 1 - config.minimumDensity);
    for (final contour in layout.contours) {
      final progress =
          ((contour.relativeDensity - config.minimumDensity) / densityRange)
              .clamp(0, 1);
      final opacity =
          (config.minimumOpacity +
              (config.maximumOpacity - config.minimumOpacity) * progress) *
          interactionOpacity;
      canvas.drawPath(
        contour.path,
        Paint()
          ..color = baseColor.withValues(alpha: opacity.clamp(0, 1))
          ..style = PaintingStyle.stroke
          ..strokeWidth = config.lineWidth
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _paintScatterClusters(
    Canvas canvas,
    ScatterChartSeries series,
    Color baseColor,
    double interactionOpacity,
  ) {
    final layout = _resolveScatterClusterLayout();
    final config = series.clusterConfig;
    if (config.showZones && config.zoneOpacity > 0) {
      final zoneRadius = Radius.circular(math.min(12, config.cellSize * 0.2));
      for (final cluster in layout.clusters) {
        final selected = cluster.sourcePointIndices.any(
          selectedPointIndices.contains,
        );
        final dimmed = hasAnySelectedPoints && !selected;
        final zoneOpacity =
            config.zoneOpacity *
            interactionOpacity *
            (dimmed ? series.interactionStyle.dimmedOpacity : 1);
        final zone = RRect.fromRectAndRadius(cluster.zoneBounds, zoneRadius);
        canvas.drawRRect(
          zone,
          Paint()
            ..color = baseColor.withValues(alpha: zoneOpacity.clamp(0, 1))
            ..style = PaintingStyle.fill,
        );
        canvas.drawRRect(
          zone,
          Paint()
            ..color = baseColor.withValues(
              alpha: (zoneOpacity * 2.4).clamp(0, 0.38),
            )
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1,
        );
      }
    }
    for (final geometry in layout.unclusteredPoints) {
      final path = Path();
      addScatterMarkerPath(
        path,
        center: geometry.center,
        radius: geometry.radius,
        width: geometry.width,
        height: geometry.height,
        rotationRadians: geometry.rotationRadians,
        shape: geometry.shape,
      );
      _paintScatterMarkerPath(
        canvas,
        path,
        _scatterMarkerStyleAt(series, geometry.pointIndex),
        baseColor,
        hasAnySelectedPoints &&
                !selectedPointIndices.contains(geometry.pointIndex)
            ? interactionOpacity * series.interactionStyle.dimmedOpacity
            : interactionOpacity,
      );
    }

    for (final cluster in layout.clusters) {
      final selectedCount = cluster.sourcePointIndices
          .where(selectedPointIndices.contains)
          .length;
      final focused = cluster.sourcePointIndices.any(
        focusedPointIndices.contains,
      );
      final opacity = hasAnySelectedPoints && selectedCount == 0
          ? interactionOpacity * series.interactionStyle.dimmedOpacity
          : math.max(0.82, interactionOpacity);
      final fillColor = baseColor.withValues(alpha: opacity.clamp(0, 1));
      canvas.drawCircle(
        cluster.center,
        cluster.radius,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        cluster.center,
        cluster.radius,
        Paint()
          ..color = const Color(0xE6FFFFFF)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      if (selectedCount > 0 || focused) {
        canvas.drawCircle(
          cluster.center,
          cluster.radius + (focused ? series.interactionStyle.focusGap : 3),
          Paint()
            ..color = focused
                ? (series.interactionStyle.focusColor ?? baseColor)
                : (series.interactionStyle.selectionColor ?? baseColor)
            ..style = PaintingStyle.stroke
            ..strokeWidth = focused
                ? series.interactionStyle.focusStrokeWidth
                : series.interactionStyle.selectionStrokeWidth,
        );
      }
      if (config.showCountLabels &&
          cluster.pointCount >= config.labelMinimumPointCount) {
        _paintScatterClusterCount(canvas, cluster, fillColor);
      }
    }
  }

  void _paintScatterClusterCount(
    Canvas canvas,
    ScatterClusterGeometry cluster,
    Color fillColor,
  ) {
    final text = cluster.pointCount > 999
        ? '${(cluster.pointCount / 1000).toStringAsFixed(cluster.pointCount >= 10000 ? 0 : 1)}k'
        : cluster.pointCount.toString();
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: fillColor.computeLuminance() > 0.52
              ? const Color(0xFF0F172A)
              : const Color(0xFFFFFFFF),
          fontSize: cluster.radius < 12 ? 9 : 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
    )..layout(maxWidth: cluster.radius * 1.7);
    painter.paint(
      canvas,
      cluster.center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  void _paintScatterBins(
    Canvas canvas,
    ScatterChartSeries series,
    Color baseColor,
    double interactionOpacity,
  ) {
    final layout = _resolveScatterBinLayout();
    final config = series.binConfig;
    for (final bin in layout.bins) {
      final selectedCount = bin.sourcePointIndices
          .where(selectedPointIndices.contains)
          .length;
      final focused = bin.sourcePointIndices.any(focusedPointIndices.contains);
      var opacity =
          config.minimumOpacity +
          (config.maximumOpacity - config.minimumOpacity) *
              bin.normalizedIntensity;
      opacity *= interactionOpacity;
      if (hasAnySelectedPoints && selectedCount == 0) {
        opacity *= series.interactionStyle.dimmedOpacity;
      }
      final fillColor = baseColor.withValues(alpha: opacity.clamp(0, 1));
      canvas.drawPath(
        bin.path,
        Paint()
          ..color = fillColor
          ..style = PaintingStyle.fill,
      );
      canvas.drawPath(
        bin.path,
        Paint()
          ..color = baseColor.withValues(alpha: math.max(0.34, opacity))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.75,
      );
      if (selectedCount > 0 || focused) {
        canvas.drawPath(
          bin.path,
          Paint()
            ..color = focused
                ? (series.interactionStyle.focusColor ?? baseColor)
                : (series.interactionStyle.selectionColor ?? baseColor)
            ..style = PaintingStyle.stroke
            ..strokeWidth = focused
                ? series.interactionStyle.focusStrokeWidth
                : series.interactionStyle.selectionStrokeWidth,
        );
      }
      if (config.showLabels &&
          bin.pointCount >= config.labelMinimumPointCount) {
        _paintScatterBinLabel(canvas, bin, fillColor, opacity, config);
      }
    }
  }

  void _paintScatterBinLabel(
    Canvas canvas,
    ScatterBinGeometry bin,
    Color fillColor,
    double opacity,
    ScatterBinConfig config,
  ) {
    final text = _formatScatterBinLabel(bin.aggregateValue, config);
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: opacity < 0.58 || fillColor.computeLuminance() > 0.52
              ? const Color(0xFF0F172A)
              : const Color(0xFFFFFFFF),
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
    )..layout(maxWidth: math.max(8, bin.paintBounds.width - 4));
    painter.paint(
      canvas,
      bin.center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  String _scatterBinAggregateLabel(
    ScatterBinConfig config,
    ScatterChartSeries series,
  ) {
    final valueLabel = switch (config.valueSource) {
      ScatterBinValueSource.x => 'X',
      ScatterBinValueSource.y => 'Y',
      ScatterBinValueSource.magnitude =>
        series.sizeEncoding?.label ?? 'Magnitude',
      ScatterBinValueSource.colorValue =>
        series.colorEncoding?.label ?? 'Color value',
      ScatterBinValueSource.opacityValue =>
        series.opacityEncoding?.label ?? 'Opacity value',
    };
    return switch (config.aggregate) {
      ScatterBinAggregate.count => 'Observation count',
      ScatterBinAggregate.sum => 'Sum of $valueLabel',
      ScatterBinAggregate.mean => 'Mean $valueLabel',
      ScatterBinAggregate.minimum => 'Minimum $valueLabel',
      ScatterBinAggregate.maximum => 'Maximum $valueLabel',
      ScatterBinAggregate.proportion => 'Share of visible observations',
    };
  }

  String _formatScatterBinAggregate(
    double value,
    ScatterBinConfig config,
    ScatterChartSeries series,
  ) {
    if (config.aggregate == ScatterBinAggregate.count) {
      return value.round().toString();
    }
    if (config.aggregate == ScatterBinAggregate.proportion) {
      return '${(value * 100).toStringAsFixed(1)}%';
    }
    return switch (config.valueSource) {
      ScatterBinValueSource.magnitude when series.sizeEncoding != null =>
        series.sizeEncoding!.format(value),
      ScatterBinValueSource.colorValue when series.colorEncoding != null =>
        series.colorEncoding!.format(value),
      ScatterBinValueSource.opacityValue when series.opacityEncoding != null =>
        series.opacityEncoding!.format(value),
      ScatterBinValueSource.y => _formatScatterBinNumber(
        value,
        unit: series.unit,
      ),
      _ => _formatScatterBinNumber(value),
    };
  }

  String _formatScatterBinLabel(double value, ScatterBinConfig config) {
    if (config.aggregate == ScatterBinAggregate.count) {
      final count = value.round();
      return count > 999
          ? '${(count / 1000).toStringAsFixed(count >= 10000 ? 0 : 1)}k'
          : '$count';
    }
    if (config.aggregate == ScatterBinAggregate.proportion) {
      return '${(value * 100).toStringAsFixed(value >= 0.1 ? 0 : 1)}%';
    }
    return _formatScatterBinNumber(value, compact: true);
  }

  String _formatScatterBinNumber(
    double value, {
    String? unit,
    bool compact = false,
  }) {
    final absolute = value.abs();
    final text = compact && absolute >= 1000
        ? '${(value / 1000).toStringAsFixed(absolute >= 10000 ? 0 : 1)}k'
        : value.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
    return unit == null || unit.isEmpty ? text : '$text $unit';
  }

  void _paintScatterPointLabels(
    Canvas canvas,
    ScatterChartSeries series,
    List<ScatterPointGeometry> geometries,
    Color baseColor,
  ) {
    final config = series.dataPointLabels;
    if (config == null || !config.show) return;
    final coordinator =
        _dataPointLabelLayoutCoordinator ??
        DataPointLabelLayoutCoordinator(
          plotBounds: Rect.fromLTWH(
            0,
            0,
            _currentTransform.plotWidth,
            _currentTransform.plotHeight,
          ),
        );
    const horizontalPadding = 4.0;
    const verticalPadding = 2.0;
    final accepted = <Rect>[];

    for (final geometry in geometries) {
      final point = geometry.point;
      final text = _dataPointLabelText(point, config, series.unit);
      if (text.isEmpty) continue;
      final labelColor = config.labelColor ?? baseColor;
      final painterKey =
          'point:$text:${labelColor.toARGB32()}:${config.fontSize}:${config.fontWeight.index}';
      final painter = _labelPainterCache.putIfAbsent(painterKey, () {
        final result = TextPainter(
          text: TextSpan(
            text: text,
            style: TextStyle(
              color: labelColor,
              fontSize: config.fontSize,
              fontWeight: config.fontWeight,
              fontFamily: fontFamily,
            ),
          ),
          textDirection: textDirection,
          textAlign: TextAlign.left,
        );
        result.layout();
        return result;
      });
      final labelSize = Size(
        painter.width + horizontalPadding * 2,
        painter.height + verticalPadding * 2,
      );
      final positions = _scatterLabelCandidatePositions(config.position);
      final candidates = [
        for (final position in positions)
          _scatterLabelRect(geometry, labelSize, position, config),
      ];
      final placement = coordinator.place(
        candidates: candidates,
        collisionPolicy: config.collisionPolicy,
        collisionPadding: config.collisionPadding,
        plotEdgeAware: config.plotEdgeAware,
      );
      if (placement == null) continue;
      final rect = placement.rect;
      accepted.add(rect);
      if (config.background case final background?) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)),
          Paint()
            ..color = background.withValues(alpha: config.backgroundOpacity),
        );
      }
      painter.paint(
        canvas,
        rect.topLeft + const Offset(horizontalPadding, verticalPadding),
      );
    }
    _visibleScatterLabelBounds = List.unmodifiable(accepted);
  }

  String _dataPointLabelText(
    ChartDataPoint point,
    DataPointLabelConfig config,
    String? unit,
  ) {
    if (config.formatter case final formatter?) return formatter(point);
    if (config.content == DataPointLabelContent.pointLabel &&
        point.label != null &&
        point.label!.trim().isNotEmpty) {
      return point.label!.trim();
    }
    return DataPointLabelConfig.autoFormatLabelValue(
      point.y,
      config.showUnit ? unit : null,
    );
  }

  List<DataPointLabelPosition> _scatterLabelCandidatePositions(
    DataPointLabelPosition preferred,
  ) => switch (preferred) {
    DataPointLabelPosition.above => const [
      DataPointLabelPosition.above,
      DataPointLabelPosition.right,
      DataPointLabelPosition.left,
      DataPointLabelPosition.below,
    ],
    DataPointLabelPosition.below => const [
      DataPointLabelPosition.below,
      DataPointLabelPosition.right,
      DataPointLabelPosition.left,
      DataPointLabelPosition.above,
    ],
    DataPointLabelPosition.left => const [
      DataPointLabelPosition.left,
      DataPointLabelPosition.above,
      DataPointLabelPosition.below,
      DataPointLabelPosition.right,
    ],
    DataPointLabelPosition.right => const [
      DataPointLabelPosition.right,
      DataPointLabelPosition.above,
      DataPointLabelPosition.below,
      DataPointLabelPosition.left,
    ],
  };

  Rect _scatterLabelRect(
    ScatterPointGeometry geometry,
    Size labelSize,
    DataPointLabelPosition position,
    DataPointLabelConfig config,
  ) {
    final markerBounds = geometry.paintBounds;
    final shiftedCenter =
        geometry.center + Offset(config.offsetX, config.offsetY);
    return switch (position) {
      DataPointLabelPosition.above => Rect.fromLTWH(
        shiftedCenter.dx - labelSize.width / 2,
        markerBounds.top - config.markerGap + config.offsetY - labelSize.height,
        labelSize.width,
        labelSize.height,
      ),
      DataPointLabelPosition.below => Rect.fromLTWH(
        shiftedCenter.dx - labelSize.width / 2,
        markerBounds.bottom + config.markerGap + config.offsetY,
        labelSize.width,
        labelSize.height,
      ),
      DataPointLabelPosition.left => Rect.fromLTWH(
        markerBounds.left - config.markerGap + config.offsetX - labelSize.width,
        shiftedCenter.dy - labelSize.height / 2,
        labelSize.width,
        labelSize.height,
      ),
      DataPointLabelPosition.right => Rect.fromLTWH(
        markerBounds.right + config.markerGap + config.offsetX,
        shiftedCenter.dy - labelSize.height / 2,
        labelSize.width,
        labelSize.height,
      ),
    };
  }

  Path _buildScatterMarkerPath(
    List<ScatterPointGeometry> geometries,
    SeriesMarkerShape shape,
  ) {
    final path = Path();
    for (final geometry in geometries) {
      addScatterMarkerPath(
        path,
        center: geometry.center,
        radius: geometry.radius,
        width: geometry.width,
        height: geometry.height,
        rotationRadians: geometry.rotationRadians,
        shape: shape,
      );
    }
    return path;
  }

  void _paintScatterMarkerPath(
    Canvas canvas,
    Path path,
    _ResolvedScatterMarkerStyle style,
    Color baseColor,
    double interactionOpacity,
  ) {
    if (style.width <= 0 || style.height <= 0) return;
    final alpha = interactionOpacity * style.opacity;
    canvas.drawPath(
      path,
      Paint()
        ..color = (style.fillColor ?? baseColor).withValues(alpha: alpha)
        ..style = PaintingStyle.fill,
    );
    if (style.strokeWidth <= 0 || style.strokeColor == null) return;
    canvas.drawPath(
      path,
      Paint()
        ..color = style.strokeColor!.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = style.strokeWidth,
    );
  }

  void _paintAreaSeries(
    Canvas canvas,
    AreaChartSeries series,
    Color baseColor,
  ) {
    if (series.points.isEmpty) return;

    // PRE-TRANSFORM all points ONCE
    final transformedPoints = series.points
        .map((p) => _currentTransform.dataToPlot(p.x, p.y))
        .toList();

    // Check if any segment has style overrides
    final hasOverrides = series.points.any((p) => p.segmentStyle != null);

    // Use theme-based opacity values: selected=1.0, hovered=0.8, normal=0.7
    final opacity = isSelected
        ? 1.0
        : isHovered
        ? 0.8
        : 0.7;
    // Use theme-based stroke width with selection multiplier
    final effectiveStrokeWidth = isSelected ? strokeWidth * 1.5 : strokeWidth;

    // Baseline fill remains continuous while its outline can use per-segment
    // stroke styling. Each outline region retains full interpolation context.
    if (series.baselineValue != null) {
      _paintAreaSeriesBaseline(
        canvas,
        series,
        transformedPoints,
        baseColor,
        opacity,
        effectiveStrokeWidth,
        hasOverrides,
      );
    } else if (!hasOverrides) {
      // FAST PATH: Single color for both fill and stroke
      _paintAreaSeriesSingleColor(
        canvas,
        series,
        transformedPoints,
        baseColor,
        opacity,
        effectiveStrokeWidth,
      );
    } else {
      // STYLED PATH: Multi-color fill and stroke
      _paintAreaSeriesMultiColor(
        canvas,
        series,
        transformedPoints,
        baseColor,
        opacity,
        effectiveStrokeWidth,
      );
    }

    // Draw data point markers if enabled (reuse cached transforms!)
    if (series.showDataPointMarkers) {
      // Series-specific dataPointMarkerRadius takes precedence over theme
      final effectiveMarkerSize = series.dataPointMarkerRadius;
      // Area series doesn't do viewport culling, so indices match directly
      _paintDataPointMarkers(
        canvas,
        transformedPoints,
        null, // No culling, so local index == original index
        effectiveMarkerSize,
        baseColor,
      );
    }

    _paintSeriesInlineLabel(canvas, series, transformedPoints, baseColor);
  }

  /// Paints an area series with a single uniform color.
  void _paintAreaSeriesSingleColor(
    Canvas canvas,
    AreaChartSeries series,
    List<Offset> transformedPoints,
    Color baseColor,
    double opacity,
    double strokeWidth,
  ) {
    final path = Path();
    final firstPlot = transformedPoints.first;

    // Start from x-axis (bottom of plot area)
    path.moveTo(firstPlot.dx, _currentTransform.plotHeight);
    path.lineTo(firstPlot.dx, firstPlot.dy);

    InterpolationGeometry.addPathSegments<Offset>(
      path: path,
      points: transformedPoints,
      interpolation: series.interpolation,
      getX: (point) => point.dx,
      getY: (point) => point.dy,
      tension: series.tension,
    );

    // Close to x-axis
    final lastPlot = transformedPoints.last;
    path.lineTo(lastPlot.dx, _currentTransform.plotHeight);
    path.close();

    // Fill area
    final fillPaint = _areaFillPaint(series, baseColor);
    canvas.drawPath(path, fillPaint);

    // Draw stroke line on top
    final linePaint = Paint()
      ..color = baseColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    linePath.moveTo(transformedPoints[0].dx, transformedPoints[0].dy);

    InterpolationGeometry.addPathSegments<Offset>(
      path: linePath,
      points: transformedPoints,
      interpolation: series.interpolation,
      getX: (point) => point.dx,
      getY: (point) => point.dy,
      tension: series.tension,
    );
    final strokePath = createDashedPath(linePath, series.dashPattern);

    if (series.lineGlow > 0) {
      final glowPaint = Paint()
        ..color = baseColor.withAlpha(60)
        ..strokeWidth = strokeWidth + series.lineGlow * 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, series.lineGlow);
      canvas.drawPath(strokePath, glowPaint);
    }
    canvas.drawPath(strokePath, linePaint);
  }

  /// Paints an area series with per-segment styles for both fill and stroke.
  void _paintAreaSeriesMultiColor(
    Canvas canvas,
    AreaChartSeries series,
    List<Offset> transformedPoints,
    Color baseColor,
    double opacity,
    double strokeWidth,
  ) {
    // Analyze style regions (same logic as line charts)
    final regions = _analyzeStyleRegions(
      series.points,
      baseColor,
      strokeWidth,
      series.dashPattern,
    );

    // Draw each region's fill and stroke
    for (final region in regions) {
      // Build the fill path for this region (closed polygon to x-axis)
      final fillPath = _buildAreaRegionFillPath(
        transformedPoints,
        region.startIndex,
        region.endIndex,
        series.interpolation,
        series.tension,
      );

      // Draw fill with region color
      final fillPaint = _areaFillPaint(series, region.color);
      canvas.drawPath(fillPath, fillPaint);

      // Build stroke path for this region
      final strokePath = _buildRegionPath(
        transformedPoints,
        region.startIndex,
        region.endIndex,
        series.interpolation,
        series.tension,
      );
      final patternedStrokePath = createDashedPath(
        strokePath,
        region.dashPattern,
      );

      // Draw stroke with region color
      final strokePaint = Paint()
        ..color = region.color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = region.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      if (series.lineGlow > 0) {
        final glowPaint = Paint()
          ..color = region.color.withAlpha(60)
          ..strokeWidth = region.strokeWidth + series.lineGlow * 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, series.lineGlow);
        canvas.drawPath(patternedStrokePath, glowPaint);
      }
      canvas.drawPath(patternedStrokePath, strokePaint);
    }
  }

  Paint _areaFillPaint(AreaChartSeries series, Color fallbackColor) {
    final gradient = series.fillGradient;
    if (gradient == null) {
      return Paint()
        ..color = fallbackColor.withValues(alpha: series.fillOpacity)
        ..style = PaintingStyle.fill;
    }

    final plotBounds = Rect.fromLTWH(
      0,
      0,
      _currentTransform.plotWidth,
      _currentTransform.plotHeight,
    );
    return Paint()
      ..shader = LinearGradient(
        colors: [
          for (final color in gradient.colors)
            color.withValues(alpha: color.a * series.fillOpacity),
        ],
        stops: gradient.stops,
        begin: gradient.begin,
        end: gradient.end,
      ).createShader(plotBounds)
      ..style = PaintingStyle.fill;
  }

  /// Paints an area series filled relative to a fixed [AreaChartSeries.baselineValue].
  ///
  /// Builds one area path from the exact same interpolation geometry as the
  /// stroke, then paints it through clips above and below the baseline. This
  /// keeps curved fills aligned with their stroke without approximating curve
  /// crossings or recalculating tangents for partial point lists.
  ///
  /// [AreaChartSeries.aboveBaselineFillColor] and
  /// [AreaChartSeries.belowBaselineFillColor] fall back to the series colour at
  /// [AreaChartSeries.fillOpacity] when null. The series stroke is drawn on top,
  /// identical to the single-colour path.
  void _paintAreaSeriesBaseline(
    Canvas canvas,
    AreaChartSeries series,
    List<Offset> transformedPoints,
    Color baseColor,
    double opacity,
    double strokeWidth,
    bool hasSegmentOverrides,
  ) {
    final baselineY = _currentTransform
        .dataToPlot(0, series.baselineValue!)
        .dy; // X is arbitrary; only .dy is used

    final aboveColor =
        series.aboveBaselineFillColor ??
        baseColor.withValues(alpha: series.fillOpacity);
    final belowColor =
        series.belowBaselineFillColor ??
        baseColor.withValues(alpha: series.fillOpacity);

    final first = transformedPoints.first;
    final last = transformedPoints.last;
    final fillPath = Path()
      ..fillType = PathFillType.evenOdd
      ..moveTo(first.dx, baselineY)
      ..lineTo(first.dx, first.dy);
    InterpolationGeometry.addPathSegments<Offset>(
      path: fillPath,
      points: transformedPoints,
      interpolation: series.interpolation,
      getX: (point) => point.dx,
      getY: (point) => point.dy,
      tension: series.tension,
    );
    fillPath
      ..lineTo(last.dx, baselineY)
      ..close();

    final plotWidth = _currentTransform.plotWidth;
    final plotHeight = _currentTransform.plotHeight;
    final clippedBaselineY = baselineY.clamp(0.0, plotHeight).toDouble();

    void paintClippedFill(Color color, Rect clip) {
      if (clip.isEmpty) return;
      canvas.save();
      canvas.clipRect(clip, doAntiAlias: false);
      canvas.drawPath(
        fillPath,
        Paint()
          ..color = color
          ..style = PaintingStyle.fill,
      );
      canvas.restore();
    }

    if (clippedBaselineY > 0) {
      paintClippedFill(
        aboveColor,
        Rect.fromLTRB(0, 0, plotWidth, clippedBaselineY),
      );
    }
    if (clippedBaselineY < plotHeight) {
      paintClippedFill(
        belowColor,
        Rect.fromLTRB(0, clippedBaselineY, plotWidth, plotHeight),
      );
    }

    // Preserve the original single-path fast path for ordinary baseline Area
    // series. Segment-region analysis is only paid for when it is requested.
    if (!hasSegmentOverrides) {
      final linePath = Path()
        ..moveTo(transformedPoints.first.dx, transformedPoints.first.dy);
      InterpolationGeometry.addPathSegments<Offset>(
        path: linePath,
        points: transformedPoints,
        interpolation: series.interpolation,
        getX: (point) => point.dx,
        getY: (point) => point.dy,
        tension: series.tension,
      );
      _paintAreaStrokePath(
        canvas,
        path: linePath,
        color: baseColor,
        opacity: opacity,
        strokeWidth: strokeWidth,
        lineGlow: series.lineGlow,
        dashPattern: series.dashPattern,
      );
      return;
    }

    // Styled region paths are derived from the full point list so
    // interpolation tangents remain continuous at style changes.
    final regions = _analyzeStyleRegions(
      series.points,
      baseColor,
      strokeWidth,
      series.dashPattern,
    );
    for (final region in regions) {
      final linePath = _buildRegionPath(
        transformedPoints,
        region.startIndex,
        region.endIndex,
        series.interpolation,
        series.tension,
      );
      _paintAreaStrokePath(
        canvas,
        path: linePath,
        color: region.color,
        opacity: opacity,
        strokeWidth: region.strokeWidth,
        lineGlow: series.lineGlow,
        dashPattern: region.dashPattern,
      );
    }
  }

  void _paintAreaStrokePath(
    Canvas canvas, {
    required Path path,
    required Color color,
    required double opacity,
    required double strokeWidth,
    required double lineGlow,
    required List<double> dashPattern,
  }) {
    final strokePath = createDashedPath(path, dashPattern);
    if (lineGlow > 0) {
      canvas.drawPath(
        strokePath,
        Paint()
          ..color = color.withAlpha(60)
          ..strokeWidth = strokeWidth + lineGlow * 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, lineGlow),
      );
    }
    canvas.drawPath(
      strokePath,
      Paint()
        ..color = color.withValues(alpha: opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  /// Builds a closed fill path for an area region (line segment + down to x-axis).
  Path _buildAreaRegionFillPath(
    List<Offset> transformedPoints,
    int startIndex,
    int endIndex,
    LineInterpolation interpolation,
    double tension,
  ) {
    final path = Path();
    final startPoint = transformedPoints[startIndex];
    final endPoint = transformedPoints[endIndex];
    final xAxisY = _currentTransform.plotHeight;

    // Start from x-axis at the start point's X
    path.moveTo(startPoint.dx, xAxisY);

    // Go up to the start point
    path.lineTo(startPoint.dx, startPoint.dy);

    InterpolationGeometry.addPathSegments<Offset>(
      path: path,
      points: transformedPoints,
      interpolation: interpolation,
      getX: (point) => point.dx,
      getY: (point) => point.dy,
      startIndex: startIndex + 1,
      endIndex: endIndex,
      tension: tension,
    );

    // Go down to x-axis at the end point's X
    path.lineTo(endPoint.dx, xAxisY);

    // Close back to start
    path.close();

    return path;
  }

  void _paintBarSeries(Canvas canvas, BarChartSeries series, Color baseColor) {
    final opacity = series.barStyle.opacity;
    final track = series.trackStyle;
    final geometries = _resolveBarGeometries();

    if (series.layoutMode == BarLayoutMode.divergingStacked &&
        barGroupInfo?.drawTrack != false) {
      _paintDivergingCenterLine(canvas, series);
    }

    if (series.layoutMode == BarLayoutMode.waterfall) {
      _paintWaterfallConnectors(canvas, series, geometries, opacity);
    }

    for (final geometry in geometries) {
      final bullet = series.bulletStyle;
      if (bullet != null) {
        BarBulletPainter.paint(
          canvas: canvas,
          geometry: geometry,
          transform: _currentTransform,
          style: bullet,
        );
      }

      if (track != null && geometry.trackRRect != null) {
        final trackPaint = Paint()
          ..color = track.color.withValues(alpha: track.opacity)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(geometry.trackRRect!, trackPaint);
        final trackBorder = track.border;
        if (trackBorder != null && trackBorder.width > 0) {
          canvas.drawRRect(
            geometry.trackRRect!,
            Paint()
              ..color = trackBorder.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = trackBorder.width,
          );
        }
      }

      final waterfallColor = _waterfallColor(series, geometry);
      final barColor = _resolvedBarColor(series, geometry, baseColor);
      final pointOpacity =
          opacity *
          (hasAnySelectedPoints &&
                  !selectedPointIndices.contains(geometry.pointIndex)
              ? series.barStyle.interaction.dimmedOpacity
              : 1.0);
      final lollipop = series.lollipopStyle;
      if (lollipop != null &&
          geometry.lollipopStemStart != null &&
          geometry.lollipopStemEnd != null &&
          geometry.lollipopHeadCenter != null) {
        final stemColor = lollipop.stemColor ?? barColor;
        final headColor = lollipop.headColor ?? barColor;
        canvas.drawLine(
          geometry.lollipopStemStart!,
          geometry.lollipopStemEnd!,
          Paint()
            ..color = stemColor.withValues(alpha: pointOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = lollipop.stemWidth
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          geometry.lollipopHeadCenter!,
          lollipop.headRadius,
          Paint()
            ..color = headColor.withValues(alpha: pointOpacity)
            ..style = PaintingStyle.fill,
        );
        final headBorder = lollipop.headBorder ?? series.barStyle.border;
        if (headBorder != null && headBorder.width > 0) {
          canvas.drawCircle(
            geometry.lollipopHeadCenter!,
            lollipop.headRadius,
            Paint()
              ..color = headBorder.color.withValues(alpha: pointOpacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = headBorder.width,
          );
        }
      } else {
        final gradient =
            geometry.point.pointStyle?.color == null && waterfallColor == null
            ? series.barStyle.gradient
            : null;
        final barPaint = Paint()..style = PaintingStyle.fill;
        if (gradient != null &&
            gradient.colors.length >= 2 &&
            (gradient.stops == null ||
                gradient.stops!.length == gradient.colors.length)) {
          barPaint.shader = Gradient.linear(
            geometry.orientation == BarOrientation.horizontal
                ? Offset(geometry.baselineX, geometry.rect.center.dy)
                : Offset(geometry.rect.center.dx, geometry.baselineY),
            geometry.valueEndPoint,
            [
              for (final color in gradient.colors)
                color.withValues(alpha: pointOpacity),
            ],
            gradient.stops,
          );
        } else {
          barPaint.color = barColor.withValues(alpha: pointOpacity);
        }
        canvas.drawRRect(geometry.rrect, barPaint);

        final pattern = series.barStyle.pattern;
        if (pattern != null) {
          BarPatternPainter.paint(
            canvas: canvas,
            clip: geometry.rrect,
            style: pattern,
            baseColor: barColor,
            opacityMultiplier: pointOpacity,
          );
        }

        final border = series.barStyle.border;
        if (border != null && border.width > 0) {
          canvas.drawRRect(
            geometry.rrect,
            Paint()
              ..color = border.color.withValues(alpha: pointOpacity)
              ..style = PaintingStyle.stroke
              ..strokeWidth = border.width,
          );
        }
      }

      if (geometry.targetStart != null && geometry.targetEnd != null) {
        final targetStyle = series.targetMarkerStyle;
        final targetColor =
            targetStyle.color ??
            (barColor.computeLuminance() > 0.45
                ? const Color(0xFF111827)
                : const Color(0xFFFFFFFF));
        canvas.drawLine(
          geometry.targetStart!,
          geometry.targetEnd!,
          Paint()
            ..color = targetColor.withValues(alpha: targetStyle.opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = targetStyle.width
            ..strokeCap = StrokeCap.square,
        );
      }

      if (geometry.errorStemStart != null &&
          geometry.errorStemEnd != null &&
          geometry.errorLowerCapStart != null &&
          geometry.errorLowerCapEnd != null &&
          geometry.errorUpperCapStart != null &&
          geometry.errorUpperCapEnd != null) {
        final errorStyle = series.errorBarStyle;
        final errorColor = errorStyle.color ?? const Color(0xFF111827);
        final errorPaint = Paint()
          ..color = errorColor.withValues(alpha: errorStyle.opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = errorStyle.width
          ..strokeCap = StrokeCap.square;
        final segments = <(Offset, Offset)>[
          (geometry.errorStemStart!, geometry.errorStemEnd!),
          (geometry.errorLowerCapStart!, geometry.errorLowerCapEnd!),
          (geometry.errorUpperCapStart!, geometry.errorUpperCapEnd!),
        ];
        if (errorStyle.color == null) {
          final haloPaint = Paint()
            ..color = const Color(
              0xFFFFFFFF,
            ).withValues(alpha: errorStyle.opacity * 0.9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = errorStyle.width + 2
            ..strokeCap = StrokeCap.square;
          for (final (start, end) in segments) {
            canvas.drawLine(start, end, haloPaint);
          }
        }
        for (final (start, end) in segments) {
          canvas.drawLine(start, end, errorPaint);
        }
      }

      if (series.labelStyle.show) {
        _paintBarLabel(canvas, series, geometry, barColor);
      }
      if (series.labelStyle.showStackTotal &&
          barGroupInfo?.isStacked == true &&
          barGroupInfo!.isOuterPoint(geometry.pointIndex)) {
        _paintBarStackTotal(canvas, series, geometry, barColor);
      }
    }
  }

  void _paintDivergingCenterLine(Canvas canvas, BarChartSeries series) {
    final style = series.divergingStyle;
    if (!style.showCenterLine || style.centerLineWidth <= 0) return;
    final transform = _currentTransform.copyWith(
      transposed: series.orientation == BarOrientation.horizontal,
    );
    final baseline = transform.dataToPlot(0, series.baselineValue);
    final paint = Paint()
      ..color = style.centerLineColor.withValues(alpha: style.centerLineOpacity)
      ..strokeWidth = style.centerLineWidth
      ..style = PaintingStyle.stroke;
    if (series.orientation == BarOrientation.horizontal) {
      canvas.drawLine(
        Offset(baseline.dx, 0),
        Offset(baseline.dx, transform.plotHeight),
        paint,
      );
    } else {
      canvas.drawLine(
        Offset(0, baseline.dy),
        Offset(transform.plotWidth, baseline.dy),
        paint,
      );
    }
  }

  Color _resolvedBarColor(
    BarChartSeries series,
    BarGeometry geometry,
    Color baseColor,
  ) =>
      geometry.point.pointStyle?.color ??
      _waterfallColor(series, geometry) ??
      baseColor;

  Color? _waterfallColor(BarChartSeries series, BarGeometry geometry) {
    if (series.layoutMode != BarLayoutMode.waterfall) return null;
    final style = series.waterfallStyle;
    if (series.isWaterfallTotal(geometry.pointIndex)) {
      return style.totalColor;
    }
    return geometry.endValue >= geometry.startValue
        ? style.increaseColor
        : style.decreaseColor;
  }

  void _paintWaterfallConnectors(
    Canvas canvas,
    BarChartSeries series,
    List<BarGeometry> geometries,
    double opacity,
  ) {
    final connector = series.waterfallStyle.connector;
    if (!connector.show || connector.width <= 0 || geometries.length < 2) {
      return;
    }
    final paint = Paint()
      ..color = connector.color.withValues(alpha: opacity)
      ..strokeWidth = connector.width
      ..style = PaintingStyle.stroke;
    for (var index = 0; index < geometries.length - 1; index++) {
      final current = geometries[index];
      final next = geometries[index + 1];
      if (series.orientation == BarOrientation.horizontal) {
        canvas.drawLine(
          Offset(current.valueEndX, current.rect.bottom),
          Offset(current.valueEndX, next.rect.top),
          paint,
        );
      } else {
        canvas.drawLine(
          Offset(current.rect.right, current.valueEndY),
          Offset(next.rect.left, current.valueEndY),
          paint,
        );
      }
    }
  }

  void _paintBarLabel(
    Canvas canvas,
    BarChartSeries series,
    BarGeometry geometry,
    Color barColor,
  ) {
    final config = series.labelStyle;
    if (config.position == BarLabelPosition.rangeEnds) {
      _paintBarRangeEndLabels(canvas, series, geometry, barColor);
      return;
    }

    final text =
        config.formatter?.call(geometry.point) ??
        switch (config.valueMode) {
          BarLabelValueMode.value => DataPointLabelConfig.autoFormatLabelValue(
            geometry.point.y,
            config.showUnit ? series.unit : null,
          ),
          BarLabelValueMode.range =>
            '${DataPointLabelConfig.autoFormatLabelValue(geometry.startValue, null)}–'
                '${DataPointLabelConfig.autoFormatLabelValue(geometry.endValue, config.showUnit ? series.unit : null)}',
          BarLabelValueMode.percentage =>
            DataPointLabelConfig.autoFormatLabelValue(
              geometry.percentage ?? geometry.point.y,
              '%',
            ),
          BarLabelValueMode.waterfall =>
            DataPointLabelConfig.autoFormatLabelValue(
              series.isWaterfallTotal(geometry.pointIndex)
                  ? geometry.endValue
                  : geometry.endValue - geometry.startValue,
              config.showUnit ? series.unit : null,
            ),
        };

    final provisionalPainter = _barLabelPainter(
      text,
      config.color ?? barColor,
      config.fontSize,
      config.fontWeight,
    );
    final insideEndOffset = _barLabelInsideEndOffset(series, geometry);
    final fitsInside =
        series.lollipopStyle == null &&
        (series.orientation == BarOrientation.horizontal
            ? geometry.rect.height >= provisionalPainter.height + 4 &&
                  geometry.rect.width >=
                      provisionalPainter.width + insideEndOffset * 2
            : geometry.rect.height >=
                      provisionalPainter.height + insideEndOffset * 2 &&
                  geometry.rect.width >= provisionalPainter.width + 4);
    final positions = switch (config.position) {
      BarLabelPosition.auto =>
        fitsInside
            ? const [
                BarLabelPosition.insideEnd,
                BarLabelPosition.outsideEnd,
                BarLabelPosition.insideCenter,
              ]
            : const [
                BarLabelPosition.outsideEnd,
                BarLabelPosition.insideEnd,
                BarLabelPosition.insideCenter,
              ],
      BarLabelPosition.insideEnd => const [
        BarLabelPosition.insideEnd,
        BarLabelPosition.outsideEnd,
      ],
      BarLabelPosition.insideCenter => const [
        BarLabelPosition.insideCenter,
        BarLabelPosition.insideEnd,
      ],
      BarLabelPosition.outsideEnd => const [
        BarLabelPosition.outsideEnd,
        BarLabelPosition.insideEnd,
      ],
      BarLabelPosition.rangeEnds => const [BarLabelPosition.outsideEnd],
    };
    _layoutAndPaintBarLabel(
      canvas: canvas,
      series: series,
      geometry: geometry,
      text: text,
      barColor: barColor,
      positions: positions,
    );
  }

  void _paintBarStackTotal(
    Canvas canvas,
    BarChartSeries series,
    BarGeometry geometry,
    Color barColor,
  ) {
    final config = series.labelStyle;
    final unit =
        series.layoutMode == BarLayoutMode.normalizedStacked ||
            series.layoutMode == BarLayoutMode.divergingStacked
        ? '%'
        : config.showUnit
        ? series.unit
        : null;
    final text =
        config.formatter?.call(geometry.point.copyWith(y: geometry.endValue)) ??
        DataPointLabelConfig.autoFormatLabelValue(geometry.endValue, unit);
    _layoutAndPaintBarLabel(
      canvas: canvas,
      series: series,
      geometry: geometry,
      text: text,
      barColor: barColor,
      positions: const [
        BarLabelPosition.outsideEnd,
        BarLabelPosition.insideEnd,
      ],
    );
  }

  void _layoutAndPaintBarLabel({
    required Canvas canvas,
    required BarChartSeries series,
    required BarGeometry geometry,
    required String text,
    required Color barColor,
    required List<BarLabelPosition> positions,
  }) {
    final config = series.labelStyle;
    final provisionalPainter = _barLabelPainter(
      text,
      config.color ?? barColor,
      config.fontSize,
      config.fontWeight,
    );
    final hasContainer =
        config.backgroundColor != null ||
        config.borderColor != null && config.borderWidth > 0;
    final boxPadding = hasContainer ? config.backgroundPadding : 0.0;
    final boxSize = Size(
      provisionalPainter.width + boxPadding * 2,
      provisionalPainter.height + boxPadding * 2,
    );
    final candidates = [
      for (final position in positions)
        _barLabelRect(series, geometry, position, boxSize),
    ];
    final displacementDirection = _barLabelDisplacementDirection(
      series,
      geometry,
    );
    final result = _barLabelLayoutCoordinator?.place(
      candidates: candidates,
      collisionPolicy: config.collisionPolicy,
      plotEdgeAware: config.plotEdgeAware,
      collisionPadding: config.collisionPadding,
      displacementDirection: displacementDirection,
      displacementStep:
          (series.orientation == BarOrientation.horizontal
              ? boxSize.width
              : boxSize.height) +
          config.collisionPadding,
    );
    if (_barLabelLayoutCoordinator != null && result == null) return;
    final labelRect = result?.rect ?? candidates.first;
    final isInside = geometry.rect.contains(labelRect.center);
    final labelColor =
        config.color ??
        (config.backgroundColor != null
            ? (config.backgroundColor!.computeLuminance() > 0.45
                  ? const Color(0xFF1F2937)
                  : const Color(0xFFFFFFFF))
            : isInside
            ? (barColor.computeLuminance() > 0.45
                  ? const Color(0xFF1A1A1A)
                  : const Color(0xFFFFFFFF))
            : barColor);
    final painter = _barLabelPainter(
      text,
      labelColor,
      config.fontSize,
      config.fontWeight,
    );

    _paintBarLabelCallout(canvas, geometry, labelRect, labelColor, config);
    _paintBarLabelContainer(canvas, labelRect, config);
    painter.paint(canvas, labelRect.topLeft + Offset(boxPadding, boxPadding));
  }

  Rect _barLabelRect(
    BarChartSeries series,
    BarGeometry geometry,
    BarLabelPosition position,
    Size labelSize,
  ) {
    if (position == BarLabelPosition.outsideEnd ||
        position == BarLabelPosition.rangeEnds ||
        position == BarLabelPosition.auto) {
      return resolveBarOutsideEndLabelRect(
        geometry: geometry,
        labelSize: labelSize,
        padding: series.labelStyle.padding,
      );
    }

    final insideEndOffset = _barLabelInsideEndOffset(series, geometry);
    if (series.orientation == BarOrientation.horizontal) {
      final valueEndIsRight = geometry.valueEndX >= geometry.baselineX;
      final x = switch (position) {
        BarLabelPosition.insideCenter =>
          geometry.rect.center.dx - labelSize.width / 2,
        BarLabelPosition.insideEnd =>
          valueEndIsRight
              ? geometry.rect.right - insideEndOffset - labelSize.width
              : geometry.rect.left + insideEndOffset,
        BarLabelPosition.outsideEnd ||
        BarLabelPosition.rangeEnds ||
        BarLabelPosition.auto => throw StateError('Handled above'),
      };
      return Rect.fromLTWH(
        x,
        geometry.rect.center.dy - labelSize.height / 2,
        labelSize.width,
        labelSize.height,
      );
    }

    final valueEndIsTop = geometry.valueEndY <= geometry.baselineY;
    final y = switch (position) {
      BarLabelPosition.insideCenter =>
        geometry.rect.center.dy - labelSize.height / 2,
      BarLabelPosition.insideEnd =>
        valueEndIsTop
            ? geometry.rect.top + insideEndOffset
            : geometry.rect.bottom - insideEndOffset - labelSize.height,
      BarLabelPosition.outsideEnd ||
      BarLabelPosition.rangeEnds ||
      BarLabelPosition.auto => throw StateError('Handled above'),
    };
    return Rect.fromLTWH(
      geometry.rect.center.dx - labelSize.width / 2,
      y,
      labelSize.width,
      labelSize.height,
    );
  }

  Offset _barLabelDisplacementDirection(
    BarChartSeries series,
    BarGeometry geometry,
  ) {
    if (series.orientation == BarOrientation.horizontal) {
      return geometry.valueEndX >= geometry.baselineX
          ? const Offset(-1, 0)
          : const Offset(1, 0);
    }
    return geometry.valueEndY <= geometry.baselineY
        ? const Offset(0, 1)
        : const Offset(0, -1);
  }

  void _paintBarLabelContainer(Canvas canvas, Rect rect, BarLabelStyle config) {
    if (config.backgroundColor == null &&
        (config.borderColor == null || config.borderWidth <= 0)) {
      return;
    }
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(config.borderRadius),
    );
    if (config.backgroundColor case final background?) {
      canvas.drawRRect(rrect, Paint()..color = background);
    }
    if (config.borderColor case final border? when config.borderWidth > 0) {
      canvas.drawRRect(
        rrect,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = config.borderWidth,
      );
    }
  }

  void _paintBarLabelCallout(
    Canvas canvas,
    BarGeometry geometry,
    Rect labelRect,
    Color labelColor,
    BarLabelStyle config, {
    Offset? anchor,
  }) {
    final callout = config.callout;
    if (!callout.show || geometry.rect.contains(labelRect.center)) return;
    final resolvedAnchor = anchor ?? geometry.valueEndPoint;
    final target = Offset(
      resolvedAnchor.dx.clamp(labelRect.left, labelRect.right),
      resolvedAnchor.dy.clamp(labelRect.top, labelRect.bottom),
    );
    if ((target - resolvedAnchor).distance < callout.minimumLength) return;
    canvas.drawLine(
      resolvedAnchor,
      target,
      Paint()
        ..color = callout.color ?? labelColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = callout.width,
    );
  }

  double _barLabelInsideEndOffset(BarChartSeries series, BarGeometry geometry) {
    final clampedRadius = math.min(
      series.barStyle.cornerRadius,
      math.min(geometry.rect.width, geometry.rect.height) / 2,
    );
    final roundedEndInset = math.min(clampedRadius, 8.0);
    return math.max(series.labelStyle.padding, roundedEndInset);
  }

  void _paintBarRangeEndLabels(
    Canvas canvas,
    BarChartSeries series,
    BarGeometry geometry,
    Color barColor,
  ) {
    final config = series.labelStyle;
    final lowerValue = math.min(geometry.startValue, geometry.endValue);
    final upperValue = math.max(geometry.startValue, geometry.endValue);
    final unit = config.showUnit ? series.unit : null;
    final labelColor = config.color ?? barColor;

    if (series.orientation == BarOrientation.horizontal) {
      _paintBarHorizontalRangeEndpointLabel(
        canvas,
        geometry: geometry,
        value: lowerValue,
        unit: unit,
        color: labelColor,
        placeAtStart: true,
        config: config,
      );
      _paintBarHorizontalRangeEndpointLabel(
        canvas,
        geometry: geometry,
        value: upperValue,
        unit: unit,
        color: labelColor,
        placeAtStart: false,
        config: config,
      );
      return;
    }

    _paintBarRangeEndpointLabel(
      canvas,
      geometry: geometry,
      value: upperValue,
      unit: unit,
      color: labelColor,
      placeAbove: true,
      config: config,
    );
    _paintBarRangeEndpointLabel(
      canvas,
      geometry: geometry,
      value: lowerValue,
      unit: unit,
      color: labelColor,
      placeAbove: false,
      config: config,
    );
  }

  void _paintBarHorizontalRangeEndpointLabel(
    Canvas canvas, {
    required BarGeometry geometry,
    required double value,
    required String? unit,
    required Color color,
    required bool placeAtStart,
    required BarLabelStyle config,
  }) {
    final text =
        config.formatter?.call(geometry.point.copyWith(y: value)) ??
        DataPointLabelConfig.autoFormatLabelValue(value, unit);
    final painter = _barLabelPainter(
      text,
      color,
      config.fontSize,
      config.fontWeight,
    );
    final padding = _barLabelBoxPadding(config);
    final size = Size(
      painter.width + padding * 2,
      painter.height + padding * 2,
    );
    final outsideX = placeAtStart
        ? geometry.rect.left - config.padding - size.width
        : geometry.rect.right + config.padding;
    final insideX = placeAtStart
        ? geometry.rect.left + config.padding
        : geometry.rect.right - config.padding - size.width;
    _paintBarRangeLabelBox(
      canvas: canvas,
      geometry: geometry,
      painter: painter,
      color: color,
      config: config,
      padding: padding,
      candidates: [
        Rect.fromLTWH(
          outsideX,
          geometry.rect.center.dy - size.height / 2,
          size.width,
          size.height,
        ),
        Rect.fromLTWH(
          insideX,
          geometry.rect.center.dy - size.height / 2,
          size.width,
          size.height,
        ),
      ],
      anchor: placeAtStart
          ? geometry.rect.centerLeft
          : geometry.rect.centerRight,
      displacementDirection: const Offset(0, 1),
    );
  }

  void _paintBarRangeEndpointLabel(
    Canvas canvas, {
    required BarGeometry geometry,
    required double value,
    required String? unit,
    required Color color,
    required bool placeAbove,
    required BarLabelStyle config,
  }) {
    final customText = config.formatter?.call(
      geometry.point.copyWith(y: value),
    );
    final valueText =
        customText ?? DataPointLabelConfig.autoFormatLabelValue(value, null);
    final horizontalText =
        customText ?? DataPointLabelConfig.autoFormatLabelValue(value, unit);
    final horizontalPainter = _barLabelPainter(
      horizontalText,
      color,
      config.fontSize,
      config.fontWeight,
      textAlign: TextAlign.center,
    );
    var painter = horizontalPainter;

    // Adjacent grouped bars are centred one bar width plus one gap apart.
    // Use that distance as the collision budget. A lone bar can use the wider
    // category space and therefore does not need a compact fallback.
    final groupInfo = barGroupInfo;
    final availableWidth = groupInfo != null && groupInfo.count > 1
        ? math.max(1.0, geometry.rect.width + groupInfo.gap - 2.0)
        : double.infinity;

    if (painter.width > availableWidth &&
        customText == null &&
        unit != null &&
        unit.isNotEmpty) {
      painter = _barLabelPainter(
        '$valueText\n$unit',
        color,
        config.fontSize,
        config.fontWeight,
        textAlign: TextAlign.center,
      );
    }

    final rotate = painter.width > availableWidth;
    if (rotate) painter = horizontalPainter;
    final centerX = geometry.rect.center.dx;
    final boxPadding = _barLabelBoxPadding(config);
    final visualSize = rotate
        ? Size(painter.height + boxPadding * 2, painter.width + boxPadding * 2)
        : Size(painter.width + boxPadding * 2, painter.height + boxPadding * 2);
    final outsideY = placeAbove
        ? geometry.rect.top - config.padding - visualSize.height
        : geometry.rect.bottom + config.padding;
    final insideY = placeAbove
        ? geometry.rect.top + config.padding
        : geometry.rect.bottom - config.padding - visualSize.height;
    _paintBarRangeLabelBox(
      canvas: canvas,
      geometry: geometry,
      painter: painter,
      color: color,
      config: config,
      padding: boxPadding,
      candidates: [
        Rect.fromLTWH(
          centerX - visualSize.width / 2,
          outsideY,
          visualSize.width,
          visualSize.height,
        ),
        Rect.fromLTWH(
          centerX - visualSize.width / 2,
          insideY,
          visualSize.width,
          visualSize.height,
        ),
      ],
      anchor: placeAbove ? geometry.rect.topCenter : geometry.rect.bottomCenter,
      displacementDirection: const Offset(1, 0),
      rotate: rotate,
    );
  }

  double _barLabelBoxPadding(BarLabelStyle config) =>
      config.backgroundColor != null ||
          config.borderColor != null && config.borderWidth > 0
      ? config.backgroundPadding
      : 0;

  void _paintBarRangeLabelBox({
    required Canvas canvas,
    required BarGeometry geometry,
    required TextPainter painter,
    required Color color,
    required BarLabelStyle config,
    required double padding,
    required List<Rect> candidates,
    required Offset anchor,
    required Offset displacementDirection,
    bool rotate = false,
  }) {
    final result = _barLabelLayoutCoordinator?.place(
      candidates: candidates,
      collisionPolicy: config.collisionPolicy,
      plotEdgeAware: config.plotEdgeAware,
      collisionPadding: config.collisionPadding,
      displacementDirection: displacementDirection,
      displacementStep:
          (rotate ? painter.height : painter.width) + config.collisionPadding,
    );
    if (_barLabelLayoutCoordinator != null && result == null) return;
    final rect = result?.rect ?? candidates.first;
    _paintBarLabelCallout(
      canvas,
      geometry,
      rect,
      color,
      config,
      anchor: anchor,
    );
    _paintBarLabelContainer(canvas, rect, config);
    if (!rotate) {
      painter.paint(canvas, rect.topLeft + Offset(padding, padding));
      return;
    }
    canvas.save();
    canvas.translate(rect.left + padding + painter.height, rect.top + padding);
    canvas.rotate(math.pi / 2);
    painter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  TextPainter _barLabelPainter(
    String text,
    Color color,
    double fontSize,
    FontWeight fontWeight, {
    TextAlign textAlign = TextAlign.left,
  }) {
    final key =
        'bar:$text:${color.toARGB32()}:$fontSize:${fontWeight.index}:${textAlign.name}';
    return _labelPainterCache.putIfAbsent(key, () {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: fontWeight,
          ),
        ),
        textDirection: textDirection,
        textAlign: textAlign,
      );
      painter.layout();
      return painter;
    });
  }

  /// Renders a single data-point label near its marker.
  ///
  /// Anchor positions (spec table):
  /// - above: centre-bottom anchor at (cx+offsetX, cy-r-gap+offsetY)
  /// - below: centre-top anchor at (cx+offsetX, cy+r+gap+offsetY)
  /// - left:  right-centre anchor at (cx-r-gap+offsetX, cy+offsetY)
  /// - right: left-centre anchor at (cx+r+gap+offsetX, cy+offsetY)
  // Returns the resolved TextPainter and top-left paint origin for a label.
  // Called from both the background pass and the text pass — cache ensures
  // layout() runs only once per unique string.
  (TextPainter, Offset) _resolveLabelLayout(
    Offset markerCenter,
    double markerRadius,
    ChartDataPoint point,
    Color seriesColor,
    DataPointLabelConfig config,
    String? unit,
  ) {
    final text = config.formatter != null
        ? config.formatter!(point)
        : DataPointLabelConfig.autoFormatLabelValue(
            point.y,
            config.showUnit ? unit : null,
          );

    final tp = _labelPainterCache.putIfAbsent(text, () {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: config.labelColor ?? seriesColor,
            fontSize: config.fontSize,
            fontWeight: config.fontWeight,
            fontFamily: fontFamily,
          ),
        ),
        textDirection: textDirection,
        textAlign: TextAlign.left,
      );
      painter.layout();
      return painter;
    });

    const gap = 2.0;
    final double paintX;
    final double paintY;
    switch (config.position) {
      case DataPointLabelPosition.above:
        paintX = markerCenter.dx + config.offsetX - tp.width / 2;
        paintY =
            markerCenter.dy - markerRadius - gap + config.offsetY - tp.height;
        break;
      case DataPointLabelPosition.below:
        paintX = markerCenter.dx + config.offsetX - tp.width / 2;
        paintY = markerCenter.dy + markerRadius + gap + config.offsetY;
        break;
      case DataPointLabelPosition.left:
        paintX =
            markerCenter.dx - markerRadius - gap + config.offsetX - tp.width;
        paintY = markerCenter.dy + config.offsetY - tp.height / 2;
        break;
      case DataPointLabelPosition.right:
        paintX = markerCenter.dx + markerRadius + gap + config.offsetX;
        paintY = markerCenter.dy + config.offsetY - tp.height / 2;
        break;
    }
    return (tp, Offset(paintX, paintY));
  }

  void _paintDataPointLabelBackground(
    Canvas canvas,
    Offset markerCenter,
    double markerRadius,
    ChartDataPoint point,
    Color seriesColor,
    DataPointLabelConfig config,
    String? unit,
  ) {
    if (config.background == null) return;
    final (tp, paintOrigin) = _resolveLabelLayout(
      markerCenter,
      markerRadius,
      point,
      seriesColor,
      config,
      unit,
    );
    const hPad = 4.0;
    const vPad = 2.0;
    final bgRect = Rect.fromLTWH(
      paintOrigin.dx - hPad,
      paintOrigin.dy - vPad,
      tp.width + hPad * 2,
      tp.height + vPad * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        bgRect,
        Radius.circular((tp.height + vPad * 2) / 2),
      ),
      Paint()
        ..color = config.background!.withValues(
          alpha: config.backgroundOpacity,
        ),
    );
  }

  void _paintDataPointLabelText(
    Canvas canvas,
    Offset markerCenter,
    double markerRadius,
    ChartDataPoint point,
    Color seriesColor,
    DataPointLabelConfig config,
    String? unit,
  ) {
    final (tp, paintOrigin) = _resolveLabelLayout(
      markerCenter,
      markerRadius,
      point,
      seriesColor,
      config,
      unit,
    );
    tp.paint(canvas, paintOrigin);
  }

  /// Paint markers using PRE-TRANSFORMED points (no redundant dataToPlot calls!)
  ///
  /// [originalIndices] maps each position in [transformedPoints] to its original
  /// index in [series.points]. This is required for correct hover matching when
  /// zoomed/panned (viewport culling changes visible point indices).
  void _paintDataPointMarkers(
    Canvas canvas,
    List<Offset> transformedPoints,
    List<int>? originalIndices,
    double radius,
    Color baseColor,
  ) {
    final hoveredMarker = coordinator?.hoveredMarker;
    final isThisSeriesHovered = hoveredMarker?.seriesId == series.id;

    // Resolve label config once — null or show==false means zero-cost skip
    final DataPointLabelConfig? labelConfig = switch (series) {
      final LineChartSeries s => s.dataPointLabels,
      final AreaChartSeries s => s.dataPointLabels,
      _ => null,
    };
    final bool paintLabels = labelConfig != null && labelConfig.show;

    final markerStyle = switch (series) {
      final LineChartSeries s => s.dataPointMarkerStyle,
      final AreaChartSeries s => s.dataPointMarkerStyle,
      _ => DataPointMarkerStyle.filled,
    };
    final isHollow = markerStyle == DataPointMarkerStyle.hollow;

    final hollowFillColor = switch (series) {
      final LineChartSeries s => s.dataPointMarkerBackground,
      final AreaChartSeries s => s.dataPointMarkerBackground,
      _ => const Color(0xFFFFFFFF),
    };

    final maskPaint = Paint()
      ..color = hollowFillColor
      ..style = PaintingStyle.fill;

    final normalPaint = Paint()
      ..color = baseColor
      ..style = isHollow ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = 2.0;

    final hoverPaint = Paint()
      ..color = baseColor
      ..style = isHollow ? PaintingStyle.stroke : PaintingStyle.fill
      ..strokeWidth = 2.0;

    final borderPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    // Pass 1: background pills — drawn first so markers appear on top of them.
    if (paintLabels && labelConfig.background != null) {
      for (int i = 0; i < transformedPoints.length; i++) {
        final originalIndex = originalIndices?[i] ?? i;
        if (originalIndex < series.points.length) {
          _paintDataPointLabelBackground(
            canvas,
            transformedPoints[i],
            radius,
            series.points[originalIndex],
            baseColor,
            labelConfig,
            series.unit,
          );
        }
      }
    }

    // Pass 2: marker circles — always on top of background pills.
    for (int i = 0; i < transformedPoints.length; i++) {
      final plotPos = transformedPoints[i];
      final originalIndex = originalIndices?[i] ?? i;
      final targetIndex = _targetIndexForRenderIndex(originalIndex);
      if (isThisSeriesHovered && targetIndex == hoveredMarker!.markerIndex) {
        if (isHollow) canvas.drawCircle(plotPos, radius * 1.5, maskPaint);
        canvas.drawCircle(plotPos, radius * 1.5, hoverPaint);
        if (!isHollow) canvas.drawCircle(plotPos, radius * 1.5, borderPaint);
      } else {
        if (isHollow) canvas.drawCircle(plotPos, radius, maskPaint);
        canvas.drawCircle(plotPos, radius, normalPaint);
      }
    }

    // Pass 3: label text — floats above markers.
    if (paintLabels) {
      for (int i = 0; i < transformedPoints.length; i++) {
        final originalIndex = originalIndices?[i] ?? i;
        if (originalIndex < series.points.length) {
          _paintDataPointLabelText(
            canvas,
            transformedPoints[i],
            radius,
            series.points[originalIndex],
            baseColor,
            labelConfig,
            series.unit,
          );
        }
      }
    }
  }

  void _paintSeriesInlineLabel(
    Canvas canvas,
    ChartSeries series,
    List<Offset> transformedPoints,
    Color baseColor,
  ) {
    final SeriesInlineLabelConfig? config = switch (series) {
      final LineChartSeries s => s.inlineLabel,
      final AreaChartSeries s => s.inlineLabel,
      _ => null,
    };
    if (config == null || transformedPoints.length < 2) return;

    final double anchorX = switch (config.position) {
      SeriesLabelPosition.left => transformedPoints.first.dx,
      SeriesLabelPosition.center =>
        (transformedPoints.first.dx + transformedPoints.last.dx) / 2,
      SeriesLabelPosition.right => transformedPoints.last.dx,
    };

    double? interpolatedY;
    for (int i = 0; i < transformedPoints.length - 1; i++) {
      final a = transformedPoints[i];
      final b = transformedPoints[i + 1];
      if (anchorX >= a.dx && anchorX <= b.dx) {
        final t = (b.dx == a.dx) ? 0.0 : (anchorX - a.dx) / (b.dx - a.dx);
        interpolatedY = a.dy + t * (b.dy - a.dy);
        break;
      }
    }
    if (interpolatedY == null &&
        (anchorX - transformedPoints.last.dx).abs() < 1.0) {
      interpolatedY = transformedPoints.last.dy;
    }
    if (interpolatedY == null) return;

    final effectiveColor = config.color ?? baseColor;

    final tp = TextPainter(
      text: TextSpan(
        text: config.text,
        style: TextStyle(
          color: effectiveColor,
          fontSize: config.fontSize,
          fontWeight: config.fontWeight,
          fontFamily: fontFamily,
        ),
      ),
      textDirection: textDirection,
      textAlign: TextAlign.left,
    )..layout();

    final double paintX = switch (config.position) {
      SeriesLabelPosition.left => anchorX,
      SeriesLabelPosition.center => anchorX - tp.width / 2,
      SeriesLabelPosition.right => anchorX - tp.width,
    };
    final double paintY = interpolatedY + config.offsetY - tp.height / 2;

    if (config.background != null) {
      final bg = config.background!;
      final pad = bg.padding;
      final bgRect = Rect.fromLTWH(
        paintX - pad.left,
        paintY - pad.top,
        tp.width + pad.horizontal,
        tp.height + pad.vertical,
      );
      final radius = Radius.circular(
        bg.cornerRadius ?? (tp.height + pad.vertical) / 2,
      );
      final rrect = RRect.fromRectAndRadius(bgRect, radius);
      canvas.drawRRect(rrect, Paint()..color = bg.color);
      if (bg.borderColor != null) {
        canvas.drawRRect(
          rrect,
          Paint()
            ..color = bg.borderColor!
            ..style = PaintingStyle.stroke
            ..strokeWidth = bg.borderWidth,
        );
      }
    }

    tp.paint(canvas, Offset(paintX, paintY));
    tp.dispose();
  }

  @override
  void onSelect() {
    // Notify parent widget via callback if needed
  }

  @override
  void onDeselect() {
    // Notify parent widget via callback if needed
  }

  @override
  void onHoverEnter() {
    // Notify parent widget via callback if needed
  }

  @override
  void onHoverExit() {
    // Notify parent widget via callback if needed
  }

  @override
  SeriesElement copyWith({bool? isHovered, bool? isSelected}) {
    return SeriesElement(
      series: series,
      transform: transform,
      isSelected: isSelected ?? this.isSelected,
      isHovered: isHovered ?? this.isHovered,
      seriesTheme: seriesTheme,
      candlestickTheme: candlestickTheme,
      seriesIndex: seriesIndex,
      coordinator: coordinator,
      barGroupInfo: barGroupInfo, // Preserve bar group info for grouped bars
      focusedPointIndices: focusedPointIndices,
      selectedPointIndices: selectedPointIndices,
      pointFocusColor: pointFocusColor,
      pointSelectionColor: pointSelectionColor,
      fontFamily: fontFamily,
      hasAnySelectedPoints: hasAnySelectedPoints,
      revealProgress: revealProgress,
      pathPointMap: pathPointMap,
      textDirection: textDirection,
    );
  }
}
