// Copyright (c) 2025 braven_charts. All rights reserved.
// Chart Annotation Base Classes for BravenChartPlus

import 'package:flutter/material.dart';
import 'package:parchment/parchment.dart';

import 'annotation_style.dart';
import 'chart_series.dart';
import 'enums.dart';
import 'legend_style.dart';

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
///
/// Rich text example:
/// ```dart
/// TextAnnotation.rich(
///   id: 'formatted',
///   richTextDelta: [
///     {'insert': 'Bold ', 'attributes': {'bold': true}},
///     {'insert': 'and normal text\n'},
///   ],
///   position: Offset(100, 50),
/// )
/// ```
class TextAnnotation extends ChartAnnotation {
  /// Creates a TextAnnotation from JSON.
  factory TextAnnotation.fromJson(Map<String, dynamic> json) {
    final posJson = json['position'] as Map<String, dynamic>;
    final position = Offset(
      (posJson['dx'] as num).toDouble(),
      (posJson['dy'] as num).toDouble(),
    );

    final anchorName = json['anchor'] as String?;
    final anchor = anchorName != null
        ? AnnotationAnchor.values.firstWhere(
            (a) => a.name == anchorName,
            orElse: () => AnnotationAnchor.topLeft,
          )
        : AnnotationAnchor.topLeft;

    return TextAnnotation._internal(
      id: json['id'] as String,
      label: json['label'] as String?,
      text: json['text'] as String?,
      richTextDelta: json['richTextDelta'] as List<dynamic>?,
      position: position,
      anchor: anchor,
      backgroundColor: json['backgroundColor'] != null ? Color(json['backgroundColor'] as int) : null,
      borderColor: json['borderColor'] != null ? Color(json['borderColor'] as int) : null,
      allowDragging: json['allowDragging'] as bool? ?? false,
      allowEditing: json['allowEditing'] as bool? ?? false,
      zIndex: json['zIndex'] as int? ?? 0,
    );
  }

  /// Creates a text annotation with plain text at a screen position.
  TextAnnotation({
    String? id,
    super.label,
    super.style,
    super.allowDragging,
    super.allowEditing,
    super.zIndex,
    required String this.text,
    required this.position,
    this.anchor = AnnotationAnchor.topLeft,
    this.backgroundColor,
    this.borderColor,
  })  : richTextDelta = null,
        assert(
          position.dx >= 0 && position.dy >= 0,
          'Position cannot have negative coordinates',
        ),
        super(id: id ?? ChartAnnotation.generateId());

  /// Creates a text annotation with rich text (Delta format) at a screen position.
  TextAnnotation.rich({
    String? id,
    super.label,
    super.style,
    super.allowDragging,
    super.allowEditing,
    super.zIndex,
    required List<dynamic> this.richTextDelta,
    required this.position,
    this.anchor = AnnotationAnchor.topLeft,
    this.backgroundColor,
    this.borderColor,
  })  : text = null,
        assert(
          position.dx >= 0 && position.dy >= 0,
          'Position cannot have negative coordinates',
        ),
        super(id: id ?? ChartAnnotation.generateId());

  /// Internal constructor for copyWith and fromJson.
  TextAnnotation._internal({
    required super.id,
    super.label,
    super.style,
    super.allowDragging,
    super.allowEditing,
    super.zIndex,
    this.text,
    this.richTextDelta,
    required this.position,
    this.anchor = AnnotationAnchor.topLeft,
    this.backgroundColor,
    this.borderColor,
  }) : assert(
          text != null || richTextDelta != null,
          'Either text or richTextDelta must be provided',
        );

  /// The plain text content to display (null if using rich text).
  final String? text;

  /// The rich text content as Delta JSON (null if using plain text).
  ///
  /// Delta format from Parchment/Fleather:
  /// ```json
  /// [
  ///   {"insert": "Bold ", "attributes": {"bold": true}},
  ///   {"insert": "normal\n"}
  /// ]
  /// ```
  final List<dynamic>? richTextDelta;

  /// The screen position where this annotation is anchored.
  final Offset position;

  /// How the text aligns relative to the position point.
  final AnnotationAnchor anchor;

  /// Optional background color for the text box.
  final Color? backgroundColor;

  /// Optional border color for the text box.
  final Color? borderColor;

  /// Returns true if this annotation uses rich text formatting.
  bool get isRichText => richTextDelta != null;

  /// Returns the plain text content, extracting from rich text if needed.
  String get plainText {
    if (text != null) return text!;
    if (richTextDelta == null) return '';

    // Extract plain text from Delta
    final buffer = StringBuffer();
    for (final op in richTextDelta!) {
      if (op is Map && op['insert'] is String) {
        buffer.write(op['insert']);
      }
    }
    return buffer.toString().trim();
  }

  /// Converts the annotation content to a TextSpan for rendering.
  ///
  /// For plain text, uses the style's textStyle.
  /// For rich text, converts Delta attributes to TextSpan children.
  ///
  /// Handles block-level attributes like headings properly:
  /// In Parchment/Quill Delta format, heading attributes are applied to the
  /// newline character at the end of a line, not the text content itself.
  /// This method looks ahead to find heading attributes and applies them
  /// to all text content in that line.
  TextSpan toTextSpan({TextStyle? baseStyle}) {
    final effectiveBaseStyle = baseStyle ?? style.textStyle;

    if (!isRichText) {
      return TextSpan(text: text, style: effectiveBaseStyle);
    }

    // Convert Delta to TextSpan children with heading support
    final children = <TextSpan>[];
    final ops = richTextDelta!;

    // Process each operation, looking ahead to find heading attributes
    for (int i = 0; i < ops.length; i++) {
      final op = ops[i];
      if (op is! Map) continue;

      final insert = op['insert'];
      if (insert is String) {
        // Get inline attributes for this operation
        final attributes = op['attributes'] as Map<String, dynamic>? ?? {};

        // Check if this is a newline with heading attribute
        if (insert == '\n' && attributes.containsKey('heading')) {
          // This is a line-ending newline with heading style
          // The heading has already been applied to previous text in this line
          // Just add the newline
          children.add(TextSpan(text: insert, style: effectiveBaseStyle));
          continue;
        }

        // For regular text, look ahead to find if this line has a heading
        int? headingLevel;
        if (!insert.contains('\n')) {
          // Look ahead to find the line-ending newline with heading attribute
          headingLevel = _findHeadingForPosition(ops, i);
        }

        // Build style from base + heading + inline attributes
        TextStyle spanStyle = effectiveBaseStyle;

        // Apply heading style first (block level)
        if (headingLevel != null) {
          spanStyle = _applyHeadingStyle(spanStyle, headingLevel);
        }

        // Apply inline attributes on top
        if (attributes.isNotEmpty) {
          spanStyle = _applyDeltaAttributes(spanStyle, attributes);
        }

        children.add(TextSpan(text: insert, style: spanStyle));
      }
      // Skip embeds and other non-string inserts
    }

    // Fallback: if no children were created, show plain text
    if (children.isEmpty) {
      return TextSpan(text: plainText, style: effectiveBaseStyle);
    }

    return TextSpan(children: children, style: effectiveBaseStyle);
  }

  /// Finds the heading level for text at the given operation index.
  /// Looks ahead to find the next newline character that ends this line
  /// and checks if it has a heading attribute.
  int? _findHeadingForPosition(List<dynamic> ops, int startIndex) {
    for (int i = startIndex; i < ops.length; i++) {
      final op = ops[i];
      if (op is! Map) continue;

      final insert = op['insert'];
      if (insert is String && insert.contains('\n')) {
        // Found a newline - check for heading attribute
        final attrs = op['attributes'] as Map<String, dynamic>?;
        if (attrs != null && attrs.containsKey('heading')) {
          final headingValue = attrs['heading'];
          if (headingValue is int) {
            return headingValue;
          }
        }
        // Found newline without heading
        return null;
      }
    }
    // No newline found - no heading
    return null;
  }

  /// Applies heading style based on level (1-6).
  /// Uses font sizes similar to HTML heading levels.
  TextStyle _applyHeadingStyle(TextStyle style, int level) {
    // Base font size from style, default to 14 if not set
    final baseFontSize = style.fontSize ?? 14.0;

    // Heading size multipliers (similar to typical heading ratios)
    final double sizeMultiplier;
    switch (level) {
      case 1:
        sizeMultiplier = 2.0; // H1: 2x base
      case 2:
        sizeMultiplier = 1.7; // H2: 1.7x base
      case 3:
        sizeMultiplier = 1.4; // H3: 1.4x base
      case 4:
        sizeMultiplier = 1.2; // H4: 1.2x base
      case 5:
        sizeMultiplier = 1.1; // H5: 1.1x base
      case 6:
        sizeMultiplier = 1.0; // H6: same as base
      default:
        return style; // Unknown level, no change
    }

    return style.copyWith(
      fontSize: baseFontSize * sizeMultiplier,
      fontWeight: level <= 2 ? FontWeight.bold : FontWeight.w600,
    );
  }

  /// Applies Delta attributes to a TextStyle.
  ///
  /// Supports Fleather's standard attributes:
  /// - 'b' for bold, 'i' for italic, 'u' for underline, 's' for strikethrough
  /// - 'fg' for foreground/text color (Parchment standard)
  /// - 'bg' for background/highlight color (Parchment standard)
  /// Also supports custom attributes for extended styling.
  TextStyle _applyDeltaAttributes(TextStyle style, Map<String, dynamic> attrs) {
    TextStyle result = style;

    // Fleather standard attributes: 'b' for bold, 'i' for italic, etc.
    if (attrs['b'] == true || attrs['bold'] == true) {
      result = result.copyWith(fontWeight: FontWeight.bold);
    }
    if (attrs['i'] == true || attrs['italic'] == true) {
      result = result.copyWith(fontStyle: FontStyle.italic);
    }
    if (attrs['u'] == true || attrs['underline'] == true) {
      result = result.copyWith(decoration: TextDecoration.underline);
    }
    if (attrs['s'] == true || attrs['strikethrough'] == true || attrs['strike'] == true) {
      result = result.copyWith(decoration: TextDecoration.lineThrough);
    }

    // Fleather/Parchment standard color attributes:
    // 'fg' is foreground (text) color - stored as ARGB int
    if (attrs['fg'] != null) {
      final fgValue = attrs['fg'];
      if (fgValue is int) {
        result = result.copyWith(color: Color(fgValue));
      }
    }
    // 'bg' is background (highlight) color - stored as ARGB int
    if (attrs['bg'] != null) {
      final bgValue = attrs['bg'];
      if (bgValue is int) {
        result = result.copyWith(backgroundColor: Color(bgValue));
      }
    }

    // Custom attributes (for potential future use or external data):
    // 'color' as alternative text color attribute
    if (attrs['color'] != null) {
      final colorValue = attrs['color'];
      if (colorValue is int) {
        result = result.copyWith(color: Color(colorValue));
      } else if (colorValue is String) {
        // Parse hex color like "#FF0000" or "0xFFFF0000"
        final parsed = _parseColor(colorValue);
        if (parsed != null) {
          result = result.copyWith(color: parsed);
        }
      }
    }
    // 'background' as alternative background color attribute
    if (attrs['background'] != null) {
      final bgValue = attrs['background'];
      if (bgValue is int) {
        result = result.copyWith(backgroundColor: Color(bgValue));
      } else if (bgValue is String) {
        final parsed = _parseColor(bgValue);
        if (parsed != null) {
          result = result.copyWith(backgroundColor: parsed);
        }
      }
    }
    // 'size' for font size (custom, not in standard Parchment)
    if (attrs['size'] != null) {
      final size = attrs['size'];
      if (size is num) {
        result = result.copyWith(fontSize: size.toDouble());
      }
    }

    return result;
  }

  /// Parses a color string (hex format).
  Color? _parseColor(String colorStr) {
    try {
      String hex = colorStr.replaceFirst('#', '').replaceFirst('0x', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // Add alpha if not present
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return null;
    }
  }

  /// Creates a ParchmentDocument from this annotation's content.
  ///
  /// Useful for initializing a Fleather editor.
  /// Note: Custom attributes like 'color' are filtered out since Parchment
  /// only supports its registered attributes (b, i, u, s, a, heading, block, etc.).
  ParchmentDocument toParchmentDocument() {
    if (isRichText && richTextDelta != null) {
      // Filter out custom attributes that Parchment doesn't understand
      final filteredDelta = _filterDeltaForParchment(richTextDelta!);
      return ParchmentDocument.fromJson(filteredDelta);
    }
    // Create a simple document with plain text
    return ParchmentDocument()..insert(0, text ?? '');
  }

  /// Filters Delta operations to only include Parchment-compatible attributes.
  ///
  /// Parchment supports: b, i, u, s, a (link), fg, bg (colors), heading, block, etc.
  /// Custom attributes like 'color', 'background', 'size' are removed.
  List<dynamic> _filterDeltaForParchment(List<dynamic> delta) {
    const parchmentAttributes = {
      'b', 'i', 'u', 's', 'a', 'c', // inline (c = inline code)
      'fg', 'bg', // colors (foreground/background)
      'heading', 'block', 'indent', 'align', 'alignment', 'direction', 'checked', // block
    };

    return delta.map((op) {
      if (op is! Map) return op;
      final opMap = Map<String, dynamic>.from(op);

      if (opMap['attributes'] != null && opMap['attributes'] is Map) {
        final attrs = Map<String, dynamic>.from(opMap['attributes'] as Map);
        attrs.removeWhere((key, value) => !parchmentAttributes.contains(key));
        if (attrs.isEmpty) {
          opMap.remove('attributes');
        } else {
          opMap['attributes'] = attrs;
        }
      }
      return opMap;
    }).toList();
  }

  /// Creates a TextAnnotation from a ParchmentDocument.
  ///
  /// Useful for saving from a Fleather editor.
  static TextAnnotation fromParchmentDocument({
    required ParchmentDocument document,
    required Offset position,
    String? id,
    String? label,
    AnnotationStyle style = const AnnotationStyle(),
    bool allowDragging = false,
    bool allowEditing = false,
    int zIndex = 0,
    AnnotationAnchor anchor = AnnotationAnchor.topLeft,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    // IMPORTANT: Delta.toJson() returns List<Operation>, not List<Map>!
    // We need to convert each Operation to its JSON map representation.
    final delta = document.toDelta();
    final jsonDelta = delta.toList().map((op) => op.toJson()).toList();
    return TextAnnotation.rich(
      id: id,
      label: label,
      style: style,
      allowDragging: allowDragging,
      allowEditing: allowEditing,
      zIndex: zIndex,
      richTextDelta: jsonDelta,
      position: position,
      anchor: anchor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
    );
  }

  /// Serializes this annotation to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'TextAnnotation',
      if (label != null) 'label': label,
      if (text != null) 'text': text,
      if (richTextDelta != null) 'richTextDelta': richTextDelta,
      'position': {'dx': position.dx, 'dy': position.dy},
      'anchor': anchor.name,
      if (backgroundColor != null) 'backgroundColor': backgroundColor!.toARGB32(),
      if (borderColor != null) 'borderColor': borderColor!.toARGB32(),
      'allowDragging': allowDragging,
      'allowEditing': allowEditing,
      'zIndex': zIndex,
      // Note: AnnotationStyle serialization would need its own toJson method
    };
  }

  /// Creates a copy with modified properties.
  TextAnnotation copyWith({
    String? id,
    String? label,
    AnnotationStyle? style,
    bool? allowDragging,
    bool? allowEditing,
    int? zIndex,
    String? text,
    List<dynamic>? richTextDelta,
    Offset? position,
    AnnotationAnchor? anchor,
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return TextAnnotation._internal(
      id: id ?? this.id,
      label: label ?? this.label,
      style: style ?? this.style,
      allowDragging: allowDragging ?? this.allowDragging,
      allowEditing: allowEditing ?? this.allowEditing,
      zIndex: zIndex ?? this.zIndex,
      text: text ?? this.text,
      richTextDelta: richTextDelta ?? this.richTextDelta,
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

// =============================================================================
// Legend Annotation
// =============================================================================

/// A draggable legend annotation that displays series information.
///
/// Unlike the simple `ChartLegend` widget, `LegendAnnotation` is rendered
/// as part of the chart canvas and can be:
/// - Dragged to any position within the chart
/// - Styled with borders, backgrounds, and custom fonts
/// - Positioned at standard anchor points (topLeft, topRight, etc.)
///
/// Example:
/// ```dart
/// LegendAnnotation(
///   id: 'main-legend',
///   series: mySeriesList,
///   legendStyle: LegendStyle(
///     position: LegendPosition.topRight,
///     backgroundColor: Colors.white.withOpacity(0.9),
///     borderColor: Colors.grey,
///   ),
/// )
/// ```
class LegendAnnotation extends ChartAnnotation {
  /// Creates a legend annotation.
  ///
  /// [series] is the list of chart series to display in the legend.
  /// [legendStyle] controls the visual appearance and position.
  LegendAnnotation({
    String? id,
    super.label,
    super.zIndex,
    required this.series,
    this.legendStyle = const LegendStyle(),
    this.hiddenSeriesIds = const {},
    this.onSeriesToggle,
    Offset? customPosition,
  })  : _customPosition = customPosition,
        super(
          id: id ?? ChartAnnotation.generateId(),
          allowDragging: legendStyle.allowDragging,
          allowEditing: false, // Legends don't support inline editing
        );

  /// The list of series to display in the legend.
  final List<ChartSeries> series;

  /// Visual style configuration for the legend.
  final LegendStyle legendStyle;

  /// Set of series IDs that are currently hidden/toggled off.
  final Set<String> hiddenSeriesIds;

  /// Callback when a series is toggled (clicked) in the legend.
  final ValueChanged<String>? onSeriesToggle;

  /// Custom position when legend has been dragged from its default location.
  final Offset? _customPosition;

  /// Returns the current position (custom if dragged, otherwise calculated from legendStyle.position).
  Offset? get customPosition => _customPosition;

  /// Whether the legend has been manually positioned.
  bool get hasCustomPosition => _customPosition != null;

  /// Creates a copy with modified properties.
  LegendAnnotation copyWith({
    String? id,
    String? label,
    int? zIndex,
    List<ChartSeries>? series,
    LegendStyle? legendStyle,
    Set<String>? hiddenSeriesIds,
    ValueChanged<String>? onSeriesToggle,
    Offset? customPosition,
    bool clearCustomPosition = false,
  }) {
    return LegendAnnotation(
      id: id ?? this.id,
      label: label ?? this.label,
      zIndex: zIndex ?? this.zIndex,
      series: series ?? this.series,
      legendStyle: legendStyle ?? this.legendStyle,
      hiddenSeriesIds: hiddenSeriesIds ?? this.hiddenSeriesIds,
      onSeriesToggle: onSeriesToggle ?? this.onSeriesToggle,
      customPosition: clearCustomPosition ? null : (customPosition ?? _customPosition),
    );
  }
}
