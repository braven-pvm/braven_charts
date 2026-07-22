// Copyright (c) 2025 braven_charts. All rights reserved.
// Chart Annotation Base Classes for BravenChartPlus

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:parchment/parchment.dart';

import '../meta/chart_surface.dart';
import 'annotation_style.dart';
import 'chart_series.dart';
import 'enums.dart';
import 'legend_style.dart';
import '../theming/components/series_theme.dart' show SeriesMarkerShape;

/// Counter for auto-generating annotation IDs.
int _annotationIdCounter = 0;

/// Base sealed class for all chart annotations using Dart 3.0+ pattern matching.
///
/// All annotation types (Point, Range, Text, Threshold, Trend, Chord, Pin,
/// Legend) extend this class.
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
///     ChordAnnotation() => 'Chord',
///     PinAnnotation() => 'Pin',
///     LegendAnnotation() => 'Legend',
///   };
/// }
/// ```
sealed class ChartAnnotation {
  /// Creates a chart annotation.
  ///
  /// If [id] is not provided, a unique ID will be auto-generated.
  /// The [id] field is mutable to allow tool handlers to assign
  /// system-generated IDs after construction.
  ChartAnnotation({
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
  ///
  /// This field is mutable to allow the agentic tool layer to assign
  /// system-generated IDs after the annotation is created.
  String id;

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
  topCenter,
  topRight,
  centerLeft,
  center,
  centerRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
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
///
/// [id] is force-excluded from the fluent surface: an annotation id is a
/// JOIN KEY — selection state, hit-testing and artifact documents bind to
/// it — so a verb that rewrites it mid-chain silently detaches the
/// annotation from everything that references it. Construct the annotation
/// with the id it should carry.
@ChartSurface(excluded: ['id'])
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
  }) : assert(dataPointIndex >= 0, 'Data point index must be non-negative'),
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

  /// Serializes this annotation to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'PointAnnotation',
      if (label != null) 'label': label,
      'seriesId': seriesId,
      'dataPointIndex': dataPointIndex,
      'offset': {'dx': offset.dx, 'dy': offset.dy},
      'markerShape': markerShape.name,
      'markerSize': markerSize,
      'markerColor': markerColor.toARGB32(),
      'labelMargin': labelMargin,
      'allowDragging': allowDragging,
      'allowEditing': allowEditing,
      'zIndex': zIndex,
    };
  }

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
/// The BOUNDS are construction-only: there is no generated verb for
/// [startX], [endX], [startY] or [endY], individually or together. A range is
/// an X band, a Y band, or a 2-D box — the constructor's
/// `startX != null || startY != null` is an OR — while `copyWith` merges each
/// bound with `??` and exposes no clear flag, so nothing can put a bound
/// BACK to null. The combined `withBounds(startX, endX, startY, endY)` this
/// class used to generate therefore took all four non-nullable and silently
/// converted an X-only band into a box; an `withXRange` pair could never
/// convert a box back into a band. Construct the range you want.
///
/// [id] is force-excluded from the fluent surface: an annotation id is a
/// JOIN KEY — selection state, hit-testing and artifact documents bind to
/// it — so a verb that rewrites it mid-chain silently detaches the
/// annotation from everything that references it. Construct the annotation
/// with the id it should carry.
@ChartSurface(excluded: ['id', 'startX', 'endX', 'startY', 'endY'])
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
    this.seriesId,
    this.fillColor,
    this.borderColor,
    this.labelPosition = AnnotationLabelPosition.topLeft,
    this.labelMargin = 8.0,
  }) : assert(
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
       assert(
         snapTolerance >= 0 && snapTolerance <= 1,
         'snapTolerance must be between 0 and 1',
       ),
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

  /// Optional series ID for multi-axis charts with perSeries normalization.
  ///
  /// When specified, the range Y values are normalized using the Y-range
  /// of the referenced series. If null, the first available series bounds
  /// are used.
  ///
  /// Example: If you have "power" and "heartrate" series with different
  /// Y-ranges, and want a range at 150-200W on the power series scale:
  /// ```dart
  /// RangeAnnotation(
  ///   startY: 150,
  ///   endY: 200,
  ///   seriesId: 'power',  // Use power series Y-range for normalization
  ///   fillColor: Colors.red.withOpacity(0.2),
  /// )
  /// ```
  final String? seriesId;

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

  /// Serializes this annotation to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'RangeAnnotation',
      if (label != null) 'label': label,
      if (startX != null) 'startX': startX,
      if (endX != null) 'endX': endX,
      if (startY != null) 'startY': startY,
      if (endY != null) 'endY': endY,
      'snapTolerance': snapTolerance,
      if (seriesId != null) 'seriesId': seriesId,
      if (fillColor != null) 'fillColor': fillColor!.toARGB32(),
      if (borderColor != null) 'borderColor': borderColor!.toARGB32(),
      'labelPosition': labelPosition.name,
      'labelMargin': labelMargin,
      'allowDragging': allowDragging,
      'allowEditing': allowEditing,
      'zIndex': zIndex,
      'snapToValue': snapToValue,
      'snapIncrement': snapIncrement,
    };
  }

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
    String? seriesId,
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
      seriesId: seriesId ?? this.seriesId,
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
///
/// [id] is force-excluded from the fluent surface: an annotation id is a
/// JOIN KEY — selection state, hit-testing and artifact documents bind to
/// it — so a verb that rewrites it mid-chain silently detaches the
/// annotation from everything that references it. Construct the annotation
/// with the id it should carry.
///
/// The RICH half of this class has no fluent surface. `surface_gen` models
/// the public plain-text constructor — [richTextDelta] is not one of its
/// parameters, so no `withRichTextDelta` exists — while [copyWith] rebuilds
/// through the private `_internal` constructor, which accepts both. The
/// consequence is stated on the generated `withText` verb: on a rich
/// annotation [isRichText] stays `true` and every renderer keeps reading the
/// Delta, so the new plain text is never drawn. Build rich content with
/// [TextAnnotation.rich].
@ChartSurface(
  excluded: ['id'],
  paramNotes: {
    'text':
        'No effect on a RICH annotation (one built with '
        'TextAnnotation.rich): richTextDelta keeps winning at render time, '
        'so the new text is stored but never drawn. The rich half is '
        'construction-only.',
  },
)
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
      backgroundColor: json['backgroundColor'] != null
          ? Color(json['backgroundColor'] as int)
          : null,
      borderColor: json['borderColor'] != null
          ? Color(json['borderColor'] as int)
          : null,
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
  }) : richTextDelta = null,
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
  }) : text = null,
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
    if (attrs['s'] == true ||
        attrs['strikethrough'] == true ||
        attrs['strike'] == true) {
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
      'heading', 'block', 'indent', 'align', 'alignment', 'direction',
      'checked', // block
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
      if (backgroundColor != null)
        'backgroundColor': backgroundColor!.toARGB32(),
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
///
/// [id] is force-excluded from the fluent surface: an annotation id is a
/// JOIN KEY — selection state, hit-testing and artifact documents bind to
/// it — so a verb that rewrites it mid-chain silently detaches the
/// annotation from everything that references it. Construct the annotation
/// with the id it should carry.
@ChartSurface(excluded: ['id'])
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
    this.seriesId,
    this.lineColor = Colors.black,
    this.lineWidth = 1.0,
    this.dashPattern,
    this.labelPosition = AnnotationLabelPosition.topLeft,
    this.labelMargin = 8.0,
    this.elevation = 0.0,
  }) : assert(value.isFinite, 'Threshold value must be finite'),
       assert(labelMargin >= 0, 'Label margin must be non-negative'),
       assert(elevation >= 0, 'Elevation must be non-negative'),
       super(id: id ?? ChartAnnotation.generateId());

  /// Which axis this threshold line is perpendicular to.
  final AnnotationAxis axis;

  /// The axis value where the threshold line is drawn.
  final double value;

  /// Optional series ID for multi-axis charts with perSeries normalization.
  ///
  /// When specified, the threshold value is normalized using the Y-range
  /// of the referenced series. If null, the first available series bounds
  /// are used.
  ///
  /// Example: If you have "power" and "heartrate" series with different
  /// Y-ranges, and want a threshold at 200W on the power series scale:
  /// ```dart
  /// ThresholdAnnotation(
  ///   axis: AnnotationAxis.y,
  ///   value: 200,  // 200 watts
  ///   seriesId: 'power',  // Use power series Y-range for normalization
  ///   lineColor: Colors.red,
  /// )
  /// ```
  final String? seriesId;

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

  /// Serializes this annotation to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'ThresholdAnnotation',
      if (label != null) 'label': label,
      'axis': axis.name,
      'value': value,
      if (seriesId != null) 'seriesId': seriesId,
      'lineColor': lineColor.toARGB32(),
      'lineWidth': lineWidth,
      if (dashPattern != null) 'dashPattern': dashPattern,
      'labelPosition': labelPosition.name,
      'labelMargin': labelMargin,
      'elevation': elevation,
      'allowDragging': allowDragging,
      'allowEditing': allowEditing,
      'zIndex': zIndex,
    };
  }

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
    String? seriesId,
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
      seriesId: seriesId ?? this.seriesId,
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
///
/// [id] is force-excluded from the fluent surface: an annotation id is a
/// JOIN KEY — selection state, hit-testing and artifact documents bind to
/// it — so a verb that rewrites it mid-chain silently detaches the
/// annotation from everything that references it. Construct the annotation
/// with the id it should carry.
@ChartSurface(excluded: ['id'])
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
  }) : assert(x.isFinite, 'X coordinate must be finite'),
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

  /// Serializes this annotation to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'PinAnnotation',
      if (label != null) 'label': label,
      'x': x,
      'y': y,
      'markerShape': markerShape.name,
      'markerSize': markerSize,
      'markerColor': markerColor.toARGB32(),
      'labelMargin': labelMargin,
      'allowDragging': allowDragging,
      'allowEditing': allowEditing,
      'zIndex': zIndex,
    };
  }

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

  /// Locally estimated scatterplot smoothing with robust reweighting.
  loess,
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
///
/// [id] is force-excluded from the fluent surface: an annotation id is a
/// JOIN KEY — selection state, hit-testing and artifact documents bind to
/// it — so a verb that rewrites it mid-chain silently detaches the
/// annotation from everything that references it. Construct the annotation
/// with the id it should carry.
@ChartSurface(
  excluded: ['id'],
  combinedSetters: [
    // `trendType != movingAverage || (windowSize != null && windowSize > 0)`
    // — switching to a moving average without a window throws, so the pair
    // moves together. `windowSize` is ignored by the other trend types.
    CombinedSetter('withTrend', ['trendType', 'windowSize']),
  ],
)
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
    this.loessSpan = 0.5,
    this.loessRobustnessIterations = 2,
    this.loessSampleCount = 100,
    this.showEquation = false,
    this.showRSquared = false,
    this.showSampleCount = false,
    this.showPearsonCorrelation = false,
    this.showSpearmanCorrelation = false,
    this.showConfidenceBand = false,
    this.showPredictionBand = false,
    this.confidenceLevel = 0.95,
    this.confidenceBandColor,
    this.predictionBandColor,
    this.confidenceBandOpacity = 0.20,
    this.predictionBandOpacity = 0.10,
    this.lineColor = Colors.blue,
    this.lineWidth = 2.0,
    this.dashPattern,
    this.elevation = 0.0,
  }) : assert(
         trendType != TrendType.movingAverage ||
             (windowSize != null && windowSize > 0),
         'windowSize must be positive when trendType is movingAverage',
       ),
       assert(degree > 0, 'degree must be positive'),
       assert(
         loessSpan.isFinite && loessSpan > 0 && loessSpan <= 1,
         'loessSpan must be finite and in the range (0, 1]',
       ),
       assert(
         loessRobustnessIterations >= 0 && loessRobustnessIterations <= 10,
         'loessRobustnessIterations must be between 0 and 10',
       ),
       assert(
         loessSampleCount >= 2 && loessSampleCount <= 500,
         'loessSampleCount must be between 2 and 500',
       ),
       assert(
         confidenceLevel.isFinite && confidenceLevel > 0 && confidenceLevel < 1,
         'confidenceLevel must be finite and in the range (0, 1)',
       ),
       assert(
         confidenceBandOpacity.isFinite &&
             confidenceBandOpacity >= 0 &&
             confidenceBandOpacity <= 1,
         'confidenceBandOpacity must be in the range [0, 1]',
       ),
       assert(
         predictionBandOpacity.isFinite &&
             predictionBandOpacity >= 0 &&
             predictionBandOpacity <= 1,
         'predictionBandOpacity must be in the range [0, 1]',
       ),
       assert(elevation >= 0, 'Elevation must be non-negative'),
       super(id: id ?? ChartAnnotation.generateId());

  /// The ID of the series to calculate the trend for.
  final String seriesId;

  /// The type of trend calculation to perform.
  final TrendType trendType;

  /// Window size for moving average trends (required for movingAverage).
  final int? windowSize;

  /// Polynomial degree for polynomial regression (default 2).
  final int degree;

  /// Fraction of finite source points used by each LOESS local fit.
  final double loessSpan;

  /// Number of residual-based robustness passes applied to LOESS.
  final int loessRobustnessIterations;

  /// Number of fitted points emitted across the finite X domain for LOESS.
  final int loessSampleCount;

  /// Whether to show a human-readable equation for parametric fits.
  ///
  /// Linear and polynomial trends expose equations. Non-parametric and moving
  /// trends omit the equation even when this option is enabled.
  final bool showEquation;

  /// Whether to show the coefficient of determination for the rendered fit.
  final bool showRSquared;

  /// Whether to show the number of finite source observations.
  final bool showSampleCount;

  /// Whether to show the Pearson product-moment correlation.
  final bool showPearsonCorrelation;

  /// Whether to show Spearman rank correlation with average ranks for ties.
  final bool showSpearmanCorrelation;

  /// Whether to draw a two-sided confidence interval for the fitted mean.
  ///
  /// Confidence bands are currently calculated for linear ordinary
  /// least-squares trends only.
  final bool showConfidenceBand;

  /// Whether to draw a two-sided prediction interval for one future value.
  ///
  /// Prediction bands are currently calculated for linear ordinary
  /// least-squares trends only.
  final bool showPredictionBand;

  /// Two-sided interval coverage, expressed as a fraction such as `0.95`.
  final double confidenceLevel;

  /// Optional confidence-band color. Defaults to [lineColor] when omitted.
  final Color? confidenceBandColor;

  /// Optional prediction-band color. Defaults to [lineColor] when omitted.
  final Color? predictionBandColor;

  /// Confidence-band fill opacity.
  final double confidenceBandOpacity;

  /// Prediction-band fill opacity.
  final double predictionBandOpacity;

  /// Whether this annotation requests any visible statistical diagnostics.
  bool get showsStatistics =>
      showEquation ||
      showRSquared ||
      showSampleCount ||
      showPearsonCorrelation ||
      showSpearmanCorrelation;

  /// The color of the trend line.
  final Color lineColor;

  /// The width of the trend line in logical pixels.
  final double lineWidth;

  /// Optional dash pattern for the trend line.
  final List<double>? dashPattern;

  /// The elevation/glow spread for the trend line in the default state.
  ///
  /// When greater than 0, a glow effect is drawn behind the line using the
  /// same color as [lineColor]. The value controls the blur radius of the glow.
  /// This only affects the default state — when selected, the selection glow
  /// is always more prominent than the elevation glow to ensure visual
  /// distinction.
  /// Defaults to 0.0 (no glow).
  final double elevation;

  /// Serializes this annotation to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'TrendAnnotation',
      if (label != null) 'label': label,
      'seriesId': seriesId,
      'trendType': trendType.name,
      if (windowSize != null) 'windowSize': windowSize,
      'degree': degree,
      'loessSpan': loessSpan,
      'loessRobustnessIterations': loessRobustnessIterations,
      'loessSampleCount': loessSampleCount,
      'showEquation': showEquation,
      'showRSquared': showRSquared,
      'showSampleCount': showSampleCount,
      'showPearsonCorrelation': showPearsonCorrelation,
      'showSpearmanCorrelation': showSpearmanCorrelation,
      'showConfidenceBand': showConfidenceBand,
      'showPredictionBand': showPredictionBand,
      'confidenceLevel': confidenceLevel,
      if (confidenceBandColor != null)
        'confidenceBandColor': confidenceBandColor!.toARGB32(),
      if (predictionBandColor != null)
        'predictionBandColor': predictionBandColor!.toARGB32(),
      'confidenceBandOpacity': confidenceBandOpacity,
      'predictionBandOpacity': predictionBandOpacity,
      'lineColor': lineColor.toARGB32(),
      'lineWidth': lineWidth,
      if (dashPattern != null) 'dashPattern': dashPattern,
      'elevation': elevation,
      'allowDragging': allowDragging,
      'allowEditing': allowEditing,
      'zIndex': zIndex,
    };
  }

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
    double? loessSpan,
    int? loessRobustnessIterations,
    int? loessSampleCount,
    bool? showEquation,
    bool? showRSquared,
    bool? showSampleCount,
    bool? showPearsonCorrelation,
    bool? showSpearmanCorrelation,
    bool? showConfidenceBand,
    bool? showPredictionBand,
    double? confidenceLevel,
    Color? confidenceBandColor,
    Color? predictionBandColor,
    double? confidenceBandOpacity,
    double? predictionBandOpacity,
    Color? lineColor,
    double? lineWidth,
    List<double>? dashPattern,
    double? elevation,
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
      loessSpan: loessSpan ?? this.loessSpan,
      loessRobustnessIterations:
          loessRobustnessIterations ?? this.loessRobustnessIterations,
      loessSampleCount: loessSampleCount ?? this.loessSampleCount,
      showEquation: showEquation ?? this.showEquation,
      showRSquared: showRSquared ?? this.showRSquared,
      showSampleCount: showSampleCount ?? this.showSampleCount,
      showPearsonCorrelation:
          showPearsonCorrelation ?? this.showPearsonCorrelation,
      showSpearmanCorrelation:
          showSpearmanCorrelation ?? this.showSpearmanCorrelation,
      showConfidenceBand: showConfidenceBand ?? this.showConfidenceBand,
      showPredictionBand: showPredictionBand ?? this.showPredictionBand,
      confidenceLevel: confidenceLevel ?? this.confidenceLevel,
      confidenceBandColor: confidenceBandColor ?? this.confidenceBandColor,
      predictionBandColor: predictionBandColor ?? this.predictionBandColor,
      confidenceBandOpacity:
          confidenceBandOpacity ?? this.confidenceBandOpacity,
      predictionBandOpacity:
          predictionBandOpacity ?? this.predictionBandOpacity,
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      dashPattern: dashPattern ?? this.dashPattern,
      elevation: elevation ?? this.elevation,
    );
  }
}

// =============================================================================
// Error Bar Annotation
// =============================================================================

/// Per-point symmetric or asymmetric uncertainty used by [ErrorBarAnnotation].
class ErrorBarDatum {
  const ErrorBarDatum({
    required this.pointIndex,
    this.xNegative = 0,
    this.xPositive = 0,
    this.yNegative = 0,
    this.yPositive = 0,
  }) : assert(pointIndex >= 0),
       assert(xNegative >= 0 && xPositive >= 0),
       assert(yNegative >= 0 && yPositive >= 0);

  /// Creates symmetric uncertainty around one source point.
  const ErrorBarDatum.symmetric({
    required this.pointIndex,
    double x = 0,
    double y = 0,
  }) : xNegative = x,
       xPositive = x,
       yNegative = y,
       yPositive = y,
       assert(pointIndex >= 0),
       assert(x >= 0 && y >= 0);

  final int pointIndex;
  final double xNegative;
  final double xPositive;
  final double yNegative;
  final double yPositive;

  bool get hasX => xNegative > 0 || xPositive > 0;
  bool get hasY => yNegative > 0 || yPositive > 0;
}

/// Draws X and Y uncertainty around selected points in a chart series.
///
/// Error magnitudes are expressed in data units. Each side can be configured
/// independently, enabling both symmetric and asymmetric error bars without
/// changing the source observations.
///
/// [id] is force-excluded from the fluent surface: an annotation id is a
/// JOIN KEY — selection state, hit-testing and artifact documents bind to
/// it — so a verb that rewrites it mid-chain silently detaches the
/// annotation from everything that references it. Construct the annotation
/// with the id it should carry.
@ChartSurface(excluded: ['id'])
class ErrorBarAnnotation extends ChartAnnotation {
  ErrorBarAnnotation({
    String? id,
    super.label,
    super.style,
    super.allowEditing,
    super.zIndex,
    this.seriesId = '',
    required List<ErrorBarDatum> values,
    this.lineColor = Colors.black54,
    this.lineWidth = 1.5,
    this.capSize = 6,
  }) : values = List.unmodifiable(values),
       assert(lineWidth > 0),
       assert(capSize >= 0),
       super(id: id ?? ChartAnnotation.generateId());

  final String seriesId;
  final List<ErrorBarDatum> values;
  final Color lineColor;
  final double lineWidth;
  final double capSize;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'ErrorBarAnnotation',
    if (label != null) 'label': label,
    'seriesId': seriesId,
    'values': [
      for (final value in values)
        {
          'pointIndex': value.pointIndex,
          'xNegative': value.xNegative,
          'xPositive': value.xPositive,
          'yNegative': value.yNegative,
          'yPositive': value.yPositive,
        },
    ],
    'lineColor': lineColor.toARGB32(),
    'lineWidth': lineWidth,
    'capSize': capSize,
    'allowEditing': allowEditing,
    'zIndex': zIndex,
  };

  ErrorBarAnnotation copyWith({
    String? id,
    String? label,
    AnnotationStyle? style,
    bool? allowEditing,
    int? zIndex,
    String? seriesId,
    List<ErrorBarDatum>? values,
    Color? lineColor,
    double? lineWidth,
    double? capSize,
  }) => ErrorBarAnnotation(
    id: id ?? this.id,
    label: label ?? this.label,
    style: style ?? this.style,
    allowEditing: allowEditing ?? this.allowEditing,
    zIndex: zIndex ?? this.zIndex,
    seriesId: seriesId ?? this.seriesId,
    values: values ?? this.values,
    lineColor: lineColor ?? this.lineColor,
    lineWidth: lineWidth ?? this.lineWidth,
    capSize: capSize ?? this.capSize,
  );
}

// =============================================================================
// Chord Annotation
// =============================================================================

/// A chord annotation that draws a straight line between two data points
/// on a chart series, with an optional perpendicular drop-line to a third
/// data point.
///
/// A chord (or secant line) connects two specific points on a curve,
/// commonly used in analysis to visualize rate of change between two
/// measurements (e.g., lactate threshold detection).
///
/// The optional [perpendicularIndex] draws a line from the chord to a data
/// point, projected perpendicularly onto the chord. This visualizes the
/// deflection distance — the maximum vertical deviation between the chord
/// and the curve — which is the classic method for detecting the first
/// lactate threshold (LT1).
///
/// Both the chord line and perpendicular line support independent styling
/// (color, width, dash pattern, elevation/glow). The perpendicular styling
/// defaults to the chord's styling when not explicitly set.
///
/// Example:
/// ```dart
/// ChordAnnotation(
///   id: 'chord1',
///   seriesId: 'lactate',
///   startIndex: 1,
///   endIndex: 14,
///   lineColor: Colors.grey,
///   dashPattern: [6, 4],
///   perpendicularIndex: 8,
///   perpendicularLabel: 'D',
/// )
/// ```
///
/// [id] is force-excluded from the fluent surface: an annotation id is a
/// JOIN KEY — selection state, hit-testing and artifact documents bind to
/// it — so a verb that rewrites it mid-chain silently detaches the
/// annotation from everything that references it. Construct the annotation
/// with the id it should carry.
@ChartSurface(
  excluded: ['id'],
  combinedSetters: [
    // `startIndex != endIndex` — a chord needs two distinct data points, so
    // the endpoints only move as a pair.
    CombinedSetter('withEndpoints', ['startIndex', 'endIndex']),
  ],
)
class ChordAnnotation extends ChartAnnotation {
  /// Creates a chord annotation.
  ChordAnnotation({
    String? id,
    super.label,
    super.style,
    super.allowDragging,
    super.allowEditing,
    super.zIndex,
    required this.seriesId,
    required this.startIndex,
    required this.endIndex,
    this.lineColor = Colors.blue,
    this.lineWidth = 2.0,
    this.dashPattern,
    this.elevation = 0.0,
    this.perpendicularIndex,
    this.perpendicularLabel,
    this.perpendicularLabelOffset = Offset.zero,
    this.perpendicularLabelStyle,
    this.perpendicularLineColor,
    this.perpendicularLineWidth,
    this.perpendicularDashPattern,
    this.perpendicularElevation,
  }) : assert(startIndex >= 0, 'startIndex must be non-negative'),
       assert(endIndex >= 0, 'endIndex must be non-negative'),
       assert(startIndex != endIndex, 'startIndex and endIndex must differ'),
       assert(elevation >= 0, 'Elevation must be non-negative'),
       assert(
         perpendicularIndex == null || perpendicularIndex >= 0,
         'perpendicularIndex must be non-negative',
       ),
       super(id: id ?? ChartAnnotation.generateId());

  /// The ID of the series containing the data points.
  final String seriesId;

  /// Index of the first data point in the series.
  final int startIndex;

  /// Index of the second data point in the series.
  final int endIndex;

  /// The color of the chord line.
  final Color lineColor;

  /// The width of the chord line in logical pixels.
  final double lineWidth;

  /// Optional dash pattern for the chord line.
  final List<double>? dashPattern;

  /// The elevation/glow spread for the chord line in the default state.
  ///
  /// When greater than 0, a glow effect is drawn behind the line using the
  /// same color as [lineColor]. The value controls the blur radius of the glow.
  /// Defaults to 0.0 (no glow).
  final double elevation;

  /// Index of a data point on the same series to draw a perpendicular line to.
  ///
  /// When set, a line is drawn from this data point to its perpendicular
  /// projection on the chord line. Used to visualize deflection distance
  /// (e.g., lactate threshold detection).
  final int? perpendicularIndex;

  /// Label text displayed near the perpendicular line.
  final String? perpendicularLabel;

  /// Offset to nudge the perpendicular label from its default centered position.
  ///
  /// The label is centered on the perpendicular line midpoint by default.
  /// Use this to adjust its position (e.g., `Offset(10, -5)` moves it
  /// 10px right and 5px up).
  final Offset perpendicularLabelOffset;

  /// Style for the perpendicular label. If null, uses the annotation's [style].
  final AnnotationStyle? perpendicularLabelStyle;

  /// Color of the perpendicular line. If null, uses [lineColor].
  final Color? perpendicularLineColor;

  /// Width of the perpendicular line. If null, uses [lineWidth].
  final double? perpendicularLineWidth;

  /// Dash pattern for the perpendicular line. If null, uses [dashPattern].
  final List<double>? perpendicularDashPattern;

  /// Elevation/glow for the perpendicular line. If null, uses [elevation].
  final double? perpendicularElevation;

  /// Effective perpendicular color (falls back to chord line color).
  Color get effectivePerpendicularColor => perpendicularLineColor ?? lineColor;

  /// Effective perpendicular width (falls back to chord line width).
  double get effectivePerpendicularWidth => perpendicularLineWidth ?? lineWidth;

  /// Effective perpendicular dash pattern.
  ///
  /// Unlike other perpendicular style getters, this does NOT fall back to
  /// [dashPattern] because `null` means "solid line" and is indistinguishable
  /// from "not set". Use [perpendicularDashPattern] directly.
  List<double>? get effectivePerpendicularDash => perpendicularDashPattern;

  /// Effective perpendicular elevation (falls back to chord elevation).
  double get effectivePerpendicularElevation =>
      perpendicularElevation ?? elevation;

  /// Effective perpendicular label style (falls back to annotation style).
  AnnotationStyle get effectivePerpendicularLabelStyle =>
      perpendicularLabelStyle ?? style;

  /// Serializes this annotation to JSON.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': 'ChordAnnotation',
      if (label != null) 'label': label,
      'seriesId': seriesId,
      'startIndex': startIndex,
      'endIndex': endIndex,
      'lineColor': lineColor.toARGB32(),
      'lineWidth': lineWidth,
      if (dashPattern != null) 'dashPattern': dashPattern,
      'elevation': elevation,
      if (perpendicularIndex != null) 'perpendicularIndex': perpendicularIndex,
      if (perpendicularLabel != null) 'perpendicularLabel': perpendicularLabel,
      if (perpendicularLabelOffset != Offset.zero)
        'perpendicularLabelOffset': [
          perpendicularLabelOffset.dx,
          perpendicularLabelOffset.dy,
        ],
      if (perpendicularLineColor != null)
        'perpendicularLineColor': perpendicularLineColor!.toARGB32(),
      if (perpendicularLineWidth != null)
        'perpendicularLineWidth': perpendicularLineWidth,
      if (perpendicularDashPattern != null)
        'perpendicularDashPattern': perpendicularDashPattern,
      if (perpendicularElevation != null)
        'perpendicularElevation': perpendicularElevation,
      'allowDragging': allowDragging,
      'allowEditing': allowEditing,
      'zIndex': zIndex,
    };
  }

  /// Creates a copy with modified properties.
  ChordAnnotation copyWith({
    String? id,
    String? label,
    AnnotationStyle? style,
    bool? allowDragging,
    bool? allowEditing,
    int? zIndex,
    String? seriesId,
    int? startIndex,
    int? endIndex,
    Color? lineColor,
    double? lineWidth,
    List<double>? dashPattern,
    double? elevation,
    int? perpendicularIndex,
    String? perpendicularLabel,
    Offset? perpendicularLabelOffset,
    AnnotationStyle? perpendicularLabelStyle,
    Color? perpendicularLineColor,
    double? perpendicularLineWidth,
    List<double>? perpendicularDashPattern,
    double? perpendicularElevation,
  }) {
    return ChordAnnotation(
      id: id ?? this.id,
      label: label ?? this.label,
      style: style ?? this.style,
      allowDragging: allowDragging ?? this.allowDragging,
      allowEditing: allowEditing ?? this.allowEditing,
      zIndex: zIndex ?? this.zIndex,
      seriesId: seriesId ?? this.seriesId,
      startIndex: startIndex ?? this.startIndex,
      endIndex: endIndex ?? this.endIndex,
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      dashPattern: dashPattern ?? this.dashPattern,
      elevation: elevation ?? this.elevation,
      perpendicularIndex: perpendicularIndex ?? this.perpendicularIndex,
      perpendicularLabel: perpendicularLabel ?? this.perpendicularLabel,
      perpendicularLabelOffset:
          perpendicularLabelOffset ?? this.perpendicularLabelOffset,
      perpendicularLabelStyle:
          perpendicularLabelStyle ?? this.perpendicularLabelStyle,
      perpendicularLineColor:
          perpendicularLineColor ?? this.perpendicularLineColor,
      perpendicularLineWidth:
          perpendicularLineWidth ?? this.perpendicularLineWidth,
      perpendicularDashPattern:
          perpendicularDashPattern ?? this.perpendicularDashPattern,
      perpendicularElevation:
          perpendicularElevation ?? this.perpendicularElevation,
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
@immutable
class LegendSizeSample {
  const LegendSizeSample({required this.radius, required this.label})
    : assert(radius >= 0 && radius < double.infinity);

  /// Marker radius in logical pixels before legend-space normalization.
  final double radius;

  /// Display-ready quantitative value represented by [radius].
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendSizeSample &&
          other.radius == radius &&
          other.label == label;

  @override
  int get hashCode => Object.hash(radius, label);
}

/// A quantitative marker-size key rendered by a native [LegendAnnotation].
///
/// This is deliberately a presentation descriptor. Chart families derive its
/// samples from their source encoding, while the legend renderer remains
/// independent of any particular series family.
@immutable
class LegendSizeScale {
  const LegendSizeScale({
    required this.label,
    required this.samples,
    required this.color,
  });

  /// Human-readable name of the metric represented by marker area.
  final String label;

  /// Ordered representative values and their source marker radii.
  final List<LegendSizeSample> samples;

  /// Fill color used for the representative markers.
  final Color color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendSizeScale &&
          other.label == label &&
          other.color == color &&
          listEquals(other.samples, samples);

  @override
  int get hashCode => Object.hash(label, color, Object.hashAll(samples));
}

/// Quantitative color key rendering strategy.
enum LegendColorScaleType {
  /// A smoothly interpolated color ramp.
  continuous,

  /// Adjacent discrete color bands with one label per band.
  piecewise,
}

/// A quantitative color key rendered by a native [LegendAnnotation].
@immutable
class LegendColorScale {
  const LegendColorScale({
    required this.label,
    required this.colors,
    required this.minimumLabel,
    required this.maximumLabel,
    this.midpointLabel,
    this.type = LegendColorScaleType.continuous,
    this.segmentLabels = const [],
  });

  /// Human-readable name of the metric represented by marker color.
  final String label;

  /// Ordered ramp colors from the low-domain edge to the high-domain edge.
  final List<Color> colors;

  /// Display-ready label for the low-domain edge.
  final String minimumLabel;

  /// Optional display-ready midpoint label.
  final String? midpointLabel;

  /// Display-ready label for the high-domain edge.
  final String maximumLabel;

  /// Whether the key is rendered as a gradient or discrete segments.
  final LegendColorScaleType type;

  /// Display-ready label for each piecewise segment.
  final List<String> segmentLabels;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendColorScale &&
          other.label == label &&
          listEquals(other.colors, colors) &&
          other.minimumLabel == minimumLabel &&
          other.midpointLabel == midpointLabel &&
          other.maximumLabel == maximumLabel &&
          other.type == type &&
          listEquals(other.segmentLabels, segmentLabels);

  @override
  int get hashCode => Object.hash(
    label,
    Object.hashAll(colors),
    minimumLabel,
    midpointLabel,
    maximumLabel,
    type,
    Object.hashAll(segmentLabels),
  );
}

/// A quantitative opacity key rendered by a native [LegendAnnotation].
///
/// Opacity keys remain a distinct semantic payload even though the native
/// renderer can share its compact ramp layout with quantitative color keys.
@immutable
class LegendOpacityScale {
  const LegendOpacityScale({
    required this.label,
    required this.color,
    required this.minimumOpacity,
    required this.maximumOpacity,
    required this.minimumLabel,
    required this.maximumLabel,
    this.midpointLabel,
  });

  /// Human-readable name of the metric represented by marker opacity.
  final String label;

  /// Base marker color used to demonstrate the opacity progression.
  final Color color;

  /// Opacity used at the low-domain edge.
  final double minimumOpacity;

  /// Opacity used at the high-domain edge.
  final double maximumOpacity;

  /// Display-ready label for the low-domain edge.
  final String minimumLabel;

  /// Optional display-ready midpoint label.
  final String? midpointLabel;

  /// Display-ready label for the high-domain edge.
  final String maximumLabel;

  /// Presentation adapter used by the native quantitative ramp painter.
  LegendColorScale get asColorScale => LegendColorScale(
    label: label,
    colors: [
      color.withValues(alpha: minimumOpacity),
      color.withValues(alpha: (minimumOpacity + maximumOpacity) / 2),
      color.withValues(alpha: maximumOpacity),
    ],
    minimumLabel: minimumLabel,
    midpointLabel: midpointLabel,
    maximumLabel: maximumLabel,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendOpacityScale &&
          other.label == label &&
          other.color == color &&
          other.minimumOpacity == minimumOpacity &&
          other.maximumOpacity == maximumOpacity &&
          other.minimumLabel == minimumLabel &&
          other.midpointLabel == midpointLabel &&
          other.maximumLabel == maximumLabel;

  @override
  int get hashCode => Object.hash(
    label,
    color,
    minimumOpacity,
    maximumOpacity,
    minimumLabel,
    midpointLabel,
    maximumLabel,
  );
}

/// One item in a categorical color/shape key.
@immutable
class LegendCategoryItem {
  const LegendCategoryItem({required this.label, this.color, this.shape})
    : assert(shape != SeriesMarkerShape.none);

  final String label;
  final Color? color;
  final SeriesMarkerShape? shape;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendCategoryItem &&
          other.label == label &&
          other.color == color &&
          other.shape == shape;

  @override
  int get hashCode => Object.hash(label, color, shape);
}

/// A categorical color/shape key rendered by a native [LegendAnnotation].
@immutable
class LegendCategoryScale {
  const LegendCategoryScale({required this.label, required this.items});

  final String label;
  final List<LegendCategoryItem> items;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendCategoryScale &&
          other.label == label &&
          listEquals(other.items, items);

  @override
  int get hashCode => Object.hash(label, Object.hashAll(items));
}

///
/// [id] is force-excluded from the fluent surface: an annotation id is a
/// JOIN KEY — selection state, hit-testing and artifact documents bind to
/// it — so a verb that rewrites it mid-chain silently detaches the
/// annotation from everything that references it. Construct the annotation
/// with the id it should carry.
@ChartSurface(
  // The four scales are MUTUALLY EXCLUSIVE (`assert(... .length <= 1)`): a
  // quantitative or categorical key lives on its own LegendAnnotation. A
  // combined setter cannot express that — it takes its members non-nullable,
  // which is precisely the state the assert rejects — and an individual
  // `withColorScale` on a legend that already carries a size scale throws.
  // Construct the keyed legend directly instead.
  excluded: ['id', 'sizeScale', 'colorScale', 'opacityScale', 'categoryScale'],
)
class LegendAnnotation extends ChartAnnotation {
  /// Creates a legend annotation.
  ///
  /// [series] is the list of chart series to display in the legend. A
  /// quantitative size key instead supplies [sizeScale] and uses a separate
  /// annotation so it can be positioned independently.
  /// [legendStyle] controls the visual appearance and position.
  LegendAnnotation({
    String? id,
    super.label,
    super.zIndex,
    this.series = const [],
    this.trendAnnotations = const [],
    this.errorBarAnnotations = const [],
    this.sizeScale,
    this.colorScale,
    this.opacityScale,
    this.categoryScale,
    this.legendStyle = const LegendStyle(),
    this.hiddenSeriesIds = const {},
    this.onSeriesToggle,
    Offset? customPosition,
  }) : assert(
         [
               sizeScale,
               colorScale,
               opacityScale,
               categoryScale,
             ].whereType<Object>().length <=
             1,
         'Legend scales use separate LegendAnnotation instances.',
       ),
       _customPosition = customPosition,
       super(
         id: id ?? ChartAnnotation.generateId(),
         allowDragging: legendStyle.allowDragging,
         allowEditing: false, // Legends don't support inline editing
       );

  /// The list of series to display in the legend.
  final List<ChartSeries> series;

  /// Trend annotations to display below the series items in the legend.
  ///
  /// Only trends with a non-empty [TrendAnnotation.label] are shown.
  final List<TrendAnnotation> trendAnnotations;

  /// Error-bar annotations described by this legend.
  ///
  /// The native legend renders their X/Y capped-line glyphs in a dedicated
  /// uncertainty section alongside any confidence or prediction bands
  /// requested by [trendAnnotations].
  final List<ErrorBarAnnotation> errorBarAnnotations;

  /// Optional quantitative marker-size key.
  ///
  /// Size scales intentionally occupy their own legend annotation instead of
  /// being mixed with categorical series toggles.
  final LegendSizeScale? sizeScale;

  /// Optional quantitative marker-color key.
  ///
  /// Color scales intentionally occupy their own legend annotation so they
  /// can be positioned independently from categorical toggles and size keys.
  final LegendColorScale? colorScale;

  /// Optional quantitative marker-opacity key.
  ///
  /// Opacity scales intentionally occupy their own legend annotation so they
  /// can be positioned independently from categorical, size, and color keys.
  final LegendOpacityScale? opacityScale;

  /// Optional categorical marker color/shape key.
  ///
  /// Category keys use the same annotation surface as every other native
  /// legend and remain independently positionable.
  final LegendCategoryScale? categoryScale;

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
    List<TrendAnnotation>? trendAnnotations,
    List<ErrorBarAnnotation>? errorBarAnnotations,
    LegendSizeScale? sizeScale,
    bool clearSizeScale = false,
    LegendColorScale? colorScale,
    bool clearColorScale = false,
    LegendOpacityScale? opacityScale,
    bool clearOpacityScale = false,
    LegendCategoryScale? categoryScale,
    bool clearCategoryScale = false,
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
      trendAnnotations: trendAnnotations ?? this.trendAnnotations,
      errorBarAnnotations: errorBarAnnotations ?? this.errorBarAnnotations,
      sizeScale: clearSizeScale ? null : (sizeScale ?? this.sizeScale),
      colorScale: clearColorScale ? null : (colorScale ?? this.colorScale),
      opacityScale: clearOpacityScale
          ? null
          : (opacityScale ?? this.opacityScale),
      categoryScale: clearCategoryScale
          ? null
          : (categoryScale ?? this.categoryScale),
      legendStyle: legendStyle ?? this.legendStyle,
      hiddenSeriesIds: hiddenSeriesIds ?? this.hiddenSeriesIds,
      onSeriesToggle: onSeriesToggle ?? this.onSeriesToggle,
      customPosition: clearCustomPosition
          ? null
          : (customPosition ?? _customPosition),
    );
  }
}
