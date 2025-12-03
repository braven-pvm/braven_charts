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
import '../models/enums.dart';
import 'resize_handle_element.dart';

/// Position for edge value labels during range annotation resize.
enum EdgeLabelPosition {
  left,
  right,
  top,
  bottom,
}

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

  /// Calculate marker bounds (circle around marker position).
  Rect _calculateMarkerBounds() {
    final screenPos = _getScreenPosition();
    if (screenPos == null) return Rect.zero;

    final hitRadius = annotation.markerSize + 4.0;
    return Rect.fromCircle(
      center: screenPos,
      radius: hitRadius,
    );
  }

  /// Calculate label bounds if label exists, null otherwise.
  /// Uses same positioning logic as _drawLabel() to ensure consistency.
  Rect? _calculateLabelBounds() {
    if (annotation.label == null || annotation.label!.isEmpty) return null;

    final screenPos = _getScreenPosition();
    if (screenPos == null) return null;

    final textStyle = annotation.style.textStyle;
    final textSpan = TextSpan(text: annotation.label, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final padding = annotation.style.padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
    final containerWidth = textPainter.width + padding.left + padding.right;
    final containerHeight = textPainter.height + padding.top + padding.bottom;
    final labelMargin = annotation.labelMargin;

    // Label positioned to the right of the marker, vertically centered
    return Rect.fromLTWH(
      screenPos.dx + annotation.markerSize + labelMargin,
      screenPos.dy - containerHeight / 2,
      containerWidth,
      containerHeight,
    );
  }

  @override
  Rect get bounds {
    final markerBounds = _calculateMarkerBounds();
    final labelBounds = _calculateLabelBounds();

    // Expand bounds to include label if present
    if (labelBounds != null) {
      return markerBounds.expandToInclude(labelBounds);
    }
    return markerBounds;
  }

  @override
  // PointAnnotations should have datapoint priority (9) so they're clickable over series (8)
  // This allows the two-click drag-to-move interaction to work correctly
  ChartElementType get elementType => ChartElementType.datapoint;

  @override
  // Render order is SEPARATE from hit test priority!
  // Points render in foreground (over series and range annotations)
  int get renderOrder => RenderOrder.pointAnnotation;

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
    // Check label first (if present) - labels are typically easier click targets
    final labelBounds = _calculateLabelBounds();
    if (labelBounds?.contains(position) == true) return true;

    // Check marker
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
          ..color = annotation.markerColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
        _drawMarker(canvas, screenPos, annotation.markerShape, annotation.markerSize, ghostPaint);

        // Draw preview marker at candidate position (highlighted)
        final previewPaint = Paint()
          ..color = annotation.markerColor.withValues(alpha: 0.8)
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

    // Add hover feedback (slightly transparent)
    if (_isHovered && !_isSelected) {
      paint.color = paint.color.withValues(alpha: 0.7);
    }

    // Draw marker slightly larger when selected
    final markerSize = _isSelected ? annotation.markerSize * 1.2 : annotation.markerSize;
    _drawMarker(canvas, screenPos, annotation.markerShape, markerSize, paint);

    // Draw selection border (simple ring around the marker)
    if (_isSelected) {
      // Use series color for the border, fallback to blue if not available
      final borderColor = series.color ?? Colors.blue;
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      // Draw border slightly larger than the marker
      _drawMarker(canvas, screenPos, annotation.markerShape, markerSize + 6, borderPaint);
    }

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

      case MarkerShape.none:
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

  // Temporary values during resize (in data coordinates)
  double? _tempStartX;
  double? _tempEndX;
  double? _tempStartY;
  double? _tempEndY;

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
    _tempStartX = null;
    _tempEndX = null;
    _tempStartY = null;
    _tempEndY = null;
  }

  /// Updates temporary edge values during resize (in data coordinates).
  void updateTempValues({
    double? startX,
    double? endX,
    double? startY,
    double? endY,
  }) {
    _tempStartX = startX;
    _tempEndX = endX;
    _tempStartY = startY;
    _tempEndY = endY;
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

    // Y-axis: endY (higher value) maps to top (lower screen Y), startY (lower value) maps to bottom (higher screen Y)
    final top = annotation.endY != null ? _currentTransform.dataToPlot(0, annotation.endY!).dy : 0.0;

    final bottom = annotation.startY != null ? _currentTransform.dataToPlot(0, annotation.startY!).dy : chartSize.height;

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
  // Range annotations render in BACKGROUND (behind everything else)
  // This is SEPARATE from hit test priority!
  int get renderOrder => RenderOrder.rangeAnnotation;

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
        fillPaint.color = fillPaint.color.withValues(alpha: fillPaint.color.a * 1.2);
      }

      canvas.drawRect(fillRect, fillPaint);
    }

    // Draw border (conditionally skip borders when range spans entire axis)
    if (annotation.borderColor != null) {
      final borderPaint = Paint()
        ..color = annotation.borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = _isSelected ? 2.0 : 1.0;

      // Draw individual border lines based on annotation bounds
      // Skip borders when the annotation spans the entire axis (null values)

      // Top border - only if endY is defined (endY = higher Y value = top of range)
      if (annotation.endY != null) {
        canvas.drawLine(
          Offset(fillRect.left, fillRect.top),
          Offset(fillRect.right, fillRect.top),
          borderPaint,
        );
      }

      // Right border - only if endX is defined (not spanning to right)
      if (annotation.endX != null) {
        canvas.drawLine(
          Offset(fillRect.right, fillRect.top),
          Offset(fillRect.right, fillRect.bottom),
          borderPaint,
        );
      }

      // Bottom border - only if startY is defined (startY = lower Y value = bottom of range)
      if (annotation.startY != null) {
        canvas.drawLine(
          Offset(fillRect.right, fillRect.bottom),
          Offset(fillRect.left, fillRect.bottom),
          borderPaint,
        );
      }

      // Left border - only if startX is defined (not spanning to left)
      if (annotation.startX != null) {
        canvas.drawLine(
          Offset(fillRect.left, fillRect.bottom),
          Offset(fillRect.left, fillRect.top),
          borderPaint,
        );
      }
    }

    // Draw label if present
    if (annotation.label != null && annotation.label!.isNotEmpty) {
      _drawLabel(canvas, fillRect, annotation.label!);
    }

    // Draw resize handles if selected
    if (_isSelected) {
      _drawResizeHandles(canvas, fillRect);
    }

    // Draw value labels during resize (similar to threshold drag labels)
    if (_tempStartX != null || _tempEndX != null || _tempStartY != null || _tempEndY != null) {
      _drawResizeValueLabels(canvas, size, fillRect);
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

  /// Draws value labels for edges being resized (similar to threshold drag labels).
  void _drawResizeValueLabels(Canvas canvas, Size size, Rect fillRect) {
    const textStyle = TextStyle(
      color: Color(0xFF000000),
      fontSize: 10,
      backgroundColor: Color(0xF0FFFFFF), // Almost opaque white
    );

    const labelPadding = 4.0;
    final labelBackgroundPaint = Paint()..color = const Color(0xF0FFFFFF);

    // Draw label for each edge being resized
    // Left edge (startX)
    if (_tempStartX != null) {
      final displayValue = _formatDataValue(_tempStartX!);
      final labelText = 'X: $displayValue';
      _drawEdgeLabel(canvas, labelText, textStyle, labelBackgroundPaint, labelPadding, fillRect.left, fillRect.center.dy, EdgeLabelPosition.left);
    }

    // Right edge (endX)
    if (_tempEndX != null) {
      final displayValue = _formatDataValue(_tempEndX!);
      final labelText = 'X: $displayValue';
      _drawEdgeLabel(canvas, labelText, textStyle, labelBackgroundPaint, labelPadding, fillRect.right, fillRect.center.dy, EdgeLabelPosition.right);
    }

    // Top edge (endY - higher value)
    if (_tempEndY != null) {
      final displayValue = _formatDataValue(_tempEndY!);
      final labelText = 'Y: $displayValue';
      _drawEdgeLabel(canvas, labelText, textStyle, labelBackgroundPaint, labelPadding, fillRect.center.dx, fillRect.top, EdgeLabelPosition.top);
    }

    // Bottom edge (startY - lower value)
    if (_tempStartY != null) {
      final displayValue = _formatDataValue(_tempStartY!);
      final labelText = 'Y: $displayValue';
      _drawEdgeLabel(canvas, labelText, textStyle, labelBackgroundPaint, labelPadding, fillRect.center.dx, fillRect.bottom, EdgeLabelPosition.bottom);
    }
  }

  /// Helper to draw a single edge label at the specified position.
  void _drawEdgeLabel(
    Canvas canvas,
    String labelText,
    TextStyle textStyle,
    Paint backgroundPaint,
    double padding,
    double edgeX,
    double edgeY,
    EdgeLabelPosition position,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(text: labelText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    double labelX, labelY;

    switch (position) {
      case EdgeLabelPosition.left:
        // Position label to the left of the edge
        labelX = edgeX - textPainter.width - padding * 3;
        labelY = edgeY - textPainter.height / 2;
        // Clamp to keep within bounds
        labelX = labelX.clamp(padding, _currentTransform.plotWidth - textPainter.width - padding);
        labelY = labelY.clamp(padding, _currentTransform.plotHeight - textPainter.height - padding);
        break;
      case EdgeLabelPosition.right:
        // Position label to the right of the edge
        labelX = edgeX + padding * 3;
        labelY = edgeY - textPainter.height / 2;
        // Clamp to keep within bounds
        labelX = labelX.clamp(padding, _currentTransform.plotWidth - textPainter.width - padding);
        labelY = labelY.clamp(padding, _currentTransform.plotHeight - textPainter.height - padding);
        break;
      case EdgeLabelPosition.top:
        // Position label above the edge
        labelX = edgeX - textPainter.width / 2;
        labelY = edgeY - textPainter.height - padding * 3;
        // Clamp to keep within bounds
        labelX = labelX.clamp(padding, _currentTransform.plotWidth - textPainter.width - padding);
        labelY = labelY.clamp(padding, _currentTransform.plotHeight - textPainter.height - padding);
        break;
      case EdgeLabelPosition.bottom:
        // Position label below the edge
        labelX = edgeX - textPainter.width / 2;
        labelY = edgeY + padding * 3;
        // Clamp to keep within bounds
        labelX = labelX.clamp(padding, _currentTransform.plotWidth - textPainter.width - padding);
        labelY = labelY.clamp(padding, _currentTransform.plotHeight - textPainter.height - padding);
        break;
    }

    // Draw background
    final bgRect = Rect.fromLTWH(
      labelX - padding,
      labelY - padding,
      textPainter.width + padding * 2,
      textPainter.height + padding * 2,
    );
    canvas.drawRect(bgRect, backgroundPaint);

    // Draw text
    textPainter.paint(canvas, Offset(labelX, labelY));
  }

  /// Formats data values for display (same logic as axis labels).
  String _formatDataValue(double value) {
    // If the value is very close to an integer, show it as an integer
    if ((value - value.round()).abs() < 0.0001) {
      return value.round().toString();
    }

    // Otherwise, show with appropriate decimal places
    if (value.abs() < 0.01) {
      return value.toStringAsExponential(1);
    } else if (value.abs() < 1) {
      return value.toStringAsFixed(2);
    } else if (value.abs() < 100) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(0);
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

  /// Resize handles are only active when the annotation is selected.
  ///
  /// This prevents resize handles from blocking other annotations (like
  /// ThresholdAnnotations) when the range is not actively being edited.
  /// User must first select the RangeAnnotation, then resize handles become
  /// active for hit testing.
  @override
  bool get isResizable => _isSelected;

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
  // Text annotations render in foreground (on top of data)
  int get renderOrder => RenderOrder.textAnnotation;

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
        bgPaint.color = bgPaint.color.withValues(alpha: (bgPaint.color.a * 1.1).clamp(0.0, 1.0));
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

  /// Calculate the line hit zone bounds (strip along the line).
  Rect _calculateLineBounds() {
    final value = _tempValue ?? annotation.value;
    const hitMargin = 20.0; // 20px margin on each side of line for easier clicking

    if (annotation.axis == AnnotationAxis.y) {
      final plotY = _currentTransform.dataToPlot(0, value).dy;
      return Rect.fromLTWH(
        0,
        plotY - annotation.lineWidth / 2 - hitMargin,
        _currentTransform.plotWidth,
        annotation.lineWidth + (hitMargin * 2),
      );
    } else {
      final plotX = _currentTransform.dataToPlot(value, 0).dx;
      return Rect.fromLTWH(
        plotX - annotation.lineWidth / 2 - hitMargin,
        0,
        annotation.lineWidth + (hitMargin * 2),
        _currentTransform.plotHeight,
      );
    }
  }

  /// Calculate label bounds if label exists, null otherwise.
  /// Uses same positioning logic as paint() to ensure consistency.
  Rect? _calculateLabelBounds() {
    if (annotation.label == null || annotation.label!.isEmpty) return null;

    final value = _tempValue ?? annotation.value;

    // Calculate line position (same as paint())
    Offset start, end;
    if (annotation.axis == AnnotationAxis.y) {
      final plotY = _currentTransform.dataToPlot(0, value).dy;
      start = Offset(0, plotY);
      end = Offset(_currentTransform.plotWidth, plotY);
    } else {
      final plotX = _currentTransform.dataToPlot(value, 0).dx;
      start = Offset(plotX, 0);
      end = Offset(plotX, _currentTransform.plotHeight);
    }

    // Calculate label dimensions (same as paint())
    final textStyle = annotation.style.textStyle;
    final textSpan = TextSpan(text: annotation.label, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final padding = annotation.style.padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
    final containerWidth = textPainter.width + padding.left + padding.right;
    final containerHeight = textPainter.height + padding.top + padding.bottom;
    final labelMargin = annotation.labelMargin;

    // Position label container based on labelPosition and axis orientation (same as paint())
    Rect bgRect;
    if (annotation.axis == AnnotationAxis.y) {
      final lineY = start.dy;
      switch (annotation.labelPosition) {
        case AnnotationLabelPosition.topLeft:
          bgRect = Rect.fromLTWH(start.dx + labelMargin, lineY - containerHeight - labelMargin, containerWidth, containerHeight);
        case AnnotationLabelPosition.topRight:
          bgRect = Rect.fromLTWH(end.dx - containerWidth - labelMargin, lineY - containerHeight - labelMargin, containerWidth, containerHeight);
        case AnnotationLabelPosition.bottomLeft:
          bgRect = Rect.fromLTWH(start.dx + labelMargin, lineY + labelMargin, containerWidth, containerHeight);
        case AnnotationLabelPosition.bottomRight:
          bgRect = Rect.fromLTWH(end.dx - containerWidth - labelMargin, lineY + labelMargin, containerWidth, containerHeight);
        case AnnotationLabelPosition.center:
          bgRect = Rect.fromLTWH((start.dx + end.dx) / 2 - containerWidth / 2, lineY - containerHeight / 2, containerWidth, containerHeight);
      }
    } else {
      final lineX = start.dx;
      switch (annotation.labelPosition) {
        case AnnotationLabelPosition.topLeft:
          bgRect = Rect.fromLTWH(lineX - containerWidth - labelMargin, start.dy + labelMargin, containerWidth, containerHeight);
        case AnnotationLabelPosition.topRight:
          bgRect = Rect.fromLTWH(lineX + labelMargin, start.dy + labelMargin, containerWidth, containerHeight);
        case AnnotationLabelPosition.bottomLeft:
          bgRect = Rect.fromLTWH(lineX - containerWidth - labelMargin, end.dy - containerHeight - labelMargin, containerWidth, containerHeight);
        case AnnotationLabelPosition.bottomRight:
          bgRect = Rect.fromLTWH(lineX + labelMargin, end.dy - containerHeight - labelMargin, containerWidth, containerHeight);
        case AnnotationLabelPosition.center:
          bgRect = Rect.fromLTWH(lineX - containerWidth / 2, (start.dy + end.dy) / 2 - containerHeight / 2, containerWidth, containerHeight);
      }
    }

    return bgRect;
  }

  @override
  Rect get bounds {
    final lineBounds = _calculateLineBounds();
    final labelBounds = _calculateLabelBounds();

    // Expand bounds to include label if present
    if (labelBounds != null) {
      return lineBounds.expandToInclude(labelBounds);
    }
    return lineBounds;
  }

  @override
  ChartElementType get elementType => ChartElementType.annotation;

  @override
  // Threshold lines render in data layer (with series)
  int get renderOrder => RenderOrder.thresholdAnnotation;

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
    // Check label first (if present) - labels are typically easier click targets
    final labelBounds = _calculateLabelBounds();
    if (labelBounds?.contains(position) == true) return true;

    // Check line hit zone
    return _calculateLineBounds().contains(position);
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

      // Draw value label during drag (similar to crosshair labels)
      _drawDragValueLabel(canvas, size, value, start, end);
    }

    // Draw elevation glow in DEFAULT state only (not selected, not dragging)
    // This creates a subtle glow effect using the line color
    if (!_isSelected && !isDragging && annotation.elevation > 0) {
      final elevationPaint = Paint()
        ..color = annotation.lineColor.withAlpha(60)
        ..strokeWidth = annotation.lineWidth + annotation.elevation * 2
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, annotation.elevation);

      if (annotation.dashPattern != null && annotation.dashPattern!.isNotEmpty) {
        _drawDashedLine(canvas, start, end, elevationPaint, annotation.dashPattern!);
      } else {
        canvas.drawLine(start, end, elevationPaint);
      }
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

  /// Draws a value label during threshold drag (similar to crosshair labels).
  void _drawDragValueLabel(Canvas canvas, Size size, double value, Offset start, Offset end) {
    const textStyle = TextStyle(
      color: Color(0xFF000000),
      fontSize: 10,
      backgroundColor: Color(0xF0FFFFFF), // Almost opaque white
    );

    const labelPadding = 4.0;
    final labelBackgroundPaint = Paint()..color = const Color(0xF0FFFFFF);

    // Format the value for display
    final displayValue = _formatDataValue(value);
    final labelText = annotation.axis == AnnotationAxis.y ? 'Y: $displayValue' : 'X: $displayValue';

    final textPainter = TextPainter(
      text: TextSpan(text: labelText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    double labelX, labelY;

    if (annotation.axis == AnnotationAxis.y) {
      // Horizontal line - position label at left edge of chart
      labelX = 8; // 8px from left edge
      labelY = start.dy - textPainter.height / 2;
      // Clamp Y position to keep within plot bounds
      labelY = labelY.clamp(labelPadding, _currentTransform.plotHeight - textPainter.height - labelPadding);
    } else {
      // Vertical line - position label at bottom of chart
      labelX = start.dx - textPainter.width / 2;
      labelY = _currentTransform.plotHeight - textPainter.height - 8; // 8px from bottom
      // Clamp X position to keep within plot bounds
      labelX = labelX.clamp(labelPadding, _currentTransform.plotWidth - textPainter.width - labelPadding);
    }

    // Draw background
    final bgRect = Rect.fromLTWH(
      labelX - labelPadding,
      labelY - labelPadding,
      textPainter.width + labelPadding * 2,
      textPainter.height + labelPadding * 2,
    );
    canvas.drawRect(bgRect, labelBackgroundPaint);

    // Draw text
    textPainter.paint(canvas, Offset(labelX, labelY));
  }

  /// Formats data values for display (same logic as axis labels).
  String _formatDataValue(double value) {
    // If the value is very close to an integer, show it as an integer
    if ((value - value.round()).abs() < 0.0001) {
      return value.round().toString();
    }

    // Otherwise, show with appropriate decimal places
    if (value.abs() < 0.01) {
      return value.toStringAsExponential(1);
    } else if (value.abs() < 1) {
      return value.toStringAsFixed(2);
    } else if (value.abs() < 100) {
      return value.toStringAsFixed(1);
    } else {
      return value.toStringAsFixed(0);
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
  // Trend lines render in data layer (with series)
  int get renderOrder => RenderOrder.trendAnnotation;

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
