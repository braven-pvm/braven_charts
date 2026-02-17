import 'package:flutter/material.dart';

import '../enums/marker_shape.dart';
import 'annotation_style.dart';
import 'chart_annotation.dart';

/// A point annotation that marks a specific data point with a custom marker.
///
/// PointAnnotation allows highlighting individual data points in a series
/// by drawing a marker at the data point's location. The marker can be
/// offset from the actual data point position for visibility.
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
  ///
  /// The [seriesId] identifies which series contains the data point.
  /// The [dataPointIndex] is the index of the data point in that series.
  /// The [offset] can shift the marker from the data point position.
  /// The [markerShape] determines the visual appearance of the marker.
  /// The [markerSize] controls the marker dimensions.
  /// The [markerColor] sets the marker fill color.
  ///
  /// Throws [AssertionError] if [dataPointIndex] is negative.
  PointAnnotation({
    super.id,
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
  }) : assert(dataPointIndex >= 0, 'Data point index must be non-negative');

  /// The ID of the series containing the data point to annotate.
  final String seriesId;

  /// The index of the data point within the series.
  ///
  /// Must be a valid index (>= 0) within the series data.
  final int dataPointIndex;

  /// Optional offset from the data point position.
  ///
  /// Useful for preventing the marker from obscuring the data point.
  final Offset offset;

  /// The shape of the marker to draw.
  final MarkerShape markerShape;

  /// The size of the marker in logical pixels.
  final double markerSize;

  /// The fill color of the marker.
  final Color markerColor;

  @override
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

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PointAnnotation &&
        other.id == id &&
        other.label == label &&
        other.style == style &&
        other.allowDragging == allowDragging &&
        other.allowEditing == allowEditing &&
        other.zIndex == zIndex &&
        other.seriesId == seriesId &&
        other.dataPointIndex == dataPointIndex &&
        other.offset == offset &&
        other.markerShape == markerShape &&
        other.markerSize == markerSize &&
        other.markerColor == markerColor;
  }

  @override
  int get hashCode => Object.hash(
    id,
    label,
    style,
    allowDragging,
    allowEditing,
    zIndex,
    seriesId,
    dataPointIndex,
    offset,
    markerShape,
    markerSize,
    markerColor,
  );
}
