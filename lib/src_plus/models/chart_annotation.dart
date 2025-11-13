// Copyright (c) 2025 braven_charts. All rights reserved.
// Chart Annotation Base Classes for BravenChartPlus

import 'package:flutter/material.dart';

import 'annotation_style.dart';

/// Counter for auto-generating annotation IDs.
int _annotationIdCounter = 0;

/// Base sealed class for all chart annotations using Dart 3.0+ pattern matching.
///
/// All annotation types (Point, Range, Text, Threshold, Trend) extend this class.
/// Use pattern matching with `switch` or `if/is` to handle different types.
///
/// Example:
/// ```dart
/// String getAnnotationType(ChartAnnotation annotation) {
///   return switch (annotation) {
///     PointAnnotation() => 'Point',
///     RangeAnnotation() => 'Range',
///     TextAnnotation() => 'Text',
///     ThresholdAnnotation() => 'Threshold',
///     TrendAnnotation() => 'Trend',
///   };
/// }
/// ```
sealed class ChartAnnotation {
  /// Creates a chart annotation.
  ///
  /// If [id] is not provided, a unique ID will be auto-generated.
  const ChartAnnotation({
    required this.id,
    this.label,
    this.style = const AnnotationStyle(),
    this.allowDragging = false,
    this.allowEditing = false,
    this.zIndex = 0,
    this.snapToValue = false,
    this.snapIncrement = 0.5,
  });

  /// Unique identifier for this annotation.
  ///
  /// Used for managing, updating, and removing annotations from a chart.
  /// Must be unique within a single chart instance.
  final String id;

  /// Optional label for this annotation.
  ///
  /// Can be displayed in the UI or used for accessibility purposes.
  final String? label;

  /// Visual style configuration for this annotation.
  ///
  /// Controls font size, colors, borders, and other visual properties.
  final AnnotationStyle style;

  /// Whether this annotation can be dragged by the user.
  ///
  /// When true, the annotation can be repositioned interactively.
  final bool allowDragging;

  /// Whether this annotation can be edited by the user.
  ///
  /// When true, the annotation's properties can be modified interactively.
  final bool allowEditing;

  /// Rendering order for this annotation.
  ///
  /// Annotations with higher zIndex values are rendered on top of
  /// annotations with lower values.
  final int zIndex;

  /// Whether to snap annotation values to nearest data point values when dragging.
  ///
  /// When true, dragging the annotation will snap its position to the nearest
  /// actual data point values on the chart axes.
  final bool snapToValue;

  /// The increment to snap to when [snapToValue] is enabled.
  ///
  /// Controls the granularity of snapping:
  /// - 0.1: Snap to tenths (2.3, 2.4, 2.5)
  /// - 0.5: Snap to halves (2.0, 2.5, 3.0) - default
  /// - 1.0: Snap to integers (2, 3, 4)
  /// - 10.0: Snap to tens (10, 20, 30)
  final double snapIncrement;

  /// Generates a unique annotation ID.
  static String generateId() => 'annotation_${_annotationIdCounter++}';
}

/// Marker shapes for point annotations.
enum MarkerShape {
  circle,
  square,
  triangle,
  diamond,
  star,
  cross,
  plus,
}

/// Anchor point for text annotations positioning.
enum AnnotationAnchor {
  topLeft,
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}

/// Position for range annotation labels.
enum AnnotationLabelPosition {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
  center,
}

/// A point annotation that marks a specific data point with a custom marker.
///
/// Example:
/// ```dart
/// PointAnnotation(
///   id: 'peak',
///   seriesId: 'temperature',
///   dataPointIndex: 42,
///   markerShape: MarkerShape.star,
///   markerSize: 12.0,
///   markerColor: Colors.red,
/// )
/// ```
class PointAnnotation extends ChartAnnotation {
  /// Creates a point annotation.
  PointAnnotation({
    String? id,
    super.label,
    super.style,
    super.allowDragging,
    super.allowEditing,
    super.zIndex,
    required this.seriesId,
    required this.dataPointIndex,
    this.offset = Offset.zero,
    this.markerShape = MarkerShape.circle,
    this.markerSize = 8.0,
    this.markerColor = Colors.blue,
  })  : assert(dataPointIndex >= 0, 'Data point index must be non-negative'),
        super(id: id ?? ChartAnnotation.generateId());

  /// The ID of the series containing the data point to annotate.
  final String seriesId;

  /// The index of the data point within the series (must be >= 0).
  final int dataPointIndex;

  /// Optional offset from the data point position.
  final Offset offset;

  /// The shape of the marker to draw.
  final MarkerShape markerShape;

  /// The size of the marker in logical pixels.
  final double markerSize;

  /// The fill color of the marker.
  final Color markerColor;

  /// Creates a copy with modified properties.
  PointAnnotation copyWith({
    String? id,
    String? label,
    AnnotationStyle? style,
    bool? allowDragging,
    bool? allowEditing,
    int? zIndex,
    String? seriesId,
    int? dataPointIndex,
    Offset? offset,
    MarkerShape? markerShape,
    double? markerSize,
    Color? markerColor,
  }) {
    return PointAnnotation(
      id: id ?? this.id,
      label: label ?? this.label,
      style: style ?? this.style,
      allowDragging: allowDragging ?? this.allowDragging,
      allowEditing: allowEditing ?? this.allowEditing,
      zIndex: zIndex ?? this.zIndex,
      seriesId: seriesId ?? this.seriesId,
      dataPointIndex: dataPointIndex ?? this.dataPointIndex,
      offset: offset ?? this.offset,
      markerShape: markerShape ?? this.markerShape,
      markerSize: markerSize ?? this.markerSize,
      markerColor: markerColor ?? this.markerColor,
    );
  }
}

/// A range annotation that highlights a rectangular region on the chart.
///
/// Example:
/// ```dart
/// RangeAnnotation(
///   id: 'weekend',
///   startX: 5.0,
///   endX: 7.0,
///   fillColor: Colors.grey.withOpacity(0.2),
///   label: 'Weekend',
/// )
/// ```
class RangeAnnotation extends ChartAnnotation {
  /// Creates a range annotation.
  ///
  /// At least one of ([startX], [endX]) or ([startY], [endY]) must be provided.
  RangeAnnotation({
    String? id,
    super.label,
    super.style,
    super.allowDragging = true,
    super.allowEditing = true,
    super.zIndex,
    super.snapToValue,
    super.snapIncrement,
    this.startX,
    this.endX,
    this.startY,
    this.endY,
    this.fillColor,
    this.borderColor,
    this.labelPosition = AnnotationLabelPosition.topLeft,
  })  : assert(
          startX != null || startY != null,
          'At least one range (X or Y) must be specified',
        ),
        assert(
          startX == null || endX == null || startX < endX,
          'startX must be less than endX',
        ),
        assert(
          startY == null || endY == null || startY < endY,
          'startY must be less than endY',
        ),
        super(id: id ?? ChartAnnotation.generateId());

  /// The starting X-axis value of the range (null = infinite negative).
  final double? startX;

  /// The ending X-axis value of the range (null = infinite positive).
  final double? endX;

  /// The starting Y-axis value of the range (null = infinite negative).
  final double? startY;

  /// The ending Y-axis value of the range (null = infinite positive).
  final double? endY;

  /// Optional fill color for the range rectangle.
  final Color? fillColor;

  /// Optional border color for the range rectangle.
  final Color? borderColor;

  /// Where to position the label text within the range.
  final AnnotationLabelPosition labelPosition;

  /// Creates a copy with modified properties.
  RangeAnnotation copyWith({
    String? id,
    String? label,
    AnnotationStyle? style,
    bool? allowDragging,
    bool? allowEditing,
    int? zIndex,
    bool? snapToValue,
    double? snapIncrement,
    double? startX,
    double? endX,
    double? startY,
    double? endY,
    Color? fillColor,
    Color? borderColor,
    AnnotationLabelPosition? labelPosition,
  }) {
    return RangeAnnotation(
      id: id ?? this.id,
      label: label ?? this.label,
      style: style ?? this.style,
      allowDragging: allowDragging ?? this.allowDragging,
      allowEditing: allowEditing ?? this.allowEditing,
      zIndex: zIndex ?? this.zIndex,
      snapToValue: snapToValue ?? this.snapToValue,
      snapIncrement: snapIncrement ?? this.snapIncrement,
      startX: startX ?? this.startX,
      endX: endX ?? this.endX,
      startY: startY ?? this.startY,
      endY: endY ?? this.endY,
      fillColor: fillColor ?? this.fillColor,
      borderColor: borderColor ?? this.borderColor,
      labelPosition: labelPosition ?? this.labelPosition,
    );
  }
}

/// A text annotation that displays text at a specific screen position.
///
/// Uses screen coordinates (static placement) rather than data coordinates.
///
/// Example:
/// ```dart
/// TextAnnotation(
///   id: 'title',
///   text: 'Sales Data',
///   position: Offset(100, 50),
///   anchor: AnnotationAnchor.topLeft,
/// )
/// ```
class TextAnnotation extends ChartAnnotation {
  /// Creates a text annotation at a screen position.
  TextAnnotation({
    String? id,
    super.label,
    super.style,
    super.allowDragging,
    super.allowEditing,
    super.zIndex,
    required this.text,
    required this.position,
    this.anchor = AnnotationAnchor.topLeft,
    this.backgroundColor,
    this.borderColor,
  })  : assert(
          position.dx >= 0 && position.dy >= 0,
          'Position cannot have negative coordinates',
        ),
        super(id: id ?? ChartAnnotation.generateId());

  /// The text content to display.
  final String text;

  /// The screen position where this annotation is anchored.
  final Offset position;

  /// How the text aligns relative to the position point.
  final AnnotationAnchor anchor;

  /// Optional background color for the text box.
  final Color? backgroundColor;

  /// Optional border color for the text box.
  final Color? borderColor;

  /// Creates a copy with modified properties.
  TextAnnotation copyWith({
    String? id,
    String? label,
    AnnotationStyle? style,
    bool? allowDragging,
    bool? allowEditing,
    int? zIndex,
    String? text,
    Offset? position,
    AnnotationAnchor? anchor,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return TextAnnotation(
      id: id ?? this.id,
      label: label ?? this.label,
      style: style ?? this.style,
      allowDragging: allowDragging ?? this.allowDragging,
      allowEditing: allowEditing ?? this.allowEditing,
      zIndex: zIndex ?? this.zIndex,
      text: text ?? this.text,
      position: position ?? this.position,
      anchor: anchor ?? this.anchor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
    );
  }
}
