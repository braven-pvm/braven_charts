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
        legendVisible = legendVisible ?? true;

  /// Creates a SeriesConfig from JSON
  factory SeriesConfig.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('SeriesConfig.fromJson not yet implemented');
  }

  /// Converts SeriesConfig to JSON
  Map<String, dynamic> toJson() {
    throw UnimplementedError('SeriesConfig.toJson not yet implemented');
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
    throw UnimplementedError('SeriesConfig.copyWith not yet implemented');
  }
}
