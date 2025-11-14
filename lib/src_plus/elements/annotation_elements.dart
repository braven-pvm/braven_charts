// Copyright (c) 2025 braven_charts. All rights reserved.
// Annotation Element Classes for ChartRenderBox Integration

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../coordinates/chart_transform.dart';
import '../interaction/core/chart_element.dart';
import '../interaction/core/element_types.dart';
import '../models/chart_annotation.dart';
import '../models/chart_series.dart';

/// A chart element that renders a point annotation marker.
///
/// Marks a specific data point with a custom marker shape and color.
class PointAnnotationElement extends ChartElement {
  PointAnnotationElement({
    required this.annotation,
    required this.series,
    required this.transform,
  })  : _isSelected = false,
        _isHovered = false {
    // Get the data point from the series
    if (annotation.dataPointIndex < series.points.length) {
      final point = series.points[annotation.dataPointIndex];
      _dataPosition = Offset(point.x, point.y);

      // Transform to screen coordinates and apply offset
      final screenPos = transform.dataToPlot(_dataPosition!.dx, _dataPosition!.dy);
      _screenPosition = screenPos + annotation.offset;

      // Calculate bounds (marker size + padding for hit testing)
      final hitRadius = annotation.markerSize + 4.0;
      _bounds = Rect.fromCircle(
        center: _screenPosition!,
        radius: hitRadius,
      );
    }
  }

  final PointAnnotation annotation;
  final ChartSeries series;
  final ChartTransform transform;

  Offset? _dataPosition;
  Offset? _screenPosition;
  Rect? _bounds;
  bool _isSelected;
  bool _isHovered;

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
    if (_screenPosition == null) return false;

    final hitRadius = annotation.markerSize + 4.0;
    final distance = (position - _screenPosition!).distance;
    return distance <= hitRadius;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_screenPosition == null) return;

    final paint = Paint()
      ..color = annotation.markerColor
      ..style = PaintingStyle.fill;

    // Add selection/hover feedback
    if (_isSelected || _isHovered) {
      paint.color = paint.color.withOpacity(_isSelected ? 1.0 : 0.7);
    }

    _drawMarker(canvas, _screenPosition!, annotation.markerShape, annotation.markerSize, paint);

    // Draw label if present
    if (annotation.label != null && annotation.label!.isNotEmpty) {
      _drawLabel(canvas, _screenPosition!, annotation.label!);
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

    final offset = Offset(
      position.dx + annotation.markerSize + 4,
      position.dy - textPainter.height / 2,
    );

    // Draw background if specified
    if (annotation.style.backgroundColor != null) {
      final bgRect = Rect.fromLTWH(
        offset.dx - 2,
        offset.dy - 2,
        textPainter.width + 4,
        textPainter.height + 4,
      );
      canvas.drawRect(bgRect, Paint()..color = annotation.style.backgroundColor!);
    }

    textPainter.paint(canvas, offset);
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
    copy._screenPosition = _screenPosition;
    copy._bounds = _bounds;
    return copy;
  }
}

/// A chart element that renders a range annotation.
///
/// Highlights a rectangular region on the chart with optional fill and border.
class RangeAnnotationElement extends ChartElement {
  RangeAnnotationElement({
    required this.annotation,
    required this.transform,
    required this.chartSize,
  })  : _isSelected = false,
        _isHovered = false {
    _calculateBounds();
  }

  final RangeAnnotation annotation;
  final ChartTransform transform;
  final Size chartSize;

  Rect? _bounds;
  Rect? _fillRect;
  bool _isSelected;
  bool _isHovered;

  void _calculateBounds() {
    // Transform data ranges to screen coordinates
    final left = annotation.startX != null ? transform.dataToPlot(annotation.startX!, 0).dx : 0.0;

    final right = annotation.endX != null ? transform.dataToPlot(annotation.endX!, 0).dx : chartSize.width;

    final top = annotation.startY != null ? transform.dataToPlot(0, annotation.startY!).dy : 0.0;

    final bottom = annotation.endY != null ? transform.dataToPlot(0, annotation.endY!).dy : chartSize.height;

    _fillRect = Rect.fromLTRB(
      left.clamp(0.0, chartSize.width),
      top.clamp(0.0, chartSize.height),
      right.clamp(0.0, chartSize.width),
      bottom.clamp(0.0, chartSize.height),
    );

    _bounds = _fillRect;
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
    return _fillRect?.contains(position) ?? false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_fillRect == null) return;

    // Draw fill
    if (annotation.fillColor != null) {
      final fillPaint = Paint()
        ..color = annotation.fillColor!
        ..style = PaintingStyle.fill;

      if (_isHovered) {
        fillPaint.color = fillPaint.color.withOpacity(fillPaint.color.opacity * 1.2);
      }

      canvas.drawRect(_fillRect!, fillPaint);
    }

    // Draw border
    if (annotation.borderColor != null) {
      final borderPaint = Paint()
        ..color = annotation.borderColor!
        ..style = PaintingStyle.stroke
        ..strokeWidth = _isSelected ? 2.0 : 1.0;

      canvas.drawRect(_fillRect!, borderPaint);
    }

    // Draw label if present
    if (annotation.label != null && annotation.label!.isNotEmpty) {
      _drawLabel(canvas, _fillRect!, annotation.label!);
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, String label) {
    final textStyle = annotation.style.textStyle;
    final textSpan = TextSpan(text: label, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    // Position label based on labelPosition
    Offset position;
    switch (annotation.labelPosition) {
      case AnnotationLabelPosition.topLeft:
        position = Offset(rect.left + 8, rect.top + 8);
        break;
      case AnnotationLabelPosition.topRight:
        position = Offset(rect.right - textPainter.width - 8, rect.top + 8);
        break;
      case AnnotationLabelPosition.bottomLeft:
        position = Offset(rect.left + 8, rect.bottom - textPainter.height - 8);
        break;
      case AnnotationLabelPosition.bottomRight:
        position = Offset(rect.right - textPainter.width - 8, rect.bottom - textPainter.height - 8);
        break;
      case AnnotationLabelPosition.center:
        position = Offset(
          rect.center.dx - textPainter.width / 2,
          rect.center.dy - textPainter.height / 2,
        );
        break;
    }

    // Draw background if specified
    if (annotation.style.backgroundColor != null) {
      final bgRect = Rect.fromLTWH(
        position.dx - 4,
        position.dy - 2,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      final bgPaint = Paint()..color = annotation.style.backgroundColor!;
      if (annotation.style.borderRadius != null) {
        canvas.drawRRect(
          RRect.fromRectAndCorners(bgRect, topLeft: annotation.style.borderRadius!.topLeft),
          bgPaint,
        );
      } else {
        canvas.drawRect(bgRect, bgPaint);
      }
    }

    textPainter.paint(canvas, position);
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
    final copy = RangeAnnotationElement(
      annotation: annotation,
      transform: transform,
      chartSize: chartSize,
    );
    copy._isSelected = isSelected ?? _isSelected;
    copy._isHovered = isHovered ?? _isHovered;
    copy._bounds = _bounds;
    copy._fillRect = _fillRect;
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

  void _calculateBounds() {
    final textStyle = annotation.style.textStyle;
    final textSpan = TextSpan(text: annotation.text, style: textStyle);
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final textSize = textPainter.size;
    final padding = annotation.style.padding ?? const EdgeInsets.all(4.0);

    // Calculate anchored position
    _anchoredPosition = _getAnchoredPosition(
      annotation.position,
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
