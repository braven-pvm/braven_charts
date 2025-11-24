// Copyright (c) 2025 braven_charts. All rights reserved.
// Annotation Element Classes for ChartRenderBox Integration

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../coordinates/chart_transform.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/element_types.dart';
import '../interaction/core/hit_test_strategy.dart';
import '../models/chart_annotation.dart';
import '../models/chart_data_point.dart';
import '../models/chart_series.dart';
import 'resize_handle_element.dart';

/// A chart element that renders a point annotation marker.
///
/// Marks a specific data point with a custom marker shape and color.
class PointAnnotationElement extends ChartElement {
  PointAnnotationElement({
    required this.annotation,
    required this.series,
    required this.transform,
  })  : _isSelected = false,
        _isHovered = false,
        _currentTransform = transform {
    // Get the data point from the series and store data coordinates
    if (annotation.dataPointIndex < series.points.length) {
      final point = series.points[annotation.dataPointIndex];
      _dataPosition = Offset(point.x, point.y);
    }
  }

  final PointAnnotation annotation;
  final ChartSeries series;
  final ChartTransform transform; // Initial transform for construction
  ChartTransform _currentTransform; // Current transform for painting

  Offset? _dataPosition; // Data coordinates (never changes)
  bool _isSelected;
  bool _isHovered;
  int? _candidateDataPointIndex; // For drag preview - shows where annotation will move to

  /// Update the current transform before painting (for real-time pan/zoom).
  /// This allows annotations to move smoothly during pan without regenerating elements.
  void updateTransform(ChartTransform newTransform) {
    _currentTransform = newTransform;
  }

  /// Update the candidate data point index for drag preview.
  void updateCandidateIndex(int? candidateIndex) {
    _candidateDataPointIndex = candidateIndex;
  }

  /// Clear the candidate data point index (end of drag).
  void clearCandidateIndex() {
    _candidateDataPointIndex = null;
  }

  /// Recalculate screen position using current transform.
  Offset? _getScreenPosition() {
    if (_dataPosition == null) return null;
    final screenPos = _currentTransform.dataToPlot(_dataPosition!.dx, _dataPosition!.dy);
    return screenPos + annotation.offset;
  }

  /// Get screen position for candidate data point (during drag preview).
  Offset? _getCandidateScreenPosition() {
    if (_candidateDataPointIndex == null || _candidateDataPointIndex! >= series.points.length) {
      return null;
    }
    final candidatePoint = series.points[_candidateDataPointIndex!];
    final screenPos = _currentTransform.dataToPlot(candidatePoint.x, candidatePoint.y);
    return screenPos + annotation.offset;
  }

  @override
  String get id => annotation.id;

  @override
  Rect get bounds {
    final screenPos = _getScreenPosition();
    if (screenPos == null) return Rect.zero;

    final hitRadius = annotation.markerSize + 4.0;
    return Rect.fromCircle(
      center: screenPos,
      radius: hitRadius,
    );
  }

  @override
  // PointAnnotations should have datapoint priority (9) so they're clickable over series (8)
  // This allows the two-click drag-to-move interaction to work correctly
  ChartElementType get elementType => ChartElementType.datapoint;

  @override
  bool get isSelected => _isSelected;

  @override
  bool get isHovered => _isHovered;

  @override
  bool get isSelectable => true;

  @override
  bool get isDraggable => annotation.allowDragging;

  @override
  bool hitTest(Offset position) {
    final screenPos = _getScreenPosition();
    if (screenPos == null) return false;

    final hitRadius = annotation.markerSize + 4.0;
    final distance = (position - screenPos).distance;
    return distance <= hitRadius;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final screenPos = _getScreenPosition();
    if (screenPos == null) return;

    // If dragging, show preview at candidate position
    if (_candidateDataPointIndex != null && _candidateDataPointIndex != annotation.dataPointIndex) {
      final candidatePos = _getCandidateScreenPosition();
      if (candidatePos != null) {
        // Draw ghost marker at original position (semi-transparent)
        final ghostPaint = Paint()
          ..color = annotation.markerColor.withOpacity(0.3)
          ..style = PaintingStyle.fill;
        _drawMarker(canvas, screenPos, annotation.markerShape, annotation.markerSize, ghostPaint);

        // Draw preview marker at candidate position (highlighted)
        final previewPaint = Paint()
          ..color = annotation.markerColor.withOpacity(0.8)
          ..style = PaintingStyle.fill;
        _drawMarker(canvas, candidatePos, annotation.markerShape, annotation.markerSize * 1.2, previewPaint);

        // Draw outline on preview marker
        final outlinePaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        _drawMarker(canvas, candidatePos, annotation.markerShape, annotation.markerSize * 1.2, outlinePaint);

        return; // Don't draw the normal marker when showing preview
      }
    }

    final paint = Paint()
      ..color = annotation.markerColor
      ..style = PaintingStyle.fill;

    // Add selection/hover feedback
    if (_isSelected || _isHovered) {
      paint.color = paint.color.withOpacity(_isSelected ? 1.0 : 0.7);
    }

    _drawMarker(canvas, screenPos, annotation.markerShape, annotation.markerSize, paint);

    // Draw label if present
    if (annotation.label != null && annotation.label!.isNotEmpty) {
      _drawLabel(canvas, screenPos, annotation.label!);
    }
  }

  void _drawMarker(Canvas canvas, Offset center, MarkerShape shape, double size, Paint paint) {
    final radius = size / 2;

    switch (shape) {
      case MarkerShape.circle:
        canvas.drawCircle(center, radius, paint);
        break;

      case MarkerShape.square:
        final rect = Rect.fromCenter(center: center, width: size, height: size);
        canvas.drawRect(rect, paint);
        break;

      case MarkerShape.triangle:
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx + radius * 0.866, center.dy + radius * 0.5)
          ..lineTo(center.dx - radius * 0.866, center.dy + radius * 0.5)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case MarkerShape.diamond:
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy)
          ..lineTo(center.dx, center.dy + radius)
          ..lineTo(center.dx - radius, center.dy)
          ..close();
        canvas.drawPath(path, paint);
        break;

      case MarkerShape.star:
        final path = Path();
        const numPoints = 5;
        const outerRadius = 1.0;
        const innerRadius = 0.4;

        for (var i = 0; i < numPoints * 2; i++) {
          final angle = (i * math.pi / numPoints) - math.pi / 2;
          final r = (i.isEven ? outerRadius : innerRadius) * radius;
          final x = center.dx + r * math.cos(angle);
          final y = center.dy + r * math.sin(angle);

          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;

      case MarkerShape.cross:
        final path = Path()
          ..moveTo(center.dx - radius, center.dy - radius)
          ..lineTo(center.dx + radius, center.dy + radius)
          ..moveTo(center.dx + radius, center.dy - radius)
          ..lineTo(center.dx - radius, center.dy + radius);
        canvas.drawPath(
            path,
            Paint()
              ..color = paint.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0);
        break;

      case MarkerShape.plus:
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..lineTo(center.dx, center.dy + radius)
          ..moveTo(center.dx - radius, center.dy)
          ..lineTo(center.dx + radius, center.dy);
        canvas.drawPath(
            path,
            Paint()
              ..color = paint.color
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0);
        break;
    }
  }

  void _drawLabel(Canvas canvas, Offset position, String label) {
    final textStyle = annotation.style.textStyle;
    final textSpan = TextSpan(text: label, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    // Get padding from style or use default
    final padding = annotation.style.padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 3);

    // Calculate label container dimensions (includes padding)
    final containerWidth = textPainter.width + padding.left + padding.right;
    final containerHeight = textPainter.height + padding.top + padding.bottom;

    // Use labelMargin from annotation
    final labelMargin = annotation.labelMargin;

    // Position label container to the right of the marker, vertically centered
    final bgRect = Rect.fromLTWH(
      position.dx + annotation.markerSize + labelMargin,
      position.dy - containerHeight / 2,
      containerWidth,
      containerHeight,
    );

    // Draw background if specified
    if (annotation.style.backgroundColor != null) {
      final bgPaint = Paint()
        ..color = annotation.style.backgroundColor!
        ..style = PaintingStyle.fill;

      final borderRadius = annotation.style.borderRadius ?? BorderRadius.circular(4);
      final rrect = borderRadius.toRRect(bgRect);
      canvas.drawRRect(rrect, bgPaint);
    }

    // Draw border if specified
    if (annotation.style.borderColor != null && annotation.style.borderWidth > 0) {
      final borderPaint = Paint()
        ..color = annotation.style.borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = annotation.style.borderWidth;

      final borderRadius = annotation.style.borderRadius ?? BorderRadius.circular(4);
      final rrect = borderRadius.toRRect(bgRect);
      canvas.drawRRect(rrect, borderPaint);
    }

    // Draw text inside container (accounting for padding)
    final textPosition = Offset(
      bgRect.left + padding.left,
      bgRect.top + padding.top,
    );
    textPainter.paint(canvas, textPosition);
  }

  @override
  void onSelect() => _isSelected = true;

  @override
  void onDeselect() => _isSelected = false;

  @override
  void onHoverEnter() => _isHovered = true;

  @override
  void onHoverExit() => _isHovered = false;

  @override
  ChartElement copyWith({bool? isHovered, bool? isSelected}) {
    final copy = PointAnnotationElement(
      annotation: annotation,
      series: series,
      transform: transform,
    );
    copy._isSelected = isSelected ?? _isSelected;
    copy._isHovered = isHovered ?? _isHovered;
    copy._dataPosition = _dataPosition;
    copy._currentTransform = _currentTransform;
    return copy;
  }
}

/// A chart element that renders a range annotation.
///
/// Highlights a rectangular region on the chart with optional fill and border.
/// Implements ResizableElement to support resizing via edge/corner handles.
class RangeAnnotationElement extends ChartElement with ResizableElement {
  RangeAnnotationElement({
    required this.annotation,
    required this.transform,
    required this.chartSize,
  })  : _isSelected = false,
        _isHovered = false,
        _currentTransform = transform;

  final RangeAnnotation annotation;
  final ChartTransform transform; // Initial transform for construction
  ChartTransform _currentTransform; // Current transform for painting
  final Size chartSize;

  bool _isSelected;
  bool _isHovered;

  // Temporary resize bounds (in screen space)
  Rect? _tempResizeBounds;

  /// Update the current transform before painting (for real-time pan/zoom).
  void updateTransform(ChartTransform newTransform) {
    _currentTransform = newTransform;
  }

  /// Updates annotation bounds (for resize operations).
  ///
  /// Stores temporary screen-space bounds that will be used during resize
  /// operations until the drag is complete.
  void updateBounds(Rect newBounds) {
    _tempResizeBounds = newBounds;
  }

  /// Clears temporary resize bounds (called when resize operation completes).
  void clearTempBounds() {
    _tempResizeBounds = null;
  }

  /// Calculate bounds and fill rect using current transform.
  Rect _calculateRect() {
    // If we're in the middle of a resize operation, use temporary bounds
    if (_tempResizeBounds != null) {
      return _tempResizeBounds!;
    }
    // Transform data ranges to screen coordinates
    final left = annotation.startX != null ? _currentTransform.dataToPlot(annotation.startX!, 0).dx : 0.0;

    final right = annotation.endX != null ? _currentTransform.dataToPlot(annotation.endX!, 0).dx : chartSize.width;

    final top = annotation.startY != null ? _currentTransform.dataToPlot(0, annotation.startY!).dy : 0.0;

    final bottom = annotation.endY != null ? _currentTransform.dataToPlot(0, annotation.endY!).dy : chartSize.height;

    final rect = Rect.fromLTRB(
      left.clamp(0.0, chartSize.width),
      top.clamp(0.0, chartSize.height),
      right.clamp(0.0, chartSize.width),
      bottom.clamp(0.0, chartSize.height),
    );

    return rect;
  }

  @override
  String get id => annotation.id;

  @override
  Rect get bounds => _calculateRect();

  @override
  ChartElementType get elementType => ChartElementType.annotation;

  @override
  bool get isSelected => _isSelected;

  @override
  bool get isHovered => _isHovered;

  @override
  bool get isSelectable => true;

  @override
  bool get isDraggable => annotation.allowDragging;

  @override
  bool hitTest(Offset position) {
    return _calculateRect().contains(position);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final fillRect = _calculateRect();

    // Draw fill
    if (annotation.fillColor != null) {
      final fillPaint = Paint()
        ..color = annotation.fillColor!
        ..style = PaintingStyle.fill;

      if (_isHovered) {
        fillPaint.color = fillPaint.color.withOpacity(fillPaint.color.opacity * 1.2);
      }

      canvas.drawRect(fillRect, fillPaint);
    }

    // Draw border
    if (annotation.borderColor != null) {
      final borderPaint = Paint()
        ..color = annotation.borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = _isSelected ? 2.0 : 1.0;

      canvas.drawRect(fillRect, borderPaint);
    }

    // Draw label if present
    if (annotation.label != null && annotation.label!.isNotEmpty) {
      _drawLabel(canvas, fillRect, annotation.label!);
    }

    // Draw resize handles if selected
    if (_isSelected) {
      _drawResizeHandles(canvas, fillRect);
    }
  }

  void _drawResizeHandles(Canvas canvas, Rect rect) {
    const handleSize = 8.0;
    final handlePaint = Paint()
      ..color = annotation.borderColor ?? const Color(0xFFFBC02D)
      ..style = PaintingStyle.fill;

    final handleBorderPaint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Get handle positions
    final handles = [
      Offset(rect.left, rect.top), // Top-left
      Offset(rect.right, rect.top), // Top-right
      Offset(rect.left, rect.bottom), // Bottom-left
      Offset(rect.right, rect.bottom), // Bottom-right
      Offset(rect.center.dx, rect.top), // Top
      Offset(rect.right, rect.center.dy), // Right
      Offset(rect.center.dx, rect.bottom), // Bottom
      Offset(rect.left, rect.center.dy), // Left
    ];

    // Draw each handle
    for (final center in handles) {
      final handleRect = Rect.fromCenter(
        center: center,
        width: handleSize,
        height: handleSize,
      );
      canvas.drawRect(handleRect, handlePaint);
      canvas.drawRect(handleRect, handleBorderPaint);
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, String label) {
    final textStyle = annotation.style.textStyle;
    final textSpan = TextSpan(text: label, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    // Get padding from style or use default
    final padding = annotation.style.padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 3);

    // Calculate label container dimensions (includes padding)
    final containerWidth = textPainter.width + padding.left + padding.right;
    final containerHeight = textPainter.height + padding.top + padding.bottom;

    // Use labelMargin from annotation
    final labelMargin = annotation.labelMargin;

    // Position label container (bgRect) based on labelPosition
    // The container edge should be labelMargin away from the range edge
    Rect bgRect;
    switch (annotation.labelPosition) {
      case AnnotationLabelPosition.topLeft:
        // Container's top-left corner is labelMargin from range's top-left corner
        bgRect = Rect.fromLTWH(
          rect.left + labelMargin,
          rect.top + labelMargin,
          containerWidth,
          containerHeight,
        );
        break;
      case AnnotationLabelPosition.topRight:
        // Container's top-right corner is labelMargin from range's top-right corner
        bgRect = Rect.fromLTWH(
          rect.right - containerWidth - labelMargin,
          rect.top + labelMargin,
          containerWidth,
          containerHeight,
        );
        break;
      case AnnotationLabelPosition.bottomLeft:
        // Container's bottom-left corner is labelMargin from range's bottom-left corner
        bgRect = Rect.fromLTWH(
          rect.left + labelMargin,
          rect.bottom - containerHeight - labelMargin,
          containerWidth,
          containerHeight,
        );
        break;
      case AnnotationLabelPosition.bottomRight:
        // Container's bottom-right corner is labelMargin from range's bottom-right corner
        bgRect = Rect.fromLTWH(
          rect.right - containerWidth - labelMargin,
          rect.bottom - containerHeight - labelMargin,
          containerWidth,
          containerHeight,
        );
        break;
      case AnnotationLabelPosition.center:
        // Container centered within the range
        bgRect = Rect.fromLTWH(
          rect.center.dx - containerWidth / 2,
          rect.center.dy - containerHeight / 2,
          containerWidth,
          containerHeight,
        );
        break;
    }

    // Draw background if specified
    if (annotation.style.backgroundColor != null) {
      final bgPaint = Paint()..color = annotation.style.backgroundColor!;
      final borderRadius = annotation.style.borderRadius ?? BorderRadius.circular(4);
      final rrect = borderRadius.toRRect(bgRect);
      canvas.drawRRect(rrect, bgPaint);
    }

    // Draw border if specified
    if (annotation.style.borderColor != null && annotation.style.borderWidth > 0) {
      final borderPaint = Paint()
        ..color = annotation.style.borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = annotation.style.borderWidth;
      final borderRadius = annotation.style.borderRadius ?? BorderRadius.circular(4);
      final rrect = borderRadius.toRRect(bgRect);
      canvas.drawRRect(rrect, borderPaint);
    }

    // Draw text inside container (accounting for padding)
    final textPosition = Offset(
      bgRect.left + padding.left,
      bgRect.top + padding.top,
    );
    textPainter.paint(canvas, textPosition);
  }

  @override
  void onSelect() => _isSelected = true;

  @override
  void onDeselect() => _isSelected = false;

  @override
  void onHoverEnter() => _isHovered = true;

  @override
  void onHoverExit() => _isHovered = false;

  // ============================================================================
  // ResizableElement implementation
  // ============================================================================

  @override
  List<ResizeHandleElement> createResizeHandleElements() {
    const handleSize = 8.0; // 8px × 8px hit target
    const halfSize = handleSize / 2;

    final rect = _calculateRect();
    final left = rect.left;
    final right = rect.right;
    final top = rect.top;
    final bottom = rect.bottom;

    return [
      // Corners
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.topLeft,
        bounds: Rect.fromCenter(center: Offset(left, top), width: handleSize, height: handleSize),
      ),
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.topRight,
        bounds: Rect.fromCenter(center: Offset(right, top), width: handleSize, height: handleSize),
      ),
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.bottomLeft,
        bounds: Rect.fromCenter(center: Offset(left, bottom), width: handleSize, height: handleSize),
      ),
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.bottomRight,
        bounds: Rect.fromCenter(center: Offset(right, bottom), width: handleSize, height: handleSize),
      ),
      // Edges (continuous zones along the edge)
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.top,
        bounds: Rect.fromLTRB(left + halfSize, top - halfSize, right - halfSize, top + halfSize),
      ),
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.right,
        bounds: Rect.fromLTRB(right - halfSize, top + halfSize, right + halfSize, bottom - halfSize),
      ),
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.bottom,
        bounds: Rect.fromLTRB(left + halfSize, bottom - halfSize, right - halfSize, bottom + halfSize),
      ),
      ResizeHandleElement(
        parentAnnotation: this,
        direction: ResizeDirection.left,
        bounds: Rect.fromLTRB(left - halfSize, top + halfSize, left + halfSize, bottom - halfSize),
      ),
    ];
  }

  @override
  List<Rect> get resizeHandleBounds {
    final handles = createResizeHandleElements();
    return handles.map((h) => h.bounds).toList();
  }

  @override
  int? getResizeHandleAt(Offset position) {
    final handles = createResizeHandleElements();
    for (int i = 0; i < handles.length; i++) {
      if (handles[i].hitTest(position)) {
        return i;
      }
    }
    return null;
  }

  @override
  bool get showResizeHandles => _isSelected;

  // ============================================================================

  @override
  ChartElement copyWith({bool? isHovered, bool? isSelected}) {
    final copy = RangeAnnotationElement(
      annotation: annotation,
      transform: transform,
      chartSize: chartSize,
    );
    copy._isSelected = isSelected ?? _isSelected;
    copy._isHovered = isHovered ?? _isHovered;
    copy._currentTransform = _currentTransform;
    return copy;
  }
}

/// A chart element that renders a text annotation.
///
/// Displays text at a fixed screen position with optional background.
class TextAnnotationElement extends ChartElement {
  TextAnnotationElement({
    required this.annotation,
  })  : _isSelected = false,
        _isHovered = false {
    _calculateBounds();
  }

  final TextAnnotation annotation;

  Rect? _bounds;
  Offset? _anchoredPosition;
  bool _isSelected;
  bool _isHovered;

  /// Temporary position during drag (null when not dragging).
  Offset? _tempPosition;

  /// Get the current temp position (used during drag completion).
  Offset? get tempPosition => _tempPosition;

  void _calculateBounds() {
    final textStyle = annotation.style.textStyle;
    final textSpan = TextSpan(text: annotation.text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final textSize = textPainter.size;
    final padding = annotation.style.padding ?? const EdgeInsets.all(4.0);

    // Use temp position during drag, otherwise use annotation's position
    final effectivePosition = _tempPosition ?? annotation.position;

    // Calculate anchored position
    _anchoredPosition = _getAnchoredPosition(
      effectivePosition,
      textSize + Offset(padding.horizontal, padding.vertical),
      annotation.anchor,
    );

    _bounds = Rect.fromLTWH(
      _anchoredPosition!.dx - padding.left,
      _anchoredPosition!.dy - padding.top,
      textSize.width + padding.horizontal,
      textSize.height + padding.vertical,
    );
  }

  Offset _getAnchoredPosition(Offset position, Size size, AnnotationAnchor anchor) {
    switch (anchor) {
      case AnnotationAnchor.topLeft:
        return position;
      case AnnotationAnchor.topCenter:
        return Offset(position.dx - size.width / 2, position.dy);
      case AnnotationAnchor.topRight:
        return Offset(position.dx - size.width, position.dy);
      case AnnotationAnchor.centerLeft:
        return Offset(position.dx, position.dy - size.height / 2);
      case AnnotationAnchor.center:
        return Offset(position.dx - size.width / 2, position.dy - size.height / 2);
      case AnnotationAnchor.centerRight:
        return Offset(position.dx - size.width, position.dy - size.height / 2);
      case AnnotationAnchor.bottomLeft:
        return Offset(position.dx, position.dy - size.height);
      case AnnotationAnchor.bottomCenter:
        return Offset(position.dx - size.width / 2, position.dy - size.height);
      case AnnotationAnchor.bottomRight:
        return Offset(position.dx - size.width, position.dy - size.height);
    }
  }

  @override
  String get id => annotation.id;

  @override
  Rect get bounds => _bounds ?? Rect.zero;

  @override
  ChartElementType get elementType => ChartElementType.annotation;

  @override
  bool get isSelected => _isSelected;

  @override
  bool get isHovered => _isHovered;

  @override
  bool get isSelectable => true;

  @override
  bool get isDraggable => annotation.allowDragging;

  @override
  bool hitTest(Offset position) {
    return _bounds?.contains(position) ?? false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_bounds == null || _anchoredPosition == null) return;

    // Draw background
    if (annotation.backgroundColor != null || annotation.style.backgroundColor != null) {
      final bgColor = annotation.backgroundColor ?? annotation.style.backgroundColor!;
      final bgPaint = Paint()..color = bgColor;

      if (_isHovered) {
        bgPaint.color = bgPaint.color.withOpacity((bgPaint.color.opacity * 1.1).clamp(0.0, 1.0));
      }

      if (annotation.style.borderRadius != null) {
        final rRect = RRect.fromRectAndCorners(
          _bounds!,
          topLeft: annotation.style.borderRadius!.topLeft,
          topRight: annotation.style.borderRadius!.topRight,
          bottomLeft: annotation.style.borderRadius!.bottomLeft,
          bottomRight: annotation.style.borderRadius!.bottomRight,
        );
        canvas.drawRRect(rRect, bgPaint);
      } else {
        canvas.drawRect(_bounds!, bgPaint);
      }
    }

    // Draw border
    if (annotation.borderColor != null || annotation.style.borderColor != null) {
      final borderColor = annotation.borderColor ?? annotation.style.borderColor!;
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = _isSelected ? annotation.style.borderWidth * 1.5 : annotation.style.borderWidth;

      if (annotation.style.borderRadius != null) {
        final rRect = RRect.fromRectAndCorners(
          _bounds!,
          topLeft: annotation.style.borderRadius!.topLeft,
          topRight: annotation.style.borderRadius!.topRight,
          bottomLeft: annotation.style.borderRadius!.bottomLeft,
          bottomRight: annotation.style.borderRadius!.bottomRight,
        );
        canvas.drawRRect(rRect, borderPaint);
      } else {
        canvas.drawRect(_bounds!, borderPaint);
      }
    }

    // Draw text
    final textStyle = annotation.style.textStyle;
    final textSpan = TextSpan(text: annotation.text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(canvas, Offset(_anchoredPosition!.dx, _anchoredPosition!.dy));
  }

  /// Update temporary position during drag.
  void updateTempPosition(Offset newPosition) {
    _tempPosition = newPosition;
    _calculateBounds(); // Recalculate bounds with new position
  }

  /// Clear temporary position after drag completes.
  void clearTempPosition() {
    _tempPosition = null;
    _calculateBounds(); // Recalculate bounds with original position
  }

  @override
  void onSelect() => _isSelected = true;

  @override
  void onDeselect() => _isSelected = false;

  @override
  void onHoverEnter() => _isHovered = true;

  @override
  void onHoverExit() => _isHovered = false;

  @override
  ChartElement copyWith({bool? isHovered, bool? isSelected}) {
    final copy = TextAnnotationElement(annotation: annotation);
    copy._isSelected = isSelected ?? _isSelected;
    copy._isHovered = isHovered ?? _isHovered;
    copy._bounds = _bounds;
    copy._anchoredPosition = _anchoredPosition;
    return copy;
  }
}

/// A chart element that renders a threshold annotation line.
///
/// Draws a horizontal or vertical reference line at a fixed axis value.
class ThresholdAnnotationElement extends ChartElement {
  ThresholdAnnotationElement({
    required this.annotation,
    required this.transform,
  })  : _isSelected = false,
        _isHovered = false,
        _currentTransform = transform;

  final ThresholdAnnotation annotation;
  final ChartTransform transform;
  ChartTransform _currentTransform;
  bool _isSelected;
  bool _isHovered;

  /// Temporary value during drag operations (in data coordinates).
  double? _tempValue;

  /// Get the temporary value being previewed during drag (if any).
  double? get tempValue => _tempValue;

  /// Update temporary value for drag preview.
  void updateTempValue(double newValue) {
    _tempValue = newValue;
  }

  /// Clear temporary value after drag completes.
  void clearTempValue() {
    _tempValue = null;
  }

  /// Update the current transform before painting.
  void updateTransform(ChartTransform newTransform) {
    _currentTransform = newTransform;
  }

  @override
  String get id => annotation.id;

  @override
  Rect get bounds {
    // Use temp value during drag, otherwise use annotation value
    final value = _tempValue ?? annotation.value;

    // Threshold spans the entire plot area in one direction
    const hitMargin = 20.0; // 20px margin on each side of line for easier clicking

    if (annotation.axis == AnnotationAxis.y) {
      // Horizontal line at Y value
      final plotY = _currentTransform.dataToPlot(0, value).dy;
      return Rect.fromLTWH(
        0,
        plotY - annotation.lineWidth / 2 - hitMargin, // Center line, then add margin above
        _currentTransform.plotWidth,
        annotation.lineWidth + (hitMargin * 2), // Line width plus margin on both sides
      );
    } else {
      // Vertical line at X value
      final plotX = _currentTransform.dataToPlot(value, 0).dx;
      return Rect.fromLTWH(
        plotX - annotation.lineWidth / 2 - hitMargin, // Center line, then add margin to left
        0,
        annotation.lineWidth + (hitMargin * 2), // Line width plus margin on both sides
        _currentTransform.plotHeight,
      );
    }
  }

  @override
  ChartElementType get elementType => ChartElementType.annotation;

  @override
  bool get isSelected => _isSelected;

  @override
  bool get isHovered => _isHovered;

  @override
  bool get isSelectable => true;

  @override
  bool get isDraggable => annotation.allowDragging;

  @override
  bool hitTest(Offset position) {
    return bounds.contains(position);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Use temp value during drag, otherwise use annotation value
    final value = _tempValue ?? annotation.value;
    final isDragging = _tempValue != null;

    // Calculate line position
    Offset start, end;
    if (annotation.axis == AnnotationAxis.y) {
      // Horizontal line
      final plotY = _currentTransform.dataToPlot(0, value).dy;
      start = Offset(0, plotY);
      end = Offset(_currentTransform.plotWidth, plotY);
    } else {
      // Vertical line
      final plotX = _currentTransform.dataToPlot(value, 0).dx;
      start = Offset(plotX, 0);
      end = Offset(plotX, _currentTransform.plotHeight);
    }

    // Draw halo effect during drag (transparent box around threshold)
    if (isDragging) {
      final haloPaint = Paint()
        ..color = annotation.lineColor.withAlpha(30)
        ..style = PaintingStyle.fill;

      const haloWidth = 8.0; // Width of halo on each side
      Rect haloRect;
      if (annotation.axis == AnnotationAxis.y) {
        // Horizontal line - halo above and below
        haloRect = Rect.fromLTRB(
          0,
          start.dy - haloWidth,
          _currentTransform.plotWidth,
          start.dy + haloWidth,
        );
      } else {
        // Vertical line - halo left and right
        haloRect = Rect.fromLTRB(
          start.dx - haloWidth,
          0,
          start.dx + haloWidth,
          _currentTransform.plotHeight,
        );
      }
      canvas.drawRect(haloRect, haloPaint);
    }

    // Draw selection glow (behind the line)
    if (_isSelected) {
      final glowPaint = Paint()
        ..color = annotation.lineColor.withAlpha(100)
        ..strokeWidth = annotation.lineWidth * 3.0
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

      if (annotation.dashPattern != null && annotation.dashPattern!.isNotEmpty) {
        _drawDashedLine(canvas, start, end, glowPaint, annotation.dashPattern!);
      } else {
        canvas.drawLine(start, end, glowPaint);
      }
    }

    // Draw main line
    final paint = Paint()
      ..color = annotation.lineColor
      ..strokeWidth = _isSelected ? annotation.lineWidth * 2.0 : annotation.lineWidth
      ..style = PaintingStyle.stroke;

    // Draw line (with dash pattern if specified)
    if (annotation.dashPattern != null && annotation.dashPattern!.isNotEmpty) {
      _drawDashedLine(canvas, start, end, paint, annotation.dashPattern!);
    } else {
      canvas.drawLine(start, end, paint);
    }

    // Draw label if present
    if (annotation.label != null && annotation.label!.isNotEmpty) {
      final textStyle = annotation.style.textStyle;
      final textSpan = TextSpan(text: annotation.label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      // Get padding from style or use default
      final padding = annotation.style.padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 3);

      // Calculate label container dimensions (includes padding)
      final containerWidth = textPainter.width + padding.left + padding.right;
      final containerHeight = textPainter.height + padding.top + padding.bottom;

      // Use labelMargin from annotation
      final labelMargin = annotation.labelMargin;

      // Position label container based on labelPosition and axis orientation
      Rect bgRect;
      if (annotation.axis == AnnotationAxis.y) {
        // Horizontal line - position label relative to line Y coordinate
        final lineY = start.dy;
        switch (annotation.labelPosition) {
          case AnnotationLabelPosition.topLeft:
            // Container above line, aligned left
            bgRect = Rect.fromLTWH(
              start.dx + labelMargin,
              lineY - containerHeight - labelMargin,
              containerWidth,
              containerHeight,
            );
            break;
          case AnnotationLabelPosition.topRight:
            // Container above line, aligned right
            bgRect = Rect.fromLTWH(
              end.dx - containerWidth - labelMargin,
              lineY - containerHeight - labelMargin,
              containerWidth,
              containerHeight,
            );
            break;
          case AnnotationLabelPosition.bottomLeft:
            // Container below line, aligned left
            bgRect = Rect.fromLTWH(
              start.dx + labelMargin,
              lineY + labelMargin,
              containerWidth,
              containerHeight,
            );
            break;
          case AnnotationLabelPosition.bottomRight:
            // Container below line, aligned right
            bgRect = Rect.fromLTWH(
              end.dx - containerWidth - labelMargin,
              lineY + labelMargin,
              containerWidth,
              containerHeight,
            );
            break;
          case AnnotationLabelPosition.center:
            // Container centered on line
            bgRect = Rect.fromLTWH(
              (start.dx + end.dx) / 2 - containerWidth / 2,
              lineY - containerHeight / 2,
              containerWidth,
              containerHeight,
            );
            break;
        }
      } else {
        // Vertical line - position label relative to line X coordinate
        final lineX = start.dx;
        switch (annotation.labelPosition) {
          case AnnotationLabelPosition.topLeft:
            // Container left of line, aligned top
            bgRect = Rect.fromLTWH(
              lineX - containerWidth - labelMargin,
              start.dy + labelMargin,
              containerWidth,
              containerHeight,
            );
            break;
          case AnnotationLabelPosition.topRight:
            // Container right of line, aligned top
            bgRect = Rect.fromLTWH(
              lineX + labelMargin,
              start.dy + labelMargin,
              containerWidth,
              containerHeight,
            );
            break;
          case AnnotationLabelPosition.bottomLeft:
            // Container left of line, aligned bottom
            bgRect = Rect.fromLTWH(
              lineX - containerWidth - labelMargin,
              end.dy - containerHeight - labelMargin,
              containerWidth,
              containerHeight,
            );
            break;
          case AnnotationLabelPosition.bottomRight:
            // Container right of line, aligned bottom
            bgRect = Rect.fromLTWH(
              lineX + labelMargin,
              end.dy - containerHeight - labelMargin,
              containerWidth,
              containerHeight,
            );
            break;
          case AnnotationLabelPosition.center:
            // Container centered on line
            bgRect = Rect.fromLTWH(
              lineX - containerWidth / 2,
              (start.dy + end.dy) / 2 - containerHeight / 2,
              containerWidth,
              containerHeight,
            );
            break;
        }
      }

      // Draw background if backgroundColor is set
      if (annotation.style.backgroundColor != null) {
        final bgPaint = Paint()
          ..color = annotation.style.backgroundColor!
          ..style = PaintingStyle.fill;
        final borderRadius = annotation.style.borderRadius ?? BorderRadius.circular(4);
        final rrect = borderRadius.toRRect(bgRect);
        canvas.drawRRect(rrect, bgPaint);
      }

      // Draw border if borderColor and borderWidth are set
      if (annotation.style.borderColor != null && annotation.style.borderWidth > 0) {
        final borderPaint = Paint()
          ..color = annotation.style.borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = annotation.style.borderWidth;
        final borderRadius = annotation.style.borderRadius ?? BorderRadius.circular(4);
        final rrect = borderRadius.toRRect(bgRect);
        canvas.drawRRect(rrect, borderPaint);
      }

      // Draw text inside container (accounting for padding)
      final textPosition = Offset(
        bgRect.left + padding.left,
        bgRect.top + padding.top,
      );
      textPainter.paint(canvas, textPosition);
    }
  }

  /// Draws a dashed line using the provided dash pattern.
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, List<double> dashPattern) {
    final totalLength = (end - start).distance;
    var currentLength = 0.0;
    var patternIndex = 0;
    var isDash = true;

    while (currentLength < totalLength) {
      final dashLength = dashPattern[patternIndex % dashPattern.length];
      final nextLength = math.min(currentLength + dashLength, totalLength);

      if (isDash) {
        final t1 = currentLength / totalLength;
        final t2 = nextLength / totalLength;
        final p1 = Offset.lerp(start, end, t1)!;
        final p2 = Offset.lerp(start, end, t2)!;
        canvas.drawLine(p1, p2, paint);
      }

      currentLength = nextLength;
      patternIndex++;
      isDash = !isDash;
    }
  }

  @override
  void onSelect() => _isSelected = true;

  @override
  void onDeselect() => _isSelected = false;

  @override
  void onHoverEnter() => _isHovered = true;

  @override
  void onHoverExit() => _isHovered = false;

  @override
  ChartElement copyWith({bool? isHovered, bool? isSelected}) {
    final copy = ThresholdAnnotationElement(
      annotation: annotation,
      transform: _currentTransform,
    );
    copy._isSelected = isSelected ?? _isSelected;
    copy._isHovered = isHovered ?? _isHovered;
    return copy;
  }
}

/// A chart element that renders a trend annotation line.
///
/// Calculates and displays statistical trend lines over series data.
class TrendAnnotationElement extends ChartElement {
  TrendAnnotationElement({
    required this.annotation,
    required this.series,
    required this.transform,
  })  : _isSelected = false,
        _isHovered = false,
        _currentTransform = transform {
    _calculateTrendPoints();
  }

  final TrendAnnotation annotation;
  final ChartSeries series;
  final ChartTransform transform;
  ChartTransform _currentTransform;
  bool _isSelected;
  bool _isHovered;
  List<Offset> _trendPoints = [];

  /// Update the current transform before painting.
  void updateTransform(ChartTransform newTransform) {
    _currentTransform = newTransform;
  }

  /// Calculate trend line points based on series data and trend type.
  void _calculateTrendPoints() {
    final dataPoints = series.points;
    if (dataPoints.isEmpty) {
      _trendPoints = [];
      return;
    }

    switch (annotation.trendType) {
      case TrendType.linear:
        _trendPoints = _calculateLinearTrend(dataPoints);
        break;
      case TrendType.polynomial:
        _trendPoints = _calculatePolynomialTrend(dataPoints, annotation.degree);
        break;
      case TrendType.movingAverage:
        _trendPoints = _calculateMovingAverage(dataPoints, annotation.windowSize!);
        break;
      case TrendType.exponentialMovingAverage:
        _trendPoints = _calculateExponentialMovingAverage(dataPoints, annotation.windowSize ?? 10);
        break;
    }
  }

  /// Calculate linear regression trend line.
  List<Offset> _calculateLinearTrend(List<ChartDataPoint> points) {
    if (points.length < 2) return [];

    // Calculate linear regression: y = mx + b
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    final n = points.length;

    for (final point in points) {
      sumX += point.x;
      sumY += point.y;
      sumXY += point.x * point.y;
      sumX2 += point.x * point.x;
    }

    final m = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final b = (sumY - m * sumX) / n;

    // Generate trend line points
    final minX = points.first.x;
    final maxX = points.last.x;
    return [
      Offset(minX, m * minX + b),
      Offset(maxX, m * maxX + b),
    ];
  }

  /// Calculate polynomial regression trend line.
  List<Offset> _calculatePolynomialTrend(List<ChartDataPoint> points, int degree) {
    if (points.isEmpty) return [];
    if (degree < 1) return _calculateLinearTrend(points);
    if (points.length <= degree) {
      // Not enough points for the requested degree, fall back to linear
      return _calculateLinearTrend(points);
    }

    // Extract x and y values
    final xValues = points.map((p) => p.x).toList();
    final yValues = points.map((p) => p.y).toList();

    // Solve for polynomial coefficients using least squares
    // We need to solve: X * coefficients = Y
    // Where X is the Vandermonde matrix
    final coefficients = _solvePolynomialLeastSquares(xValues, yValues, degree);

    // Generate trend line points using the polynomial
    final minX = xValues.reduce((a, b) => a < b ? a : b);
    final maxX = xValues.reduce((a, b) => a > b ? a : b);

    // Generate smooth curve with more points than input data
    final numPoints = (points.length * 3).clamp(20, 100);
    final step = (maxX - minX) / (numPoints - 1);

    final result = <Offset>[];
    for (int i = 0; i < numPoints; i++) {
      final x = minX + (step * i);
      double y = 0;

      // Calculate y = a0 + a1*x + a2*x^2 + ... + an*x^n
      for (int j = 0; j <= degree; j++) {
        y += coefficients[j] * _pow(x, j);
      }

      result.add(Offset(x, y));
    }

    return result;
  }

  /// Solve polynomial least squares using normal equations.
  /// Returns coefficients [a0, a1, a2, ..., an] for polynomial y = a0 + a1*x + a2*x^2 + ... + an*x^n
  List<double> _solvePolynomialLeastSquares(List<double> xValues, List<double> yValues, int degree) {
    final n = xValues.length;
    final m = degree + 1; // Number of coefficients

    // Build the design matrix (Vandermonde matrix) and solve normal equations
    // Normal equations: (X^T * X) * coefficients = X^T * y

    // Create X^T * X matrix (m x m)
    final xtx = List.generate(m, (_) => List<double>.filled(m, 0.0));
    final xty = List<double>.filled(m, 0.0);

    // Fill X^T * X and X^T * y
    for (int i = 0; i < m; i++) {
      for (int j = 0; j < m; j++) {
        double sum = 0;
        for (int k = 0; k < n; k++) {
          sum += _pow(xValues[k], i + j);
        }
        xtx[i][j] = sum;
      }

      double sum = 0;
      for (int k = 0; k < n; k++) {
        sum += yValues[k] * _pow(xValues[k], i);
      }
      xty[i] = sum;
    }

    // Solve using Gaussian elimination
    return _gaussianElimination(xtx, xty);
  }

  /// Fast integer power function.
  double _pow(double base, int exponent) {
    if (exponent == 0) return 1.0;
    if (exponent == 1) return base;

    double result = 1.0;
    double currentBase = base;
    int currentExp = exponent;

    while (currentExp > 0) {
      if (currentExp.isOdd) {
        result *= currentBase;
      }
      currentBase *= currentBase;
      currentExp ~/= 2;
    }

    return result;
  }

  /// Solve linear system Ax = b using Gaussian elimination with partial pivoting.
  List<double> _gaussianElimination(List<List<double>> a, List<double> b) {
    final n = b.length;

    // Create augmented matrix
    final aug = List.generate(n, (i) => [...a[i], b[i]]);

    // Forward elimination with partial pivoting
    for (int i = 0; i < n; i++) {
      // Find pivot
      int maxRow = i;
      for (int k = i + 1; k < n; k++) {
        if (aug[k][i].abs() > aug[maxRow][i].abs()) {
          maxRow = k;
        }
      }

      // Swap rows
      if (maxRow != i) {
        final temp = aug[i];
        aug[i] = aug[maxRow];
        aug[maxRow] = temp;
      }

      // Check for singular matrix
      if (aug[i][i].abs() < 1e-10) {
        // Singular matrix, return zero coefficients
        return List<double>.filled(n, 0.0);
      }

      // Eliminate column
      for (int k = i + 1; k < n; k++) {
        final factor = aug[k][i] / aug[i][i];
        for (int j = i; j <= n; j++) {
          aug[k][j] -= factor * aug[i][j];
        }
      }
    }

    // Back substitution
    final x = List<double>.filled(n, 0.0);
    for (int i = n - 1; i >= 0; i--) {
      double sum = aug[i][n];
      for (int j = i + 1; j < n; j++) {
        sum -= aug[i][j] * x[j];
      }
      x[i] = sum / aug[i][i];
    }

    return x;
  }

  /// Calculate simple moving average.
  /// Uses right-aligned window: each average is placed at the last point in the window.
  /// This is the standard approach used in financial charting.
  List<Offset> _calculateMovingAverage(List<ChartDataPoint> points, int windowSize) {
    if (points.length < windowSize) return [];
    if (windowSize < 1) return [];

    final result = <Offset>[];
    
    // Calculate moving average with right-aligned window
    for (int i = windowSize - 1; i < points.length; i++) {
      double sum = 0;
      for (int j = 0; j < windowSize; j++) {
        sum += points[i - j].y;
      }
      final average = sum / windowSize;
      result.add(Offset(points[i].x, average));
    }
    
    return result;
  }

  /// Calculate exponential moving average.
  /// Uses standard EMA formula with smoothing factor alpha = 2 / (period + 1).
  List<Offset> _calculateExponentialMovingAverage(List<ChartDataPoint> points, int period) {
    if (points.isEmpty) return [];
    if (period < 1) return [];

    final alpha = 2.0 / (period + 1);
    final result = <Offset>[];
    
    // Initialize EMA with first data point
    double ema = points.first.y;
    result.add(Offset(points.first.x, ema));

    // Calculate EMA for remaining points
    for (int i = 1; i < points.length; i++) {
      ema = alpha * points[i].y + (1 - alpha) * ema;
      result.add(Offset(points[i].x, ema));
    }
    
    return result;
  }

  @override
  String get id => annotation.id;

  @override
  Rect get bounds {
    if (_trendPoints.isEmpty) return Rect.zero;

    // Calculate bounds from trend points in plot coordinates
    final plotPoints = _trendPoints.map((p) => _currentTransform.dataToPlot(p.dx, p.dy)).toList();

    double minX = plotPoints.first.dx;
    double maxX = plotPoints.first.dx;
    double minY = plotPoints.first.dy;
    double maxY = plotPoints.first.dy;

    for (final point in plotPoints) {
      minX = math.min(minX, point.dx);
      maxX = math.max(maxX, point.dx);
      minY = math.min(minY, point.dy);
      maxY = math.max(maxY, point.dy);
    }

    // Add hit test margin
    return Rect.fromLTRB(
      minX - annotation.lineWidth - 4,
      minY - annotation.lineWidth - 4,
      maxX + annotation.lineWidth + 4,
      maxY + annotation.lineWidth + 4,
    );
  }

  @override
  ChartElementType get elementType => ChartElementType.annotation;

  @override
  bool get isSelected => _isSelected;

  @override
  bool get isHovered => _isHovered;

  @override
  bool get isSelectable => true;

  @override
  bool get isDraggable => annotation.allowDragging;

  @override
  bool hitTest(Offset position) {
    if (_trendPoints.isEmpty) return false;

    // Convert trend points to plot coordinates
    final plotPoints = _trendPoints.map((p) => _currentTransform.dataToPlot(p.dx, p.dy)).toList();

    // Check if click is near any line segment
    final hitRadius = annotation.lineWidth + 4;
    for (int i = 0; i < plotPoints.length - 1; i++) {
      final distance = _distanceToLineSegment(position, plotPoints[i], plotPoints[i + 1]);
      if (distance <= hitRadius) return true;
    }
    return false;
  }

  /// Calculate distance from point to line segment.
  double _distanceToLineSegment(Offset point, Offset lineStart, Offset lineEnd) {
    final lengthSquared = (lineEnd - lineStart).distanceSquared;
    if (lengthSquared == 0) return (point - lineStart).distance;

    final t = math.max(
      0.0,
      math.min(1.0, ((point - lineStart).dx * (lineEnd - lineStart).dx + (point - lineStart).dy * (lineEnd - lineStart).dy) / lengthSquared),
    );
    final projection = lineStart + (lineEnd - lineStart) * t;
    return (point - projection).distance;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_trendPoints.isEmpty) return;

    final paint = Paint()
      ..color = annotation.lineColor
      ..strokeWidth = _isSelected ? annotation.lineWidth * 1.5 : annotation.lineWidth
      ..style = PaintingStyle.stroke;

    // Convert trend points to plot coordinates
    final plotPoints = _trendPoints.map((p) => _currentTransform.dataToPlot(p.dx, p.dy)).toList();

    // Draw trend line
    if (annotation.dashPattern != null && annotation.dashPattern!.isNotEmpty) {
      for (int i = 0; i < plotPoints.length - 1; i++) {
        _drawDashedLine(canvas, plotPoints[i], plotPoints[i + 1], paint, annotation.dashPattern!);
      }
    } else {
      final path = Path()..moveTo(plotPoints.first.dx, plotPoints.first.dy);
      for (int i = 1; i < plotPoints.length; i++) {
        path.lineTo(plotPoints[i].dx, plotPoints[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    // Draw label if present
    if (annotation.label != null && annotation.label!.isNotEmpty) {
      final textStyle = annotation.style.textStyle;
      final textSpan = TextSpan(text: annotation.label, style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      // Get padding from style or use default
      final padding = annotation.style.padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 3);

      // Calculate label container dimensions (includes padding)
      final containerWidth = textPainter.width + padding.left + padding.right;
      final containerHeight = textPainter.height + padding.top + padding.bottom;

      // Use labelMargin from annotation
      final labelMargin = annotation.labelMargin;

      // Position label container to the right of trend line end, vertically centered
      final bgRect = Rect.fromLTWH(
        plotPoints.last.dx + labelMargin,
        plotPoints.last.dy - containerHeight / 2,
        containerWidth,
        containerHeight,
      );

      // Draw background if backgroundColor is set
      if (annotation.style.backgroundColor != null) {
        final bgPaint = Paint()
          ..color = annotation.style.backgroundColor!
          ..style = PaintingStyle.fill;
        final borderRadius = annotation.style.borderRadius ?? BorderRadius.circular(4);
        final rrect = borderRadius.toRRect(bgRect);
        canvas.drawRRect(rrect, bgPaint);
      }

      // Draw border if borderColor and borderWidth are set
      if (annotation.style.borderColor != null && annotation.style.borderWidth > 0) {
        final borderPaint = Paint()
          ..color = annotation.style.borderColor!
          ..style = PaintingStyle.stroke
          ..strokeWidth = annotation.style.borderWidth;
        final borderRadius = annotation.style.borderRadius ?? BorderRadius.circular(4);
        final rrect = borderRadius.toRRect(bgRect);
        canvas.drawRRect(rrect, borderPaint);
      }

      // Draw text inside container (accounting for padding)
      final textPosition = Offset(
        bgRect.left + padding.left,
        bgRect.top + padding.top,
      );
      textPainter.paint(canvas, textPosition);
    }
  }

  /// Draws a dashed line using the provided dash pattern.
  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint, List<double> dashPattern) {
    final totalLength = (end - start).distance;
    var currentLength = 0.0;
    var patternIndex = 0;
    var isDash = true;

    while (currentLength < totalLength) {
      final dashLength = dashPattern[patternIndex % dashPattern.length];
      final nextLength = math.min(currentLength + dashLength, totalLength);

      if (isDash) {
        final t1 = currentLength / totalLength;
        final t2 = nextLength / totalLength;
        final p1 = Offset.lerp(start, end, t1)!;
        final p2 = Offset.lerp(start, end, t2)!;
        canvas.drawLine(p1, p2, paint);
      }

      currentLength = nextLength;
      patternIndex++;
      isDash = !isDash;
    }
  }

  @override
  void onSelect() => _isSelected = true;

  @override
  void onDeselect() => _isSelected = false;

  @override
  void onHoverEnter() => _isHovered = true;

  @override
  void onHoverExit() => _isHovered = false;

  @override
  ChartElement copyWith({bool? isHovered, bool? isSelected}) {
    final copy = TrendAnnotationElement(
      annotation: annotation,
      series: series,
      transform: _currentTransform,
    );
    copy._isSelected = isSelected ?? _isSelected;
    copy._isHovered = isHovered ?? _isHovered;
    copy._trendPoints = _trendPoints;
    return copy;
  }
}
