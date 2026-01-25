/// Axis type enumeration
enum AxisType {
  numeric,
  time,
  category,
}

/// Axis position enumeration
enum AxisPosition {
  left,
  right,
}

/// Configuration for the X-axis of a chart.
///
/// Validates that min < max when both are set,
/// paddingPercent >= 0, and tickCount >= 2.
class XAxisConfig {
  /// Axis label
  final String? label;

  /// Unit of measurement
  final String? unit;

  /// Type of axis (numeric, time, or category)
  final AxisType type;

  /// Minimum value for the axis
  final double? min;

  /// Maximum value for the axis
  final double? max;

  /// Whether to automatically calculate the range
  final bool autoRange;

  /// Padding percentage added to the range
  final double paddingPercent;

  /// Number of tick marks on the axis
  final int? tickCount;

  /// Format string for tick labels
  final String? tickFormat;

  /// Rotation angle for tick labels in degrees
  final double tickRotation;

  /// Whether to show tick marks
  final bool showTicks;

  /// Whether to show the axis line
  final bool showAxisLine;

  /// Whether to show grid lines
  final bool showGridLines;

  /// Color for grid lines
  final String? gridColor;

  /// Dash pattern for grid lines
  final List<double>? gridDash;

  /// Creates a new XAxisConfig instance
  XAxisConfig({
    this.label,
    this.unit,
    AxisType? type,
    this.min,
    this.max,
    bool? autoRange,
    double? paddingPercent,
    this.tickCount,
    this.tickFormat,
    double? tickRotation,
    bool? showTicks,
    bool? showAxisLine,
    bool? showGridLines,
    this.gridColor,
    this.gridDash,
  })  : type = type ?? AxisType.numeric,
        autoRange = autoRange ?? true,
        paddingPercent = paddingPercent ?? 0.0,
        tickRotation = tickRotation ?? 0.0,
        showTicks = showTicks ?? true,
        showAxisLine = showAxisLine ?? true,
        showGridLines = showGridLines ?? true,
        assert(
          min == null || max == null || min < max,
          'min must be less than max when both are set',
        ),
        assert(
          (paddingPercent ?? 0.0) >= 0,
          'paddingPercent must be non-negative',
        ),
        assert(
          tickCount == null || tickCount >= 2,
          'tickCount must be at least 2',
        );

  /// Creates an XAxisConfig from JSON
  factory XAxisConfig.fromJson(Map<String, dynamic> json) {
    return XAxisConfig(
      label: json['label'] as String?,
      unit: json['unit'] as String?,
      type: json['type'] != null
          ? AxisType.values.firstWhere((e) => e.name == json['type'])
          : AxisType.numeric,
      min: json['min'] as double?,
      max: json['max'] as double?,
      autoRange: json['autoRange'] as bool? ?? true,
      paddingPercent: json['paddingPercent'] as double? ?? 0.0,
      tickCount: json['tickCount'] as int?,
      tickFormat: json['tickFormat'] as String?,
      tickRotation: json['tickRotation'] as double? ?? 0.0,
      showTicks: json['showTicks'] as bool? ?? true,
      showAxisLine: json['showAxisLine'] as bool? ?? true,
      showGridLines: json['showGridLines'] as bool? ?? true,
      gridColor: json['gridColor'] as String?,
      gridDash: json['gridDash'] != null
          ? (json['gridDash'] as List).cast<double>()
          : null,
    );
  }

  /// Converts XAxisConfig to JSON
  Map<String, dynamic> toJson() {
    return {
      if (label != null) 'label': label,
      if (unit != null) 'unit': unit,
      'type': type.name,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      'autoRange': autoRange,
      'paddingPercent': paddingPercent,
      if (tickCount != null) 'tickCount': tickCount,
      if (tickFormat != null) 'tickFormat': tickFormat,
      'tickRotation': tickRotation,
      'showTicks': showTicks,
      'showAxisLine': showAxisLine,
      'showGridLines': showGridLines,
      if (gridColor != null) 'gridColor': gridColor,
      if (gridDash != null) 'gridDash': gridDash,
    };
  }

  /// Creates a copy with modified values
  XAxisConfig copyWith({
    String? label,
    String? unit,
    AxisType? type,
    double? min,
    double? max,
    bool? autoRange,
    double? paddingPercent,
    int? tickCount,
    String? tickFormat,
    double? tickRotation,
    bool? showTicks,
    bool? showAxisLine,
    bool? showGridLines,
    String? gridColor,
    List<double>? gridDash,
  }) {
    return XAxisConfig(
      label: label ?? this.label,
      unit: unit ?? this.unit,
      type: type ?? this.type,
      min: min ?? this.min,
      max: max ?? this.max,
      autoRange: autoRange ?? this.autoRange,
      paddingPercent: paddingPercent ?? this.paddingPercent,
      tickCount: tickCount ?? this.tickCount,
      tickFormat: tickFormat ?? this.tickFormat,
      tickRotation: tickRotation ?? this.tickRotation,
      showTicks: showTicks ?? this.showTicks,
      showAxisLine: showAxisLine ?? this.showAxisLine,
      showGridLines: showGridLines ?? this.showGridLines,
      gridColor: gridColor ?? this.gridColor,
      gridDash: gridDash ?? this.gridDash,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is XAxisConfig &&
        other.label == label &&
        other.type == type &&
        other.min == min &&
        other.max == max &&
        other.autoRange == autoRange;
  }

  @override
  int get hashCode {
    return Object.hash(
      label,
      type,
      min,
      max,
      autoRange,
    );
  }
}

/// Configuration for the Y-axis of a chart.
///
/// Validates that min < max when both are set,
/// paddingPercent >= 0, and tickCount >= 2.
class YAxisConfig {
  /// Optional ID for multi-axis reference
  final String? id;

  /// Axis label
  final String? label;

  /// Unit of measurement
  final String? unit;

  /// Position of the axis (left or right)
  final AxisPosition position;

  /// Minimum value for the axis
  final double? min;

  /// Maximum value for the axis
  final double? max;

  /// Whether to automatically calculate the range
  final bool autoRange;

  /// Whether to include zero in the range
  final bool includeZero;

  /// Padding percentage added to the range
  final double paddingPercent;

  /// Number of tick marks on the axis
  final int? tickCount;

  /// Format string for tick labels
  final String? tickFormat;

  /// Whether to show tick marks
  final bool showTicks;

  /// Whether to show the axis line
  final bool showAxisLine;

  /// Whether to show grid lines
  final bool showGridLines;

  /// Color for grid lines
  final String? gridColor;

  /// Color for the axis
  final String? color;

  /// Creates a new YAxisConfig instance
  YAxisConfig({
    this.id,
    this.label,
    this.unit,
    AxisPosition? position,
    this.min,
    this.max,
    bool? autoRange,
    bool? includeZero,
    double? paddingPercent,
    this.tickCount,
    this.tickFormat,
    bool? showTicks,
    bool? showAxisLine,
    bool? showGridLines,
    this.gridColor,
    this.color,
  })  : position = position ?? AxisPosition.left,
        autoRange = autoRange ?? true,
        includeZero = includeZero ?? false,
        paddingPercent = paddingPercent ?? 0.0,
        showTicks = showTicks ?? true,
        showAxisLine = showAxisLine ?? true,
        showGridLines = showGridLines ?? true,
        assert(
          min == null || max == null || min < max,
          'min must be less than max when both are set',
        ),
        assert(
          (paddingPercent ?? 0.0) >= 0,
          'paddingPercent must be non-negative',
        ),
        assert(
          tickCount == null || tickCount >= 2,
          'tickCount must be at least 2',
        );

  /// Creates a YAxisConfig from JSON
  factory YAxisConfig.fromJson(Map<String, dynamic> json) {
    return YAxisConfig(
      id: json['id'] as String?,
      label: json['label'] as String?,
      unit: json['unit'] as String?,
      position: json['position'] != null
          ? AxisPosition.values.firstWhere((e) => e.name == json['position'])
          : AxisPosition.left,
      min: json['min'] as double?,
      max: json['max'] as double?,
      autoRange: json['autoRange'] as bool? ?? true,
      includeZero: json['includeZero'] as bool? ?? false,
      paddingPercent: json['paddingPercent'] as double? ?? 0.0,
      tickCount: json['tickCount'] as int?,
      tickFormat: json['tickFormat'] as String?,
      showTicks: json['showTicks'] as bool? ?? true,
      showAxisLine: json['showAxisLine'] as bool? ?? true,
      showGridLines: json['showGridLines'] as bool? ?? true,
      gridColor: json['gridColor'] as String?,
      color: json['color'] as String?,
    );
  }

  /// Converts YAxisConfig to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (label != null) 'label': label,
      if (unit != null) 'unit': unit,
      'position': position.name,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      'autoRange': autoRange,
      'includeZero': includeZero,
      'paddingPercent': paddingPercent,
      if (tickCount != null) 'tickCount': tickCount,
      if (tickFormat != null) 'tickFormat': tickFormat,
      'showTicks': showTicks,
      'showAxisLine': showAxisLine,
      'showGridLines': showGridLines,
      if (gridColor != null) 'gridColor': gridColor,
      if (color != null) 'color': color,
    };
  }

  /// Creates a copy with modified values
  YAxisConfig copyWith({
    String? id,
    String? label,
    String? unit,
    AxisPosition? position,
    double? min,
    double? max,
    bool? autoRange,
    bool? includeZero,
    double? paddingPercent,
    int? tickCount,
    String? tickFormat,
    bool? showTicks,
    bool? showAxisLine,
    bool? showGridLines,
    String? gridColor,
    String? color,
  }) {
    return YAxisConfig(
      id: id ?? this.id,
      label: label ?? this.label,
      unit: unit ?? this.unit,
      position: position ?? this.position,
      min: min ?? this.min,
      max: max ?? this.max,
      autoRange: autoRange ?? this.autoRange,
      includeZero: includeZero ?? this.includeZero,
      paddingPercent: paddingPercent ?? this.paddingPercent,
      tickCount: tickCount ?? this.tickCount,
      tickFormat: tickFormat ?? this.tickFormat,
      showTicks: showTicks ?? this.showTicks,
      showAxisLine: showAxisLine ?? this.showAxisLine,
      showGridLines: showGridLines ?? this.showGridLines,
      gridColor: gridColor ?? this.gridColor,
      color: color ?? this.color,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is YAxisConfig &&
        other.id == id &&
        other.label == label &&
        other.position == position &&
        other.min == min &&
        other.max == max;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      label,
      position,
      min,
      max,
    );
  }
}
