// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Series Rendering

import 'dart:ui';

import '../coordinates/chart_transform.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/coordinator.dart';
import '../interaction/core/element_types.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import '../theming/components/series_theme.dart';

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
      regions.add(_StyleRegion(
        startIndex: regionStart,
        endIndex: i,
        color: currentColor,
        strokeWidth: currentWidth,
      ));

      // Start new region from this point
      regionStart = i;
      currentColor = pointColor;
      currentWidth = pointWidth;
    }
  }

  // Close final region (always ends at last point)
  regions.add(_StyleRegion(
    startIndex: regionStart,
    endIndex: points.length - 1,
    color: currentColor,
    strokeWidth: currentWidth,
  ));

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
class SeriesElement implements ChartElement {
  SeriesElement({
    required this.series,
    required this.transform,
    this.isSelected = false,
    this.isHovered = false,
    this.seriesTheme,
    this.seriesIndex = 0,
    this.coordinator,
    @Deprecated('Use seriesTheme instead') double? strokeWidth,
    @Deprecated('Use seriesTheme instead') Color? themeColor,
  })  : _deprecatedStrokeWidth = strokeWidth,
        _deprecatedThemeColor = themeColor,
        _currentTransform = transform {
    _computeBounds();
  }

  ChartSeries series; // Made mutable for updateSeries()
  final ChartTransform transform; // Initial transform for bounds computation
  ChartTransform _currentTransform; // Current transform for painting
  final SeriesTheme? seriesTheme;
  final int seriesIndex;
  final ChartInteractionCoordinator? coordinator;

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
  void updateTransform(ChartTransform newTransform) {
    _currentTransform = newTransform;
  }

  /// Update the series data without recreating the element.
  /// This preserves the path cache, avoiding expensive Bezier regeneration.
  /// Only invalidates cache if the point count changed significantly.
  ///
  /// [skipBoundsComputation] should be true for streaming updates where
  /// bounds are tracked externally (in StreamingBuffer). This avoids
  /// expensive O(n) iteration through all points on every frame.
  void updateSeries(ChartSeries newSeries,
      {bool skipBoundsComputation = true}) {
    // Check if we need to invalidate path cache
    final pointCountChanged = newSeries.points.length != series.points.length;

    series = newSeries;

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
  }

  /// Invalidates all cached rendering data.
  /// Call when series data changes or segment styles are modified.
  void _invalidateAllCaches() {
    _cachedPath = null;
    _cachedTransformedPoints = null;
    _cachedOriginalIndices = null;
    _cachedHasSegmentOverrides = null;
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

  /// Compute bounding box that encompasses all data points (with stroke padding).
  void _computeBounds() {
    if (series.isEmpty) {
      _bounds = Rect.zero;
      return;
    }

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final point in series.points) {
      final plotPos = transform.dataToPlot(point.x, point.y);
      minX = plotPos.dx < minX ? plotPos.dx : minX;
      maxX = plotPos.dx > maxX ? plotPos.dx : maxX;
      minY = plotPos.dy < minY ? plotPos.dy : minY;
      maxY = plotPos.dy > maxY ? plotPos.dy : maxY;
    }

    // Add padding for stroke width
    final padding = strokeWidth / 2;
    _bounds = Rect.fromLTRB(
        minX - padding, minY - padding, maxX + padding, maxY + padding);
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

    // For line series: check if position is near any line segment
    // For scatter: check if near any point
    // For now: simple line segment hit testing
    final threshold = strokeWidth * 2; // Hit detection tolerance

    for (int i = 0; i < series.points.length - 1; i++) {
      final p1 = series.points[i];
      final p2 = series.points[i + 1];

      final plotP1 = transform.dataToPlot(p1.x, p1.y);
      final plotP2 = transform.dataToPlot(p2.x, p2.y);

      final distance = _distanceToLineSegment(position, plotP1, plotP2);
      if (distance <= threshold) {
        return true;
      }
    }

    return false;
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
    final t = ((point.dx - segStart.dx) * dx + (point.dy - segStart.dy) * dy) /
        lengthSquared;
    final clampedT = t.clamp(0.0, 1.0);

    // Find closest point on segment
    final closest =
        Offset(segStart.dx + clampedT * dx, segStart.dy + clampedT * dy);

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
  }

  void _paintLineSeries(
      Canvas canvas, LineChartSeries series, Color baseColor) {
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
    _cachedHasSegmentOverrides =
        series.points.any((p) => p.segmentStyle != null);
    return _cachedHasSegmentOverrides!;
  }

  /// Original single-color line rendering (fast path).
  void _paintLineSeriesSingleColor(
      Canvas canvas, LineChartSeries series, Color baseColor) {
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

      for (int idx = 0; idx < series.points.length; idx++) {
        final point = series.points[idx];
        // Include points slightly outside viewport for smooth edge rendering
        if (point.x >= xMin - 1 && point.x <= xMax + 1) {
          visiblePoints.add(point);
          visibleIndices.add(idx);
        } else if (point.x > xMax + 1) {
          break; // Points are sorted by X, no need to check further
        }
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

      // Draw line with configured interpolation using cached transforms
      switch (series.interpolation) {
        case LineInterpolation.linear:
          for (int i = 1; i < transformedPoints.length; i++) {
            path.lineTo(transformedPoints[i].dx, transformedPoints[i].dy);
          }
          break;
        case LineInterpolation.bezier:
          _addBezierToPath(path, transformedPoints, series.tension);
          break;
        case LineInterpolation.stepped:
          _addSteppedToPath(path, transformedPoints);
          break;
        case LineInterpolation.monotone:
          _addMonotoneToPath(path, transformedPoints);
          break;
      }

      // Cache the generated path, transformed points, original indices, and transform
      _cachedPath = path;
      _cachedTransformedPoints = transformedPoints;
      _cachedOriginalIndices = visibleIndices;
      _cachedTransform = _currentTransform;
    }

    // Paint using the cached path (no regeneration on hover!)
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
      Canvas canvas, LineChartSeries series, Color baseColor) {
    final opacity = _getOpacity();
    final effectiveStrokeWidth = isSelected ? strokeWidth * 1.5 : strokeWidth;

    // Filter to visible points (same optimization as single-color path)
    final visiblePoints = <ChartDataPoint>[];
    final visibleIndices = <int>[]; // Track original indices for style lookup
    final xMin = _currentTransform.dataXMin;
    final xMax = _currentTransform.dataXMax;

    for (int i = 0; i < series.points.length; i++) {
      final point = series.points[i];
      if (point.x >= xMin - 1 && point.x <= xMax + 1) {
        visiblePoints.add(point);
        visibleIndices.add(i);
      } else if (point.x > xMax + 1) {
        break;
      }
    }

    if (visiblePoints.length < 2) return;

    // Pre-transform ALL visible points once
    final transformedPoints = visiblePoints
        .map((p) => _currentTransform.dataToPlot(p.x, p.y))
        .toList();

    // Analyze style regions (uses visible points, not full series)
    final regions =
        _analyzeStyleRegions(visiblePoints, baseColor, effectiveStrokeWidth);

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

    // Add segments based on interpolation type
    for (int i = startIndex; i < endIndex; i++) {
      switch (interpolation) {
        case LineInterpolation.linear:
          path.lineTo(allPoints[i + 1].dx, allPoints[i + 1].dy);
          break;

        case LineInterpolation.bezier:
          // Calculate control points using FULL context for smooth tangents
          final (cp1, cp2) =
              _calculateBezierControlPoints(allPoints, i, tension);
          path.cubicTo(
            cp1.dx,
            cp1.dy,
            cp2.dx,
            cp2.dy,
            allPoints[i + 1].dx,
            allPoints[i + 1].dy,
          );
          break;

        case LineInterpolation.stepped:
          // Horizontal then vertical
          path.lineTo(allPoints[i + 1].dx, allPoints[i].dy);
          path.lineTo(allPoints[i + 1].dx, allPoints[i + 1].dy);
          break;

        case LineInterpolation.monotone:
          // Currently uses linear (monotone implementation pending)
          path.lineTo(allPoints[i + 1].dx, allPoints[i + 1].dy);
          break;
      }
    }

    return path;
  }

  /// Calculates bezier control points for segment i→i+1.
  ///
  /// Uses Catmull-Rom to Bezier conversion with full point context
  /// for proper tangent calculation at region boundaries.
  (Offset cp1, Offset cp2) _calculateBezierControlPoints(
    List<Offset> points,
    int i,
    double tension,
  ) {
    // Get 4 points for Catmull-Rom: p0, p1 (start), p2 (end), p3
    // Clamp to array bounds for edge cases
    final p0 = points[i > 0 ? i - 1 : 0];
    final p1 = points[i];
    final p2 = points[i + 1];
    final p3 = points[i + 2 < points.length ? i + 2 : points.length - 1];

    // Scale tension for visible curvature (same as _addBezierToPath)
    final alpha = tension * 2.0;

    // Catmull-Rom to cubic bezier control points
    final cp1 = Offset(
      p1.dx + (p2.dx - p0.dx) * alpha / 3,
      p1.dy + (p2.dy - p0.dy) * alpha / 3,
    );

    final cp2 = Offset(
      p2.dx - (p3.dx - p1.dx) * alpha / 3,
      p2.dy - (p3.dy - p1.dy) * alpha / 3,
    );

    return (cp1, cp2);
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
      Canvas canvas, ScatterChartSeries series, Color baseColor) {
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
      Canvas canvas, AreaChartSeries series, Color baseColor) {
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

    if (!hasOverrides) {
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

    // Build fill path through points using configured interpolation
    switch (series.interpolation) {
      case LineInterpolation.linear:
        for (int i = 1; i < transformedPoints.length; i++) {
          path.lineTo(transformedPoints[i].dx, transformedPoints[i].dy);
        }
        break;
      case LineInterpolation.bezier:
        _addBezierToPath(path, transformedPoints, series.tension,
            startIndex: 1);
        break;
      case LineInterpolation.stepped:
        _addSteppedToPath(path, transformedPoints, startIndex: 1);
        break;
      case LineInterpolation.monotone:
        _addMonotoneToPath(path, transformedPoints, startIndex: 1);
        break;
    }

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

    switch (series.interpolation) {
      case LineInterpolation.linear:
        for (int i = 1; i < transformedPoints.length; i++) {
          linePath.lineTo(transformedPoints[i].dx, transformedPoints[i].dy);
        }
        break;
      case LineInterpolation.bezier:
        _addBezierToPath(linePath, transformedPoints, series.tension);
        break;
      case LineInterpolation.stepped:
        _addSteppedToPath(linePath, transformedPoints);
        break;
      case LineInterpolation.monotone:
        _addMonotoneToPath(linePath, transformedPoints);
        break;
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
      canvas.drawPath(strokePath, strokePaint);
    }
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

    // Draw the line segment using the appropriate interpolation
    switch (interpolation) {
      case LineInterpolation.linear:
        for (int i = startIndex + 1; i <= endIndex; i++) {
          path.lineTo(transformedPoints[i].dx, transformedPoints[i].dy);
        }
        break;

      case LineInterpolation.bezier:
        // For bezier, calculate control points for each segment
        for (int i = startIndex; i < endIndex; i++) {
          final (cp1, cp2) =
              _calculateBezierControlPoints(transformedPoints, i, tension);
          path.cubicTo(
            cp1.dx,
            cp1.dy,
            cp2.dx,
            cp2.dy,
            transformedPoints[i + 1].dx,
            transformedPoints[i + 1].dy,
          );
        }
        break;

      case LineInterpolation.stepped:
        for (int i = startIndex; i < endIndex; i++) {
          final current = transformedPoints[i];
          final next = transformedPoints[i + 1];
          path.lineTo(next.dx, current.dy); // Horizontal to next X
          path.lineTo(next.dx, next.dy); // Vertical to next Y
        }
        break;

      case LineInterpolation.monotone:
        // Monotone uses linear fallback (same as _buildRegionPath)
        for (int i = startIndex + 1; i <= endIndex; i++) {
          path.lineTo(transformedPoints[i].dx, transformedPoints[i].dy);
        }
        break;
    }

    // Go down to x-axis at the end point's X
    path.lineTo(endPoint.dx, xAxisY);

    // Close back to start
    path.close();

    return path;
  }

  void _paintBarSeries(Canvas canvas, BarChartSeries series, Color baseColor) {
    // Use theme-based opacity values: selected=1.0, hovered=0.8, normal=0.7
    final opacity = isSelected
        ? 1.0
        : isHovered
            ? 0.8
            : 0.7;

    // Check if any point has style overrides
    final hasOverrides = series.points.any((p) => p.pointStyle != null);

    // Pre-calculate default bar width
    double defaultBarWidth;
    if (series.barWidthPixels != null) {
      defaultBarWidth =
          series.barWidthPixels! / _currentTransform.dataPerPixelX;
      defaultBarWidth = defaultBarWidth.clamp(series.minWidth, series.maxWidth);
    } else {
      final spacingInPixels = _calculateXAxisSpacing(series.points);
      defaultBarWidth = spacingInPixels * series.barWidthPercent!;
      defaultBarWidth = defaultBarWidth.clamp(series.minWidth, series.maxWidth);
    }

    if (!hasOverrides) {
      // FAST PATH: Single color for all bars
      final barPaint = Paint()
        ..color = baseColor.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      for (final point in series.points) {
        final plotPos = _currentTransform.dataToPlot(point.x, point.y);
        final zeroY = _currentTransform.dataToPlot(point.x, 0).dy;

        final rect = Rect.fromLTRB(
          plotPos.dx - defaultBarWidth / 2,
          plotPos.dy,
          plotPos.dx + defaultBarWidth / 2,
          zeroY,
        );
        canvas.drawRect(rect, barPaint);
      }
    } else {
      // STYLED PATH: Per-bar coloring
      for (final point in series.points) {
        final plotPos = _currentTransform.dataToPlot(point.x, point.y);
        final zeroY = _currentTransform.dataToPlot(point.x, 0).dy;

        final barColor = point.pointStyle?.color ?? baseColor;
        // PointStyle.size for bars is a width multiplier (1.0 = default width)
        final widthMultiplier = point.pointStyle?.size ?? 1.0;
        final barWidth = defaultBarWidth * widthMultiplier;

        final barPaint = Paint()
          ..color = barColor.withValues(alpha: opacity)
          ..style = PaintingStyle.fill;

        final rect = Rect.fromLTRB(
          plotPos.dx - barWidth / 2,
          plotPos.dy,
          plotPos.dx + barWidth / 2,
          zeroY,
        );
        canvas.drawRect(rect, barPaint);
      }
    }
  }

  double _calculateXAxisSpacing(List<ChartDataPoint> points) {
    if (points.length == 1) return _currentTransform.plotWidth * 0.6;

    double minXSpacing = double.infinity;
    for (int i = 0; i < points.length - 1; i++) {
      final xSpacing = (points[i + 1].x - points[i].x).abs();
      if (xSpacing > 0 && xSpacing < minXSpacing) {
        minXSpacing = xSpacing;
      }
    }

    if (minXSpacing != double.infinity) {
      return minXSpacing / _currentTransform.dataPerPixelX;
    }
    return 40.0;
  }

  // ==================== OPTIMIZED INTERPOLATION METHODS ====================

  /// Add bezier curves using PRE-TRANSFORMED points (no redundant dataToPlot calls!)
  /// Uses Catmull-Rom spline converted to cubic bezier, ensuring curve passes through all data points.
  void _addBezierToPath(
      Path path, List<Offset> transformedPoints, double tension,
      {int startIndex = 1}) {
    if (transformedPoints.length < 2 ||
        startIndex >= transformedPoints.length) {
      return;
    }

    // Scale tension for visible curvature: 0.0 = straight, 1.0 = smooth Catmull-Rom
    // The standard Catmull-Rom formula divides by 6, but we use a stronger multiplier
    // to make curves more pronounced at the default tension of 0.25
    final alpha = tension * 2.0; // Amplify tension for visible curves

    for (int i = startIndex; i < transformedPoints.length; i++) {
      // For segment from point[i-1] to point[i], we need 4 points for Catmull-Rom:
      // p0 = point before start (or start if at beginning)
      // p1 = start of segment (point[i-1])
      // p2 = end of segment (point[i])
      // p3 = point after end (or end if at end)
      final p0 = transformedPoints[i > 1 ? i - 2 : 0];
      final p1 = transformedPoints[i - 1];
      final p2 = transformedPoints[i];
      final p3 = transformedPoints[i < transformedPoints.length - 1
          ? i + 1
          : transformedPoints.length - 1];

      // Catmull-Rom to cubic bezier control points
      // Control point 1: 1/3 of the way from p1 toward the tangent direction
      // Control point 2: 1/3 of the way from p2 toward the tangent direction (reversed)
      final cp1x = p1.dx + (p2.dx - p0.dx) * alpha / 3;
      final cp1y = p1.dy + (p2.dy - p0.dy) * alpha / 3;
      final cp2x = p2.dx - (p3.dx - p1.dx) * alpha / 3;
      final cp2y = p2.dy - (p3.dy - p1.dy) * alpha / 3;

      // Draw cubic bezier from current position (p1) to p2
      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
    }
  }

  /// Add stepped lines using PRE-TRANSFORMED points (no redundant dataToPlot calls!)
  void _addSteppedToPath(Path path, List<Offset> transformedPoints,
      {int startIndex = 1}) {
    if (transformedPoints.length < 2 ||
        startIndex >= transformedPoints.length) {
      return;
    }

    for (int i = startIndex; i < transformedPoints.length; i++) {
      final prevPlot = transformedPoints[i - 1];
      final currPlot = transformedPoints[i];

      path.lineTo(currPlot.dx, prevPlot.dy);
      path.lineTo(currPlot.dx, currPlot.dy);
    }
  }

  /// Add monotone curves using PRE-TRANSFORMED points (currently uses linear)
  void _addMonotoneToPath(Path path, List<Offset> transformedPoints,
      {int startIndex = 1}) {
    if (transformedPoints.length < 2 ||
        startIndex >= transformedPoints.length) {
      return;
    }

    for (int i = startIndex; i < transformedPoints.length; i++) {
      path.lineTo(transformedPoints[i].dx, transformedPoints[i].dy);
    }
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
    // Check if any marker in this series is hovered
    final hoveredMarker = coordinator?.hoveredMarker;
    final isThisSeriesHovered = hoveredMarker?.seriesId == series.id;

    // Paint setup
    final normalPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    final hoverPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (int i = 0; i < transformedPoints.length; i++) {
      final plotPos = transformedPoints[i];
      // Use original index for hover comparison (handles viewport culling)
      final originalIndex = originalIndices?[i] ?? i;

      if (isThisSeriesHovered && originalIndex == hoveredMarker!.markerIndex) {
        // Paint highlighted marker (larger with border)
        canvas.drawCircle(plotPos, radius * 1.5, hoverPaint);
        canvas.drawCircle(plotPos, radius * 1.5, borderPaint);
      } else {
        // Paint normal marker
        canvas.drawCircle(plotPos, radius, normalPaint);
      }
    }
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
    );
  }
}
