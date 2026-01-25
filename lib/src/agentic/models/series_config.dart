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

/// Stub implementation for SeriesConfig model
/// This will be implemented in the green phase of TDD
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
  final String? yAxisId;
  final String? unit;
  final bool visible;
  final bool legendVisible;

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
    this.yAxisId,
    this.unit,
    bool? visible,
    bool? legendVisible,
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
    if (!((dataColumn != null || data != null) && (dataColumn == null || data == null))) {
      throw ArgumentError('Series must have either dataColumn or data, but not both');
    }
    if (dataColumn == null && data == null) {
      throw ArgumentError('Series must have either dataColumn or data');
    }
    if (dataId != null && dataColumn == null) {
      throw ArgumentError('dataId requires dataColumn to be set');
    }
    final localYAxisId = yAxisId;
    if (localYAxisId != null && localYAxisId.isEmpty) {
      throw ArgumentError('yAxisId cannot be empty string');
    }
    final localColor = color;
    if (localColor != null && !_isValidColor(localColor)) {
      throw ArgumentError('color must be in #RGB or #RRGGBB format');
    }
  }

  /// Validates hex color format
  static bool _isValidColor(String color) {
    final hexPattern = RegExp(r'^#([0-9A-Fa-f]{3}|[0-9A-Fa-f]{6})$');
    return hexPattern.hasMatch(color);
  }

  /// Creates a SeriesConfig from JSON
  factory SeriesConfig.fromJson(Map<String, dynamic> json) {
    return SeriesConfig(
      id: json['id'] as String,
      name: json['name'] as String?,
      dataColumn: json['dataColumn'] as String?,
      dataId: json['dataId'] as String?,
      data: json['data'] as List<dynamic>?,
      color: json['color'] as String?,
      strokeWidth: json['strokeWidth'] as double? ?? 2.0,
      strokeDash: json['strokeDash'] != null ? (json['strokeDash'] as List).cast<double>() : null,
      fillOpacity: json['fillOpacity'] as double? ?? 0.0,
      markerStyle: json['markerStyle'] != null ? MarkerStyle.values.firstWhere((e) => e.name == json['markerStyle']) : MarkerStyle.none,
      markerSize: json['markerSize'] as double? ?? 4.0,
      interpolation: json['interpolation'] != null ? Interpolation.values.firstWhere((e) => e.name == json['interpolation']) : Interpolation.linear,
      showPoints: json['showPoints'] as bool? ?? false,
      yAxisId: json['yAxisId'] as String?,
      unit: json['unit'] as String?,
      visible: json['visible'] as bool? ?? true,
      legendVisible: json['legendVisible'] as bool? ?? true,
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
      if (yAxisId != null) 'yAxisId': yAxisId,
      if (unit != null) 'unit': unit,
      'visible': visible,
      'legendVisible': legendVisible,
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
    String? yAxisId,
    String? unit,
    bool? visible,
    bool? legendVisible,
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
      yAxisId: yAxisId ?? this.yAxisId,
      unit: unit ?? this.unit,
      visible: visible ?? this.visible,
      legendVisible: legendVisible ?? this.legendVisible,
    );
  }
}
