import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Configuration for a chart annotation.
///
/// Annotations provide additional context or highlights on charts.
/// The [type] field determines which optional fields are relevant:
/// - [AnnotationType.referenceLine]: uses [orientation], [value]
/// - [AnnotationType.zone]: uses [minValue], [maxValue]
/// - [AnnotationType.textLabel]: uses [text], [position]
/// - [AnnotationType.marker]: uses [x], [y]
///
/// Uses [EquatableMixin] for value equality comparisons.
///
/// ## Example
///
/// ```dart
/// // Reference line annotation
/// final refLine = AnnotationConfig(
///   type: AnnotationType.referenceLine,
///   orientation: Orientation.horizontal,
///   value: 100.0,
///   label: 'Threshold',
///   color: '#FF0000',
/// );
///
/// // Zone annotation
/// final zone = AnnotationConfig(
///   type: AnnotationType.zone,
///   minValue: 80.0,
///   maxValue: 120.0,
///   color: '#00FF00',
///   opacity: 0.3,
/// );
/// ```
///
/// ## JSON Serialization
///
/// ```dart
/// final json = annotation.toJson();
/// final restored = AnnotationConfig.fromJson(json);
/// ```
class AnnotationConfig with EquatableMixin {
  /// The type of annotation.
  final AnnotationType type;

  /// Orientation for reference lines (horizontal or vertical).
  final Orientation? orientation;

  /// Value position for reference lines.
  final double? value;

  /// Minimum value for zone annotations.
  final double? minValue;

  /// Maximum value for zone annotations.
  final double? maxValue;

  /// X coordinate for marker annotations.
  final double? x;

  /// Y coordinate for marker annotations.
  final double? y;

  /// Position for text labels and markers.
  final AnnotationPosition? position;

  /// Text content for text label annotations.
  final String? text;

  /// Label displayed next to the annotation.
  final String? label;

  /// Color for the annotation (hex string or named color).
  final String? color;

  /// Opacity of the annotation (0.0 to 1.0).
  final double? opacity;

  /// Font size for text label annotations.
  final double? fontSize;

  /// Line width for reference line annotations.
  final double? lineWidth;

  /// Dash pattern for reference line annotations.
  ///
  /// Example: [5, 3] creates a dashed line with 5px dashes and 3px gaps.
  final List<double>? dashPattern;

  /// ID of the series this annotation is associated with.
  final String? seriesId;

  /// Creates an [AnnotationConfig] with the given parameters.
  ///
  /// [type] is required. Other parameters are optional and depend on
  /// the annotation type being configured.
  const AnnotationConfig({
    required this.type,
    this.orientation,
    this.value,
    this.minValue,
    this.maxValue,
    this.x,
    this.y,
    this.position,
    this.text,
    this.label,
    this.color,
    this.opacity,
    this.fontSize,
    this.lineWidth,
    this.dashPattern,
    this.seriesId,
  });

  /// Creates an [AnnotationConfig] from a JSON map.
  ///
  /// Parses all fields including enum values.
  /// Sanitizes seriesId by trimming whitespace and trailing punctuation.
  /// Handles LLM malformed JSON where value is embedded in seriesId string.
  factory AnnotationConfig.fromJson(Map<String, dynamic> json) {
    // Get initial values
    double? value = (json['value'] as num?)?.toDouble();
    String? seriesId = json['seriesId'] as String?;

    // Sanitize seriesId - LLMs sometimes include trailing commas or whitespace
    if (seriesId != null) {
      seriesId = seriesId.trim();
      // Remove trailing punctuation that LLMs sometimes include
      while (seriesId!.isNotEmpty &&
          (seriesId.endsWith(',') ||
              seriesId.endsWith('.') ||
              seriesId.endsWith(';'))) {
        seriesId = seriesId.substring(0, seriesId.length - 1).trim();
      }
      if (seriesId.isEmpty) seriesId = null;

      // Check for malformed JSON where value is embedded in seriesId
      // Pattern: "usage','value':1.4," or "usage","value":1.4
      if (seriesId != null && seriesId.contains('value')) {
        // Try to extract value from malformed string like: "usage','value':1.4,"
        final valueMatch = RegExp(r'''['":]?value['":]?\s*[:=]?\s*([0-9.]+)''')
            .firstMatch(seriesId);
        if (valueMatch != null && value == null) {
          final extractedValue = double.tryParse(valueMatch.group(1)!);
          if (extractedValue != null) {
            value = extractedValue;
          }
        }
      }

      // Reject obviously malformed seriesId (contains JSON syntax)
      if (seriesId != null &&
          (seriesId.contains('"') ||
              seriesId.contains("'") ||
              seriesId.contains(':') ||
              seriesId.contains('{') ||
              seriesId.contains('}'))) {
        // This is malformed JSON - extract just the first word as a best-effort
        final match = RegExp(r'^[a-zA-Z0-9_-]+').firstMatch(seriesId);
        seriesId = match?.group(0);
      }
    }

    return AnnotationConfig(
      type: AnnotationType.values.byName(json['type'] as String),
      orientation: json['orientation'] != null
          ? Orientation.values.byName(json['orientation'] as String)
          : null,
      value: value,
      minValue: (json['minValue'] as num?)?.toDouble(),
      maxValue: (json['maxValue'] as num?)?.toDouble(),
      x: (json['x'] as num?)?.toDouble(),
      y: (json['y'] as num?)?.toDouble(),
      position: json['position'] != null
          ? AnnotationPosition.values.byName(json['position'] as String)
          : null,
      text: json['text'] as String?,
      label: json['label'] as String?,
      color: json['color'] as String?,
      opacity: (json['opacity'] as num?)?.toDouble(),
      fontSize: (json['fontSize'] as num?)?.toDouble(),
      lineWidth: (json['lineWidth'] as num?)?.toDouble(),
      dashPattern: (json['dashPattern'] as List<dynamic>?)?.cast<double>(),
      seriesId: seriesId,
    );
  }

  /// Converts this [AnnotationConfig] to a JSON map.
  ///
  /// Includes all properties. Enum values are serialized as their names.
  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      if (orientation != null) 'orientation': orientation!.name,
      if (value != null) 'value': value,
      if (minValue != null) 'minValue': minValue,
      if (maxValue != null) 'maxValue': maxValue,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (position != null) 'position': position!.name,
      if (text != null) 'text': text,
      if (label != null) 'label': label,
      if (color != null) 'color': color,
      if (opacity != null) 'opacity': opacity,
      if (fontSize != null) 'fontSize': fontSize,
      if (lineWidth != null) 'lineWidth': lineWidth,
      if (dashPattern != null) 'dashPattern': dashPattern,
      if (seriesId != null) 'seriesId': seriesId,
    };
  }

  /// Creates a copy of this [AnnotationConfig] with optionally overridden values.
  ///
  /// If a parameter is not provided, the original value is preserved.
  AnnotationConfig copyWith({
    AnnotationType? type,
    Orientation? orientation,
    double? value,
    double? minValue,
    double? maxValue,
    double? x,
    double? y,
    AnnotationPosition? position,
    String? text,
    String? label,
    String? color,
    double? opacity,
    double? fontSize,
    double? lineWidth,
    List<double>? dashPattern,
    String? seriesId,
  }) {
    return AnnotationConfig(
      type: type ?? this.type,
      orientation: orientation ?? this.orientation,
      value: value ?? this.value,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      x: x ?? this.x,
      y: y ?? this.y,
      position: position ?? this.position,
      text: text ?? this.text,
      label: label ?? this.label,
      color: color ?? this.color,
      opacity: opacity ?? this.opacity,
      fontSize: fontSize ?? this.fontSize,
      lineWidth: lineWidth ?? this.lineWidth,
      dashPattern: dashPattern ?? this.dashPattern,
      seriesId: seriesId ?? this.seriesId,
    );
  }

  @override
  List<Object?> get props => [
        type,
        orientation,
        value,
        minValue,
        maxValue,
        x,
        y,
        position,
        text,
        label,
        color,
        opacity,
        fontSize,
        lineWidth,
        dashPattern,
        seriesId,
      ];

  @override
  String toString() => 'AnnotationConfig(type: $type, label: $label)';
}
