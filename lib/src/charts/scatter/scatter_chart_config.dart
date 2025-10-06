/// Scatter chart configuration and styling options
library;

import '../base/chart_config.dart';

/// Mode for determining marker sizes
///
/// - [fixed]: All markers have the same size
/// - [dataDriven]: Marker size varies based on a third data dimension
enum MarkerSizingMode {
  /// Fixed size for all markers
  fixed,

  /// Size determined by data (bubble chart)
  dataDriven,
}

/// Style of marker rendering
///
/// - [filled]: Solid filled markers
/// - [outlined]: Hollow markers with border only
/// - [both]: Filled markers with visible border
enum MarkerStyle {
  /// Solid filled markers
  filled,

  /// Hollow markers with border
  outlined,

  /// Filled with border
  both,
}

/// Configuration for scatter chart rendering
///
/// All instances are immutable and validated at construction.
/// Constitutional requirement: Input validation (Testing Excellence)
class ScatterChartConfig {
  /// Marker shape for data points
  final MarkerShape markerShape;

  /// Marker sizing mode
  final MarkerSizingMode sizingMode;

  /// Fixed marker size (required when sizingMode is fixed)
  ///
  /// VALIDATION: Must be > 0 if sizingMode is fixed
  final double? fixedSize;

  /// Minimum marker size (required when sizingMode is dataDriven)
  ///
  /// VALIDATION: Must be > 0 and < maxSize if sizingMode is dataDriven
  final double? minSize;

  /// Maximum marker size (required when sizingMode is dataDriven)
  ///
  /// VALIDATION: Must be > minSize if sizingMode is dataDriven
  final double? maxSize;

  /// Marker rendering style
  final MarkerStyle markerStyle;

  /// Border width for outlined markers
  ///
  /// VALIDATION: Must be >= 0.0
  final double borderWidth;

  /// Whether to enable clustering for dense data
  final bool enableClustering;

  /// Cluster threshold (minimum points to form cluster)
  ///
  /// VALIDATION: Must be >= 2 if enableClustering is true
  final int clusterThreshold;

  /// Creates scatter chart configuration
  ///
  /// Throws [ArgumentError] if validation fails:
  /// - sizingMode = fixed but fixedSize is null or <= 0
  /// - sizingMode = dataDriven but minSize or maxSize is null
  /// - sizingMode = dataDriven but minSize >= maxSize
  /// - borderWidth < 0
  /// - enableClustering = true but clusterThreshold < 2
  const ScatterChartConfig({
    required this.markerShape,
    required this.sizingMode,
    this.fixedSize,
    this.minSize,
    this.maxSize,
    required this.markerStyle,
    required this.borderWidth,
    required this.enableClustering,
    required this.clusterThreshold,
  }) : assert(
          sizingMode != MarkerSizingMode.fixed || (fixedSize != null && fixedSize > 0),
          'fixedSize is required and must be > 0 when sizingMode is fixed',
        ),
       assert(
          sizingMode != MarkerSizingMode.dataDriven || minSize != null,
          'minSize is required when sizingMode is dataDriven',
        ),
       assert(
          sizingMode != MarkerSizingMode.dataDriven || maxSize != null,
          'maxSize is required when sizingMode is dataDriven',
        ),
       assert(borderWidth >= 0.0, 'borderWidth must be >= 0.0'),
       assert(
          clusterThreshold >= 2,
          'clusterThreshold must be >= 2',
        );

  /// Creates a copy with modified properties
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
  }) {
    return ScatterChartConfig(
      markerShape: markerShape ?? this.markerShape,
      sizingMode: sizingMode ?? this.sizingMode,
      fixedSize: fixedSize ?? this.fixedSize,
      minSize: minSize ?? this.minSize,
      maxSize: maxSize ?? this.maxSize,
      markerStyle: markerStyle ?? this.markerStyle,
      borderWidth: borderWidth ?? this.borderWidth,
      enableClustering: enableClustering ?? this.enableClustering,
      clusterThreshold: clusterThreshold ?? this.clusterThreshold,
    );
  }

  /// Validates the configuration
  ///
  /// Throws [ArgumentError] if invalid
  void validate() {
    if (sizingMode == MarkerSizingMode.fixed) {
      if (fixedSize == null || fixedSize! <= 0) {
        throw ArgumentError(
          'fixedSize is required and must be > 0 when sizingMode is fixed, got $fixedSize',
        );
      }
    }

    if (sizingMode == MarkerSizingMode.dataDriven) {
      if (minSize == null) {
        throw ArgumentError('minSize is required when sizingMode is dataDriven');
      }
      if (maxSize == null) {
        throw ArgumentError('maxSize is required when sizingMode is dataDriven');
      }
      if (minSize! >= maxSize!) {
        throw ArgumentError(
          'minSize must be < maxSize when sizingMode is dataDriven, got minSize=$minSize, maxSize=$maxSize',
        );
      }
    }

    if (borderWidth < 0.0) {
      throw ArgumentError('borderWidth must be >= 0.0, got $borderWidth');
    }

    if (clusterThreshold < 2) {
      throw ArgumentError(
        'clusterThreshold must be >= 2, got $clusterThreshold',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterChartConfig &&
          runtimeType == other.runtimeType &&
          markerShape == other.markerShape &&
          sizingMode == other.sizingMode &&
          fixedSize == other.fixedSize &&
          minSize == other.minSize &&
          maxSize == other.maxSize &&
          markerStyle == other.markerStyle &&
          borderWidth == other.borderWidth &&
          enableClustering == other.enableClustering &&
          clusterThreshold == other.clusterThreshold;

  @override
  int get hashCode => Object.hash(
        markerShape,
        sizingMode,
        fixedSize,
        minSize,
        maxSize,
        markerStyle,
        borderWidth,
        enableClustering,
        clusterThreshold,
      );

  @override
  String toString() {
    return 'ScatterChartConfig(markerShape: $markerShape, sizingMode: $sizingMode, '
        'fixedSize: $fixedSize, minSize: $minSize, maxSize: $maxSize, '
        'markerStyle: $markerStyle, borderWidth: $borderWidth, '
        'enableClustering: $enableClustering, clusterThreshold: $clusterThreshold)';
  }
}

