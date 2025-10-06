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

  /// Creates an area baseline configuration
  ///
  /// Throws [ArgumentError] if validation fails:
  /// - [type] = [AreaBaselineType.fixed] requires [fixedValue] != null
  /// - [type] = [AreaBaselineType.series] requires [seriesId] != null
  const AreaBaseline({
    required this.type,
    this.fixedValue,
    this.seriesId,
  }) : assert(
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
      other is AreaBaseline &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          fixedValue == other.fixedValue &&
          seriesId == other.seriesId;

  @override
  int get hashCode => Object.hash(type, fixedValue, seriesId);

  @override
  String toString() {
    return 'AreaBaseline(type: $type, fixedValue: $fixedValue, seriesId: $seriesId)';
  }
}

