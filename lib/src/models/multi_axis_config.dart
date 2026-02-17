/// Multi-axis configuration container for charts.
///
/// This library provides the [MultiAxisConfig] class that combines all
/// multi-axis configuration components into a single container.
library;

import 'package:flutter/foundation.dart' show listEquals;

import 'normalization_mode.dart';
import 'series_axis_binding.dart';
import 'y_axis_config.dart';

/// Container for multi-axis chart configuration.
///
/// Combines axis configurations, series-to-axis bindings, and normalization
/// mode into a single configuration object that can be passed to chart widgets.
///
/// Example:
/// ```dart
/// final config = MultiAxisConfig(
///   axes: [
///     YAxisConfig(id: 'power', position: YAxisPosition.left, unit: 'W'),
///     YAxisConfig(id: 'hr', position: YAxisPosition.right, unit: 'bpm'),
///   ],
///   bindings: [
///     SeriesAxisBinding(seriesId: 'power-series', yAxisId: 'power'),
///     SeriesAxisBinding(seriesId: 'hr-series', yAxisId: 'hr'),
///   ],
///   mode: NormalizationMode.auto,
/// );
///
/// // Helper methods
/// final powerAxis = config.getAxisById('power');
/// final axisForSeries = config.getAxisForSeries('hr-series');
/// final hrBindings = config.getBindingsForAxis('hr');
/// ```
class MultiAxisConfig {
  /// Creates a multi-axis configuration.
  ///
  /// All parameters are optional with sensible defaults:
  /// - [axes] defaults to an empty list
  /// - [bindings] defaults to an empty list
  /// - [mode] defaults to [NormalizationMode.auto]
  const MultiAxisConfig({
    this.axes = const [],
    this.bindings = const [],
    this.mode = NormalizationMode.auto,
  });

  /// List of Y-axis configurations.
  ///
  /// Each axis should have a unique [YAxisConfig.id] for binding purposes.
  final List<YAxisConfig> axes;

  /// List of series-to-axis bindings.
  ///
  /// Each binding associates a series ID with an axis ID.
  final List<SeriesAxisBinding> bindings;

  /// Normalization mode controlling when data normalization is applied.
  final NormalizationMode mode;

  /// Returns the axis configuration with the given [id], or null if not found.
  ///
  /// Example:
  /// ```dart
  /// final powerAxis = config.getAxisById('power');
  /// if (powerAxis != null) {
  ///   print('Power axis position: ${powerAxis.position}');
  /// }
  /// ```
  YAxisConfig? getAxisById(String id) {
    for (final axis in axes) {
      if (axis.id == id) {
        return axis;
      }
    }
    return null;
  }

  /// Returns the axis configuration for the given [seriesId], or null if not found.
  ///
  /// This method first finds the binding for the series, then looks up the
  /// corresponding axis. Returns null if either the binding or axis is not found.
  ///
  /// Example:
  /// ```dart
  /// final axis = config.getAxisForSeries('power-series');
  /// if (axis != null) {
  ///   print('Series uses axis: ${axis.id}');
  /// }
  /// ```
  YAxisConfig? getAxisForSeries(String seriesId) {
    for (final binding in bindings) {
      if (binding.seriesId == seriesId) {
        return getAxisById(binding.yAxisId);
      }
    }
    return null;
  }

  /// Returns all bindings for the given [axisId].
  ///
  /// Returns an empty list if no bindings reference the axis.
  /// Multiple series can share the same axis.
  ///
  /// Example:
  /// ```dart
  /// final bindings = config.getBindingsForAxis('shared-axis');
  /// print('${bindings.length} series share this axis');
  /// ```
  List<SeriesAxisBinding> getBindingsForAxis(String axisId) {
    return bindings.where((binding) => binding.yAxisId == axisId).toList();
  }

  /// Creates a copy of this configuration with specified properties overridden.
  MultiAxisConfig copyWith({
    List<YAxisConfig>? axes,
    List<SeriesAxisBinding>? bindings,
    NormalizationMode? mode,
  }) {
    return MultiAxisConfig(
      axes: axes ?? this.axes,
      bindings: bindings ?? this.bindings,
      mode: mode ?? this.mode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MultiAxisConfig &&
        listEquals(other.axes, axes) &&
        listEquals(other.bindings, bindings) &&
        other.mode == mode;
  }

  @override
  int get hashCode =>
      Object.hash(Object.hashAll(axes), Object.hashAll(bindings), mode);

  @override
  String toString() {
    return 'MultiAxisConfig('
        'axes: ${axes.length} axes, '
        'bindings: ${bindings.length} bindings, '
        'mode: $mode'
        ')';
  }
}
