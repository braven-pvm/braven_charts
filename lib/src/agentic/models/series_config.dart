import 'axis_config.dart' show YAxisConfig, AxisPosition;

/// Marker style enumeration
enum MarkerStyle {
  none,
  circle,
  square,
  triangle,
  diamond,
}

/// Interpolation type enumeration
enum Interpolation {
  linear,
  bezier,
  stepped,
  monotone,
}

/// Agentic series configuration model
///
/// FR-001: Y-axis configuration is done via nested [yAxisConfig] object,
/// NOT via flat fields or yAxisId references.
/// FR-002: Flat y-axis fields are not supported.
class SeriesConfig {
  final String id;
  final String? name;
  final String? dataColumn;
  final String? dataId;
  final List<dynamic>? data;
  final String? color;
  final double strokeWidth;
  final List<double>? strokeDash;
  final double fillOpacity;
  final MarkerStyle markerStyle;
  final double markerSize;
  final Interpolation interpolation;
  final bool showPoints;
  // FR-002: yAxisId is no longer supported - use yAxisConfig instead
  final String? unit;
  final bool visible;
  final bool legendVisible;

  // Type-discriminated fields for specific chart types
  final double? barWidthPercent;
  final double? barWidthPixels;
  final double? tension;
  final double? markerRadius;
  final double? dataPointMarkerRadius;

  /// FR-001: Nested Y-axis configuration for this series.
  /// Contains position, label, unit, color, min, max, etc.
  /// Replaces flat fields per FR-002.
  final YAxisConfig? yAxisConfig;

  /// Minimum bar width in pixels (for bar charts).
  final double? barMinWidth;

  /// Maximum bar width in pixels (for bar charts).
  final double? barMaxWidth;

  /// Convenience getter for lineWidth (alias for strokeWidth)
  double get lineWidth => strokeWidth;

  /// Convenience getter for dashPattern (alias for strokeDash)
  List<double>? get dashPattern => strokeDash;

  /// Creates a new SeriesConfig instance
  SeriesConfig({
    required this.id,
    this.name,
    this.dataColumn,
    this.dataId,
    this.data,
    this.color,
    double? strokeWidth,
    this.strokeDash,
    double? fillOpacity,
    MarkerStyle? markerStyle,
    double? markerSize,
    Interpolation? interpolation,
    bool? showPoints,
    // FR-002: yAxisId parameter removed - use yAxisConfig instead
    this.unit,
    bool? visible,
    bool? legendVisible,
    this.barWidthPercent,
    this.barWidthPixels,
    this.tension,
    this.markerRadius,
    this.dataPointMarkerRadius,
    this.yAxisConfig,
    this.barMinWidth,
    this.barMaxWidth,
  })  : strokeWidth = strokeWidth ?? 2.0,
        fillOpacity = fillOpacity ?? 0.0,
        markerStyle = markerStyle ?? MarkerStyle.none,
        markerSize = markerSize ?? 4.0,
        interpolation = interpolation ?? Interpolation.linear,
        showPoints = showPoints ?? false,
        visible = visible ?? true,
        legendVisible = legendVisible ?? true {
    if (id.isEmpty) throw ArgumentError('Series id cannot be empty');
    if ((strokeWidth ?? 2.0) < 0) {
      throw ArgumentError('strokeWidth cannot be negative');
    }
    if ((fillOpacity ?? 0.0) < 0 || (fillOpacity ?? 0.0) > 1) {
      throw ArgumentError('fillOpacity must be between 0 and 1');
    }
    if ((markerSize ?? 4.0) < 0) {
      throw ArgumentError('markerSize cannot be negative');
    }
    if (!((dataColumn != null || data != null) &&
        (dataColumn == null || data == null))) {
      throw ArgumentError(
          'Series must have either dataColumn or data, but not both');
    }
    if (dataColumn == null && data == null) {
      throw ArgumentError('Series must have either dataColumn or data');
    }
    if (dataId != null && dataColumn == null) {
      throw ArgumentError('dataId requires dataColumn to be set');
    }
    final localColor = color;
    if (localColor != null && !_isValidColor(localColor)) {
      throw ArgumentError('color must be in #RGB or #RRGGBB format');
    }
    // FR-002: yAxisId and flat y-axis fields no longer supported.
    // Y-axis configuration is via nested yAxisConfig (FR-001).
  }

  /// Validates hex color format
  static bool _isValidColor(String color) {
    final hexPattern = RegExp(r'^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$');
    return hexPattern.hasMatch(color);
  }

  /// Creates a SeriesConfig from JSON
  factory SeriesConfig.fromJson(Map<String, dynamic> json) {
    // FR-001: Build yAxisConfig from nested object or flat fields (backward compat)
    YAxisConfig? yAxisConfig;
    if (json['yAxisConfig'] != null) {
      // Preferred: nested yAxisConfig object
      yAxisConfig =
          YAxisConfig.fromJson(json['yAxisConfig'] as Map<String, dynamic>);
    } else if (_hasFlatYAxisFields(json)) {
      // Backward compatibility: build from flat fields (LLM tool input)
      yAxisConfig = YAxisConfig(
        position: _parseAxisPosition(json['yAxisPosition'] as String?),
        label: json['yAxisLabel'] as String?,
        unit: json['yAxisUnit'] as String?,
        color: json['yAxisColor'] as String?,
        min: (json['yAxisMin'] as num?)?.toDouble(),
        max: (json['yAxisMax'] as num?)?.toDouble(),
      );
    }

    return SeriesConfig(
      id: json['id'] as String,
      name: json['name'] as String?,
      dataColumn: json['dataColumn'] as String?,
      dataId: json['dataId'] as String?,
      data: json['data'] as List<dynamic>?,
      color: json['color'] as String?,
      strokeWidth: json['strokeWidth'] as double? ?? 2.0,
      strokeDash: json['strokeDash'] != null
          ? (json['strokeDash'] as List).cast<double>()
          : null,
      fillOpacity: json['fillOpacity'] as double? ?? 0.0,
      markerStyle: json['markerStyle'] != null
          ? MarkerStyle.values.firstWhere((e) => e.name == json['markerStyle'])
          : MarkerStyle.none,
      markerSize: json['markerSize'] as double? ?? 4.0,
      interpolation: json['interpolation'] != null
          ? Interpolation.values
              .firstWhere((e) => e.name == json['interpolation'])
          : Interpolation.linear,
      showPoints: json['showPoints'] as bool? ?? false,
      // FR-002: yAxisId is no longer supported; use yAxisConfig instead
      unit: json['unit'] as String?,
      visible: json['visible'] as bool? ?? true,
      legendVisible: json['legendVisible'] as bool? ?? true,
      barWidthPercent: json['barWidthPercent'] as double?,
      barWidthPixels: json['barWidthPixels'] as double?,
      tension: json['tension'] as double?,
      markerRadius: json['markerRadius'] as double?,
      dataPointMarkerRadius: json['dataPointMarkerRadius'] as double?,
      yAxisConfig: yAxisConfig,
    );
  }

  /// Check if JSON has any flat y-axis fields (backward compatibility)
  static bool _hasFlatYAxisFields(Map<String, dynamic> json) {
    return json['yAxisPosition'] != null ||
        json['yAxisLabel'] != null ||
        json['yAxisUnit'] != null ||
        json['yAxisColor'] != null ||
        json['yAxisMin'] != null ||
        json['yAxisMax'] != null;
  }

  /// Parse axis position string to enum
  static AxisPosition _parseAxisPosition(String? position) {
    if (position == null) return AxisPosition.left;
    return AxisPosition.values.firstWhere(
      (e) => e.name == position,
      orElse: () => AxisPosition.left,
    );
  }

  /// Converts SeriesConfig to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (name != null) 'name': name,
      if (dataColumn != null) 'dataColumn': dataColumn,
      if (dataId != null) 'dataId': dataId,
      if (data != null) 'data': data,
      if (color != null) 'color': color,
      'strokeWidth': strokeWidth,
      if (strokeDash != null) 'strokeDash': strokeDash,
      'fillOpacity': fillOpacity,
      'markerStyle': markerStyle.name,
      'markerSize': markerSize,
      'interpolation': interpolation.name,
      'showPoints': showPoints,
      // FR-002: yAxisId is no longer serialized
      if (unit != null) 'unit': unit,
      'visible': visible,
      'legendVisible': legendVisible,
      if (barWidthPercent != null) 'barWidthPercent': barWidthPercent,
      if (barWidthPixels != null) 'barWidthPixels': barWidthPixels,
      if (tension != null) 'tension': tension,
      if (markerRadius != null) 'markerRadius': markerRadius,
      if (dataPointMarkerRadius != null)
        'dataPointMarkerRadius': dataPointMarkerRadius,
      // FR-001: Serialize nested yAxisConfig object
      if (yAxisConfig != null) 'yAxisConfig': yAxisConfig!.toJson(),
    };
  }

  /// Creates a copy with modified values
  SeriesConfig copyWith({
    String? id,
    String? name,
    String? dataColumn,
    String? dataId,
    List<dynamic>? data,
    String? color,
    double? strokeWidth,
    List<double>? strokeDash,
    double? fillOpacity,
    MarkerStyle? markerStyle,
    double? markerSize,
    Interpolation? interpolation,
    bool? showPoints,
    String? unit,
    bool? visible,
    bool? legendVisible,
    double? barWidthPercent,
    double? barWidthPixels,
    double? tension,
    double? markerRadius,
    double? dataPointMarkerRadius,
    YAxisConfig? yAxisConfig,
  }) {
    return SeriesConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      dataColumn: dataColumn ?? this.dataColumn,
      dataId: dataId ?? this.dataId,
      data: data ?? this.data,
      color: color ?? this.color,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeDash: strokeDash ?? this.strokeDash,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      markerStyle: markerStyle ?? this.markerStyle,
      markerSize: markerSize ?? this.markerSize,
      interpolation: interpolation ?? this.interpolation,
      showPoints: showPoints ?? this.showPoints,
      unit: unit ?? this.unit,
      visible: visible ?? this.visible,
      legendVisible: legendVisible ?? this.legendVisible,
      barWidthPercent: barWidthPercent ?? this.barWidthPercent,
      barWidthPixels: barWidthPixels ?? this.barWidthPixels,
      tension: tension ?? this.tension,
      markerRadius: markerRadius ?? this.markerRadius,
      dataPointMarkerRadius:
          dataPointMarkerRadius ?? this.dataPointMarkerRadius,
      yAxisConfig: yAxisConfig ?? this.yAxisConfig,
    );
  }
}
