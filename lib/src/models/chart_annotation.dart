// Copyright (c) 2025 braven_charts. All rights reserved.
// Chart Annotation Base Classes for BravenChartPlus

import 'package:flutter/material.dart';

import 'annotation_style.dart';
import 'enums.dart';

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
    this.labelMargin = 4.0,
  })  : assert(dataPointIndex >= 0, 'Data point index must be non-negative'),
        assert(labelMargin >= 0, 'Label margin must be non-negative'),
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

  /// The spacing between the marker edge and the label container edge.
  ///
  /// Controls how far the label is positioned from the marker.
  /// Defaults to 4.0 logical pixels.
  final double labelMargin;

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
    double? labelMargin,
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
      labelMargin: labelMargin ?? this.labelMargin,
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
    this.snapTolerance = 0.05,
    this.startX,
    this.endX,
    this.startY,
    this.endY,
    this.fillColor,
    this.borderColor,
    this.labelPosition = AnnotationLabelPosition.topLeft,
    this.labelMargin = 8.0,
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
        assert(snapTolerance >= 0 && snapTolerance <= 1, 'snapTolerance must be between 0 and 1'),
        assert(labelMargin >= 0, 'Label margin must be non-negative'),
        super(id: id ?? ChartAnnotation.generateId());

  /// The starting X-axis value of the range (null = infinite negative).
  final double? startX;

  /// The ending X-axis value of the range (null = infinite positive).
  final double? endX;

  /// The starting Y-axis value of the range (null = infinite negative).
  final double? startY;

  /// The ending Y-axis value of the range (null = infinite positive).
  final double? endY;

  /// The snap tolerance as a fraction of the visible viewport range (0.0 to 1.0).
  ///
  /// When [snapToValue] is enabled, this controls the maximum distance from a data
  /// point for snapping to occur, expressed as a percentage of the visible range.
  /// For example, 0.05 (default) means snap within 5% of the visible X or Y range.
  ///
  /// Defaults to 0.05 (5% of viewport).
  final double snapTolerance;

  /// Optional fill color for the range rectangle.
  final Color? fillColor;

  /// Optional border color for the range rectangle.
  final Color? borderColor;

  /// Where to position the label text within the range.
  final AnnotationLabelPosition labelPosition;

  /// The spacing between the range edge and the label container edge.
  ///
  /// Controls how far the label is positioned from the range boundary.
  /// Defaults to 8.0 logical pixels.
  final double labelMargin;

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
    double? snapTolerance,
    double? startX,
    double? endX,
    double? startY,
    double? endY,
    Color? fillColor,
    Color? borderColor,
    AnnotationLabelPosition? labelPosition,
    double? labelMargin,
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
      snapTolerance: snapTolerance ?? this.snapTolerance,
      startX: startX ?? this.startX,
      endX: endX ?? this.endX,
      startY: startY ?? this.startY,
      endY: endY ?? this.endY,
      fillColor: fillColor ?? this.fillColor,
      borderColor: borderColor ?? this.borderColor,
      labelPosition: labelPosition ?? this.labelPosition,
      labelMargin: labelMargin ?? this.labelMargin,
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

/// Which axis a threshold annotation is perpendicular to.
enum AnnotationAxis {
  /// Horizontal line at Y value.
  y,

  /// Vertical line at X value.
  x,
}

/// A threshold annotation that draws a reference line at a fixed axis value.
///
/// Creates horizontal or vertical lines across the chart to mark important
/// reference values (e.g., target values, limits, averages).
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
  ThresholdAnnotation({
    String? id,
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
    this.labelMargin = 8.0,
    this.elevation = 0.0,
  })  : assert(value.isFinite, 'Threshold value must be finite'),
        assert(labelMargin >= 0, 'Label margin must be non-negative'),
        assert(elevation >= 0, 'Elevation must be non-negative'),
        super(id: id ?? ChartAnnotation.generateId());

  /// Which axis this threshold line is perpendicular to.
  final AnnotationAxis axis;

  /// The axis value where the threshold line is drawn.
  final double value;

  /// The color of the threshold line.
  final Color lineColor;

  /// The width of the threshold line in logical pixels.
  final double lineWidth;

  /// Optional dash pattern for the line.
  final List<double>? dashPattern;

  /// Where to position the label text along the threshold line.
  final AnnotationLabelPosition labelPosition;

  /// The spacing between the threshold line and the label container edge.
  ///
  /// Controls how far the label is positioned from the threshold line.
  /// Defaults to 8.0 logical pixels.
  final double labelMargin;

  /// The elevation/glow spread for the threshold line in the default state.
  ///
  /// When greater than 0, a glow effect is drawn behind the line using the
  /// same color as [lineColor]. The value controls the blur radius of the glow.
  ///
  /// This only affects the default state (not selected or dragging).
  /// Defaults to 0.0 (no glow).
  final double elevation;

  /// Creates a copy with modified properties.
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
    double? labelMargin,
    double? elevation,
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
      labelMargin: labelMargin ?? this.labelMargin,
      elevation: elevation ?? this.elevation,
    );
  }
}

/// A pin annotation that marks an arbitrary position on the chart using x/y coordinates.
///
/// Unlike [PointAnnotation] which is tied to a specific series and data point,
/// PinAnnotation uses explicit x/y coordinates and is not attached to any series.
/// It moves with zoom/pan based on coordinate transformation.
///
/// Example:
/// ```dart
/// PinAnnotation(
///   id: 'marker1',
///   x: 25.0,
///   y: 150.0,
///   label: 'Important Point',
///   markerShape: MarkerShape.star,
///   markerSize: 12.0,
///   markerColor: Colors.red,
/// )
/// ```
class PinAnnotation extends ChartAnnotation {
  /// Creates a pin annotation at the specified x/y coordinates.
  PinAnnotation({
    String? id,
    super.label,
    super.style,
    super.allowDragging,
    super.allowEditing,
    super.zIndex,
    required this.x,
    required this.y,
    this.markerShape = MarkerShape.circle,
    this.markerSize = 8.0,
    this.markerColor = Colors.blue,
    this.labelMargin = 4.0,
  })  : assert(x.isFinite, 'X coordinate must be finite'),
        assert(y.isFinite, 'Y coordinate must be finite'),
        assert(labelMargin >= 0, 'Label margin must be non-negative'),
        super(id: id ?? ChartAnnotation.generateId());

  /// The X-axis data coordinate.
  final double x;

  /// The Y-axis data coordinate.
  final double y;

  /// The shape of the marker to draw.
  final MarkerShape markerShape;

  /// The size of the marker in logical pixels.
  final double markerSize;

  /// The fill color of the marker.
  final Color markerColor;

  /// The spacing between the marker edge and the label container edge.
  ///
  /// Controls how far the label is positioned from the marker.
  /// Defaults to 4.0 logical pixels.
  final double labelMargin;

  /// Creates a copy with modified properties.
  PinAnnotation copyWith({
    String? id,
    String? label,
    AnnotationStyle? style,
    bool? allowDragging,
    bool? allowEditing,
    int? zIndex,
    double? x,
    double? y,
    MarkerShape? markerShape,
    double? markerSize,
    Color? markerColor,
    double? labelMargin,
  }) {
    return PinAnnotation(
      id: id ?? this.id,
      label: label ?? this.label,
      style: style ?? this.style,
      allowDragging: allowDragging ?? this.allowDragging,
      allowEditing: allowEditing ?? this.allowEditing,
      zIndex: zIndex ?? this.zIndex,
      x: x ?? this.x,
      y: y ?? this.y,
      markerShape: markerShape ?? this.markerShape,
      markerSize: markerSize ?? this.markerSize,
      markerColor: markerColor ?? this.markerColor,
      labelMargin: labelMargin ?? this.labelMargin,
    );
  }
}

/// Type of trend calculation.
enum TrendType {
  /// Linear regression (y = mx + b).
  linear,

  /// Polynomial regression (y = ax^n + bx^(n-1) + ... + c).
  polynomial,

  /// Simple moving average.
  movingAverage,

  /// Exponential moving average.
  exponentialMovingAverage,
}

/// A trend annotation that overlays statistical trend lines on chart data.
///
/// Calculates and displays trend lines (linear regression, polynomial fits,
/// moving averages, etc.) for a specific data series.
///
/// Example:
/// ```dart
/// TrendAnnotation(
///   id: 'trend1',
///   seriesId: 'temperature',
///   trendType: TrendType.linear,
///   lineColor: Colors.red,
///   dashPattern: [5, 5],
/// )
/// ```
class TrendAnnotation extends ChartAnnotation {
  /// Creates a trend annotation.
  TrendAnnotation({
    String? id,
    super.label,
    super.style,
    super.allowDragging,
    super.allowEditing,
    super.zIndex,
    this.seriesId = '',
    required this.trendType,
    this.windowSize,
    this.degree = 2,
    this.lineColor = Colors.blue,
    this.lineWidth = 2.0,
    this.dashPattern,
    this.labelMargin = 4.0,
  })  : assert(
          trendType != TrendType.movingAverage || (windowSize != null && windowSize > 0),
          'windowSize must be positive when trendType is movingAverage',
        ),
        assert(
          degree > 0,
          'degree must be positive',
        ),
        assert(labelMargin >= 0, 'Label margin must be non-negative'),
        super(id: id ?? ChartAnnotation.generateId());

  /// The ID of the series to calculate the trend for.
  final String seriesId;

  /// The type of trend calculation to perform.
  final TrendType trendType;

  /// Window size for moving average trends (required for movingAverage).
  final int? windowSize;

  /// Polynomial degree for polynomial regression (default 2).
  final int degree;

  /// The color of the trend line.
  final Color lineColor;

  /// The width of the trend line in logical pixels.
  final double lineWidth;

  /// Optional dash pattern for the trend line.
  final List<double>? dashPattern;

  /// The spacing between the trend line endpoint and the label container edge.
  ///
  /// Controls how far the label is positioned from the trend line end.
  /// Defaults to 4.0 logical pixels.
  final double labelMargin;

  /// Creates a copy with modified properties.
  TrendAnnotation copyWith({
    String? id,
    String? label,
    AnnotationStyle? style,
    bool? allowDragging,
    bool? allowEditing,
    int? zIndex,
    String? seriesId,
    TrendType? trendType,
    int? windowSize,
    int? degree,
    Color? lineColor,
    double? lineWidth,
    List<double>? dashPattern,
    double? labelMargin,
  }) {
    return TrendAnnotation(
      id: id ?? this.id,
      label: label ?? this.label,
      style: style ?? this.style,
      allowDragging: allowDragging ?? this.allowDragging,
      allowEditing: allowEditing ?? this.allowEditing,
      zIndex: zIndex ?? this.zIndex,
      seriesId: seriesId ?? this.seriesId,
      trendType: trendType ?? this.trendType,
      windowSize: windowSize ?? this.windowSize,
      degree: degree ?? this.degree,
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      dashPattern: dashPattern ?? this.dashPattern,
      labelMargin: labelMargin ?? this.labelMargin,
    );
  }
}
