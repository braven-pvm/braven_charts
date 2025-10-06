/// Contract: ScatterChartConfig
///
/// Configuration object for scatter plot rendering.
/// All instances must be immutable and validated.
library;

abstract class ScatterChartConfig {
  /// Marker shape for data points
  MarkerShape get markerShape;

  /// Marker sizing mode
  MarkerSizingMode get sizingMode;

  /// Fixed marker size (required when sizingMode is fixed)
  /// VALIDATION: Must be > 0 if sizingMode is fixed
  double? get fixedSize;

  /// Minimum marker size (required when sizingMode is dataDriven)
  /// VALIDATION: Must be > 0 and < maxSize if sizingMode is dataDriven
  double? get minSize;

  /// Maximum marker size (required when sizingMode is dataDriven)
  /// VALIDATION: Must be > minSize if sizingMode is dataDriven
  double? get maxSize;

  /// Marker rendering style
  MarkerStyle get markerStyle;

  /// Border width for outlined markers
  /// VALIDATION: Must be >= 0.0
  double get borderWidth;

  /// Whether to enable clustering for dense data
  bool get enableClustering;

  /// Cluster threshold (minimum points to form cluster)
  /// VALIDATION: Must be >= 2 if enableClustering is true
  int get clusterThreshold;

  /// Create a copy with modified properties
  ScatterChartConfig copyWith({
    MarkerShape? markerShape,
    MarkerSizingMode? sizingMode,
    double? fixedSize,
    double? minSize,
    double? maxSize,
    MarkerStyle? markerStyle,
    double? borderWidth,
    bool? enableClustering,
    int? clusterThreshold,
  });

  /// Validate configuration
  /// Throws ArgumentError if invalid
  void validate();
}

/// Marker sizing modes
enum MarkerSizingMode {
  /// All markers same size (use fixedSize)
  fixed,

  /// Marker size represents third variable (use minSize/maxSize)
  /// Size determined by ChartDataPoint.metadata['size']
  dataDriven,
}

/// Marker rendering styles
enum MarkerStyle {
  /// Filled marker with series color
  filled,

  /// Outlined marker with border color
  outlined,

  /// Both filled and outlined
  both,
}
