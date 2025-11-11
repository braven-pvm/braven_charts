// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Series Rendering

import 'dart:ui';

import '../coordinates/chart_transform.dart';
import '../interaction/core/chart_element.dart';
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
  }) {
    _computeBounds();
  }

  final ChartSeries series;
  final ChartTransform transform;
  final double strokeWidth;
  final Color? themeColor;

  @override
  final bool isSelected;

  @override
  final bool isHovered;

  late Rect _bounds;

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
    // DEBUG: Print color being used
    print('   SeriesElement.paint "${series.name}": themeColor=$themeColor, seriesColor=${series.color}, baseColor=$baseColor');

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

    // Draw line with configured interpolation
    switch (series.interpolation) {
      case LineInterpolation.linear:
        _paintLinearPath(canvas, series.points, paint);
        break;
      case LineInterpolation.bezier:
        _paintBezierPath(canvas, series.points, paint, series.tension);
        break;
      case LineInterpolation.stepped:
        _paintSteppedPath(canvas, series.points, paint);
        break;
      case LineInterpolation.monotone:
        _paintMonotonePath(canvas, series.points, paint);
        break;
    }

    // Draw data point markers if enabled
    if (series.showDataPointMarkers) {
      _paintDataPointMarkers(canvas, series.points, series.dataPointMarkerRadius, baseColor);
    }
  }

  void _paintScatterSeries(Canvas canvas, ScatterChartSeries series, Color baseColor) {
    // Create paint for filled circles
    final pointPaint = Paint()
      ..color = isSelected
          ? baseColor.withOpacity(1.0)
          : isHovered
              ? baseColor.withOpacity(0.8)
              : baseColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    for (final point in series.points) {
      final plotPos = transform.dataToPlot(point.x, point.y);
      canvas.drawCircle(plotPos, series.markerRadius, pointPaint);
    }
  }

  void _paintAreaSeries(Canvas canvas, AreaChartSeries series, Color baseColor) {
    if (series.points.isEmpty) return;

    final path = Path();
    final firstPoint = series.points.first;
    final firstPlot = transform.dataToPlot(firstPoint.x, firstPoint.y);

    // Start from x-axis (bottom of plot area)
    path.moveTo(firstPlot.dx, transform.plotHeight);
    path.lineTo(firstPlot.dx, firstPlot.dy);

    // Build path through points using configured interpolation
    switch (series.interpolation) {
      case LineInterpolation.linear:
        for (int i = 1; i < series.points.length; i++) {
          final point = series.points[i];
          final plotPos = transform.dataToPlot(point.x, point.y);
          path.lineTo(plotPos.dx, plotPos.dy);
        }
        break;
      case LineInterpolation.bezier:
        _addBezierToPath(path, series.points, series.tension, startIndex: 1);
        break;
      case LineInterpolation.stepped:
        _addSteppedToPath(path, series.points, startIndex: 1);
        break;
      case LineInterpolation.monotone:
        _addMonotoneToPath(path, series.points, startIndex: 1);
        break;
    }

    // Close to x-axis
    final lastPoint = series.points.last;
    final lastPlot = transform.dataToPlot(lastPoint.x, lastPoint.y);
    path.lineTo(lastPlot.dx, transform.plotHeight);
    path.close();

    // Fill area
    final fillPaint = Paint()
      ..color = baseColor.withOpacity(series.fillOpacity)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw line on top
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

    switch (series.interpolation) {
      case LineInterpolation.linear:
        _paintLinearPath(canvas, series.points, linePaint);
        break;
      case LineInterpolation.bezier:
        _paintBezierPath(canvas, series.points, linePaint, series.tension);
        break;
      case LineInterpolation.stepped:
        _paintSteppedPath(canvas, series.points, linePaint);
        break;
      case LineInterpolation.monotone:
        _paintMonotonePath(canvas, series.points, linePaint);
        break;
    }

    // Draw data point markers if enabled
    if (series.showDataPointMarkers) {
      _paintDataPointMarkers(canvas, series.points, series.dataPointMarkerRadius, baseColor);
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
      final plotPos = transform.dataToPlot(point.x, point.y);
      final zeroY = transform.dataToPlot(point.x, 0).dy;

      // Calculate bar width based on configuration
      double barWidth;
      if (series.barWidthPixels != null) {
        // Explicit pixel width (scales with zoom)
        barWidth = series.barWidthPixels! / transform.dataPerPixelX;
        barWidth = barWidth.clamp(series.minWidth, series.maxWidth);
      } else {
        // Percentage of X-axis spacing
        final spacingInPixels = _calculateXAxisSpacing(series.points);
        barWidth = spacingInPixels * series.barWidthPercent!;
        barWidth = barWidth.clamp(series.minWidth, series.maxWidth);
      }

      final rect = Rect.fromLTRB(plotPos.dx - barWidth / 2, plotPos.dy, plotPos.dx + barWidth / 2, zeroY);
      canvas.drawRect(rect, barPaint);
    }
  }

  /// Calculate typical X-axis spacing for bar width calculations.
  double _calculateXAxisSpacing(List<ChartDataPoint> points) {
    if (points.length == 1) {
      // Single bar: use 60% of visible plot width
      return transform.plotWidth * 0.6;
    }

    // Multiple bars: calculate minimum X spacing between points
    double minXSpacing = double.infinity;
    for (int i = 0; i < points.length - 1; i++) {
      final xSpacing = (points[i + 1].x - points[i].x).abs();
      if (xSpacing > 0 && xSpacing < minXSpacing) {
        minXSpacing = xSpacing;
      }
    }

    // Convert data spacing to plot pixels
    if (minXSpacing != double.infinity) {
      return minXSpacing / transform.dataPerPixelX;
    } else {
      return 40.0; // Fallback if spacing calculation fails
    }
  }

  // ==================== LINE INTERPOLATION METHODS ====================

  /// Paint linear (straight line) path through points.
  void _paintLinearPath(Canvas canvas, List<ChartDataPoint> points, Paint paint) {
    final path = Path();
    bool first = true;

    for (final point in points) {
      final plotPos = transform.dataToPlot(point.x, point.y);
      if (first) {
        path.moveTo(plotPos.dx, plotPos.dy);
        first = false;
      } else {
        path.lineTo(plotPos.dx, plotPos.dy);
      }
    }

    canvas.drawPath(path, paint);
  }

  /// Paint smooth bezier curve through points using Catmull-Rom splines.
  void _paintBezierPath(Canvas canvas, List<ChartDataPoint> points, Paint paint, double tension) {
    if (points.length < 2) return;

    final path = Path();
    final firstPlot = transform.dataToPlot(points[0].x, points[0].y);
    path.moveTo(firstPlot.dx, firstPlot.dy);

    _addBezierToPath(path, points, tension);
    canvas.drawPath(path, paint);
  }

  /// Add bezier curves to an existing path (for area charts).
  void _addBezierToPath(Path path, List<ChartDataPoint> points, double tension, {int startIndex = 1}) {
    if (points.length < 2 || startIndex >= points.length) return;

    // Convert tension (0.0-1.0) to Catmull-Rom alpha (0.0 = tight, 0.5 = centripetal, 1.0 = loose)
    final alpha = tension;

    for (int i = startIndex; i < points.length; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = i < points.length - 1 ? points[i + 1] : points[i];
      final p3 = i < points.length - 2 ? points[i + 2] : p2;

      // Calculate control points using Catmull-Rom to cubic bezier conversion
      final plot0 = transform.dataToPlot(p0.x, p0.y);
      final plot1 = transform.dataToPlot(p1.x, p1.y);
      final plot2 = transform.dataToPlot(p2.x, p2.y);
      final plot3 = transform.dataToPlot(p3.x, p3.y);

      // Control points for cubic bezier (simplified formula)
      final cp1x = plot1.dx + (plot2.dx - plot0.dx) * alpha / 6;
      final cp1y = plot1.dy + (plot2.dy - plot0.dy) * alpha / 6;
      final cp2x = plot2.dx - (plot3.dx - plot1.dx) * alpha / 6;
      final cp2y = plot2.dy - (plot3.dy - plot1.dy) * alpha / 6;

      path.cubicTo(cp1x, cp1y, cp2x, cp2y, plot2.dx, plot2.dy);
    }
  }

  /// Paint stepped (horizontal then vertical) path through points.
  void _paintSteppedPath(Canvas canvas, List<ChartDataPoint> points, Paint paint) {
    if (points.length < 2) return;

    final path = Path();
    final firstPlot = transform.dataToPlot(points[0].x, points[0].y);
    path.moveTo(firstPlot.dx, firstPlot.dy);

    _addSteppedToPath(path, points);
    canvas.drawPath(path, paint);
  }

  /// Add stepped lines to an existing path (for area charts).
  void _addSteppedToPath(Path path, List<ChartDataPoint> points, {int startIndex = 1}) {
    if (points.length < 2 || startIndex >= points.length) return;

    for (int i = startIndex; i < points.length; i++) {
      final prevPlot = transform.dataToPlot(points[i - 1].x, points[i - 1].y);
      final currPlot = transform.dataToPlot(points[i].x, points[i].y);

      // Horizontal line to next X, then vertical line to next Y
      path.lineTo(currPlot.dx, prevPlot.dy);
      path.lineTo(currPlot.dx, currPlot.dy);
    }
  }

  /// Paint monotone cubic interpolation (preserves monotonicity).
  void _paintMonotonePath(Canvas canvas, List<ChartDataPoint> points, Paint paint) {
    // For simplicity, use linear interpolation for now (full monotone is complex)
    // TODO: Implement full monotone cubic interpolation if needed
    _paintLinearPath(canvas, points, paint);
  }

  /// Add monotone curves to an existing path (for area charts).
  void _addMonotoneToPath(Path path, List<ChartDataPoint> points, {int startIndex = 1}) {
    // For simplicity, use linear interpolation for now
    // TODO: Implement full monotone cubic interpolation if needed
    if (points.length < 2 || startIndex >= points.length) return;

    for (int i = startIndex; i < points.length; i++) {
      final currPlot = transform.dataToPlot(points[i].x, points[i].y);
      path.lineTo(currPlot.dx, currPlot.dy);
    }
  }

  /// Paint data point markers (dots) at each data point.
  void _paintDataPointMarkers(Canvas canvas, List<ChartDataPoint> points, double radius, Color baseColor) {
    final markerPaint = Paint()
      ..color = baseColor
      ..style = PaintingStyle.fill;

    for (final point in points) {
      final plotPos = transform.dataToPlot(point.x, point.y);
      canvas.drawCircle(plotPos, radius, markerPaint);
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
    );
  }
}
