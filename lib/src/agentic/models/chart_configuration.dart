/// Chart type enumeration
enum ChartType {
  line,
  area,
  bar,
  scatter,
}

/// Stub for ChartStyleConfig
class ChartStyleConfig {
  ChartStyleConfig({
    dynamic backgroundColor,
    dynamic gridColor,
    dynamic axisColor,
    dynamic plotArea,
    String? fontFamily,
    double? fontSize,
  });
}

/// Stub implementation for ChartConfiguration model
/// This will be implemented in the green phase of TDD
class ChartConfiguration {
  final ChartType type;
  final String? title;
  final String? subtitle;
  final List<dynamic> series;
  final dynamic xAxis;
  final List<dynamic> yAxes;
  final dynamic style;
  final dynamic interactions;
  final List<dynamic>? annotations;
  final dynamic layout;

  /// Creates a new ChartConfiguration instance
  ChartConfiguration({
    required this.type,
    this.title,
    this.subtitle,
    List<dynamic>? series,
    this.xAxis,
    List<dynamic>? yAxes,
    this.style,
    this.interactions,
    this.annotations,
    this.layout,
  })  : series = series ?? [],
        yAxes = yAxes ?? [];

  /// Creates a ChartConfiguration from JSON
  factory ChartConfiguration.fromJson(Map<String, dynamic> json) {
    throw UnimplementedError('ChartConfiguration.fromJson not yet implemented');
  }

  /// Converts ChartConfiguration to JSON
  Map<String, dynamic> toJson() {
    throw UnimplementedError('ChartConfiguration.toJson not yet implemented');
  }

  /// Creates a copy with modified values
  ChartConfiguration copyWith({
    ChartType? type,
    String? title,
    String? subtitle,
    List<dynamic>? series,
    dynamic xAxis,
    List<dynamic>? yAxes,
    dynamic style,
    dynamic interactions,
    List<dynamic>? annotations,
    dynamic layout,
  }) {
    throw UnimplementedError('ChartConfiguration.copyWith not yet implemented');
  }
}
