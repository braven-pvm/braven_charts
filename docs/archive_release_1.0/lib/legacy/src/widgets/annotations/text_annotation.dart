import 'package:flutter/material.dart';

import '../enums/annotation_anchor.dart';
import 'annotation_style.dart';
import 'chart_annotation.dart';

/// A text annotation that displays text at a specific screen position.
///
/// **Screen-Coordinate Positioning:**
/// TextAnnotation uses [position] (Offset) for static screen placement.
/// - Text stays fixed at screen coordinates regardless of zoom/pan
/// - Example: Chart title overlay, watermark, static labels
///
/// **For Data-Anchored Text:**
/// Use [PointAnnotation] instead - it supports labels anchored to data points
/// that move with zoom/pan operations.
///
/// **Example:**
/// ```dart
/// // Screen-coordinate mode (static position)
/// TextAnnotation(
///   id: 'title',
///   text: 'Sales Data',
///   position: Offset(100, 50),
///   anchor: AnnotationAnchor.topLeft,
/// )
/// ```
class TextAnnotation extends ChartAnnotation {
  /// Creates a text annotation at a screen position.
  ///
  /// **Required parameters:**
  /// - [text]: The content to display
  /// - [position]: Screen coordinate where text is anchored
  ///
  /// **Optional styling:**
  /// - [anchor]: How text aligns relative to position (default: topLeft)
  /// - [backgroundColor]: Optional background fill color
  /// - [borderColor]: Optional border color
  ///
  /// **Validation:**
  /// - [position] must have non-negative coordinates
  TextAnnotation({
    super.id,
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
  }) : assert(
         position.dx >= 0 && position.dy >= 0,
         'Position cannot have negative coordinates',
       );

  /// The text content to display.
  final String text;

  /// The screen position where this annotation is anchored.
  ///
  /// Text is placed at this fixed screen location regardless of zoom/pan.
  /// Must have non-negative dx and dy values.
  final Offset position;

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
    anchor,
    backgroundColor,
    borderColor,
  );
}
