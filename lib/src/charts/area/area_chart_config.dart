/// Area chart configuration and styling options
library;

/// Style of area fill rendering
///
/// Determines how the area under the line is filled:
/// - [solid]: Solid color fill with optional opacity
/// - [gradient]: Vertical gradient from line to baseline
/// - [pattern]: Pattern fill (e.g., diagonal lines, dots)
enum AreaFillStyle {
  /// Solid color fill with opacity control
  solid,

  /// Vertical gradient from top (line) to bottom (baseline)
  gradient,

  /// Pattern fill (diagonal lines, dots, etc.)
  pattern,
}

/// Type of baseline for area chart
///
/// Determines what the area is filled relative to:
/// - [zero]: Fill from zero line (y=0)
/// - [fixed]: Fill from a fixed y-value
/// - [series]: Fill from another data series
enum AreaBaselineType {
  /// Fill from y=0 (zero line)
  zero,

  /// Fill from a fixed y-value
  fixed,

  /// Fill from another data series
  series,
}

/// Baseline configuration for area charts
///
/// Defines what the area is filled relative to. The baseline can be:
/// - Zero line (y=0)
/// - A fixed y-value
/// - Another data series
///
/// Constitutional requirement: Input validation (Testing Excellence)
class AreaBaseline {
  /// Creates an area baseline configuration
  ///
  /// Throws [ArgumentError] if validation fails:
  /// - [type] = [AreaBaselineType.fixed] requires [fixedValue] != null
  /// - [type] = [AreaBaselineType.series] requires [seriesId] != null
  const AreaBaseline({
    required this.type,
    this.fixedValue,
    this.seriesId,
  })  : assert(
          type != AreaBaselineType.fixed || fixedValue != null,
          'fixedValue is required when type is AreaBaselineType.fixed',
        ),
        assert(
          type != AreaBaselineType.series || seriesId != null,
          'seriesId is required when type is AreaBaselineType.series',
        );

  /// Creates a baseline at y=0
  const AreaBaseline.zero()
      : type = AreaBaselineType.zero,
        fixedValue = null,
        seriesId = null;

  /// Creates a baseline at a fixed y-value
  const AreaBaseline.fixed(double value)
      : type = AreaBaselineType.fixed,
        fixedValue = value,
        seriesId = null;

  /// Creates a baseline from another data series
  const AreaBaseline.series(String id)
      : type = AreaBaselineType.series,
        fixedValue = null,
        seriesId = id;

  /// Type of baseline
  final AreaBaselineType type;

  /// Fixed Y value (required when type is [AreaBaselineType.fixed])
  ///
  /// VALIDATION: Must be non-null if type is fixed
  final double? fixedValue;

  /// Series ID to use as baseline (required when type is [AreaBaselineType.series])
  ///
  /// VALIDATION: Must be non-null if type is series
  final String? seriesId;

  /// Creates a copy with modified properties
  AreaBaseline copyWith({
    AreaBaselineType? type,
    double? fixedValue,
    String? seriesId,
  }) {
    return AreaBaseline(
      type: type ?? this.type,
      fixedValue: fixedValue ?? this.fixedValue,
      seriesId: seriesId ?? this.seriesId,
    );
  }

  /// Validates the baseline configuration
  ///
  /// Throws [ArgumentError] if invalid:
  /// - [type] = [AreaBaselineType.fixed] but [fixedValue] is null
  /// - [type] = [AreaBaselineType.series] but [seriesId] is null
  void validate() {
    if (type == AreaBaselineType.fixed && fixedValue == null) {
      throw ArgumentError('fixedValue is required when type is AreaBaselineType.fixed');
    }
    if (type == AreaBaselineType.series && seriesId == null) {
      throw ArgumentError('seriesId is required when type is AreaBaselineType.series');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AreaBaseline && runtimeType == other.runtimeType && type == other.type && fixedValue == other.fixedValue && seriesId == other.seriesId;

  @override
  int get hashCode => Object.hash(type, fixedValue, seriesId);

  @override
  String toString() {
    return 'AreaBaseline(type: $type, fixedValue: $fixedValue, seriesId: $seriesId)';
  }
}

/// Configuration for area chart rendering
///
/// All instances are immutable and validated at construction.
/// Constitutional requirement: Input validation (Testing Excellence)
class AreaChartConfig {
  /// Fill style for the area
  final AreaFillStyle fillStyle;

  /// Baseline configuration
  final AreaBaseline baseline;

  /// Whether to stack multiple series
  final bool stacked;

  /// Fill opacity (0.0 = transparent, 1.0 = opaque)
  ///
  /// VALIDATION: Must be in range [0.0, 1.0]
  final double fillOpacity;

  /// Whether to draw line on top of fill
  final bool showLine;

  /// Line configuration (required if showLine is true)
  ///
  /// VALIDATION: Must be non-null if showLine is true
  final dynamic lineConfig; // TODO: Replace with LineChartConfig when available

  /// Creates area chart configuration
  ///
  /// Throws [ArgumentError] if validation fails:
  /// - [fillOpacity] not in [0.0, 1.0]
  /// - [showLine] = true but [lineConfig] is null
  const AreaChartConfig({
    required this.fillStyle,
    required this.baseline,
    required this.stacked,
    required this.fillOpacity,
    required this.showLine,
    this.lineConfig,
  }) : assert(
          fillOpacity >= 0.0 && fillOpacity <= 1.0,
          'fillOpacity must be in range [0.0, 1.0]',
        ),
       assert(
          !showLine || lineConfig != null,
          'lineConfig is required when showLine is true',
        );

  /// Creates a copy with modified properties
  AreaChartConfig copyWith({
    AreaFillStyle? fillStyle,
    AreaBaseline? baseline,
    bool? stacked,
    double? fillOpacity,
    bool? showLine,
    dynamic lineConfig,
  }) {
    return AreaChartConfig(
      fillStyle: fillStyle ?? this.fillStyle,
      baseline: baseline ?? this.baseline,
      stacked: stacked ?? this.stacked,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      showLine: showLine ?? this.showLine,
      lineConfig: lineConfig ?? this.lineConfig,
    );
  }

  /// Validates the configuration
  ///
  /// Throws [ArgumentError] if invalid:
  /// - [fillOpacity] not in [0.0, 1.0]
  /// - [showLine] = true but [lineConfig] is null
  void validate() {
    if (fillOpacity < 0.0 || fillOpacity > 1.0) {
      throw ArgumentError('fillOpacity must be in range [0.0, 1.0], got $fillOpacity');
    }
    if (showLine && lineConfig == null) {
      throw ArgumentError('lineConfig is required when showLine is true');
    }
    baseline.validate();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AreaChartConfig &&
          runtimeType == other.runtimeType &&
          fillStyle == other.fillStyle &&
          baseline == other.baseline &&
          stacked == other.stacked &&
          fillOpacity == other.fillOpacity &&
          showLine == other.showLine &&
          lineConfig == other.lineConfig;

  @override
  int get hashCode => Object.hash(
        fillStyle,
        baseline,
        stacked,
        fillOpacity,
        showLine,
        lineConfig,
      );

  @override
  String toString() {
    return 'AreaChartConfig(fillStyle: $fillStyle, baseline: $baseline, '
        'stacked: $stacked, fillOpacity: $fillOpacity, showLine: $showLine, '
        'lineConfig: $lineConfig)';
  }
}
