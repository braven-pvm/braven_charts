import 'package:flutter/material.dart';

import '../enums/annotation_anchor.dart';
import 'annotation_style.dart';
import 'chart_annotation.dart';

/// A text annotation that displays text at a specific position.
///
/// **Dual-Mode Positioning:**
/// TextAnnotation supports two positioning modes:
///
/// 1. **Screen-coordinate mode** (viewport-independent):
///    - Uses [position] (Offset) for static screen placement
///    - Text stays fixed regardless of zoom/pan
///    - Example: Chart title overlay, watermark
///
/// 2. **Data-coordinate mode** (data-anchored):
///    - Uses [dataX], [dataY], [seriesId] for data-point anchoring
///    - Text moves with data during zoom/pan
///    - Example: Data point labels, event markers
///
/// **Mode Selection:**
/// - If [dataX], [dataY], [seriesId] are ALL provided → data-coordinate mode
/// - Otherwise → screen-coordinate mode (uses [position])
///
/// **Examples:**
/// ```dart
/// // Screen-coordinate mode (static position)
/// TextAnnotation(
///   id: 'title',
///   text: 'Sales Data',
///   position: Offset(100, 50),
///   anchor: AnnotationAnchor.topLeft,
/// )
///
/// // Data-coordinate mode (anchored to data point)
/// TextAnnotation(
///   id: 'peak',
///   text: 'Peak Sales',
///   dataX: 42.0,
///   dataY: 1850.0,
///   seriesId: 'revenue',
///   anchor: AnnotationAnchor.bottomCenter,
/// )
/// ```
class TextAnnotation extends ChartAnnotation {
  /// Creates a text annotation.
  ///
  /// **Required parameters:**
  /// - [text]: The content to display
  ///
  /// **Screen-coordinate mode:**
  /// - [position]: Screen coordinate where text is anchored (required for this mode)
  ///
  /// **Data-coordinate mode:**
  /// - [dataX]: X-axis data value (required for this mode)
  /// - [dataY]: Y-axis data value (required for this mode)
  /// - [seriesId]: Series identifier for data point (required for this mode)
  ///
  /// **Optional styling:**
  /// - [anchor]: How text aligns relative to position (default: topLeft)
  /// - [backgroundColor]: Optional background fill color
  /// - [borderColor]: Optional border color
  ///
  /// **Validation:**
  /// - Screen mode: [position] must have non-negative coordinates
  /// - Data mode: All three fields ([dataX], [dataY], [seriesId]) must be provided together
  /// - Cannot mix modes: Either use [position] OR [dataX]/[dataY]/[seriesId]
  TextAnnotation({
    super.id,
    super.label,
    super.style,
    super.allowDragging,
    super.allowEditing,
    super.zIndex,
    required this.text,
    this.position,
    this.dataX,
    this.dataY,
    this.seriesId,
    this.anchor = AnnotationAnchor.topLeft,
    this.backgroundColor,
    this.borderColor,
  })  : assert(
          (position != null && dataX == null && dataY == null && seriesId == null) ||
              (position == null && dataX != null && dataY != null && seriesId != null),
          'TextAnnotation must use EITHER screen coordinates (position) OR data coordinates (dataX, dataY, seriesId), not both or neither',
        ),
        assert(
          position == null || (position.dx >= 0 && position.dy >= 0),
          'Position cannot have negative coordinates',
        );

  /// The text content to display.
  final String text;

  /// The screen position where this annotation is anchored (screen-coordinate mode).
  ///
  /// **Screen-coordinate mode**: When [position] is provided (and data coordinates are null),
  /// the text is placed at this fixed screen location regardless of zoom/pan.
  ///
  /// **Mutually exclusive with data-coordinate mode**: Cannot be used with [dataX]/[dataY]/[seriesId].
  ///
  /// Must have non-negative dx and dy values.
  final Offset? position;

  /// X-axis data value for data-anchored positioning (data-coordinate mode).
  ///
  /// **Data-coordinate mode**: When [dataX], [dataY], and [seriesId] are ALL provided,
  /// the text is anchored to this data point and moves with zoom/pan.
  ///
  /// **Mutually exclusive with screen-coordinate mode**: Cannot be used with [position].
  final double? dataX;

  /// Y-axis data value for data-anchored positioning (data-coordinate mode).
  ///
  /// **Data-coordinate mode**: When [dataX], [dataY], and [seriesId] are ALL provided,
  /// the text is anchored to this data point and moves with zoom/pan.
  ///
  /// **Mutually exclusive with screen-coordinate mode**: Cannot be used with [position].
  final double? dataY;

  /// Series identifier for data-anchored positioning (data-coordinate mode).
  ///
  /// **Data-coordinate mode**: Specifies which series contains the data point.
  /// Must match a ChartSeries.id in the chart.
  ///
  /// **Mutually exclusive with screen-coordinate mode**: Cannot be used with [position].
  final String? seriesId;

  /// How the text aligns relative to the position point.
  ///
  /// For example, [AnnotationAnchor.topLeft] means the position point
  /// is at the top-left corner of the text box.
  final AnnotationAnchor anchor;

  /// Optional background color for the text box.
  ///
  /// If null, the text has no background fill.
  final Color? backgroundColor;

  /// Optional border color for the text box.
  ///
  /// If null, the text has no border.
  final Color? borderColor;

  @override
  TextAnnotation copyWith({
    String? id,
    String? label,
    AnnotationStyle? style,
    bool? allowDragging,
    bool? allowEditing,
    int? zIndex,
    String? text,
    Offset? position,
    double? dataX,
    double? dataY,
    String? seriesId,
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
      dataX: dataX ?? this.dataX,
      dataY: dataY ?? this.dataY,
      seriesId: seriesId ?? this.seriesId,
      anchor: anchor ?? this.anchor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TextAnnotation &&
        other.id == id &&
        other.label == label &&
        other.style == style &&
        other.allowDragging == allowDragging &&
        other.allowEditing == allowEditing &&
        other.zIndex == zIndex &&
        other.text == text &&
        other.position == position &&
        other.dataX == dataX &&
        other.dataY == dataY &&
        other.seriesId == seriesId &&
        other.anchor == anchor &&
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor;
  }

  @override
  int get hashCode => Object.hash(
        id,
        label,
        style,
        allowDragging,
        allowEditing,
        zIndex,
        text,
        position,
        dataX,
        dataY,
        seriesId,
        anchor,
        backgroundColor,
        borderColor,
      );
}
