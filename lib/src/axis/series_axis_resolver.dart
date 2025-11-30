// Copyright (c) 2024 Braven. All rights reserved.
// SPDX-License-Identifier: Apache-2.0

import '../models/series_axis_binding.dart';
import '../models/y_axis_config.dart';

/// Resolves which Y-axis a series should render against.
///
/// Provides utility methods for mapping series to their corresponding Y-axis
/// configurations based on explicit bindings or default fallbacks.
///
/// This resolver is used by [ChartRenderBox] to determine axis assignment
/// for each series in a multi-axis chart.
///
/// Example:
/// ```dart
/// final axes = [
///   YAxisConfig(id: 'price', position: YAxisPosition.left),
///   YAxisConfig(id: 'volume', position: YAxisPosition.right),
/// ];
/// final bindings = [
///   SeriesAxisBinding(seriesId: 'series-1', axisId: 'price'),
///   SeriesAxisBinding(seriesId: 'series-2', axisId: 'volume'),
/// ];
///
/// // Returns 'price'
/// final axisId = SeriesAxisResolver.resolveAxisId('series-1', bindings, axes);
///
/// // Returns the YAxisConfig with id 'volume'
/// final axis = SeriesAxisResolver.resolveAxis('series-2', bindings, axes);
/// ```
class SeriesAxisResolver {
  /// Private constructor to prevent instantiation.
  const SeriesAxisResolver._();

  /// Resolves the axis ID for a given series.
  ///
  /// Returns the axis ID from the binding if one exists for [seriesId],
  /// otherwise returns the ID of the first axis in [axes], or 'default'
  /// if no axes are configured.
  ///
  /// Parameters:
  /// - [seriesId]: The unique identifier of the series
  /// - [bindings]: List of series-to-axis bindings
  /// - [axes]: List of available Y-axis configurations
  ///
  /// Returns the resolved axis ID string.
  static String resolveAxisId(
    String seriesId,
    List<SeriesAxisBinding> bindings,
    List<YAxisConfig> axes,
  ) {
    // Look for explicit binding first
    for (final binding in bindings) {
      if (binding.seriesId == seriesId) {
        return binding.yAxisId;
      }
    }

    // Fall back to first axis if available
    if (axes.isNotEmpty) {
      return axes.first.id;
    }

    // Ultimate fallback
    return 'default';
  }

  /// Resolves the [YAxisConfig] for a given series.
  ///
  /// First determines the axis ID using [resolveAxisId], then looks up
  /// the corresponding [YAxisConfig] from the [axes] list.
  ///
  /// Parameters:
  /// - [seriesId]: The unique identifier of the series
  /// - [bindings]: List of series-to-axis bindings
  /// - [axes]: List of available Y-axis configurations
  ///
  /// Returns the resolved [YAxisConfig], or `null` if no matching axis
  /// is found in [axes].
  static YAxisConfig? resolveAxis(
    String seriesId,
    List<SeriesAxisBinding> bindings,
    List<YAxisConfig> axes,
  ) {
    final axisId = resolveAxisId(seriesId, bindings, axes);

    for (final axis in axes) {
      if (axis.id == axisId) {
        return axis;
      }
    }

    return null;
  }
}
