// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../core/chart_element.dart';

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
  });

  @override
  final String id;

  /// Data points that make up this series.
  final List<Offset> points;

  final Color color;
  final double strokeWidth;

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
  int get priority => 5; // MEDIUM-LOW (per conflict resolution scenario 2)

  @override
  String get elementType => 'series';

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
      isSelected: isSelected ?? this.isSelected,
      isHovered: isHovered ?? this.isHovered,
    );
  }

  @override
  bool hitTest(Offset position) {
    if (points.length < 2) return false;

    // Check distance to each line segment
    for (int i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      final distance = _distanceToLineSegment(position, p1, p2);
      if (distance <= hitTolerance) {
        return true;
      }
    }

    return false;
  }

  /// Calculates distance from a point to a line segment.
  double _distanceToLineSegment(Offset point, Offset segStart, Offset segEnd) {
    final dx = segEnd.dx - segStart.dx;
    final dy = segEnd.dy - segStart.dy;

    if (dx == 0 && dy == 0) {
      // Segment is a point
      return (point - segStart).distance;
    }

    // Parameter t represents position along segment (0 = start, 1 = end)
    final t = ((point.dx - segStart.dx) * dx + (point.dy - segStart.dy) * dy) / (dx * dx + dy * dy);

    // Clamp t to [0, 1] to stay on segment
    final tClamped = t.clamp(0.0, 1.0);

    // Find closest point on segment
    final closest = Offset(
      segStart.dx + tClamped * dx,
      segStart.dy + tClamped * dy,
    );

    return (point - closest).distance;
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
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
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
    debugPrint('[SimulatedSeries] Selected: $id (${points.length} points)');
  }

  @override
  void onDeselect() {
    isSelected = false;
    debugPrint('[SimulatedSeries] Deselected: $id');
  }

  @override
  void onHoverEnter() {
    isHovered = true;
    debugPrint('[SimulatedSeries] Hover enter: $id');
  }

  @override
  void onHoverExit() {
    isHovered = false;
    debugPrint('[SimulatedSeries] Hover exit: $id');
  }

  @override
  String toString() => 'SimulatedSeries(id: $id, points: ${points.length})';
}
