import 'package:equatable/equatable.dart';

import 'enums.dart';

/// Configuration for a chart annotation (V2 Schema).
///
/// Annotations provide visual overlays on charts for highlighting data,
/// marking thresholds, or adding contextual information.
///
/// ## V2 Schema: System-Generated IDs
///
/// In the V2 schema, annotation IDs are **system-generated and read-only**.
/// When creating annotations via [CreateChartTool] or [ModifyChartTool],
/// the system automatically assigns unique UUIDs. These IDs enable:
///
/// - **Targeted updates**: Modify specific annotations by ID
/// - **Targeted removal**: Remove specific annotations by ID
/// - **State tracking**: Query current annotations via [GetChartTool]
///
/// ## Annotation Types
///
/// The [type] field determines which optional fields are relevant:
///
/// | Type | Required Fields | Optional Fields |
/// |------|-----------------|------------------|
/// | [AnnotationType.referenceLine] | [orientation], [value] | [label], [color], [lineWidth], [dashPattern] |
/// | [AnnotationType.zone] | [minValue], [maxValue] | [label], [color], [opacity] |
/// | [AnnotationType.textLabel] | [text], [position] | [fontSize], [color] |
/// | [AnnotationType.marker] | [seriesId] | [dataPointIndex], [x], [y] |
///
/// ## Validation Rules (V030-V044)
///
/// The [SchemaValidator] enforces annotation requirements:
/// - **V030**: Error if [seriesId] references non-existent series
/// - **V031-V034**: Errors for missing seriesId in context-specific scenarios
/// - **V040-V044**: Errors for missing required type-specific fields
///
/// ## Example: Reference Line
///
/// ```dart
/// final threshold = AnnotationConfig(
///   type: AnnotationType.referenceLine,
///   orientation: Orientation.horizontal,
///   value: 100.0,
///   label: 'Max Threshold',
///   color: '#FF0000',
///   seriesId: 'power', // Required in perSeries mode
/// );
/// ```
///
/// ## Example: Zone Annotation
///
/// ```dart
/// final zone = AnnotationConfig(
///   type: AnnotationType.zone,
///   minValue: 80.0,
///   maxValue: 120.0,
///   color: '#00FF00',
///   opacity: 0.3,
///   label: 'Optimal Range',
/// );
/// ```
///
/// ## JSON Serialization
///
/// ```dart
/// final json = annotation.toJson();
/// // ID is included if present: { "id": "uuid", "type": "referenceLine", ... }
/// final restored = AnnotationConfig.fromJson(json);
/// ```
///
/// See also:
/// - [GetChartTool] to discover annotation IDs
/// - [ModifyChartTool] to update/remove annotations by ID
/// - [SchemaValidator] for validation rules V030-V044
class AnnotationConfig with EquatableMixin {
  /// Unique identifier for this annotation (V2 Schema).
  ///
  /// This field is **system-generated and read-only**. When annotations are
  /// created via [CreateChartTool] or [ModifyChartTool], the system assigns
  /// a unique UUID automatically.
  ///
  /// ## Usage
  ///
  /// - **Read IDs**: Use [GetChartTool] to discover annotation IDs
  /// - **Update by ID**: Use `modify_chart` with `update.annotations[].id`
  /// - **Remove by ID**: Use `modify_chart` with `remove.annotations[]`
  ///
  /// ## Validation
  ///
  /// - **V022**: Warning if agent supplies ID when adding annotations (ignored)
  /// - **V004**: Error if duplicate annotation IDs exist
  ///
  /// IDs are never null after chart creation; this nullable type supports
  /// deserialization and construction before system assignment.
  final String? id;

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

  /// Index of the data point within the series for point-style annotations.
  ///
  /// Used by marker/point annotations to reference a specific data point.
  /// Must be a valid index within the series data array (0 to length-1).
  final int? dataPointIndex;

  /// Creates an [AnnotationConfig] with the given parameters.
  ///
  /// [type] is required. Other parameters are optional and depend on
  /// the annotation type being configured.
  const AnnotationConfig({
    this.id,
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
    this.dataPointIndex,
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
      id: json['id'] as String?,
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
      dataPointIndex: json['dataPointIndex'] as int?,
    );
  }

  /// Converts this [AnnotationConfig] to a JSON map.
  ///
  /// Includes all properties. Enum values are serialized as their names.
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
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
      if (dataPointIndex != null) 'dataPointIndex': dataPointIndex,
    };
  }

  /// Creates a copy of this [AnnotationConfig] with optionally overridden values.
  ///
  /// If a parameter is not provided, the original value is preserved.
  AnnotationConfig copyWith({
    String? id,
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
    int? dataPointIndex,
  }) {
    return AnnotationConfig(
      id: id ?? this.id,
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
      dataPointIndex: dataPointIndex ?? this.dataPointIndex,
    );
  }

  @override
  List<Object?> get props => [
        id,
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
        dataPointIndex,
      ];

  @override
  String toString() => 'AnnotationConfig(type: $type, label: $label)';
}
