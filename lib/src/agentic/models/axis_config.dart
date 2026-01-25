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

/// Stub implementation for XAxisConfig model
/// This will be implemented in the green phase of TDD
class XAxisConfig {
  final String? label;
  final String? unit;
  final AxisType type;
  final double? min;
  final double? max;
  final bool autoRange;
  final double paddingPercent;
  final int? tickCount;
  final String? tickFormat;
  final double tickRotation;
  final bool showTicks;
  final bool showAxisLine;
  final bool showGridLines;
  final String? gridColor;
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
        showGridLines = showGridLines ?? true;

  /// Creates an XAxisConfig from JSON
  factory XAxisConfig.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('XAxisConfig.fromJson not yet implemented');
  }

  /// Converts XAxisConfig to JSON
  Map<String, dynamic> toJson() {
    throw UnimplementedError('XAxisConfig.toJson not yet implemented');
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
    throw UnimplementedError('XAxisConfig.copyWith not yet implemented');
  }
}

/// Stub implementation for YAxisConfig model
/// This will be implemented in the green phase of TDD
class YAxisConfig {
  final String? id;
  final String? label;
  final String? unit;
  final AxisPosition position;
  final double? min;
  final double? max;
  final bool autoRange;
  final bool includeZero;
  final double paddingPercent;
  final int? tickCount;
  final String? tickFormat;
  final bool showTicks;
  final bool showAxisLine;
  final bool showGridLines;
  final String? gridColor;
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
        showGridLines = showGridLines ?? true;

  /// Creates a YAxisConfig from JSON
  factory YAxisConfig.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('YAxisConfig.fromJson not yet implemented');
  }

  /// Converts YAxisConfig to JSON
  Map<String, dynamic> toJson() {
    throw UnimplementedError('YAxisConfig.toJson not yet implemented');
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
    throw UnimplementedError('YAxisConfig.copyWith not yet implemented');
  }
}
