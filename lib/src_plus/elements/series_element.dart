// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Series Rendering

import 'dart:ui';

import '../coordinates/chart_transform.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/coordinator.dart';
import '../interaction/core/element_types.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';

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
    this.strokeWidth = 2.0,
    this.themeColor,
    this.coordinator,
  }) : _currentTransform = transform {
    _computeBounds();
  }

  final ChartSeries series;
  final ChartTransform transform; // Initial transform for bounds computation
  ChartTransform _currentTransform; // Current transform for painting
  final double strokeWidth;
  final Color? themeColor;
  final ChartInteractionCoordinator? coordinator;

  /// Update the current transform before painting (for real-time pan/zoom).
  /// This allows path caching to work - transform stored at construction stays fixed,
  /// but _currentTransform updates on every paint.
  void updateTransform(ChartTransform newTransform) {
    _currentTransform = newTransform;
  }

  @override
  final bool isSelected;

  @override
  final bool isHovered;

  late Rect _bounds;

  // Cache the rendered path to avoid recalculating on every paint
  Path? _cachedPath;
  List<Offset>? _cachedTransformedPoints;
  late ChartTransform _cachedTransform;

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
    _bounds = Rect.fromLTRB(minX - padding, minY - padding, maxX + padding, maxY + padding);
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
    final t = ((point.dx - segStart.dx) * dx + (point.dy - segStart.dy) * dy) / lengthSquared;
    final clampedT = t.clamp(0.0, 1.0);

    // Find closest point on segment
    final closest = Offset(segStart.dx + clampedT * dx, segStart.dy + clampedT * dy);

    return (point - closest).distance;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    // Use themeColor if provided, otherwise fall back to series color or default
    final baseColor = themeColor ?? series.color ?? const Color(0xFF2196F3);

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

  void _paintLineSeries(Canvas canvas, LineChartSeries series, Color baseColor) {
    final paint = Paint()
      ..color = isSelected
          ? baseColor.withOpacity(1.0)
          : isHovered
              ? baseColor.withOpacity(0.8)
              : baseColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? series.strokeWidth * 1.5 : series.strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Check if we need to regenerate the path (transform changed or no cache)
    final needsRegeneration = _cachedPath == null || _cachedTransform != _currentTransform;

    if (needsRegeneration) {
      // PRE-TRANSFORM all points ONCE to avoid redundant calculations
      final transformedPoints = series.points.map((p) => _currentTransform.dataToPlot(p.x, p.y)).toList();

      final path = Path();
      if (transformedPoints.isEmpty) return;
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

      // Cache the generated path, transformed points, and transform
      _cachedPath = path;
      _cachedTransformedPoints = transformedPoints;
      _cachedTransform = _currentTransform;
    }

    // Paint using the cached path (no regeneration on hover!)
    canvas.drawPath(_cachedPath!, paint);

    // Draw data point markers if enabled (use cached transforms!)
    if (series.showDataPointMarkers && _cachedTransformedPoints != null) {
      _paintDataPointMarkers(canvas, _cachedTransformedPoints!, series.dataPointMarkerRadius, baseColor);
    }
  }

  void _paintScatterSeries(Canvas canvas, ScatterChartSeries series, Color baseColor) {
    final pointPaint = Paint()
      ..color = isSelected
          ? baseColor.withOpacity(1.0)
          : isHovered
              ? baseColor.withOpacity(0.8)
              : baseColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (final point in series.points) {
      final plotPos = _currentTransform.dataToPlot(point.x, point.y);
      canvas.drawCircle(plotPos, series.markerRadius, pointPaint);
    }
  }

  void _paintAreaSeries(Canvas canvas, AreaChartSeries series, Color baseColor) {
    if (series.points.isEmpty) return;

    // PRE-TRANSFORM all points ONCE
    final transformedPoints = series.points.map((p) => _currentTransform.dataToPlot(p.x, p.y)).toList();

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
        _addBezierToPath(path, transformedPoints, series.tension, startIndex: 1);
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
      ..color = baseColor.withOpacity(series.fillOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw line on top (reuse cached transforms!)
    final linePaint = Paint()
      ..color = isSelected
          ? baseColor.withOpacity(1.0)
          : isHovered
              ? baseColor.withOpacity(0.8)
              : baseColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? series.strokeWidth * 1.5 : series.strokeWidth
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

    // Draw data point markers if enabled (reuse cached transforms!)
    if (series.showDataPointMarkers) {
      _paintDataPointMarkers(canvas, transformedPoints, series.dataPointMarkerRadius, baseColor);
    }
  }

  void _paintBarSeries(Canvas canvas, BarChartSeries series, Color baseColor) {
    final barPaint = Paint()
      ..color = isSelected
          ? baseColor.withOpacity(1.0)
          : isHovered
              ? baseColor.withOpacity(0.8)
              : baseColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (final point in series.points) {
      final plotPos = _currentTransform.dataToPlot(point.x, point.y);
      final zeroY = _currentTransform.dataToPlot(point.x, 0).dy;

      // Calculate bar width based on configuration
      double barWidth;
      if (series.barWidthPixels != null) {
        barWidth = series.barWidthPixels! / _currentTransform.dataPerPixelX;
        barWidth = barWidth.clamp(series.minWidth, series.maxWidth);
      } else {
        final spacingInPixels = _calculateXAxisSpacing(series.points);
        barWidth = spacingInPixels * series.barWidthPercent!;
        barWidth = barWidth.clamp(series.minWidth, series.maxWidth);
      }

      final rect = Rect.fromLTRB(plotPos.dx - barWidth / 2, plotPos.dy, plotPos.dx + barWidth / 2, zeroY);
      canvas.drawRect(rect, barPaint);
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
  void _addBezierToPath(Path path, List<Offset> transformedPoints, double tension, {int startIndex = 1}) {
    if (transformedPoints.length < 2 || startIndex >= transformedPoints.length) return;

    final alpha = tension;

    for (int i = startIndex; i < transformedPoints.length; i++) {
      // Access pre-transformed points by index - NO TRANSFORMS IN LOOP!
      final plot0 = transformedPoints[i > 0 ? i - 1 : i];
      final plot1 = transformedPoints[i];
      final plot2 = transformedPoints[i < transformedPoints.length - 1 ? i + 1 : i];
      final plot3 = transformedPoints[i < transformedPoints.length - 2 ? i + 2 : i];

      // Catmull-Rom to cubic bezier control points
      final cp1x = plot1.dx + (plot2.dx - plot0.dx) * alpha / 6;
      final cp1y = plot1.dy + (plot2.dy - plot0.dy) * alpha / 6;
      final cp2x = plot2.dx - (plot3.dx - plot1.dx) * alpha / 6;
      final cp2y = plot2.dy - (plot3.dy - plot1.dy) * alpha / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, plot2.dx, plot2.dy);
    }
  }

  /// Add stepped lines using PRE-TRANSFORMED points (no redundant dataToPlot calls!)
  void _addSteppedToPath(Path path, List<Offset> transformedPoints, {int startIndex = 1}) {
    if (transformedPoints.length < 2 || startIndex >= transformedPoints.length) return;

    for (int i = startIndex; i < transformedPoints.length; i++) {
      final prevPlot = transformedPoints[i - 1];
      final currPlot = transformedPoints[i];

      path.lineTo(currPlot.dx, prevPlot.dy);
      path.lineTo(currPlot.dx, currPlot.dy);
    }
  }

  /// Add monotone curves using PRE-TRANSFORMED points (currently uses linear)
  void _addMonotoneToPath(Path path, List<Offset> transformedPoints, {int startIndex = 1}) {
    if (transformedPoints.length < 2 || startIndex >= transformedPoints.length) return;

    for (int i = startIndex; i < transformedPoints.length; i++) {
      path.lineTo(transformedPoints[i].dx, transformedPoints[i].dy);
    }
  }

  /// Paint markers using PRE-TRANSFORMED points (no redundant dataToPlot calls!)
  void _paintDataPointMarkers(Canvas canvas, List<Offset> transformedPoints, double radius, Color baseColor) {
    // Check if any marker in this series is hovered
    final hoveredMarker = coordinator?.hoveredMarker;
    final isThisSeriesHovered = hoveredMarker?.seriesId == series.id;

    // ignore: avoid_print
    if (isThisSeriesHovered) {
      print('🎨 Painting markers for ${series.id}: hoveredIndex=${hoveredMarker!.markerIndex}, totalMarkers=${transformedPoints.length}');
    }

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

      if (isThisSeriesHovered && i == hoveredMarker!.markerIndex) {
        // Paint highlighted marker (larger with border)
        // ignore: avoid_print
        print('✨ Painting HIGHLIGHTED marker at index $i: pos=$plotPos, radius=${radius * 1.5}');
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
      strokeWidth: strokeWidth,
      coordinator: coordinator,
    );
  }
}
