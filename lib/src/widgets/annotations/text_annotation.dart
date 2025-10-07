import 'package:flutter/material.dart';

import '../enums/annotation_anchor.dart';
import 'annotation_style.dart';
import 'chart_annotation.dart';

/// A text annotation that displays text at a specific screen position.
///
/// TextAnnotation allows placing arbitrary text labels anywhere on the chart
/// using screen coordinates (Offset). The [anchor] property controls how the
/// text is positioned relative to the [position] point.
///
/// Example:
/// ```dart
/// TextAnnotation(
///   id: 'label1',
///   text: 'Important Event',
///   position: Offset(100, 50),
///   anchor: AnnotationAnchor.topLeft,
/// )
/// ```
class TextAnnotation extends ChartAnnotation {
  /// Creates a text annotation.
  ///
  /// The [text] is the content to display.
  /// The [position] is the screen coordinate where the text is anchored.
  /// The [anchor] determines how the text aligns relative to [position].
  /// The [backgroundColor] is optional and creates a filled background.
  /// The [borderColor] is optional and draws a border around the text.
  ///
  /// Throws [AssertionError] if [position] has negative coordinates.
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
