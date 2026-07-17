// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Series Rendering

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart'
    show FontWeight, TextAlign, TextDirection, TextPainter, TextSpan, TextStyle;

import '../coordinates/chart_transform.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/data_hit.dart';
import '../interaction/core/coordinator.dart';
import '../interaction/core/element_types.dart';
import '../models/bar_group_info.dart';
import '../models/bar_chart_style.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../models/data_point_label_config.dart';
import '../models/series_inline_label_config.dart';
import '../rendering/bar_geometry.dart';
import '../theming/components/series_theme.dart';
import '../utils/interpolation_geometry.dart';

// =============================================================================
// Style Region for Segment Color Batching
// =============================================================================

/// Represents a continuous region of same-styled segments for batched rendering.
///
/// When segment colors are used, the series line is divided into regions
/// where each region has consistent styling (color + stroke width).
/// This enables efficient batched rendering with minimal drawPath() calls.
class _StyleRegion {
  const _StyleRegion({
    required this.startIndex,
    required this.endIndex,
    required this.color,
    required this.strokeWidth,
  });

  /// Index of first point in region (segment starts here).
  final int startIndex;

  /// Index of last point in region (segment ends here, inclusive).
  final int endIndex;

  /// Effective color for this region.
  final Color color;

  /// Effective stroke width for this region.
  final double strokeWidth;

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
) {
  if (points.length < 2) return [];

  final regions = <_StyleRegion>[];
  int regionStart = 0;

  // Get effective style for first segment (from first point)
  Color currentColor = points[0].segmentStyle?.color ?? defaultColor;
  double currentWidth =
      points[0].segmentStyle?.strokeWidth ?? defaultStrokeWidth;

  // Iterate through points, detecting style changes
  // Note: We check points[i] for segment i→i+1's style
  for (int i = 1; i < points.length - 1; i++) {
    final style = points[i].segmentStyle;
    final pointColor = style?.color ?? defaultColor;
    final pointWidth = style?.strokeWidth ?? defaultStrokeWidth;

    // Check if style changed at this point
    if (pointColor != currentColor || pointWidth != currentWidth) {
      // Close current region (ends at point i, inclusive)
      regions.add(
        _StyleRegion(
          startIndex: regionStart,
          endIndex: i,
          color: currentColor,
          strokeWidth: currentWidth,
        ),
      );

      // Start new region from this point
      regionStart = i;
      currentColor = pointColor;
      currentWidth = pointWidth;
    }
  }

  // Close final region (always ends at last point)
  regions.add(
    _StyleRegion(
      startIndex: regionStart,
      endIndex: points.length - 1,
      color: currentColor,
      strokeWidth: currentWidth,
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
    this.seriesIndex = 0,
    this.coordinator,
    this.barGroupInfo,
    this.focusedPointIndices = const {},
    this.selectedPointIndices = const {},
    this.pointFocusColor,
    this.pointSelectionColor,
    this.fontFamily,
    this.hasAnySelectedPoints = false,
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
  final SeriesTheme? seriesTheme;
  @override
  final int seriesIndex;

  @override
  int get pointCount => series.points.length;
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
  MarkerShape get markerShape =>
      seriesTheme?.markerShapeAt(seriesIndex) ?? MarkerShape.circle;

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
      _barGeometries = null;
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

    series = newSeries;
    _barGeometries = null;

    // PERFORMANCE: Skip bounds computation for streaming updates.
    // Streaming elements use pre-computed bounds from StreamingBuffer
    // and aren't added to QuadTree, so bounds aren't needed.
    if (!skipBoundsComputation) {
      _computeBounds();
    }

    // Invalidate cache only if geometry changed significantly
    if (pointCountChanged) {
      _invalidateAllCaches();
    }
    // Always clear label cache — label config may have changed
    _labelPainterCache.clear();
  }

  /// Invalidates all cached rendering data.
  /// Call when series data changes or segment styles are modified.
  void _invalidateAllCaches() {
    _cachedPath = null;
    _cachedTransformedPoints = null;
    _cachedOriginalIndices = null;
    _cachedHasSegmentOverrides = null;
    _barGeometries = null;
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
  List<Offset>? _cachedTransformedPoints;
  List<int>?
  _cachedOriginalIndices; // Maps visible point index → original series.points index
  late ChartTransform _cachedTransform;

  // Segment color caching - fast-path check result
  bool? _cachedHasSegmentOverrides;

  // TextPainter cache for data-point labels — keyed by formatted text string
  final Map<String, TextPainter> _labelPainterCache = {};
  List<BarGeometry>? _barGeometries;

  List<BarGeometry> _resolveBarGeometries() {
    final cached = _barGeometries;
    if (cached != null) return cached;
    final currentSeries = series;
    if (currentSeries is! BarChartSeries) return const [];
    return _barGeometries = BarGeometryEngine.layout(
      series: currentSeries,
      transform: _currentTransform,
      groupInfo: barGroupInfo,
    );
  }

  /// Returns the canonical rendered geometry for a bar point, when available.
  ///
  /// Crosshair markers and other interaction overlays use this instead of
  /// transforming the raw Y value, which would be incorrect for stacks.
  BarGeometry? barGeometryForPoint(int pointIndex) {
    if (series is! BarChartSeries || pointIndex < 0) return null;
    final geometries = _resolveBarGeometries();
    if (pointIndex >= geometries.length) return null;
    return geometries[pointIndex];
  }

  /// Returns the topmost bar geometry whose interaction bounds contain [point].
  BarGeometry? barGeometryAt(Offset point) {
    if (series is! BarChartSeries) return null;
    for (final geometry in _resolveBarGeometries().reversed) {
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

    if (series is BarChartSeries) {
      final geometries = _resolveBarGeometries();
      if (geometries.isEmpty) {
        _bounds = Rect.zero;
        return;
      }
      var bounds = geometries.first.paintBounds;
      for (final geometry in geometries.skip(1)) {
        bounds = bounds.expandToInclude(geometry.paintBounds);
      }
      final borderWidth =
          (series as BarChartSeries).barStyle.border?.width ?? 0;
      _bounds = bounds.inflate(math.max(1, borderWidth / 2));
      return;
    }

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final point in series.points) {
      // Use _currentTransform for perSeries normalization support
      final plotPos = _currentTransform.dataToPlot(point.x, point.y);
      minX = plotPos.dx < minX ? plotPos.dx : minX;
      maxX = plotPos.dx > maxX ? plotPos.dx : maxX;
      minY = plotPos.dy < minY ? plotPos.dy : minY;
      maxY = plotPos.dy > maxY ? plotPos.dy : maxY;
    }

    // Add padding for stroke width
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
  Rect get bounds => _bounds;

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

    if (series is BarChartSeries) {
      return _resolveBarGeometries().any(
        (geometry) => geometry.hitBounds.contains(position),
      );
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

    ChartDataHit? nearest;
    var nearestDistance = maxDistance;
    for (var index = 0; index < source.points.length; index++) {
      final hit = dataHitForPointIndex(index);
      if (hit == null) continue;
      final distance = (position - hit.plotPosition).distance;
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearest = hit;
      }
    }
    return nearest;
  }

  @override
  ChartDataHit? dataHitForPointIndex(int pointIndex) {
    if (pointIndex < 0 || pointIndex >= series.points.length) return null;
    final point = series.points[pointIndex];
    if (!point.isValid) return null;
    final position = _currentTransform.dataToPlot(point.x, point.y);
    return ChartDataHit(
      seriesId: series.id,
      pointIndex: pointIndex,
      plotPosition: position,
      semanticBounds: Rect.fromCircle(center: position, radius: 24),
      point: point,
      formattedValue:
          '${point.y.toStringAsFixed(2)}${series.unit == null || series.unit!.isEmpty ? '' : ' ${series.unit}'}',
      ordinal: pointIndex + 1,
      count: series.points.length,
      isSelected: selectedPointIndices.contains(pointIndex),
      isFocused: focusedPointIndices.contains(pointIndex),
    );
  }

  @override
  Iterable<ChartDataHit> get semanticDataHits => const <ChartDataHit>[];

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
    }
    _paintLinkedPoints(canvas, baseColor);
  }

  void _paintLinkedPoints(Canvas canvas, Color baseColor) {
    if (focusedPointIndices.isEmpty && selectedPointIndices.isEmpty) return;
    if (series is BarChartSeries) {
      _paintLinkedBars(canvas, baseColor);
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
      if (index < 0 || index >= series.points.length) continue;
      final point = series.points[index];
      final offset = _currentTransform.dataToPlot(point.x, point.y);
      canvas.drawCircle(offset, markerSize + 5, selectionFill);
      canvas.drawCircle(offset, markerSize + 3, selectionBorder);
      canvas.drawCircle(offset, math.max(2, markerSize * 0.5), pointFill);
    }
    for (final index in focusedPointIndices) {
      if (index < 0 || index >= series.points.length) continue;
      final point = series.points[index];
      final offset = _currentTransform.dataToPlot(point.x, point.y);
      canvas.drawCircle(offset, markerSize + 7, focusPaint);
    }
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
    // Use theme-based opacity values: selected=1.0, hovered=0.8, normal=0.7
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
      _cachedTransformedPoints = transformedPoints;
      _cachedOriginalIndices = visibleIndices;
      _cachedTransform = _currentTransform;
    }

    // Paint using the cached path (no regeneration on hover!)
    if (series.lineGlow > 0) {
      final glowPaint = Paint()
        ..color = baseColor.withAlpha(60)
        ..strokeWidth = effectiveStrokeWidth + series.lineGlow * 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, series.lineGlow);
      canvas.drawPath(_cachedPath!, glowPaint);
    }
    canvas.drawPath(_cachedPath!, paint);

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
        canvas.drawPath(regionPath, glowPaint);
      }
      canvas.drawPath(regionPath, paint);
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
    final opacity = isSelected
        ? 1.0
        : isHovered
        ? 0.8
        : 0.7;
    // Use theme marker size if available, otherwise series-specific size
    final defaultMarkerSize =
        seriesTheme?.markerSizeAt(seriesIndex) ?? series.markerRadius;

    // Check if any point has style overrides
    final hasOverrides = series.points.any((p) => p.pointStyle != null);

    if (!hasOverrides) {
      // FAST PATH: Single color/size for all points
      final pointPaint = Paint()
        ..color = baseColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      for (final point in series.points) {
        final plotPos = _currentTransform.dataToPlot(point.x, point.y);
        canvas.drawCircle(plotPos, defaultMarkerSize, pointPaint);
      }
    } else {
      // STYLED PATH: Per-point styling
      for (final point in series.points) {
        final plotPos = _currentTransform.dataToPlot(point.x, point.y);
        final pointColor = point.pointStyle?.color ?? baseColor;
        final pointSize = point.pointStyle?.size ?? defaultMarkerSize;

        final pointPaint = Paint()
          ..color = pointColor.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

        canvas.drawCircle(plotPos, pointSize, pointPaint);
      }
    }
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

    // NOTE: When baselineValue is set, segmentStyle per-point colour overrides
    // are not applied — the baseline fill path handles all fill and stroke.
    if (series.baselineValue != null) {
      _paintAreaSeriesBaseline(
        canvas,
        series,
        transformedPoints,
        baseColor,
        opacity,
        effectiveStrokeWidth,
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
    final fillPaint = Paint()
      ..color = baseColor.withValues(alpha: series.fillOpacity)
      ..style = PaintingStyle.fill;
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

    if (series.lineGlow > 0) {
      final glowPaint = Paint()
        ..color = baseColor.withAlpha(60)
        ..strokeWidth = strokeWidth + series.lineGlow * 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, series.lineGlow);
      canvas.drawPath(linePath, glowPaint);
    }
    canvas.drawPath(linePath, linePaint);
  }

  /// Paints an area series with per-segment colors for both fill and stroke.
  void _paintAreaSeriesMultiColor(
    Canvas canvas,
    AreaChartSeries series,
    List<Offset> transformedPoints,
    Color baseColor,
    double opacity,
    double strokeWidth,
  ) {
    // Analyze style regions (same logic as line charts)
    final regions = _analyzeStyleRegions(series.points, baseColor, strokeWidth);

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
      final fillPaint = Paint()
        ..color = region.color.withValues(alpha: series.fillOpacity)
        ..style = PaintingStyle.fill;
      canvas.drawPath(fillPath, fillPaint);

      // Build stroke path for this region
      final strokePath = _buildRegionPath(
        transformedPoints,
        region.startIndex,
        region.endIndex,
        series.interpolation,
        series.tension,
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
        canvas.drawPath(strokePath, glowPaint);
      }
      canvas.drawPath(strokePath, strokePaint);
    }
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

    // Draw the series stroke on top (identical to single-colour path).
    final linePaint = Paint()
      ..color = baseColor.withValues(alpha: opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path()
      ..moveTo(transformedPoints.first.dx, transformedPoints.first.dy);
    InterpolationGeometry.addPathSegments<Offset>(
      path: linePath,
      points: transformedPoints,
      interpolation: series.interpolation,
      getX: (p) => p.dx,
      getY: (p) => p.dy,
      tension: series.tension,
    );

    if (series.lineGlow > 0) {
      canvas.drawPath(
        linePath,
        Paint()
          ..color = baseColor.withAlpha(60)
          ..strokeWidth = strokeWidth + series.lineGlow * 2
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, series.lineGlow),
      );
    }
    canvas.drawPath(linePath, linePaint);
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

    if (series.layoutMode == BarLayoutMode.waterfall) {
      _paintWaterfallConnectors(canvas, series, geometries, opacity);
    }

    for (final geometry in geometries) {
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

      if (series.labelStyle.show) {
        _paintBarLabel(canvas, series, geometry, barColor);
      }
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

    var position = config.position;
    final provisionalPainter = _barLabelPainter(
      text,
      config.color ?? barColor,
      config.fontSize,
      config.fontWeight,
    );
    final insideEndOffset = _barLabelInsideEndOffset(series, geometry);
    if (position == BarLabelPosition.auto) {
      final fitsInside = series.orientation == BarOrientation.horizontal
          ? geometry.rect.height >= provisionalPainter.height + 4 &&
                geometry.rect.width >=
                    provisionalPainter.width + insideEndOffset * 2
          : geometry.rect.height >=
                    provisionalPainter.height + insideEndOffset * 2 &&
                geometry.rect.width >= provisionalPainter.width + 4;
      position = fitsInside
          ? BarLabelPosition.insideEnd
          : BarLabelPosition.outsideEnd;
    }

    final isInside = position != BarLabelPosition.outsideEnd;
    final labelColor =
        config.color ??
        (isInside
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
    if (series.orientation == BarOrientation.horizontal) {
      final valueEndIsRight = geometry.valueEndX >= geometry.baselineX;
      final x = switch (position) {
        BarLabelPosition.insideCenter =>
          geometry.rect.center.dx - painter.width / 2,
        BarLabelPosition.insideEnd =>
          valueEndIsRight
              ? geometry.rect.right - insideEndOffset - painter.width
              : geometry.rect.left + insideEndOffset,
        BarLabelPosition.outsideEnd =>
          valueEndIsRight
              ? geometry.rect.right + config.padding
              : geometry.rect.left - config.padding - painter.width,
        BarLabelPosition.rangeEnds => geometry.rect.left,
        BarLabelPosition.auto => geometry.rect.left,
      };
      painter.paint(
        canvas,
        Offset(x, geometry.rect.center.dy - painter.height / 2),
      );
      return;
    }

    final x = geometry.rect.center.dx - painter.width / 2;
    final valueEndIsTop = geometry.valueEndY <= geometry.baselineY;
    final y = switch (position) {
      BarLabelPosition.insideCenter =>
        geometry.rect.center.dy - painter.height / 2,
      BarLabelPosition.insideEnd =>
        valueEndIsTop
            ? geometry.rect.top + insideEndOffset
            : geometry.rect.bottom - insideEndOffset - painter.height,
      BarLabelPosition.outsideEnd =>
        valueEndIsTop
            ? geometry.rect.top - config.padding - painter.height
            : geometry.rect.bottom + config.padding,
      BarLabelPosition.rangeEnds => geometry.rect.top,
      BarLabelPosition.auto => geometry.rect.top,
    };
    painter.paint(canvas, Offset(x, y));
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
    painter.paint(
      canvas,
      Offset(
        placeAtStart
            ? geometry.rect.left - config.padding - painter.width
            : geometry.rect.right + config.padding,
        geometry.rect.center.dy - painter.height / 2,
      ),
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
    if (!rotate) {
      painter.paint(
        canvas,
        Offset(
          centerX - painter.width / 2,
          placeAbove
              ? geometry.rect.top - config.padding - painter.height
              : geometry.rect.bottom + config.padding,
        ),
      );
      return;
    }

    // Rotate only as the final fallback. After a clockwise quarter-turn the
    // painter's visual width is its original height and its visual height is
    // its original width.
    final visualTop = placeAbove
        ? geometry.rect.top - config.padding - painter.width
        : geometry.rect.bottom + config.padding;
    canvas.save();
    canvas.translate(centerX + painter.height / 2, visualTop);
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
        textDirection: TextDirection.ltr,
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
        textDirection: TextDirection.ltr,
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
      if (isThisSeriesHovered && originalIndex == hoveredMarker!.markerIndex) {
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
      textDirection: TextDirection.ltr,
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
      seriesIndex: seriesIndex,
      coordinator: coordinator,
      barGroupInfo: barGroupInfo, // Preserve bar group info for grouped bars
      focusedPointIndices: focusedPointIndices,
      selectedPointIndices: selectedPointIndices,
      pointFocusColor: pointFocusColor,
      pointSelectionColor: pointSelectionColor,
      fontFamily: fontFamily,
      hasAnySelectedPoints: hasAnySelectedPoints,
    );
  }
}
