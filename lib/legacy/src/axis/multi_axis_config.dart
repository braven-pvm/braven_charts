import 'normalization_mode.dart';
import 'series_axis_binding.dart';
import 'y_axis_config.dart';

/// Configuration for multi-axis chart rendering and normalization.
///
/// This is the master configuration class that combines all multi-axis
/// settings: axis definitions, series-to-axis bindings, and normalization
/// behavior. Pass this to the chart widget to enable multi-axis support.
///
/// Example:
/// ```dart
/// final config = MultiAxisConfig(
///   axes: [
///     YAxisConfig(id: 'power', position: YAxisPosition.left),
///     YAxisConfig(id: 'hr', position: YAxisPosition.right),
///   ],
///   bindings: [
///     SeriesAxisBinding(seriesId: 'power-data', axisId: 'power'),
///     SeriesAxisBinding(seriesId: 'hr-data', axisId: 'hr'),
///   ],
///   mode: NormalizationMode.auto,
/// );
/// ```
///
/// See also:
/// - [YAxisConfig] - Configuration for individual Y-axes
/// - [SeriesAxisBinding] - Maps series to axes
/// - [NormalizationMode] - Controls when normalization is applied
class MultiAxisConfig {
  /// Creates a multi-axis configuration.
  ///
  /// - [axes]: List of Y-axis configurations. Each axis should have a unique ID.
  /// - [bindings]: List of series-to-axis bindings. Each binding maps a
  ///   data series to one of the configured axes by ID.
  /// - [mode]: Controls when normalization is applied. Defaults to [NormalizationMode.auto].
  /// - [autoDetectionThreshold]: When [mode] is [NormalizationMode.auto], this
  ///   specifies the minimum ratio between the largest and smallest series
  ///   range that triggers multi-axis normalization. Defaults to 10.0 (10x difference).
  const MultiAxisConfig({
    required this.axes,
    required this.bindings,
    this.mode = NormalizationMode.auto,
    this.autoDetectionThreshold = 10.0,
  });

  /// All Y-axis configurations for this chart.
  ///
  /// Each axis should have a unique [YAxisConfig.id]. The chart supports
  /// up to 4 axes positioned at [YAxisPosition.outerLeft], [YAxisPosition.left],
  /// [YAxisPosition.right], and [YAxisPosition.outerRight].
  final List<YAxisConfig> axes;

  /// Mappings from data series to Y-axes.
  ///
  /// Each binding associates a series (by its ID) with an axis (by its ID).
  /// Series without bindings default to the primary (left) axis.
  /// Multiple series can share the same axis if they have compatible ranges.
  final List<SeriesAxisBinding> bindings;

  /// Controls when normalization is applied.
  ///
  /// - [NormalizationMode.none]: No normalization, traditional single-axis behavior
  /// - [NormalizationMode.auto]: Normalize when series ranges differ by [autoDetectionThreshold]
  /// - [NormalizationMode.always]: Always normalize all series
  ///
  /// Defaults to [NormalizationMode.auto].
  final NormalizationMode mode;

  /// Threshold ratio for automatic normalization detection.
  ///
  /// When [mode] is [NormalizationMode.auto], the chart compares the ranges
  /// of all series. If the ratio between the largest and smallest range
  /// exceeds this threshold, multi-axis normalization is enabled.
  ///
  /// For example, with the default value of 10.0:
  /// - Series A range: 0-300 (range = 300)
  /// - Series B range: 0-4 (range = 4)
  /// - Ratio: 300/4 = 75 > 10.0 → normalization enabled
  ///
  /// Defaults to 10.0.
  final double autoDetectionThreshold;

  /// Finds the axis configuration for a given axis ID.
  ///
  /// Returns `null` if no axis with the given ID is found.
  YAxisConfig? getAxisById(String axisId) {
    for (final axis in axes) {
      if (axis.id == axisId) return axis;
    }
    return null;
  }

  /// Finds the axis configuration for a given series ID.
  ///
  /// Looks up the binding for the series, then returns the corresponding
  /// axis configuration. Returns `null` if the series has no binding or
  /// the bound axis is not found.
  YAxisConfig? getAxisForSeries(String seriesId) {
    for (final binding in bindings) {
      if (binding.seriesId == seriesId) {
        return getAxisById(binding.axisId);
      }
    }
    return null;
  }

  /// Creates a copy of this configuration with the given fields replaced.
  MultiAxisConfig copyWith({
    List<YAxisConfig>? axes,
    List<SeriesAxisBinding>? bindings,
    NormalizationMode? mode,
    double? autoDetectionThreshold,
  }) {
    return MultiAxisConfig(
      axes: axes ?? this.axes,
      bindings: bindings ?? this.bindings,
      mode: mode ?? this.mode,
      autoDetectionThreshold:
          autoDetectionThreshold ?? this.autoDetectionThreshold,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MultiAxisConfig) return false;
    if (axes.length != other.axes.length) return false;
    if (bindings.length != other.bindings.length) return false;
    for (var i = 0; i < axes.length; i++) {
      if (axes[i] != other.axes[i]) return false;
    }
    for (var i = 0; i < bindings.length; i++) {
      if (bindings[i] != other.bindings[i]) return false;
    }
    return mode == other.mode &&
        autoDetectionThreshold == other.autoDetectionThreshold;
  }

  @override
  int get hashCode {
    return Object.hash(
      Object.hashAll(axes),
      Object.hashAll(bindings),
      mode,
      autoDetectionThreshold,
    );
  }

  @override
  String toString() {
    return 'MultiAxisConfig(axes: $axes, bindings: $bindings, '
        'mode: $mode, autoDetectionThreshold: $autoDetectionThreshold)';
  }
}
