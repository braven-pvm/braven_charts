/// Bar chart configuration and styling options
library;

/// Orientation of bars
///
/// - [vertical]: Bars extend vertically from baseline (standard column chart)
/// - [horizontal]: Bars extend horizontally from baseline
enum BarOrientation {
  /// Vertical bars (column chart)
  vertical,

  /// Horizontal bars
  horizontal,
}

/// Grouping mode for multiple series
///
/// - [grouped]: Bars are placed side-by-side within each category
/// - [stacked]: Bars are stacked on top of each other
enum BarGroupingMode {
  /// Side-by-side bars for each series
  grouped,

  /// Stacked bars (one on top of another)
  stacked,
}

/// Configuration for bar chart rendering
///
/// All instances are immutable and validated at construction.
/// Constitutional requirement: Input validation (Testing Excellence)
class BarChartConfig {
  // TODO: Use Flutter Color when available

  /// Creates bar chart configuration
  ///
  /// Throws [ArgumentError] if validation fails:
  /// - [barWidthRatio] not in (0.0, 1.0]
  /// - [barSpacing] < 0.0
  /// - [groupSpacing] < 0.0
  /// - [cornerRadius] < 0.0
  /// - [borderWidth] < 0.0
  /// - [useGradient] = true but both gradientStart and gradientEnd are null
  const BarChartConfig({
    required this.orientation,
    required this.groupingMode,
    required this.barWidthRatio,
    required this.barSpacing,
    required this.groupSpacing,
    required this.cornerRadius,
    required this.borderWidth,
    this.borderColor,
    required this.useGradient,
    this.gradientStart,
    this.gradientEnd,
  })  : assert(
          barWidthRatio > 0.0 && barWidthRatio <= 1.0,
          'barWidthRatio must be in range (0.0, 1.0]',
        ),
        assert(barSpacing >= 0.0, 'barSpacing must be >= 0.0'),
        assert(groupSpacing >= 0.0, 'groupSpacing must be >= 0.0'),
        assert(cornerRadius >= 0.0, 'cornerRadius must be >= 0.0'),
        assert(borderWidth >= 0.0, 'borderWidth must be >= 0.0'),
        assert(
          !useGradient || gradientStart != null || gradientEnd != null,
          'useGradient=true requires at least one gradient color',
        );

  /// Chart orientation (vertical or horizontal)
  final BarOrientation orientation;

  /// Grouping mode (grouped or stacked)
  final BarGroupingMode groupingMode;

  /// Bar width as percentage of category width
  ///
  /// VALIDATION: Must be in range (0.0, 1.0]
  final double barWidthRatio;

  /// Spacing between bars in a group (logical pixels)
  ///
  /// VALIDATION: Must be >= 0.0
  final double barSpacing;

  /// Spacing between groups (logical pixels)
  ///
  /// VALIDATION: Must be >= 0.0
  final double groupSpacing;

  /// Corner radius for rounded corners (0 = sharp)
  ///
  /// VALIDATION: Must be >= 0.0
  final double cornerRadius;

  /// Border width (0 = no border)
  ///
  /// VALIDATION: Must be >= 0.0
  final double borderWidth;

  /// Border color (null = use series color)
  final int? borderColor; // TODO: Use Flutter Color when available

  /// Whether to use gradient fill
  final bool useGradient;

  /// Gradient start color (null = use series color)
  final int? gradientStart; // TODO: Use Flutter Color when available

  /// Gradient end color (null = lighter series color)
  final int? gradientEnd;

  /// Creates a copy with modified properties
  BarChartConfig copyWith({
    BarOrientation? orientation,
    BarGroupingMode? groupingMode,
    double? barWidthRatio,
    double? barSpacing,
    double? groupSpacing,
    double? cornerRadius,
    double? borderWidth,
    int? borderColor,
    bool? useGradient,
    int? gradientStart,
    int? gradientEnd,
  }) {
    return BarChartConfig(
      orientation: orientation ?? this.orientation,
      groupingMode: groupingMode ?? this.groupingMode,
      barWidthRatio: barWidthRatio ?? this.barWidthRatio,
      barSpacing: barSpacing ?? this.barSpacing,
      groupSpacing: groupSpacing ?? this.groupSpacing,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      useGradient: useGradient ?? this.useGradient,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
    );
  }

  /// Validates the configuration
  ///
  /// Throws [ArgumentError] if invalid
  void validate() {
    if (barWidthRatio <= 0.0 || barWidthRatio > 1.0) {
      throw ArgumentError(
        'barWidthRatio must be in range (0.0, 1.0], got $barWidthRatio',
      );
    }
    if (barSpacing < 0.0) {
      throw ArgumentError('barSpacing must be >= 0.0, got $barSpacing');
    }
    if (groupSpacing < 0.0) {
      throw ArgumentError('groupSpacing must be >= 0.0, got $groupSpacing');
    }
    if (cornerRadius < 0.0) {
      throw ArgumentError('cornerRadius must be >= 0.0, got $cornerRadius');
    }
    if (borderWidth < 0.0) {
      throw ArgumentError('borderWidth must be >= 0.0, got $borderWidth');
    }
    if (useGradient && gradientStart == null && gradientEnd == null) {
      throw ArgumentError(
        'useGradient=true requires at least one gradient color',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarChartConfig &&
          runtimeType == other.runtimeType &&
          orientation == other.orientation &&
          groupingMode == other.groupingMode &&
          barWidthRatio == other.barWidthRatio &&
          barSpacing == other.barSpacing &&
          groupSpacing == other.groupSpacing &&
          cornerRadius == other.cornerRadius &&
          borderWidth == other.borderWidth &&
          borderColor == other.borderColor &&
          useGradient == other.useGradient &&
          gradientStart == other.gradientStart &&
          gradientEnd == other.gradientEnd;

  @override
  int get hashCode => Object.hash(
        orientation,
        groupingMode,
        barWidthRatio,
        barSpacing,
        groupSpacing,
        cornerRadius,
        borderWidth,
        borderColor,
        useGradient,
        gradientStart,
        gradientEnd,
      );

  @override
  String toString() {
    return 'BarChartConfig(orientation: $orientation, groupingMode: $groupingMode, '
        'barWidthRatio: $barWidthRatio, barSpacing: $barSpacing, '
        'groupSpacing: $groupSpacing, cornerRadius: $cornerRadius, '
        'borderWidth: $borderWidth, borderColor: $borderColor, '
        'useGradient: $useGradient, gradientStart: $gradientStart, '
        'gradientEnd: $gradientEnd)';
  }
}
