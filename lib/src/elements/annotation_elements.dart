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
import '../models/data_range.dart';
import '../models/enums.dart';
import '../models/legend_style.dart';
import 'resize_handle_element.dart';

/// Position for edge value labels during range annotation resize.
enum EdgeLabelPosition { left, right, top, bottom }

/// A chart element that renders a point annotation marker.
///
/// Marks a specific data point with a custom marker shape and color.
class PointAnnotationElement extends ChartElement {
  PointAnnotationElement({required this.annotation, required this.series, required this.transform})
    : _isSelected = false,
      _isHovered = false,
      _currentTransform = transform {
    // Get the data point from the series and store data coordinates
    if (annotation.dataPointIndex < series.points.length) {
      final point = series.points[annotation.dataPointIndex];
      _dataPosition = Offset(point.x, point.y);
    }
    _cacheLabelPainter(); // Cache the label TextPainter if label exists
  }

  final PointAnnotation annotation;
  final ChartSeries series;
  final ChartTransform transform; // Initial transform for construction
  ChartTransform _currentTransform; // Current transform for painting

  Offset? _dataPosition; // Data coordinates (never changes)
  bool _isSelected;
  bool _isHovered;
  int? _candidateDataPointIndex; // For drag preview - shows where annotation will move to

  /// Cached label TextPainter to avoid recreating on every bounds/paint call.
  TextPainter? _cachedLabelPainter;
  Size? _cachedLabelSize;

  /// Caches the label TextPainter if label exists.
  /// Called once on construction since label text doesn't change.
  void _cacheLabelPainter() {
    if (annotation.label == null || annotation.label!.isEmpty) return;

    final textStyle = annotation.style.textStyle;
    final textSpan = TextSpan(text: annotation.label, style: textStyle);
    _cachedLabelPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    _cachedLabelSize = _cachedLabelPainter!.size;
  }

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
    return Rect.fromCircle(center: screenPos, radius: hitRadius);
  }

  /// Calculate label bounds if label exists, null otherwise.
  /// Uses cached TextPainter for efficiency.
  Rect? _calculateLabelBounds() {
    // Use cached size if available
    if (_cachedLabelSize == null) return null;

    final screenPos = _getScreenPosition();
    if (screenPos == null) return null;

    final padding = annotation.style.padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
    final containerWidth = _cachedLabelSize!.width + padding.left + padding.right;
    final containerHeight = _cachedLabelSize!.height + padding.top + padding.bottom;
    final labelMargin = annotation.labelMargin;

    // Label positioned to the right of the marker, vertically centered
    return Rect.fromLTWH(screenPos.dx + annotation.markerSize + labelMargin, screenPos.dy - containerHeight / 2, containerWidth, containerHeight);
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

        // Draw ghost label at original position (if present)
        if (annotation.label != null && annotation.label!.isNotEmpty) {
          _drawLabel(canvas, screenPos, annotation.label!, alpha: 0.3);
        }

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

        // Draw preview label at candidate position (if present)
        if (annotation.label != null && annotation.label!.isNotEmpty) {
          _drawLabel(canvas, candidatePos, annotation.label!, alpha: 0.7);
        }

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
            ..strokeWidth = 2.0,
        );
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
            ..strokeWidth = 2.0,
        );
        break;

      case MarkerShape.none:
        break;
    }
  }

  void _drawLabel(Canvas canvas, Offset position, String label, {double alpha = 1.0}) {
    if (_cachedLabelSize == null) return;

    // Use cached painter for full opacity, create new one for ghost effect
    TextPainter textPainter;
    if (alpha < 1.0) {
      // Ghost effect needs modified color
      final baseTextStyle = annotation.style.textStyle;
      final textStyle = baseTextStyle.copyWith(color: (baseTextStyle.color ?? Colors.black).withValues(alpha: alpha));
      final textSpan = TextSpan(text: label, style: textStyle);
      textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    } else {
      // Use cached painter for normal rendering
      textPainter = _cachedLabelPainter!;
    }

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
      final bgColor = alpha < 1.0 ? annotation.style.backgroundColor!.withValues(alpha: alpha) : annotation.style.backgroundColor!;
      final bgPaint = Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill;

      final borderRadius = annotation.style.borderRadius ?? BorderRadius.circular(4);
      final rrect = borderRadius.toRRect(bgRect);
      canvas.drawRRect(rrect, bgPaint);
    }

    // Draw border if specified
    if (annotation.style.borderColor != null && annotation.style.borderWidth > 0) {
      final borderColor = alpha < 1.0 ? annotation.style.borderColor!.withValues(alpha: alpha) : annotation.style.borderColor!;
      final borderPaint = Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = annotation.style.borderWidth;

      final borderRadius = annotation.style.borderRadius ?? BorderRadius.circular(4);
      final rrect = borderRadius.toRRect(bgRect);
      canvas.drawRRect(rrect, borderPaint);
    }

    // Draw text inside container (accounting for padding)
    final textPosition = Offset(bgRect.left + padding.left, bgRect.top + padding.top);
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
    final copy = PointAnnotationElement(annotation: annotation, series: series, transform: transform);
    copy._isSelected = isSelected ?? _isSelected;
    copy._isHovered = isHovered ?? _isHovered;
    copy._dataPosition = _dataPosition;
    copy._currentTransform = _currentTransform;
    copy._cachedLabelPainter = _cachedLabelPainter;
    copy._cachedLabelSize = _cachedLabelSize;
    return copy;
  }
}

/// A chart element that renders a pin annotation marker at arbitrary coordinates.
///
/// Similar to [PointAnnotationElement] but not tied to any series.
/// Uses explicit x/y coordinates for positioning.
class PinAnnotationElement extends ChartElement {
  PinAnnotationElement({required this.annotation, required this.transform}) : _isSelected = false, _isHovered = false, _currentTransform = transform {
    _cacheLabelPainter();
  }

  final PinAnnotation annotation;
  final ChartTransform transform; // Initial transform for construction
  ChartTransform _currentTransform; // Current transform for painting

  bool _isSelected;
  bool _isHovered;

  // Temporary position during drag (in data coordinates)
  double? _tempX;
  double? _tempY;

  /// Cached label TextPainter to avoid recreating on every bounds/paint call.
  TextPainter? _cachedLabelPainter;
  Size? _cachedLabelSize;

  /// Caches the label TextPainter if label exists.
  void _cacheLabelPainter() {
    if (annotation.label == null || annotation.label!.isEmpty) return;

    final textStyle = annotation.style.textStyle;
    final textSpan = TextSpan(text: annotation.label, style: textStyle);
    _cachedLabelPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();
    _cachedLabelSize = _cachedLabelPainter!.size;
  }

  /// Update the current transform before painting (for real-time pan/zoom).
  void updateTransform(ChartTransform newTransform) {
    _currentTransform = newTransform;
  }

  /// Update temporary position during drag (in data coordinates).
  void updateTempPosition(double x, double y) {
    _tempX = x;
    _tempY = y;
  }

  /// Clear temporary position after drag completes.
  void clearTempPosition() {
    _tempX = null;
    _tempY = null;
  }

  /// Get current temp position (if dragging).
  (double, double)? get tempPosition => _tempX != null && _tempY != null ? (_tempX!, _tempY!) : null;

  /// Recalculate screen position using current transform.
  Offset _getScreenPosition() {
    final x = _tempX ?? annotation.x;
    final y = _tempY ?? annotation.y;
    return _currentTransform.dataToPlot(x, y);
  }

  @override
  String get id => annotation.id;

  /// Calculate marker bounds (circle around marker position).
  Rect _calculateMarkerBounds() {
    final screenPos = _getScreenPosition();
    final hitRadius = annotation.markerSize + 4.0;
    return Rect.fromCircle(center: screenPos, radius: hitRadius);
  }

  /// Calculate label bounds if label exists, null otherwise.
  /// Uses cached TextPainter for efficiency.
  Rect? _calculateLabelBounds() {
    if (_cachedLabelSize == null) return null;

    final screenPos = _getScreenPosition();

    final padding = annotation.style.padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
    final containerWidth = _cachedLabelSize!.width + padding.left + padding.right;
    final containerHeight = _cachedLabelSize!.height + padding.top + padding.bottom;
    final labelMargin = annotation.labelMargin;

    // Label positioned to the right of the marker, vertically centered
    return Rect.fromLTWH(screenPos.dx + annotation.markerSize + labelMargin, screenPos.dy - containerHeight / 2, containerWidth, containerHeight);
  }

  @override
  Rect get bounds {
    final markerBounds = _calculateMarkerBounds();
    final labelBounds = _calculateLabelBounds();

    if (labelBounds != null) {
      return markerBounds.expandToInclude(labelBounds);
    }
    return markerBounds;
  }

  @override
  // PinAnnotations have same priority as PointAnnotations (datapoint level)
  ChartElementType get elementType => ChartElementType.datapoint;

  @override
  // Render order same as TextAnnotation (foreground labels)
  int get renderOrder => RenderOrder.pinAnnotation;

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
    // Check label first (if present)
    final labelBounds = _calculateLabelBounds();
    if (labelBounds?.contains(position) == true) return true;

    // Check marker
    final screenPos = _getScreenPosition();
    final hitRadius = annotation.markerSize + 4.0;
    final distance = (position - screenPos).distance;
    return distance <= hitRadius;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final screenPos = _getScreenPosition();
    final isDragging = _tempX != null;

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

    // Draw selection border
    if (_isSelected) {
      final borderPaint = Paint()
        ..color = annotation.markerColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      _drawMarker(canvas, screenPos, annotation.markerShape, markerSize + 6, borderPaint);
    }

    // Draw drag value label during drag
    if (isDragging) {
      _drawDragValueLabel(canvas, size, screenPos);
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
            ..strokeWidth = 2.0,
        );
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
            ..strokeWidth = 2.0,
        );
        break;

      case MarkerShape.none:
        break;
    }
  }

  void _drawLabel(Canvas canvas, Offset position, String label) {
    if (_cachedLabelPainter == null) return;

    final padding = annotation.style.padding ?? const EdgeInsets.symmetric(horizontal: 6, vertical: 3);
    final containerWidth = _cachedLabelPainter!.width + padding.left + padding.right;
    final containerHeight = _cachedLabelPainter!.height + padding.top + padding.bottom;
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

    // Draw text inside container using cached painter
    final textPosition = Offset(bgRect.left + padding.left, bgRect.top + padding.top);
    _cachedLabelPainter!.paint(canvas, textPosition);
  }

  /// Draws coordinate value labels during drag (similar to ThresholdAnnotation).
  void _drawDragValueLabel(Canvas canvas, Size size, Offset screenPos) {
    const textStyle = TextStyle(color: Color(0xFF000000), fontSize: 10, backgroundColor: Color(0xF0FFFFFF));

    const labelPadding = 4.0;
    final labelBackgroundPaint = Paint()..color = const Color(0xF0FFFFFF);

    final x = _tempX ?? annotation.x;
    final y = _tempY ?? annotation.y;
    final labelText = 'X: ${_formatDataValue(x)}, Y: ${_formatDataValue(y)}';

    final textPainter = TextPainter(
      text: TextSpan(text: labelText, style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    // Position label below the marker
    double labelX = screenPos.dx - textPainter.width / 2;
    double labelY = screenPos.dy + annotation.markerSize + 8;

    // Clamp to keep within bounds
    labelX = labelX.clamp(labelPadding, _currentTransform.plotWidth - textPainter.width - labelPadding);
    labelY = labelY.clamp(labelPadding, _currentTransform.plotHeight - textPainter.height - labelPadding);

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

  String _formatDataValue(double value) {
    if ((value - value.round()).abs() < 0.0001) {
      return value.round().toString();
    }
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
    final copy = PinAnnotationElement(annotation: annotation, transform: transform);
    copy._isSelected = isSelected ?? _isSelected;
    copy._isHovered = isHovered ?? _isHovered;
    copy._currentTransform = _currentTransform;
    copy._tempX = _tempX;
    copy._tempY = _tempY;
    copy._cachedLabelPainter = _cachedLabelPainter;
    copy._cachedLabelSize = _cachedLabelSize;
    return copy;
  }
}

/// A chart element that renders a range annotation.
///
/// Highlights a rectangular region on the chart with optional fill and border.
/// Implements ResizableElement to support resizing via edge/corner handles.
class RangeAnnotationElement extends ChartElement with ResizableElement {
  RangeAnnotationElement({required this.annotation, required this.transform, required this.chartSize, this.axisBounds})
    : _isSelected = false,
      _isHovered = false,
      _currentTransform = transform,
      _axisBounds = axisBounds;

  final RangeAnnotation annotation;
  final ChartTransform transform; // Initial transform for construction
  ChartTransform _currentTransform; // Current transform for painting
  final Size chartSize;

  /// Optional axis bounds for perSeries normalization.
  ///
  /// When provided (in perSeries normalization mode), the range Y values
  /// are normalized using these bounds before converting to screen coordinates.
  /// This ensures ranges appear at the correct position when each series
  /// has its own Y-axis range.
  final DataRange? axisBounds;
  DataRange? _axisBounds;

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

  /// Update axis bounds for perSeries normalization.
  void updateAxisBounds(DataRange? newBounds) {
    _axisBounds = newBounds;
  }

  /// Converts a Y data value to plot Y coordinate.
  ///
  /// When [_axisBounds] is set (perSeries normalization mode), the value
  /// is first normalized to 0-1 range using axis bounds, then mapped to
  /// the plot height. This ensures range annotations appear at the correct
  /// position when each series has its own Y-axis range.
  ///
  /// When axisBounds is null, uses standard transform.
  double _valueToPlotY(double value) {
    final bounds = _axisBounds;
    if (bounds != null && bounds.span > 0) {
      // PerSeries mode: normalize value to 0-1, then map to screen
      // Formula matches MultiAxisPainter:
      //   normalizedY = (value - min) / (max - min)
      //   screenY = plotHeight - (normalizedY * plotHeight)  [inverted Y]
      final normalizedY = (value - bounds.min) / bounds.span;
      return _currentTransform.plotHeight * (1.0 - normalizedY);
    } else {
      // Standard mode: use transform directly
      return _currentTransform.dataToPlot(0, value).dy;
    }
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
  void updateTempValues({double? startX, double? endX, double? startY, double? endY}) {
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
    // Use _valueToPlotY for perSeries normalization support
    final top = annotation.endY != null ? _valueToPlotY(annotation.endY!) : 0.0;

    final bottom = annotation.startY != null ? _valueToPlotY(annotation.startY!) : chartSize.height;

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
        canvas.drawLine(Offset(fillRect.left, fillRect.top), Offset(fillRect.right, fillRect.top), borderPaint);
      }

      // Right border - only if endX is defined (not spanning to right)
      if (annotation.endX != null) {
        canvas.drawLine(Offset(fillRect.right, fillRect.top), Offset(fillRect.right, fillRect.bottom), borderPaint);
      }

      // Bottom border - only if startY is defined (startY = lower Y value = bottom of range)
      if (annotation.startY != null) {
        canvas.drawLine(Offset(fillRect.right, fillRect.bottom), Offset(fillRect.left, fillRect.bottom), borderPaint);
      }

      // Left border - only if startX is defined (not spanning to left)
      if (annotation.startX != null) {
        canvas.drawLine(Offset(fillRect.left, fillRect.bottom), Offset(fillRect.left, fillRect.top), borderPaint);
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
      final handleRect = Rect.fromCenter(center: center, width: handleSize, height: handleSize);
      canvas.drawRect(handleRect, handlePaint);
      canvas.drawRect(handleRect, handleBorderPaint);
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, String label) {
    final textStyle = annotation.style.textStyle;
    final textSpan = TextSpan(text: label, style: textStyle);
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

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
        bgRect = Rect.fromLTWH(rect.left + labelMargin, rect.top + labelMargin, containerWidth, containerHeight);
        break;
      case AnnotationLabelPosition.topRight:
        // Container's top-right corner is labelMargin from range's top-right corner
        bgRect = Rect.fromLTWH(rect.right - containerWidth - labelMargin, rect.top + labelMargin, containerWidth, containerHeight);
        break;
      case AnnotationLabelPosition.bottomLeft:
        // Container's bottom-left corner is labelMargin from range's bottom-left corner
        bgRect = Rect.fromLTWH(rect.left + labelMargin, rect.bottom - containerHeight - labelMargin, containerWidth, containerHeight);
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
        bgRect = Rect.fromLTWH(rect.center.dx - containerWidth / 2, rect.center.dy - containerHeight / 2, containerWidth, containerHeight);
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
    final textPosition = Offset(bgRect.left + padding.left, bgRect.top + padding.top);
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
    final bgRect = Rect.fromLTWH(labelX - padding, labelY - padding, textPainter.width + padding * 2, textPainter.height + padding * 2);
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
    final copy = RangeAnnotationElement(annotation: annotation, transform: transform, chartSize: chartSize);
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
  TextAnnotationElement({required this.annotation}) : _isSelected = false, _isHovered = false {
    _calculateBoundsAndPainter();
  }

  final TextAnnotation annotation;

  Rect? _bounds;
  Offset? _anchoredPosition;
  bool _isSelected;
  bool _isHovered;

  /// Cached TextPainter to avoid recreating on every paint call.
  /// This is expensive to create, especially for rich text with complex formatting.
  TextPainter? _cachedTextPainter;

  /// Cached TextSpan to detect when we need to rebuild the painter.
  TextSpan? _cachedTextSpan;

  /// Temporary position during drag (null when not dragging).
  Offset? _tempPosition;

  /// Get the current temp position (used during drag completion).
  Offset? get tempPosition => _tempPosition;

  /// Calculates bounds and caches the TextPainter for efficient painting.
  /// This is called once on construction and when position changes during drag.
  void _calculateBoundsAndPainter() {
    final textStyle = annotation.style.textStyle;

    // Use toTextSpan() to support both plain and rich text
    // Cache the span to avoid rebuilding on every paint
    _cachedTextSpan = annotation.toTextSpan(baseStyle: textStyle);

    // Create and cache the TextPainter
    _cachedTextPainter = TextPainter(text: _cachedTextSpan, textDirection: TextDirection.ltr)..layout();

    final textSize = _cachedTextPainter!.size;
    final padding = annotation.style.padding ?? const EdgeInsets.all(4.0);

    // Use temp position during drag, otherwise use annotation's position
    final effectivePosition = _tempPosition ?? annotation.position;

    // Calculate anchored position
    _anchoredPosition = _getAnchoredPosition(effectivePosition, textSize + Offset(padding.horizontal, padding.vertical), annotation.anchor);

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

    // Draw text using cached TextPainter (created in _calculateBoundsAndPainter)
    if (_cachedTextPainter != null) {
      _cachedTextPainter!.paint(canvas, Offset(_anchoredPosition!.dx, _anchoredPosition!.dy));
    }
  }

  /// Update temporary position during drag.
  void updateTempPosition(Offset newPosition) {
    _tempPosition = newPosition;
    _calculateBoundsAndPainter(); // Recalculate bounds with new position
  }

  /// Clear temporary position after drag completes.
  void clearTempPosition() {
    _tempPosition = null;
    _calculateBoundsAndPainter(); // Recalculate bounds with original position
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
    copy._cachedTextPainter = _cachedTextPainter;
    copy._cachedTextSpan = _cachedTextSpan;
    return copy;
  }
}

/// A chart element that renders a threshold annotation line.
///
/// Draws a horizontal or vertical reference line at a fixed axis value.
///
/// For multi-axis charts with perSeries normalization, the threshold value
/// must be normalized using the appropriate axis bounds. Pass [axisBounds]
/// to enable this normalization.
class ThresholdAnnotationElement extends ChartElement {
  ThresholdAnnotationElement({required this.annotation, required this.transform, this.axisBounds})
    : _isSelected = false,
      _isHovered = false,
      _currentTransform = transform,
      _axisBounds = axisBounds;

  final ThresholdAnnotation annotation;
  final ChartTransform transform;
  ChartTransform _currentTransform;
  bool _isSelected;
  bool _isHovered;

  /// Optional axis bounds for perSeries normalization.
  ///
  /// When provided (in perSeries normalization mode), the threshold [value]
  /// is normalized using these bounds before converting to screen coordinates.
  /// This ensures thresholds appear at the correct position when each series
  /// has its own Y-axis range.
  final DataRange? axisBounds;
  DataRange? _axisBounds;

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

  /// Update axis bounds for perSeries normalization.
  void updateAxisBounds(DataRange? newBounds) {
    _axisBounds = newBounds;
  }

  /// Converts a Y data value to plot Y coordinate.
  ///
  /// When [_axisBounds] is set (perSeries normalization mode), the value
  /// is first normalized to 0-1 range using axis bounds, then mapped to
  /// the plot height. This ensures threshold lines appear at the correct
  /// position when each series has its own Y-axis range.
  ///
  /// For X-axis values or when axisBounds is null, uses standard transform.
  double _valueToPlotY(double value) {
    final bounds = _axisBounds;
    if (bounds != null && bounds.span > 0) {
      // PerSeries mode: normalize value to 0-1, then map to screen
      // Formula matches MultiAxisPainter:
      //   normalizedY = (value - min) / (max - min)
      //   screenY = plotHeight - (normalizedY * plotHeight)  [inverted Y]
      final normalizedY = (value - bounds.min) / bounds.span;
      return _currentTransform.plotHeight * (1.0 - normalizedY);
    } else {
      // Standard mode: use transform directly
      return _currentTransform.dataToPlot(0, value).dy;
    }
  }

  @override
  String get id => annotation.id;

  /// Calculate the line hit zone bounds (strip along the line).
  Rect _calculateLineBounds() {
    final value = _tempValue ?? annotation.value;
    const hitMargin = 20.0; // 20px margin on each side of line for easier clicking

    if (annotation.axis == AnnotationAxis.y) {
      // Use _valueToPlotY for perSeries normalization support
      final plotY = _valueToPlotY(value);
      return Rect.fromLTWH(0, plotY - annotation.lineWidth / 2 - hitMargin, _currentTransform.plotWidth, annotation.lineWidth + (hitMargin * 2));
    } else {
      final plotX = _currentTransform.dataToPlot(value, 0).dx;
      return Rect.fromLTWH(plotX - annotation.lineWidth / 2 - hitMargin, 0, annotation.lineWidth + (hitMargin * 2), _currentTransform.plotHeight);
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
      // Use _valueToPlotY for perSeries normalization support
      final plotY = _valueToPlotY(value);
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
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

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
      // Horizontal line - use _valueToPlotY for perSeries normalization support
      final plotY = _valueToPlotY(value);
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
        haloRect = Rect.fromLTRB(0, start.dy - haloWidth, _currentTransform.plotWidth, start.dy + haloWidth);
      } else {
        // Vertical line - halo left and right
        haloRect = Rect.fromLTRB(start.dx - haloWidth, 0, start.dx + haloWidth, _currentTransform.plotHeight);
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
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr)..layout();

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
            bgRect = Rect.fromLTWH(start.dx + labelMargin, lineY - containerHeight - labelMargin, containerWidth, containerHeight);
            break;
          case AnnotationLabelPosition.topRight:
            // Container above line, aligned right
            bgRect = Rect.fromLTWH(end.dx - containerWidth - labelMargin, lineY - containerHeight - labelMargin, containerWidth, containerHeight);
            break;
          case AnnotationLabelPosition.bottomLeft:
            // Container below line, aligned left
            bgRect = Rect.fromLTWH(start.dx + labelMargin, lineY + labelMargin, containerWidth, containerHeight);
            break;
          case AnnotationLabelPosition.bottomRight:
            // Container below line, aligned right
            bgRect = Rect.fromLTWH(end.dx - containerWidth - labelMargin, lineY + labelMargin, containerWidth, containerHeight);
            break;
          case AnnotationLabelPosition.center:
            // Container centered on line
            bgRect = Rect.fromLTWH((start.dx + end.dx) / 2 - containerWidth / 2, lineY - containerHeight / 2, containerWidth, containerHeight);
            break;
        }
      } else {
        // Vertical line - position label relative to line X coordinate
        final lineX = start.dx;
        switch (annotation.labelPosition) {
          case AnnotationLabelPosition.topLeft:
            // Container left of line, aligned top
            bgRect = Rect.fromLTWH(lineX - containerWidth - labelMargin, start.dy + labelMargin, containerWidth, containerHeight);
            break;
          case AnnotationLabelPosition.topRight:
            // Container right of line, aligned top
            bgRect = Rect.fromLTWH(lineX + labelMargin, start.dy + labelMargin, containerWidth, containerHeight);
            break;
          case AnnotationLabelPosition.bottomLeft:
            // Container left of line, aligned bottom
            bgRect = Rect.fromLTWH(lineX - containerWidth - labelMargin, end.dy - containerHeight - labelMargin, containerWidth, containerHeight);
            break;
          case AnnotationLabelPosition.bottomRight:
            // Container right of line, aligned bottom
            bgRect = Rect.fromLTWH(lineX + labelMargin, end.dy - containerHeight - labelMargin, containerWidth, containerHeight);
            break;
          case AnnotationLabelPosition.center:
            // Container centered on line
            bgRect = Rect.fromLTWH(lineX - containerWidth / 2, (start.dy + end.dy) / 2 - containerHeight / 2, containerWidth, containerHeight);
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
      final textPosition = Offset(bgRect.left + padding.left, bgRect.top + padding.top);
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
    final copy = ThresholdAnnotationElement(annotation: annotation, transform: _currentTransform, axisBounds: _axisBounds);
    copy._isSelected = isSelected ?? _isSelected;
    copy._isHovered = isHovered ?? _isHovered;
    return copy;
  }
}

/// A chart element that renders a trend annotation line.
///
/// Calculates and displays statistical trend lines over series data.
///
/// In perSeries normalization mode, the trend line Y values must be
/// normalized using the appropriate axis bounds. Pass [axisBounds]
/// to enable correct positioning when each series has its own Y range.
class TrendAnnotationElement extends ChartElement {
  TrendAnnotationElement({required this.annotation, required this.series, required this.transform, this.axisBounds})
    : _isSelected = false,
      _isHovered = false,
      _currentTransform = transform,
      _axisBounds = axisBounds {
    _calculateTrendPoints();
  }

  final TrendAnnotation annotation;
  final ChartSeries series;
  final ChartTransform transform;
  ChartTransform _currentTransform;
  final DataRange? axisBounds;
  DataRange? _axisBounds;
  bool _isSelected;
  bool _isHovered;
  List<Offset> _trendPoints = [];

  // Cached plot-space points and bounds to avoid O(n) recomputation
  // on every QuadTree insert/query/split and every hitTest/paint call.
  List<Offset>? _cachedPlotPoints;
  Rect? _cachedBounds;
  ChartTransform? _plotPointsCachedTransform;
  DataRange? _plotPointsCachedAxisBounds;

  /// Returns trend points converted to plot-space coordinates.
  ///
  /// Cached and invalidated only when the transform or axis bounds change.
  /// This eliminates O(n) `_dataToPlot` calls on every `bounds`, `hitTest`,
  /// and `paint` invocation — previously the dominant cost when a
  /// TrendAnnotation was present (hundreds of coordinate transforms per frame).
  List<Offset> get _plotPoints {
    if (_cachedPlotPoints != null && identical(_plotPointsCachedTransform, _currentTransform) && _plotPointsCachedAxisBounds == _axisBounds) {
      return _cachedPlotPoints!;
    }
    _cachedPlotPoints = _trendPoints.map((p) => _dataToPlot(p.dx, p.dy)).toList();
    _plotPointsCachedTransform = _currentTransform;
    _plotPointsCachedAxisBounds = _axisBounds;
    _cachedBounds = null; // bounds depend on plot points
    return _cachedPlotPoints!;
  }

  /// Invalidates the cached plot-space points and bounds.
  void _invalidatePlotCache() {
    _cachedPlotPoints = null;
    _cachedBounds = null;
  }

  /// Update the current transform before painting.
  void updateTransform(ChartTransform newTransform) {
    if (!identical(_currentTransform, newTransform)) {
      _currentTransform = newTransform;
      _invalidatePlotCache();
    }
  }

  /// Update axis bounds for perSeries normalization.
  void updateAxisBounds(DataRange? newBounds) {
    if (_axisBounds != newBounds) {
      _axisBounds = newBounds;
      _invalidatePlotCache();
    }
  }

  /// Converts a data point to plot coordinates.
  ///
  /// When [_axisBounds] is set (perSeries normalization mode), the Y value
  /// is first normalized to 0-1 range using axis bounds, then mapped to
  /// the plot height. This ensures trend lines appear at the correct
  /// position when each series has its own Y-axis range.
  ///
  /// When axisBounds is null, uses standard transform.
  Offset _dataToPlot(double x, double y) {
    final bounds = _axisBounds;
    if (bounds != null && bounds.span > 0) {
      // PerSeries mode: normalize Y to 0-1, then map to screen
      // X axis uses standard transform
      final plotX = _currentTransform.dataToPlot(x, 0).dx;
      // Y axis uses axisBounds normalization (same formula as ThresholdAnnotationElement)
      final normalizedY = (y - bounds.min) / bounds.span;
      final plotY = _currentTransform.plotHeight * (1.0 - normalizedY);
      return Offset(plotX, plotY);
    } else {
      // Standard mode: use transform directly
      return _currentTransform.dataToPlot(x, y);
    }
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
    return [Offset(minX, m * minX + b), Offset(maxX, m * maxX + b)];
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

  /// Evaluates the trend line Y value at the given data-space X coordinate.
  ///
  /// Uses binary search and linear interpolation on the computed
  /// [_trendPoints]. Returns null if the trend has no points or
  /// [dataX] is outside the trend's X range.
  double? evaluateAt(double dataX) {
    if (_trendPoints.length < 2) return null;

    final first = _trendPoints.first;
    final last = _trendPoints.last;

    // Outside range
    if (dataX < first.dx || dataX > last.dx) return null;

    // Binary search for the bracketing segment
    var lo = 0;
    var hi = _trendPoints.length - 1;
    while (lo < hi - 1) {
      final mid = (lo + hi) >> 1;
      if (_trendPoints[mid].dx <= dataX) {
        lo = mid;
      } else {
        hi = mid;
      }
    }

    final left = _trendPoints[lo];
    final right = _trendPoints[hi];
    final span = right.dx - left.dx;
    if (span == 0) return left.dy;

    final t = (dataX - left.dx) / span;
    return left.dy + (right.dy - left.dy) * t;
  }

  @override
  String get id => annotation.id;

  @override
  Rect get bounds {
    if (_trendPoints.isEmpty) return Rect.zero;

    // Return cached bounds if available (invalidated when plot points change)
    if (_cachedBounds != null) return _cachedBounds!;

    final plotPoints = _plotPoints;

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

    // Add hit test margin (12px matches the hitTest radius for reliable selection)
    _cachedBounds = Rect.fromLTRB(
      minX - annotation.lineWidth - 12,
      minY - annotation.lineWidth - 12,
      maxX + annotation.lineWidth + 12,
      maxY + annotation.lineWidth + 12,
    );
    return _cachedBounds!;
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

    final plotPoints = _plotPoints;

    // Check if click is near any line segment (12px matches threshold's UX feel)
    final hitRadius = annotation.lineWidth + 12;
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

    final plotPoints = _plotPoints;

    // Draw elevation glow in DEFAULT state only (not selected)
    // This creates a subtle glow effect using the line color — same pattern
    // as ThresholdAnnotationElement's elevation glow.
    if (!_isSelected && annotation.elevation > 0) {
      final elevationPaint = Paint()
        ..color = annotation.lineColor.withAlpha(60)
        ..strokeWidth = annotation.lineWidth + annotation.elevation * 2
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, annotation.elevation);

      if (annotation.dashPattern != null && annotation.dashPattern!.isNotEmpty) {
        _drawDashedPolyline(canvas, plotPoints, elevationPaint, annotation.dashPattern!);
      } else {
        final elevationPath = Path()..moveTo(plotPoints.first.dx, plotPoints.first.dy);
        for (int i = 1; i < plotPoints.length; i++) {
          elevationPath.lineTo(plotPoints[i].dx, plotPoints[i].dy);
        }
        canvas.drawPath(elevationPath, elevationPaint);
      }
    }

    // Draw selection glow (behind the line) — always more prominent than
    // the elevation glow so the selection state is visually distinct.
    if (_isSelected) {
      final glowPaint = Paint()
        ..color = annotation.lineColor.withAlpha(130)
        ..strokeWidth = annotation.lineWidth * 4.0 + annotation.elevation * 2
        ..style = PaintingStyle.stroke
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5.0 + annotation.elevation);

      if (annotation.dashPattern != null && annotation.dashPattern!.isNotEmpty) {
        _drawDashedPolyline(canvas, plotPoints, glowPaint, annotation.dashPattern!);
      } else {
        final glowPath = Path()..moveTo(plotPoints.first.dx, plotPoints.first.dy);
        for (int i = 1; i < plotPoints.length; i++) {
          glowPath.lineTo(plotPoints[i].dx, plotPoints[i].dy);
        }
        canvas.drawPath(glowPath, glowPaint);
      }
    }

    // Draw main line
    final paint = Paint()
      ..color = annotation.lineColor
      ..strokeWidth = _isSelected ? annotation.lineWidth * 2.5 : annotation.lineWidth
      ..style = PaintingStyle.stroke;

    if (annotation.dashPattern != null && annotation.dashPattern!.isNotEmpty) {
      _drawDashedPolyline(canvas, plotPoints, paint, annotation.dashPattern!);
    } else {
      final path = Path()..moveTo(plotPoints.first.dx, plotPoints.first.dy);
      for (int i = 1; i < plotPoints.length; i++) {
        path.lineTo(plotPoints[i].dx, plotPoints[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  /// Draws a dashed polyline that carries dash state across all segments.
  ///
  /// Unlike per-segment dashing, this ensures the dash pattern flows
  /// continuously along the entire polyline — critical for moving average
  /// and EMA trends that have many short segments.
  void _drawDashedPolyline(Canvas canvas, List<Offset> points, Paint paint, List<double> dashPattern) {
    if (points.length < 2) return;

    var patternIndex = 0;
    var isDash = true;
    var remaining = dashPattern[0];

    for (int i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];
      final segLength = (end - start).distance;
      if (segLength == 0) continue;

      var consumed = 0.0;
      while (consumed < segLength) {
        final available = segLength - consumed;
        final step = math.min(remaining, available);

        if (isDash) {
          final t1 = consumed / segLength;
          final t2 = (consumed + step) / segLength;
          final p1 = Offset.lerp(start, end, t1)!;
          final p2 = Offset.lerp(start, end, t2)!;
          canvas.drawLine(p1, p2, paint);
        }

        consumed += step;
        remaining -= step;

        if (remaining <= 0) {
          patternIndex = (patternIndex + 1) % dashPattern.length;
          remaining = dashPattern[patternIndex];
          isDash = !isDash;
        }
      }
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
    final copy = TrendAnnotationElement(annotation: annotation, series: series, transform: _currentTransform);
    copy._isSelected = isSelected ?? _isSelected;
    copy._isHovered = isHovered ?? _isHovered;
    copy._trendPoints = _trendPoints;
    return copy;
  }
}

// =============================================================================
// Legend Annotation Element
// =============================================================================

/// A chart element that renders a draggable legend.
///
/// Displays series names with color indicators, similar to professional
/// charting software legends. The legend can be dragged to any position
/// within the chart area.
class LegendAnnotationElement extends ChartElement {
  LegendAnnotationElement({required this.annotation, required Size chartSize}) : _chartSize = chartSize, _isSelected = false, _isHovered = false {
    _calculateBounds();
  }

  final LegendAnnotation annotation;
  Size _chartSize;

  Rect? _bounds;
  bool _isSelected;
  bool _isHovered;

  /// Temporary position during drag (null when not dragging).
  Offset? _tempPosition;

  /// Cached text painters for each series item.
  final List<TextPainter> _textPainters = [];

  /// Cached text painters for each trend annotation item.
  final List<TextPainter> _trendTextPainters = [];

  /// Get the current temp position (used during drag completion).
  Offset? get tempPosition => _tempPosition;

  /// Update chart size (called when chart is resized).
  void updateChartSize(Size newSize) {
    if (_chartSize != newSize) {
      _chartSize = newSize;
      _calculateBounds();
    }
  }

  /// Calculates legend bounds based on series items and style.
  void _calculateBounds() {
    final style = annotation.legendStyle;
    final padding = style.effectivePadding;

    // Clear and rebuild text painters
    _textPainters.clear();
    _trendTextPainters.clear();

    double maxSeriesTextWidth = 0;
    double totalSeriesTextHeight = 0;

    for (final series in annotation.series) {
      final painter = TextPainter(
        text: TextSpan(text: series.displayName, style: style.textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      _textPainters.add(painter);
      maxSeriesTextWidth = math.max(maxSeriesTextWidth, painter.width);
      totalSeriesTextHeight += painter.height;
    }

    // Build trend text painters
    final hasTrends = annotation.trendAnnotations.isNotEmpty;
    double trendHeaderWidth = 0;
    double trendHeaderHeight = 0;
    double maxTrendTextWidth = 0;

    if (hasTrends) {
      final headerPainter = TextPainter(
        text: TextSpan(
          text: 'Trends',
          style: style.textStyle.copyWith(
            fontStyle: FontStyle.italic,
            color: style.textStyle.color?.withAlpha(140) ?? const Color(0x8C000000),
            fontSize: (style.textStyle.fontSize ?? 11) - 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      trendHeaderWidth = headerPainter.width;
      trendHeaderHeight = headerPainter.height;

      for (final trend in annotation.trendAnnotations) {
        final label = trend.label ?? '';
        final painter = TextPainter(
          text: TextSpan(
            text: label,
            style: style.textStyle.copyWith(color: trend.lineColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        _trendTextPainters.add(painter);
        maxTrendTextWidth = math.max(maxTrendTextWidth, painter.width);
      }
    }

    // Calculate legend size
    final itemCount = annotation.series.length;
    final markerItemWidth = style.markerSize + style.markerLabelSpacing;
    final halfSpacing = style.itemSpacing / 2;
    final double legendWidth;
    final double legendHeight;

    if (style.orientation == LegendOrientation.vertical) {
      if (!hasTrends) {
        // Single column: series items stacked
        legendWidth = padding.left + markerItemWidth + maxSeriesTextWidth + padding.right;
        legendHeight = padding.top + totalSeriesTextHeight + (itemCount > 1 ? (itemCount - 1) * style.itemSpacing : 0) + padding.bottom;
      } else {
        // Two-column layout: series left, "Trends" header + items right
        final seriesColWidth = markerItemWidth + maxSeriesTextWidth;
        final trendColWidth = math.max(trendHeaderWidth, markerItemWidth + maxTrendTextWidth);
        final columnGap = style.itemSpacing * 2;

        final seriesColHeight = totalSeriesTextHeight + (itemCount > 1 ? (itemCount - 1) * style.itemSpacing : 0);
        double trendItemsHeight = 0;
        for (final tp in _trendTextPainters) {
          trendItemsHeight += tp.height;
        }
        if (_trendTextPainters.length > 1) {
          trendItemsHeight += (_trendTextPainters.length - 1) * style.itemSpacing;
        }

        legendWidth = padding.left + seriesColWidth + columnGap + trendColWidth + padding.right;
        legendHeight = padding.top + trendHeaderHeight + halfSpacing + math.max(seriesColHeight, trendItemsHeight) + padding.bottom;
      }
    } else {
      // Horizontal: series items side by side on row 1
      double seriesRowWidth = 0;
      for (final painter in _textPainters) {
        seriesRowWidth += markerItemWidth + painter.width;
      }
      seriesRowWidth += (itemCount > 1 ? (itemCount - 1) * style.itemSpacing : 0);

      final maxSeriesItemHeight = _textPainters.isEmpty ? style.textStyle.fontSize ?? 11 : _textPainters.map((p) => p.height).reduce(math.max);
      final seriesRowHeight = math.max(style.markerSize, maxSeriesItemHeight);

      if (!hasTrends) {
        legendWidth = padding.left + seriesRowWidth + padding.right;
        legendHeight = padding.top + seriesRowHeight + padding.bottom;
      } else {
        // Three rows: series row, divider + header row, trend items row
        double trendHeight = halfSpacing + 1.0 + halfSpacing; // divider
        trendHeight += trendHeaderHeight + halfSpacing; // header + gap

        double maxTrendItemHeight = 0;
        for (final tp in _trendTextPainters) {
          maxTrendItemHeight = math.max(maxTrendItemHeight, tp.height);
        }
        maxTrendItemHeight = math.max(maxTrendItemHeight, style.markerSize);
        trendHeight += maxTrendItemHeight;

        double trendRowWidth = 0;
        for (int i = 0; i < _trendTextPainters.length; i++) {
          trendRowWidth += markerItemWidth + _trendTextPainters[i].width;
          if (i < _trendTextPainters.length - 1) trendRowWidth += style.itemSpacing;
        }

        final maxRowWidth = math.max(seriesRowWidth, math.max(trendHeaderWidth, trendRowWidth));
        legendWidth = padding.left + maxRowWidth + padding.right;
        legendHeight = padding.top + seriesRowHeight + trendHeight + padding.bottom;
      }
    }

    // Calculate position based on anchor or custom position
    final Offset topLeft;
    if (_tempPosition != null) {
      topLeft = _tempPosition!;
    } else if (annotation.hasCustomPosition) {
      topLeft = annotation.customPosition!;
    } else {
      topLeft = _calculateAnchoredPosition(Size(legendWidth, legendHeight), style.position, style.offset);
    }

    _bounds = Rect.fromLTWH(topLeft.dx, topLeft.dy, legendWidth, legendHeight);
  }

  /// Calculates position based on anchor point.
  Offset _calculateAnchoredPosition(Size legendSize, LegendPosition position, Offset offset) {
    const margin = 8.0;
    final double x, y;

    switch (position) {
      case LegendPosition.topLeft:
        x = margin;
        y = margin;
      case LegendPosition.topCenter:
        x = (_chartSize.width - legendSize.width) / 2;
        y = margin;
      case LegendPosition.topRight:
        x = _chartSize.width - legendSize.width - margin;
        y = margin;
      case LegendPosition.centerLeft:
        x = margin;
        y = (_chartSize.height - legendSize.height) / 2;
      case LegendPosition.center:
        x = (_chartSize.width - legendSize.width) / 2;
        y = (_chartSize.height - legendSize.height) / 2;
      case LegendPosition.centerRight:
        x = _chartSize.width - legendSize.width - margin;
        y = (_chartSize.height - legendSize.height) / 2;
      case LegendPosition.bottomLeft:
        x = margin;
        y = _chartSize.height - legendSize.height - margin;
      case LegendPosition.bottomCenter:
        x = (_chartSize.width - legendSize.width) / 2;
        y = _chartSize.height - legendSize.height - margin;
      case LegendPosition.bottomRight:
        x = _chartSize.width - legendSize.width - margin;
        y = _chartSize.height - legendSize.height - margin;
    }

    return Offset(x + offset.dx, y + offset.dy);
  }

  @override
  String get id => annotation.id;

  @override
  Rect get bounds => _bounds ?? Rect.zero;

  @override
  ChartElementType get elementType => ChartElementType.annotation;

  @override
  int get renderOrder => RenderOrder.legend;

  @override
  bool get isSelected => _isSelected;

  @override
  bool get isHovered => _isHovered;

  @override
  bool get isSelectable => true;

  @override
  bool get isDraggable => annotation.legendStyle.allowDragging;

  @override
  bool hitTest(Offset position) => _bounds?.contains(position) ?? false;

  @override
  void paint(Canvas canvas, Size size) {
    if (_bounds == null || (annotation.series.isEmpty && annotation.trendAnnotations.isEmpty)) return;

    final style = annotation.legendStyle;
    final padding = style.effectivePadding;

    // Apply opacity
    canvas.saveLayer(_bounds, Paint()..color = Colors.white.withValues(alpha: style.opacity));

    // Draw background
    final bgPaint = Paint()..color = style.effectiveBackgroundColor;
    if (_isHovered) {
      bgPaint.color = bgPaint.color.withValues(alpha: (bgPaint.color.a * 1.05).clamp(0.0, 1.0));
    }

    final rRect = RRect.fromRectAndCorners(
      _bounds!,
      topLeft: style.effectiveBorderRadius.topLeft,
      topRight: style.effectiveBorderRadius.topRight,
      bottomLeft: style.effectiveBorderRadius.bottomLeft,
      bottomRight: style.effectiveBorderRadius.bottomRight,
    );
    canvas.drawRRect(rRect, bgPaint);

    // Draw border
    final borderPaint = Paint()
      ..color = style.effectiveBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _isSelected ? style.borderWidth * 1.5 : style.borderWidth;
    canvas.drawRRect(rRect, borderPaint);

    // Draw legend items
    double currentX = _bounds!.left + padding.left;
    double currentY = _bounds!.top + padding.top;

    final hasTrends = annotation.trendAnnotations.isNotEmpty && _trendTextPainters.isNotEmpty;
    final halfSpacing = style.itemSpacing / 2;

    // For horizontal layout, compute the series row height so markers/text
    // are centered within just the first row.
    final seriesRowHeight = style.orientation == LegendOrientation.horizontal
        ? math.max(style.markerSize, _textPainters.isEmpty ? style.textStyle.fontSize ?? 11 : _textPainters.map((p) => p.height).reduce(math.max))
        : 0.0;

    // For vertical layout with trends, compute header height and offset
    // series items down so they align with trend items below the header.
    double trendHeaderHeight = 0;
    if (style.orientation == LegendOrientation.vertical && hasTrends) {
      final headerPainter = TextPainter(
        text: TextSpan(
          text: 'Trends',
          style: style.textStyle.copyWith(
            fontStyle: FontStyle.italic,
            color: style.textStyle.color?.withAlpha(140) ?? const Color(0x8C000000),
            fontSize: (style.textStyle.fontSize ?? 11) - 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      trendHeaderHeight = headerPainter.height;
      // Offset series items down so they start at the same Y as trend items
      currentY += trendHeaderHeight + halfSpacing;
    }

    for (int i = 0; i < annotation.series.length; i++) {
      final series = annotation.series[i];
      final textPainter = _textPainters[i];
      final isHidden = annotation.hiddenSeriesIds.contains(series.id);

      // Get series color
      final seriesColor = isHidden ? Colors.grey : (series.color ?? _defaultColors[i % _defaultColors.length]);

      // Draw marker
      final markerCenter = style.orientation == LegendOrientation.vertical
          ? Offset(currentX + style.markerSize / 2, currentY + textPainter.height / 2)
          : Offset(currentX + style.markerSize / 2, _bounds!.top + padding.top + seriesRowHeight / 2);

      _drawMarker(canvas, markerCenter, seriesColor, style);

      // Draw text
      final textX = currentX + style.markerSize + style.markerLabelSpacing;
      final textY = style.orientation == LegendOrientation.vertical
          ? currentY
          : _bounds!.top + padding.top + (seriesRowHeight - textPainter.height) / 2;

      // Apply strikethrough if hidden
      if (isHidden) {
        final hiddenPainter = TextPainter(
          text: TextSpan(
            text: series.displayName,
            style: style.textStyle.copyWith(color: Colors.grey, decoration: TextDecoration.lineThrough),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        hiddenPainter.paint(canvas, Offset(textX, textY));
      } else {
        textPainter.paint(canvas, Offset(textX, textY));
      }

      // Move to next item position
      if (style.orientation == LegendOrientation.vertical) {
        currentY += textPainter.height + style.itemSpacing;
      } else {
        currentX += style.markerSize + style.markerLabelSpacing + textPainter.width + style.itemSpacing;
      }
    }

    // Draw trend annotations section (if any)
    if (hasTrends) {
      // Build header painter for rendering
      final headerPainter = TextPainter(
        text: TextSpan(
          text: 'Trends',
          style: style.textStyle.copyWith(
            fontStyle: FontStyle.italic,
            color: style.textStyle.color?.withAlpha(140) ?? const Color(0x8C000000),
            fontSize: (style.textStyle.fontSize ?? 11) - 1,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      if (style.orientation == LegendOrientation.vertical) {
        // Two-column layout: series was drawn in left column.
        // Now draw "Trends" header and trend items in the right column.
        double maxSeriesTextWidth = 0;
        for (final tp in _textPainters) {
          maxSeriesTextWidth = math.max(maxSeriesTextWidth, tp.width);
        }
        final seriesColWidth = style.markerSize + style.markerLabelSpacing + maxSeriesTextWidth;
        final columnGap = style.itemSpacing * 2;
        final rightColX = _bounds!.left + padding.left + seriesColWidth + columnGap;

        // Draw "Trends" header at top of right column
        headerPainter.paint(canvas, Offset(rightColX, _bounds!.top + padding.top));

        // Draw trend items stacked in right column, below header
        double trendY = _bounds!.top + padding.top + trendHeaderHeight + halfSpacing;
        for (int i = 0; i < annotation.trendAnnotations.length && i < _trendTextPainters.length; i++) {
          final trend = annotation.trendAnnotations[i];
          final trendPainter = _trendTextPainters[i];

          final markerCenter = Offset(rightColX + style.markerSize / 2, trendY + trendPainter.height / 2);
          _drawMarker(canvas, markerCenter, trend.lineColor, style, dashPattern: trend.dashPattern);

          final textX = rightColX + style.markerSize + style.markerLabelSpacing;
          trendPainter.paint(canvas, Offset(textX, trendY));

          trendY += trendPainter.height + style.itemSpacing;
        }
      } else {
        // Horizontal: three rows — series row already drawn above.
        // Reset X for new rows below series.
        currentX = _bounds!.left + padding.left;
        currentY = _bounds!.top + padding.top + seriesRowHeight;

        // Draw divider line
        currentY += halfSpacing;
        final dividerPaint = Paint()
          ..color = style.effectiveBorderColor.withAlpha(80)
          ..strokeWidth = 1.0;
        canvas.drawLine(Offset(_bounds!.left + padding.left, currentY), Offset(_bounds!.right - padding.right, currentY), dividerPaint);
        currentY += 1.0 + halfSpacing;

        // Draw "Trends" header on its own line
        headerPainter.paint(canvas, Offset(currentX, currentY));
        currentY += headerPainter.height + halfSpacing;

        // Draw trend items side by side on the next line
        double trendRowHeight = 0;
        for (final tp in _trendTextPainters) {
          trendRowHeight = math.max(trendRowHeight, tp.height);
        }
        trendRowHeight = math.max(trendRowHeight, style.markerSize);

        for (int i = 0; i < annotation.trendAnnotations.length && i < _trendTextPainters.length; i++) {
          final trend = annotation.trendAnnotations[i];
          final trendPainter = _trendTextPainters[i];

          final markerCenter = Offset(currentX + style.markerSize / 2, currentY + trendRowHeight / 2);
          _drawMarker(canvas, markerCenter, trend.lineColor, style, dashPattern: trend.dashPattern);

          final textX = currentX + style.markerSize + style.markerLabelSpacing;
          final textY = currentY + (trendRowHeight - trendPainter.height) / 2;
          trendPainter.paint(canvas, Offset(textX, textY));

          currentX += style.markerSize + style.markerLabelSpacing + trendPainter.width + style.itemSpacing;
        }
      }
    }

    canvas.restore();
  }

  /// Draws a marker at the given position.
  void _drawMarker(Canvas canvas, Offset center, Color color, LegendStyle style, {List<double>? dashPattern}) {
    final paint = Paint()..color = color;

    switch (style.markerShape) {
      case LegendMarkerShape.circle:
        canvas.drawCircle(center, style.markerSize / 2, paint);

      case LegendMarkerShape.square:
        canvas.drawRect(Rect.fromCenter(center: center, width: style.markerSize, height: style.markerSize), paint);

      case LegendMarkerShape.line:
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = style.markerLineWidth
          ..strokeCap = StrokeCap.round;
        final startX = center.dx - style.markerSize / 2;
        final endX = center.dx + style.markerSize / 2;
        final markerLen = style.markerSize;
        if (dashPattern != null && dashPattern.isNotEmpty) {
          // Use butt caps for dashed patterns — round caps add strokeWidth/2
          // visual bleed on each end of every dash, making small gaps invisible.
          paint.strokeCap = StrokeCap.butt;

          // Classify pattern type so each gets appropriate legend scaling:
          //  - Dotted:   drawn < gap, e.g. [2, 6]      — many small dots
          //  - Dash-dot: 4+ segments,  e.g. [8, 4, 2, 4] — mixed long/short
          //  - Dashed:   drawn >= gap, e.g. [5, 5]     — fewer long dashes
          final dashLen = dashPattern.first;
          final gapLen = dashPattern.length > 1 ? dashPattern[1] : dashPattern.first;
          final isDotted = dashLen < gapLen && dashPattern.length <= 2;
          final isDashDot = dashPattern.length > 2;

          if (isDotted) {
            // --- DOTTED ---
            paint.strokeWidth = math.min(style.markerLineWidth, 1.5);
            const targetCycles = 3.5;
            final patternTotal = dashPattern.fold<double>(0, (a, b) => a + b);
            final scale = patternTotal > 0 ? markerLen / (patternTotal * targetCycles) : 1.0;
            final scaled = dashPattern.map((v) => (v * scale).clamp(0.8, markerLen)).toList();
            // Cap gaps so they never exceed 2× the dot size.
            final maxGap = scaled[0] * 2.0;
            for (int i = 1; i < scaled.length; i += 2) {
              scaled[i] = math.min(scaled[i], maxGap);
            }

            double x = startX;
            int patternIdx = 0;
            while (x < endX) {
              final segLen = scaled[patternIdx % scaled.length];
              final segEnd = math.min(x + segLen, endX);
              if (patternIdx % 2 == 0) {
                canvas.drawLine(Offset(x, center.dy), Offset(segEnd, center.dy), paint);
              }
              x = segEnd;
              patternIdx++;
            }
          } else if (isDashDot) {
            // --- DASH-DOT (e.g. [8, 4, 2, 4]) ---
            // Scale to fit exactly 1 full cycle so the long dash and short
            // dot are both visible with correct proportions.
            paint.strokeWidth = math.min(style.markerLineWidth, 2.0);
            final patternTotal = dashPattern.fold<double>(0, (a, b) => a + b);
            final scale = patternTotal > 0 ? markerLen / patternTotal : 1.0;
            // Clamp each segment independently: drawn segments get a 1px
            // floor (preserves the dot), gaps get a 2px floor (stays visible).
            final scaled = <double>[];
            for (int i = 0; i < dashPattern.length; i++) {
              final v = dashPattern[i] * scale;
              scaled.add(v.clamp(i.isEven ? 1.0 : 2.0, markerLen));
            }

            double x = startX;
            int patternIdx = 0;
            while (x < endX) {
              final segLen = scaled[patternIdx % scaled.length];
              final segEnd = math.min(x + segLen, endX);
              if (patternIdx % 2 == 0) {
                canvas.drawLine(Offset(x, center.dy), Offset(segEnd, center.dy), paint);
              }
              x = segEnd;
              patternIdx++;
            }
          } else {
            // --- DASHED ---
            paint.strokeWidth = math.min(style.markerLineWidth, 2.0);
            const targetCycles = 1.5;
            final patternTotal = dashPattern.fold<double>(0, (a, b) => a + b);
            final scale = patternTotal > 0 ? markerLen / (patternTotal * targetCycles) : 1.0;
            final scaled = dashPattern.map((v) => (v * scale).clamp(4.0, markerLen)).toList();

            double x = startX;
            int patternIdx = 0;
            while (x < endX) {
              final segLen = scaled[patternIdx % scaled.length];
              final segEnd = math.min(x + segLen, endX);
              if (patternIdx % 2 == 0) {
                canvas.drawLine(Offset(x, center.dy), Offset(segEnd, center.dy), paint);
              }
              x = segEnd;
              patternIdx++;
            }
          }
        } else {
          canvas.drawLine(Offset(startX, center.dy), Offset(endX, center.dy), paint);
        }

      case LegendMarkerShape.diamond:
        final half = style.markerSize / 2;
        final path = Path()
          ..moveTo(center.dx, center.dy - half)
          ..lineTo(center.dx + half, center.dy)
          ..lineTo(center.dx, center.dy + half)
          ..lineTo(center.dx - half, center.dy)
          ..close();
        canvas.drawPath(path, paint);
    }
  }

  /// Update temporary position during drag.
  void updateTempPosition(Offset newPosition) {
    _tempPosition = newPosition;
    _calculateBounds();
  }

  /// Clear temporary position after drag completes.
  void clearTempPosition() {
    _tempPosition = null;
    _calculateBounds();
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
  int get priority => ElementPriority.forType(elementType);

  @override
  ChartElement copyWith({bool? isHovered, bool? isSelected}) {
    final copy = LegendAnnotationElement(annotation: annotation, chartSize: _chartSize);
    copy._isSelected = isSelected ?? _isSelected;
    copy._isHovered = isHovered ?? _isHovered;
    copy._bounds = _bounds;
    copy._tempPosition = _tempPosition;
    return copy;
  }

  /// Default color palette for series without explicit colors.
  static const List<Color> _defaultColors = [
    Color(0xFF2196F3), // Blue
    Color(0xFFF44336), // Red
    Color(0xFF4CAF50), // Green
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFEB3B), // Yellow
    Color(0xFFE91E63), // Pink
    Color(0xFF009688), // Teal
    Color(0xFF795548), // Brown
  ];
}
