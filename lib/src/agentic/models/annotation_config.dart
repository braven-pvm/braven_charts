/// Annotation type enumeration
enum AnnotationType {
  referenceLine,
  zone,
  textLabel,
  marker,
}

/// Orientation enumeration for lines and zones
enum AnnotationOrientation {
  horizontal,
  vertical,
}

/// Lightweight annotation model for AI-driven annotation creation.
///
/// This is a simplified representation that the AI can understand and generate,
/// which can later be converted to the full annotation models for rendering.
class AnnotationConfig {
  /// Type of annotation
  final String type;

  /// Orientation for lines and zones (horizontal or vertical)
  final String? orientation;

  /// Value for reference lines
  final double? value;

  /// Minimum value for zones
  final double? minValue;

  /// Maximum value for zones
  final double? maxValue;

  /// X coordinate for text labels and markers (data coordinates)
  final double? x;

  /// Y coordinate for text labels and markers (data coordinates)
  final double? y;

  /// Semantic position for text labels (topLeft, topCenter, topRight,
  /// centerLeft, center, centerRight, bottomLeft, bottomCenter, bottomRight)
  final String? position;

  /// Text content for text labels
  final String? text;

  /// Label for the annotation
  final String? label;

  /// Color for the annotation
  final String? color;

  /// Opacity/transparency (0.0 to 1.0)
  final double? opacity;

  /// Font size for text labels
  final double? fontSize;

  /// Line width for reference lines
  final double? lineWidth;

  /// Dash pattern for lines
  final List<double>? dashPattern;

  /// Series ID for threshold annotations in perSeries normalization mode.
  ///
  /// When normalizationMode is perSeries, each series has its own Y-axis range.
  /// This field specifies which series's Y-range the threshold value should use.
  /// Required for horizontal threshold lines in perSeries mode.
  final String? seriesId;

  /// Creates a new AnnotationConfig instance
  AnnotationConfig({
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

  /// Creates an AnnotationConfig from JSON
  factory AnnotationConfig.fromJson(Map<String, dynamic> json) {
    return AnnotationConfig(
      type: json['type'] as String,
      orientation: json['orientation'] as String?,
      value: json['value'] as double?,
      minValue: json['minValue'] as double?,
      maxValue: json['maxValue'] as double?,
      x: json['x'] as double?,
      y: json['y'] as double?,
      position: json['position'] as String?,
      text: json['text'] as String?,
      label: json['label'] as String?,
      color: json['color'] as String?,
      opacity: json['opacity'] as double?,
      fontSize: json['fontSize'] as double?,
      lineWidth: json['lineWidth'] as double?,
      dashPattern: json['dashPattern'] != null ? (json['dashPattern'] as List).cast<double>() : null,
      seriesId: json['seriesId'] as String?,
    );
  }

  /// Converts AnnotationConfig to JSON
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (orientation != null) 'orientation': orientation,
      if (value != null) 'value': value,
      if (minValue != null) 'minValue': minValue,
      if (maxValue != null) 'maxValue': maxValue,
      if (x != null) 'x': x,
      if (y != null) 'y': y,
      if (position != null) 'position': position,
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

  /// Creates a copy with modified values
  AnnotationConfig copyWith({
    String? type,
    String? orientation,
    double? value,
    double? minValue,
    double? maxValue,
    double? x,
    double? y,
    String? position,
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
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnnotationConfig &&
        other.type == type &&
        other.orientation == orientation &&
        other.value == value &&
        other.minValue == minValue &&
        other.maxValue == maxValue &&
        other.x == x &&
        other.y == y &&
        other.position == position &&
        other.text == text &&
        other.label == label &&
        other.color == color &&
        other.opacity == opacity &&
        other.fontSize == fontSize &&
        other.lineWidth == lineWidth;
  }

  @override
  int get hashCode {
    return Object.hash(
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
    );
  }
}
