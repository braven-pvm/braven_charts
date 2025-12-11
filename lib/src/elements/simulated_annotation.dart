// Copyright (c) 2025 braven_charts. All rights reserved.
// Phase 0 Prototype - Interaction Architecture

import 'dart:ui';

import 'package:flutter/material.dart' show Colors;

import '../interaction/core/chart_element.dart';
import '../interaction/core/element_types.dart';
import '../interaction/core/hit_test_strategy.dart';
import 'resize_handle_element.dart';

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
  ChartElementType get elementType => ChartElementType.annotation;

  // Priority derived from elementType (6 - MEDIUM priority)

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
  Offset get tooltipPosition =>
      _bounds.topLeft + const Offset(0, -20); // Above annotation

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
  /// **DEPRECATED**: Use createResizeHandleElements() instead.
  List<({String id, Offset center, ResizeDirection direction})>
      getResizeHandles() {
    final left = _bounds.left;
    final right = _bounds.right;
    final top = _bounds.top;
    final bottom = _bounds.bottom;
    final center = _bounds.center;

    return [
      // Corners
      (id: 'tl', center: Offset(left, top), direction: ResizeDirection.topLeft),
      (
        id: 'tr',
        center: Offset(right, top),
        direction: ResizeDirection.topRight
      ),
      (
        id: 'bl',
        center: Offset(left, bottom),
        direction: ResizeDirection.bottomLeft
      ),
      (
        id: 'br',
        center: Offset(right, bottom),
        direction: ResizeDirection.bottomRight
      ),
      // Midpoints
      (id: 't', center: Offset(center.dx, top), direction: ResizeDirection.top),
      (
        id: 'r',
        center: Offset(right, center.dy),
        direction: ResizeDirection.right
      ),
      (
        id: 'b',
        center: Offset(center.dx, bottom),
        direction: ResizeDirection.bottom
      ),
      (
        id: 'l',
        center: Offset(left, center.dy),
        direction: ResizeDirection.left
      ),
    ];
  }

  /// Creates ResizeHandleElement instances for this annotation.
  ///
  /// These are separate ChartElements with priority 7 that participate
  /// in the unified hit-testing system. This ensures datapoints (priority 9)
  /// win over resize handles when they overlap.
  ///
  /// Returns list of 8 handle elements for the QuadTree.
  List<ResizeHandleElement> createResizeHandleElements() {
    const handleSize = 8.0; // 8px × 8px hit target
    const halfSize = handleSize / 2;

    final left = _bounds.left;
    final right = _bounds.right;
    final top = _bounds.top;
    final bottom = _bounds.bottom;

    return [
      // Corners
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.topLeft,
        bounds: Rect.fromCenter(
            center: Offset(left, top), width: handleSize, height: handleSize),
      ),
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.topRight,
        bounds: Rect.fromCenter(
            center: Offset(right, top), width: handleSize, height: handleSize),
      ),
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.bottomLeft,
        bounds: Rect.fromCenter(
            center: Offset(left, bottom),
            width: handleSize,
            height: handleSize),
      ),
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.bottomRight,
        bounds: Rect.fromCenter(
            center: Offset(right, bottom),
            width: handleSize,
            height: handleSize),
      ),
      // Edges (use continuous zones along the edge)
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.top,
        bounds: Rect.fromLTRB(
            left + halfSize, top - halfSize, right - halfSize, top + halfSize),
      ),
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.right,
        bounds: Rect.fromLTRB(right - halfSize, top + halfSize,
            right + halfSize, bottom - halfSize),
      ),
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.bottom,
        bounds: Rect.fromLTRB(left + halfSize, bottom - halfSize,
            right - halfSize, bottom + halfSize),
      ),
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.left,
        bounds: Rect.fromLTRB(left - halfSize, top + halfSize, left + halfSize,
            bottom - halfSize),
      ),
    ];
  }

  /// Hit tests for resize handles using continuous edge zones.
  ///
  /// Returns the resize direction if hit on edge/corner, null otherwise.
  ///
  /// **Note**: Edges are always hittable for interaction (selection/resize),
  /// even when not selected. Uses continuous 8px edge zones instead of discrete handles.
  ResizeDirection? hitTestHandle(Offset position) {
    // Use RectangleHitStrategy with continuous edge zones
    final strategy = RectangleHitStrategy(
      bounds: _bounds,
      edgeWidth: 8.0,
      enabledZones: {HitZone.edges},
    );

    // Check if position is on edge
    if (strategy.isOnEdge(position)) {
      return strategy.getResizeDirection(position);
    }

    return null;
  }

  @override
  bool hitTest(Offset position) {
    // Use RectangleHitStrategy for both edges and body
    final strategy = RectangleHitStrategy(
      bounds: _bounds,
      edgeWidth: 8.0,
      enabledZones: {HitZone.edges, HitZone.body},
    );

    return strategy.test(position);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background with transparency so you can see elements behind
    final bgPaint = Paint()
      ..color = backgroundColor.withOpacity(0.25) // Much more transparent
      ..style = PaintingStyle.fill;
    canvas.drawRect(_bounds, bgPaint);

    // Draw border (thicker if selected)
    final borderPaint = Paint()
      ..color = isSelected ? borderColor : borderColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 2.5 : 1.5;
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
  String get tooltipText =>
      'Annotation: $text (${_bounds.width.toInt()} x ${_bounds.height.toInt()})';

  @override
  String toString() =>
      'SimulatedAnnotation(id: $id, bounds: $_bounds, text: "$text")';
}
