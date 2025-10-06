/// Line chart configuration and styling options
library;

import '../base/chart_config.dart';

/// Style of line rendering
///
/// Determines how the line connects data points:
/// - [straight]: Direct linear connection between points
/// - [smooth]: Smooth bezier curve through points
/// - [stepped]: Horizontal-then-vertical steps between points
enum LineStyle {
  /// Connect points with straight line segments
  straight,

  /// Connect points with smooth bezier curves
  smooth,

  /// Connect points with horizontal-then-vertical steps (step chart)
  stepped,
}

/// Configuration for line chart rendering
///
/// All instances are immutable and validated at construction.
/// Constitutional requirement: Input validation (Testing Excellence)
class LineChartConfig {
  /// Creates line chart configuration
  ///
  /// Throws [ArgumentError] if validation fails:
  /// - [markerSize] <= 0
  /// - [lineWidth] <= 0
  /// - [dashPattern] has odd length
  const LineChartConfig({
    required this.lineStyle,
    required this.markerShape,
    required this.markerSize,
    required this.showMarkers,
    required this.lineWidth,
    this.dashPattern,
    required this.connectNulls,
  })  : assert(markerSize > 0, 'markerSize must be > 0'),
        assert(lineWidth > 0, 'lineWidth must be > 0'),
        assert(
          dashPattern == null || dashPattern.length % 2 == 0,
          'dashPattern must have even length (on/off pairs)',
        );

  /// Line rendering style
  final LineStyle lineStyle;

  /// Marker shape for data points
  final MarkerShape markerShape;

  /// Marker size in logical pixels
  ///
  /// VALIDATION: Must be > 0
  final double markerSize;

  /// Whether to show markers at data points
  final bool showMarkers;

  /// Line width in logical pixels
  ///
  /// VALIDATION: Must be > 0
  final double lineWidth;

  /// Dash pattern for dashed lines (null = solid line)
  ///
  /// Pattern is specified as alternating on/off lengths.
  /// For example, [5, 3] creates 5px dash, 3px gap.
  ///
  /// VALIDATION: If non-null, must have even length (on/off pairs)
  final List<double>? dashPattern;

  /// Whether to connect null values in data
  ///
  /// If true, null data points are skipped and the line continues.
  /// If false, null data points create gaps in the line.
  final bool connectNulls;

  /// Creates a copy with modified properties
  LineChartConfig copyWith({
    LineStyle? lineStyle,
    MarkerShape? markerShape,
    double? markerSize,
    bool? showMarkers,
    double? lineWidth,
    List<double>? dashPattern,
    bool? connectNulls,
  }) {
    return LineChartConfig(
      lineStyle: lineStyle ?? this.lineStyle,
      markerShape: markerShape ?? this.markerShape,
      markerSize: markerSize ?? this.markerSize,
      showMarkers: showMarkers ?? this.showMarkers,
      lineWidth: lineWidth ?? this.lineWidth,
      dashPattern: dashPattern ?? this.dashPattern,
      connectNulls: connectNulls ?? this.connectNulls,
    );
  }

  /// Validates the configuration
  ///
  /// Throws [ArgumentError] if invalid:
  /// - [markerSize] <= 0
  /// - [lineWidth] <= 0
  /// - [dashPattern] has odd length
  void validate() {
    if (markerSize <= 0) {
      throw ArgumentError('markerSize must be > 0, got $markerSize');
    }
    if (lineWidth <= 0) {
      throw ArgumentError('lineWidth must be > 0, got $lineWidth');
    }
    if (dashPattern != null && dashPattern!.length % 2 != 0) {
      throw ArgumentError(
        'dashPattern must have even length (on/off pairs), got length ${dashPattern!.length}',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineChartConfig &&
          runtimeType == other.runtimeType &&
          lineStyle == other.lineStyle &&
          markerShape == other.markerShape &&
          markerSize == other.markerSize &&
          showMarkers == other.showMarkers &&
          lineWidth == other.lineWidth &&
          _listEquals(dashPattern, other.dashPattern) &&
          connectNulls == other.connectNulls;

  @override
  int get hashCode => Object.hash(
        lineStyle,
        markerShape,
        markerSize,
        showMarkers,
        lineWidth,
        Object.hashAll(dashPattern ?? const []),
        connectNulls,
      );

  @override
  String toString() {
    return 'LineChartConfig(lineStyle: $lineStyle, markerShape: $markerShape, '
        'markerSize: $markerSize, showMarkers: $showMarkers, lineWidth: $lineWidth, '
        'dashPattern: $dashPattern, connectNulls: $connectNulls)';
  }

  /// Helper to compare nullable lists
  static bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
