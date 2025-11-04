import 'package:flutter/material.dart';

import 'annotation_style.dart';
import 'chart_annotation.dart';

/// A range annotation that highlights a rectangular region on the chart.
///
/// RangeAnnotation can highlight time ranges (horizontal), value ranges
/// (vertical), or both by defining start and end bounds. At least one
/// axis range (X or Y) must be specified.
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
  /// The [fillColor] creates a filled rectangle within the range.
  /// The [borderColor] draws a border around the range.
  /// The [labelPosition] determines where the label text appears.
  /// The [snapToValue] enables snapping to nearest data point values when dragging.
  /// The [snapIncrement] controls the snap granularity when snapToValue is enabled.
  ///
  /// Throws [AssertionError] if startX >= endX or startY >= endY when both are provided.
  RangeAnnotation({
    super.id,
    super.label,
    super.style,
    super.allowDragging,
    super.allowEditing,
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
        );

  /// The starting X-axis value of the range.
  ///
  /// If null, the range extends infinitely in the negative X direction.
  final double? startX;

  /// The ending X-axis value of the range.
  ///
  /// If null, the range extends infinitely in the positive X direction.
  final double? endX;

  /// The starting Y-axis value of the range.
  ///
  /// If null, the range extends infinitely in the negative Y direction.
  final double? startY;

  /// The ending Y-axis value of the range.
  ///
  /// If null, the range extends infinitely in the positive Y direction.
  final double? endY;

  /// Optional fill color for the range rectangle.
  ///
  /// If null, the range has no fill.
  final Color? fillColor;

  /// Optional border color for the range rectangle.
  ///
  /// If null, the range has no border.
  final Color? borderColor;

  /// Where to position the label text within the range.
  final AnnotationLabelPosition labelPosition;

  @override
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RangeAnnotation &&
        other.id == id &&
        other.label == label &&
        other.style == style &&
        other.allowDragging == allowDragging &&
        other.allowEditing == allowEditing &&
        other.zIndex == zIndex &&
        other.snapToValue == snapToValue &&
        other.snapIncrement == snapIncrement &&
        other.startX == startX &&
        other.endX == endX &&
        other.startY == startY &&
        other.endY == endY &&
        other.fillColor == fillColor &&
        other.borderColor == borderColor &&
        other.labelPosition == labelPosition;
  }

  @override
  int get hashCode => Object.hash(
        id,
        label,
        style,
        allowDragging,
        allowEditing,
        zIndex,
        snapToValue,
        snapIncrement,
        startX,
        endX,
        startY,
        endY,
        fillColor,
        borderColor,
        labelPosition,
      );
}

/// Position for range annotation labels.
enum AnnotationLabelPosition {
  /// Top-left corner of the range.
  topLeft,

  /// Top-right corner of the range.
  topRight,

  /// Bottom-left corner of the range.
  bottomLeft,

  /// Bottom-right corner of the range.
  bottomRight,

  /// Center of the range.
  center,
}
