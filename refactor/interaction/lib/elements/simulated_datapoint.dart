// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../core/chart_element.dart';

/// Simulated datapoint element for testing.
///
/// **Purpose**: Test the interaction architecture with realistic datapoint behavior.
///
/// **Properties** (per CONFLICT_RESOLUTION_TABLE.md):
/// - Priority: 6 (medium - per scenario 2)
/// - Hit radius: 10px (per scenario 5)
/// - Selectable: always true
/// - Draggable: true (left-drag if started on point)
/// - Tooltip: shows on hover (suspended during pan)
class SimulatedDatapoint extends ChartElement with TooltipElement {
  SimulatedDatapoint({
    required this.id,
    required this.center,
    this.radius = 6.0,
    this.isSelected = false,
    this.isHovered = false,
    this.color = const Color(0xFF2196F3),
    this.label = '',
  });
  @override
  final String id;

  final Offset center;
  final double radius;

  @override
  bool isSelected;

  @override
  bool isHovered;

  final Color color;
  final String label;

  @override
  Rect get bounds => Rect.fromCircle(center: center, radius: radius);

  @override
  int get priority => 6; // Per conflict resolution scenario 2

  @override
  String get elementType => 'datapoint';

  @override
  bool get isSelectable => true;

  @override
  bool get isDraggable => true;

  @override
  bool hitTest(Offset position) {
    // Per conflict resolution scenario 5: hit radius = 10px for interaction
    const hitRadius = 10.0;
    final distance = (position - center).distance;
    return distance <= hitRadius;
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw datapoint circle
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    if (isHovered) {
      paint.color = color.withOpacity(0.8);
    }

    canvas.drawCircle(center, radius, paint);

    // Draw selection indicator
    if (isSelected) {
      final selectionPaint = Paint()
        ..color = const Color(0xFF0088FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(center, radius + 3, selectionPaint);
    }

    // Draw hover indicator
    if (isHovered) {
      final hoverPaint = Paint()
        ..color = const Color(0x40FFFFFF)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, radius + 1, hoverPaint);
    }
  }

  @override
  void onSelect() {
    debugPrint('[Datapoint $id] Selected');
  }

  @override
  void onDeselect() {
    debugPrint('[Datapoint $id] Deselected');
  }

  @override
  void onHoverEnter() {
    debugPrint('[Datapoint $id] Hover enter');
  }

  @override
  void onHoverExit() {
    debugPrint('[Datapoint $id] Hover exit');
  }

  @override
  ChartElement copyWith({bool? isHovered, bool? isSelected}) {
    return SimulatedDatapoint(
      id: id,
      center: center,
      radius: radius,
      isSelected: isSelected ?? this.isSelected,
      isHovered: isHovered ?? this.isHovered,
      color: color,
      label: label,
    );
  }

  // TooltipElement implementation
  @override
  String get tooltipText => label.isNotEmpty ? label : 'Datapoint $id';

  @override
  bool get showTooltip => isHovered;

  @override
  Offset get tooltipPosition => center + Offset(0, -radius - 10);
}
