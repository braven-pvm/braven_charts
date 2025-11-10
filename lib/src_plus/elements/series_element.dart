// Copyright (c) 2025 braven_charts. All rights reserved.
// BravenChartPlus - Series Rendering

import 'dart:ui';

import '../coordinates/chart_transform.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/element_types.dart';
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
  }) {
    _computeBounds();
  }

  final ChartSeries series;
  final ChartTransform transform;
  final double strokeWidth;

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
    final closest = Offset(
      segStart.dx + clampedT * dx,
      segStart.dy + clampedT * dy,
    );

    return (point - closest).distance;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    final color = series.color ?? const Color(0xFF2196F3);
    final paint = Paint()
      ..color = isSelected
          ? color.withOpacity(1.0)
          : isHovered
              ? color.withOpacity(0.8)
              : color.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? strokeWidth * 1.5 : strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw based on series style
    switch (series.style ?? SeriesStyle.line) {
      case SeriesStyle.line:
        _paintLine(canvas, paint);
        break;
      case SeriesStyle.scatter:
        _paintScatter(canvas, paint);
        break;
      case SeriesStyle.area:
        _paintArea(canvas, paint);
        break;
      case SeriesStyle.bar:
        _paintBar(canvas, paint);
        break;
    }
  }

  void _paintLine(Canvas canvas, Paint paint) {
    final path = Path();
    bool first = true;

    for (final point in series.points) {
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

  void _paintScatter(Canvas canvas, Paint paint) {
    final pointPaint = paint..style = PaintingStyle.fill;

    final radius = strokeWidth * 2;

    for (final point in series.points) {
      final plotPos = transform.dataToPlot(point.x, point.y);
      canvas.drawCircle(plotPos, radius, pointPaint);
    }
  }

  void _paintArea(Canvas canvas, Paint paint) {
    if (series.points.isEmpty) return;

    final path = Path();
    final firstPoint = series.points.first;
    final firstPlot = transform.dataToPlot(firstPoint.x, firstPoint.y);

    // Start from x-axis (bottom of plot area)
    path.moveTo(firstPlot.dx, transform.plotHeight);
    path.lineTo(firstPlot.dx, firstPlot.dy);

    // Draw line through points
    for (int i = 1; i < series.points.length; i++) {
      final point = series.points[i];
      final plotPos = transform.dataToPlot(point.x, point.y);
      path.lineTo(plotPos.dx, plotPos.dy);
    }

    // Close to x-axis
    final lastPoint = series.points.last;
    final lastPlot = transform.dataToPlot(lastPoint.x, lastPoint.y);
    path.lineTo(lastPlot.dx, transform.plotHeight);
    path.close();

    // Fill area
    final fillPaint = Paint()
      ..color = (series.color ?? const Color(0xFF2196F3)).withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // Draw line on top
    _paintLine(canvas, paint);
  }

  void _paintBar(Canvas canvas, Paint paint) {
    const barWidth = 10.0; // TODO: Calculate from data density
    final barPaint = paint..style = PaintingStyle.fill;

    for (final point in series.points) {
      final plotPos = transform.dataToPlot(point.x, point.y);
      final zeroY = transform.dataToPlot(point.x, 0).dy;

      final rect = Rect.fromLTRB(
        plotPos.dx - barWidth / 2,
        plotPos.dy,
        plotPos.dx + barWidth / 2,
        zeroY,
      );
      canvas.drawRect(rect, barPaint);
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
