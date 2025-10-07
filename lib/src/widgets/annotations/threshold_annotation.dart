import 'package:flutter/material.dart';
import 'chart_annotation.dart';
import 'annotation_style.dart';
import '../enums/annotation_axis.dart';
import 'range_annotation.dart';

/// A threshold annotation that draws a reference line at a fixed axis value.
///
/// ThresholdAnnotation creates horizontal or vertical lines across the chart
/// to mark important reference values (e.g., target values, limits, averages).
///
/// Example:
/// ```dart
/// ThresholdAnnotation(
///   id: 'target',
///   axis: AnnotationAxis.y,
///   value: 100.0,
///   label: 'Target',
///   lineColor: Colors.green,
///   lineWidth: 2.0,
/// )
/// ```
class ThresholdAnnotation extends ChartAnnotation {
  /// Creates a threshold annotation.
  ///
  /// The [axis] determines whether this is a horizontal (y-axis) or
  /// vertical (x-axis) line.
  /// The [value] is the axis value where the line is drawn.
  /// The [lineColor] sets the line color.
  /// The [lineWidth] controls the line thickness.
  /// The [dashPattern] creates a dashed line if provided.
  /// The [labelPosition] determines where the label appears along the line.
  ///
  /// Throws [AssertionError] if [value] is NaN or infinite.
  ThresholdAnnotation({
    super.id,
    super.label,
    super.style,
    super.allowDragging,
    super.allowEditing,
    super.zIndex,
    required this.axis,
    required this.value,
    this.lineColor = Colors.black,
    this.lineWidth = 1.0,
    this.dashPattern,
    this.labelPosition = AnnotationLabelPosition.topLeft,
  }) : assert(
          value.isFinite,
          'Threshold value must be finite (not NaN or infinite)',
        );

  /// Which axis this threshold line is perpendicular to.
  ///
  /// [AnnotationAxis.y] creates a horizontal line at the Y value.
  /// [AnnotationAxis.x] creates a vertical line at the X value.
  final AnnotationAxis axis;

  /// The axis value where the threshold line is drawn.
  ///
  /// Must be a finite number (not NaN or infinite).
  final double value;

  /// The color of the threshold line.
  final Color lineColor;

  /// The width of the threshold line in logical pixels.
  final double lineWidth;

  /// Optional dash pattern for the line.
  ///
  /// If null, the line is solid. If provided, alternates between
  /// dash length and gap length (e.g., [5, 3] for 5px dash, 3px gap).
  final List<double>? dashPattern;

  /// Where to position the label text along the threshold line.
  final AnnotationLabelPosition labelPosition;

  @override
  ThresholdAnnotation copyWith({
    String? id,
    String? label,
    AnnotationStyle? style,
    bool? allowDragging,
    bool? allowEditing,
    int? zIndex,
    AnnotationAxis? axis,
    double? value,
    Color? lineColor,
    double? lineWidth,
    List<double>? dashPattern,
    AnnotationLabelPosition? labelPosition,
  }) {
    return ThresholdAnnotation(
      id: id ?? this.id,
      label: label ?? this.label,
      style: style ?? this.style,
      allowDragging: allowDragging ?? this.allowDragging,
      allowEditing: allowEditing ?? this.allowEditing,
      zIndex: zIndex ?? this.zIndex,
      axis: axis ?? this.axis,
      value: value ?? this.value,
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      dashPattern: dashPattern ?? this.dashPattern,
      labelPosition: labelPosition ?? this.labelPosition,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ThresholdAnnotation &&
        other.id == id &&
        other.label == label &&
        other.style == style &&
        other.allowDragging == allowDragging &&
        other.allowEditing == allowEditing &&
        other.zIndex == zIndex &&
        other.axis == axis &&
        other.value == value &&
        other.lineColor == lineColor &&
        other.lineWidth == lineWidth &&
        _listEquals(other.dashPattern, dashPattern) &&
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
        axis,
        value,
        lineColor,
        lineWidth,
        Object.hashAll(dashPattern ?? []),
        labelPosition,
      );

  /// Helper to compare nullable lists.
  bool _listEquals(List<double>? a, List<double>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
