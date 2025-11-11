// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'dart:ui';

import '../core/chart_element.dart';
import '../core/element_types.dart';
import '../core/hit_test_strategy.dart';

/// Simulated series element for testing.
///
/// **Purpose**: Test series interaction behavior including:
/// - Click to select series (highlight all points)
/// - Hover to highlight series line
/// - No drag unless Alt modifier pressed
///
/// **Properties** (per CONFLICT_RESOLUTION_TABLE.md):
/// - Priority: 5 (MEDIUM-LOW - loses to annotations and datapoints)
/// - Selectable: true (click to select)
/// - Draggable: false (unless Alt modifier - not in Phase 0)
/// - Hover: highlights line
class SimulatedSeries extends ChartElement {
  SimulatedSeries({
    required this.id,
    required this.points,
    this.color = const Color(0xFF2196F3),
    this.strokeWidth = 2.0,
    this.isSelected = false,
    this.isHovered = false,
    this.useBezier = false,
    this.tension = 0.3,
  });

  @override
  final String id;

  /// Data points that make up this series.
  final List<Offset> points;

  final Color color;
  final double strokeWidth;
  final bool useBezier;
  final double tension;

  @override
  bool isSelected;

  @override
  bool isHovered;

  /// Hit test tolerance (px from line).
  static const double hitTolerance = 10.0;

  @override
  Rect get bounds {
    if (points.isEmpty) return Rect.zero;

    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (final point in points) {
      if (point.dx < minX) minX = point.dx;
      if (point.dy < minY) minY = point.dy;
      if (point.dx > maxX) maxX = point.dx;
      if (point.dy > maxY) maxY = point.dy;
    }

    // Add hit tolerance margin
    return Rect.fromLTRB(
      minX - hitTolerance,
      minY - hitTolerance,
      maxX + hitTolerance,
      maxY + hitTolerance,
    );
  }

  @override
  ChartElementType get elementType => ChartElementType.series;

  // Priority derived from elementType (7 - HIGH priority)

  @override
  bool get isSelectable => true;

  @override
  bool get isDraggable => false; // Not draggable in Phase 0

  @override
  ChartElement copyWith({bool? isHovered, bool? isSelected}) {
    return SimulatedSeries(
      id: id,
      points: points,
      color: color,
      strokeWidth: strokeWidth,
      useBezier: useBezier,
      tension: tension,
      isSelected: isSelected ?? this.isSelected,
      isHovered: isHovered ?? this.isHovered,
    );
  }

  @override
  bool hitTest(Offset position) {
    return LineHitStrategy(points: points, tolerance: hitTolerance).test(position);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Determine line color and width based on state
    final lineColor = isSelected
        ? color
        : isHovered
            ? color.withOpacity(0.8)
            : color.withOpacity(0.6);
    final lineWidth = (isSelected || isHovered) ? strokeWidth + 1.0 : strokeWidth;

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw line segments
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);

    if (useBezier && points.length > 2) {
      // Draw bezier curves between points
      for (int i = 0; i < points.length - 1; i++) {
        final p0 = i > 0 ? points[i - 1] : points[i];
        final p1 = points[i];
        final p2 = points[i + 1];
        final p3 = i < points.length - 2 ? points[i + 2] : p2;

        // Calculate control points using Catmull-Rom spline
        final cp1x = p1.dx + (p2.dx - p0.dx) / 6 * tension;
        final cp1y = p1.dy + (p2.dy - p0.dy) / 6 * tension;
        final cp2x = p2.dx - (p3.dx - p1.dx) / 6 * tension;
        final cp2y = p2.dy - (p3.dy - p1.dy) / 6 * tension;

        path.cubicTo(cp1x, cp1y, cp2x, cp2y, p2.dx, p2.dy);
      }
    } else {
      // Draw simple lines
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
    }

    canvas.drawPath(path, paint);

    // Draw highlight glow if selected
    if (isSelected) {
      final glowPaint = Paint()
        ..color = color.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = lineWidth + 6.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

      canvas.drawPath(path, glowPaint);
    }
  }

  // ============================================================================
  // Interaction Callbacks
  // ============================================================================

  @override
  void onSelect() {
    isSelected = true;
  }

  @override
  void onDeselect() {
    isSelected = false;
  }

  @override
  void onHoverEnter() {
    isHovered = true;
  }

  @override
  void onHoverExit() {
    isHovered = false;
  }

  @override
  String toString() => 'SimulatedSeries(id: $id, points: ${points.length})';
}
