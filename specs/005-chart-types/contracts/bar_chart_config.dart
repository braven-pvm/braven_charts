/// Contract: BarChartConfig
///
/// Configuration object for bar chart rendering.
/// All instances must be immutable and validated.
library;

abstract class BarChartConfig {
  /// Chart orientation (vertical or horizontal)
  BarOrientation get orientation;

  /// Grouping mode (grouped or stacked)
  BarGroupingMode get groupingMode;

  /// Bar width as percentage of category width
  /// VALIDATION: Must be in range (0.0, 1.0]
  double get barWidthRatio;

  /// Spacing between bars in a group (logical pixels)
  /// VALIDATION: Must be >= 0.0
  double get barSpacing;

  /// Spacing between groups (logical pixels)
  /// VALIDATION: Must be >= 0.0
  double get groupSpacing;

  /// Corner radius for rounded corners (0 = sharp)
  /// VALIDATION: Must be >= 0.0
  double get cornerRadius;

  /// Border width (0 = no border)
  /// VALIDATION: Must be >= 0.0
  double get borderWidth;

  /// Border color (null = use series color)
  Color? get borderColor;

  /// Whether to use gradient fill
  bool get useGradient;

  /// Gradient start color (null = use series color)
  Color? get gradientStart;

  /// Gradient end color (null = lighter series color)
  Color? get gradientEnd;

  /// Create a copy with modified properties
  BarChartConfig copyWith({
    BarOrientation? orientation,
    BarGroupingMode? groupingMode,
    double? barWidthRatio,
    double? barSpacing,
    double? groupSpacing,
    double? cornerRadius,
    double? borderWidth,
    Color? borderColor,
    bool? useGradient,
    Color? gradientStart,
    Color? gradientEnd,
  });

  /// Validate configuration
  /// Throws ArgumentError if invalid
  void validate();
}

/// Bar chart orientation
enum BarOrientation {
  /// Vertical bars (column chart)
  vertical,

  /// Horizontal bars
  horizontal,
}

/// Multi-series bar grouping modes
enum BarGroupingMode {
  /// Bars side-by-side at each category
  grouped,

  /// Bars stacked vertically/horizontally
  stacked,
}
