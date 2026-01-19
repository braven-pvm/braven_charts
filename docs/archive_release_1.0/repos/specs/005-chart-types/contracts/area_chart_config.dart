/// Contract: AreaChartConfig
///
/// Configuration object for area chart rendering.
/// All instances must be immutable and validated.
library;

abstract class AreaChartConfig {
  /// Fill style for the area
  AreaFillStyle get fillStyle;

  /// Baseline configuration
  AreaBaseline get baseline;

  /// Whether to stack multiple series
  bool get stacked;

  /// Fill opacity (0.0 = transparent, 1.0 = opaque)
  /// VALIDATION: Must be in range [0.0, 1.0]
  double get fillOpacity;

  /// Whether to draw line on top of fill
  bool get showLine;

  /// Line configuration (required if showLine is true)
  /// VALIDATION: Must be non-null if showLine is true
  LineChartConfig? get lineConfig;

  /// Create a copy with modified properties
  AreaChartConfig copyWith({
    AreaFillStyle? fillStyle,
    AreaBaseline? baseline,
    bool? stacked,
    double? fillOpacity,
    bool? showLine,
    LineChartConfig? lineConfig,
  });

  /// Validate configuration
  /// Throws ArgumentError if invalid
  void validate();
}

/// Area fill styles
enum AreaFillStyle {
  /// Solid color fill
  solid,

  /// Linear gradient (vertical by default)
  gradient,

  /// Custom pattern (future extension)
  pattern,
}

/// Baseline configuration for area charts
abstract class AreaBaseline {
  /// Baseline type
  AreaBaselineType get type;

  /// Fixed Y value (required when type is fixed)
  /// VALIDATION: Must be non-null if type is fixed
  double? get fixedValue;

  /// Series ID to use as baseline (required when type is series)
  /// VALIDATION: Must be non-null if type is series
  String? get seriesId;

  /// Validate baseline configuration
  void validate();
}

/// Baseline types
enum AreaBaselineType {
  /// Y = 0 baseline
  zero,

  /// Fixed Y value
  fixed,

  /// Another series as baseline
  series,
}
