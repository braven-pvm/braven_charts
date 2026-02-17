/// Contract: LineChartConfig
///
/// Configuration object for line chart rendering.
/// All instances must be immutable and validated.
library;

abstract class LineChartConfig {
  /// Line rendering style
  LineStyle get lineStyle;

  /// Marker shape for data points
  MarkerShape get markerShape;

  /// Marker size in logical pixels
  /// VALIDATION: Must be > 0
  double get markerSize;

  /// Whether to show markers at data points
  bool get showMarkers;

  /// Line width in logical pixels
  /// VALIDATION: Must be > 0
  double get lineWidth;

  /// Dash pattern for dashed lines (null = solid)
  /// VALIDATION: If non-null, must have even length (on/off pairs)
  List<double>? get dashPattern;

  /// Whether to connect null values in data
  bool get connectNulls;

  /// Create a copy with modified properties
  LineChartConfig copyWith({
    LineStyle? lineStyle,
    MarkerShape? markerShape,
    double? markerSize,
    bool? showMarkers,
    double? lineWidth,
    List<double>? dashPattern,
    bool? connectNulls,
  });

  /// Validate configuration
  /// Throws ArgumentError if invalid
  void validate();
}

/// Line rendering styles
enum LineStyle {
  /// Linear interpolation between points
  straight,

  /// Catmull-Rom spline converted to cubic bezier
  smooth,

  /// Constant value (horizontal then vertical segments)
  stepped,
}

/// Marker shapes (shared with scatter chart)
enum MarkerShape { circle, square, triangle, diamond, cross, plus, none }
