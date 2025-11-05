// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Colors;

import '../core/chart_element.dart';

/// Simulated annotation element for testing.
///
/// **Purpose**: Test annotation interaction behavior including:
/// - Dragging annotations
/// - Resizing via handles
/// - Double-click to edit
/// - Right-click for context menu (Edit/Delete)
///
/// **Properties** (per CONFLICT_RESOLUTION_TABLE.md):
/// - Priority: 7-9 (HIGH - wins over datapoints and series)
/// - Resize handles: Priority 10 (CRITICAL - highest)
/// - Draggable: true (left-drag from annotation body)
/// - Resizable: true (drag from handles)
/// - Editable: true (double-click)
class SimulatedAnnotation extends ChartElement with TooltipElement {
  SimulatedAnnotation({
    required this.id,
    required Rect bounds,
    this.text = '',
    this.isSelected = false,
    this.isHovered = false,
    this.backgroundColor = const Color(0xFFFFF9C4),
    this.borderColor = const Color(0xFFFBC02D),
    this.textColor = const Color(0xFF000000),
  }) : _bounds = bounds;

  @override
  final String id;

  Rect _bounds;

  final String text;

  @override
  bool isSelected;

  @override
  bool isHovered;

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;

  /// Size of resize handles (8x8 px).
  static const double handleSize = 8.0;

  /// Hit test radius for resize handles (extends beyond visual size).
  static const double handleHitRadius = 12.0;

  @override
  Rect get bounds => _bounds;

  @override
  int get priority => 8; // HIGH priority (per conflict resolution)

  @override
  String get elementType => 'annotation';

  @override
  bool get isSelectable => true;

  @override
  bool get isDraggable => true;

  /// Whether this annotation is resizable.
  bool get isResizable => true;

  /// Whether this annotation is editable (double-click).
  bool get isEditable => true;

  @override
  bool get showTooltip => isHovered;

  @override
  Offset get tooltipPosition => _bounds.topLeft + const Offset(0, -20); // Above annotation

  @override
  ChartElement copyWith({bool? isHovered, bool? isSelected}) {
    return SimulatedAnnotation(
      id: id,
      bounds: _bounds,
      text: text,
      isSelected: isSelected ?? this.isSelected,
      isHovered: isHovered ?? this.isHovered,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      textColor: textColor,
    );
  }

  /// Updates the annotation bounds (for drag/resize operations).
  void updateBounds(Rect newBounds) {
    _bounds = newBounds;
  }

  /// Gets all resize handle positions.
  ///
  /// Returns 8 handles: corners (TL, TR, BL, BR) + midpoints (T, R, B, L).
  List<({String id, Offset center, ResizeDirection direction})> getResizeHandles() {
    final left = _bounds.left;
    final right = _bounds.right;
    final top = _bounds.top;
    final bottom = _bounds.bottom;
    final centerX = _bounds.center.dx;
    final centerY = _bounds.center.dy;

    return [
      // Corners
      (id: 'tl', center: Offset(left, top), direction: ResizeDirection.topLeft),
      (id: 'tr', center: Offset(right, top), direction: ResizeDirection.topRight),
      (id: 'bl', center: Offset(left, bottom), direction: ResizeDirection.bottomLeft),
      (id: 'br', center: Offset(right, bottom), direction: ResizeDirection.bottomRight),
      // Midpoints
      (id: 't', center: Offset(centerX, top), direction: ResizeDirection.top),
      (id: 'r', center: Offset(right, centerY), direction: ResizeDirection.right),
      (id: 'b', center: Offset(centerX, bottom), direction: ResizeDirection.bottom),
      (id: 'l', center: Offset(left, centerY), direction: ResizeDirection.left),
    ];
  }

  /// Hit tests for resize handles.
  ///
  /// Returns the handle ID and direction if hit, null otherwise.
  ({String handleId, ResizeDirection direction})? hitTestHandle(Offset position) {
    if (!isSelected) return null; // Handles only visible when selected

    final handles = getResizeHandles();
    for (final handle in handles) {
      final distance = (position - handle.center).distance;
      if (distance <= handleHitRadius) {
        return (handleId: handle.id, direction: handle.direction);
      }
    }
    return null;
  }

  @override
  bool hitTest(Offset position) {
    // Check handles first (higher priority)
    if (hitTestHandle(position) != null) {
      return true;
    }

    // Then check annotation body
    return _bounds.contains(position);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawRect(_bounds, bgPaint);

    // Draw border (thicker if selected)
    final borderPaint = Paint()
      ..color = isSelected ? borderColor : borderColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.0 : 1.0;
    canvas.drawRect(_bounds, borderPaint);

    // Draw hover indicator
    if (isHovered && !isSelected) {
      final hoverPaint = Paint()
        ..color = borderColor.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawRect(_bounds.inflate(2), hoverPaint);
    }

    // Draw resize handles if selected
    if (isSelected) {
      final handlePaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.fill;

      final handleBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      for (final handle in getResizeHandles()) {
        final handleRect = Rect.fromCenter(
          center: handle.center,
          width: handleSize,
          height: handleSize,
        );
        canvas.drawRect(handleRect, handlePaint);
        canvas.drawRect(handleRect, handleBorderPaint);
      }
    }

    // TODO: Draw text (needs TextPainter - skip for Phase 0)
    // For Phase 0, we'll just draw a simple placeholder
    if (text.isNotEmpty) {
      debugPrint('Annotation text: $text (rendering not implemented in Phase 0)');
    }
  }

  // ============================================================================
  // Interaction Callbacks
  // ============================================================================

  @override
  void onSelect() {
    isSelected = true;
    debugPrint('[SimulatedAnnotation] Selected: $id');
  }

  @override
  void onDeselect() {
    isSelected = false;
    debugPrint('[SimulatedAnnotation] Deselected: $id');
  }

  @override
  void onHoverEnter() {
    isHovered = true;
    debugPrint('[SimulatedAnnotation] Hover enter: $id');
  }

  @override
  void onHoverExit() {
    isHovered = false;
    debugPrint('[SimulatedAnnotation] Hover exit: $id');
  }

  @override
  String get tooltipText => 'Annotation: $text (${_bounds.width.toInt()} x ${_bounds.height.toInt()})';

  @override
  String toString() => 'SimulatedAnnotation(id: $id, bounds: $_bounds, text: "$text")';
}

/// Resize direction for annotation handles.
enum ResizeDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  top,
  right,
  bottom,
  left,
}
