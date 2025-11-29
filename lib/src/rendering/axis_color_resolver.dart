// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Resolves axis colors from configuration or bound series.
///
/// This library provides the [AxisColorResolver] class for determining
/// the effective color of a Y-axis in multi-axis charts.
library;

import 'dart:ui' show Color;

import '../models/chart_series.dart';
import '../models/series_axis_binding.dart';
import '../models/y_axis_config.dart';

/// Resolves the effective color for a Y-axis.
///
/// Color resolution priority:
/// 1. Explicit [YAxisConfig.color] if set
/// 2. Color of first bound [ChartSeries]
/// 3. Default color (configurable)
///
/// This implements FR-007: "Each Y-axis MUST support color-coding to match
/// its bound series."
///
/// Example:
/// ```dart
/// final color = AxisColorResolver.resolveAxisColor(
///   powerAxis,
///   bindings,
///   series,
/// );
/// ```
class AxisColorResolver {
  /// Private constructor - this is a utility class with static methods only.
  const AxisColorResolver._();

  /// Default color when no other color source is available.
  ///
  /// This gray color (0xFF333333) is used as a fallback when:
  /// - The axis has no explicit color set
  /// - No series is bound to the axis
  /// - The bound series has no color set
  static const Color defaultAxisColor = Color(0xFF333333);

  /// Resolves the effective color for a Y-axis.
  ///
  /// Resolution priority:
  /// 1. Return [YAxisConfig.color] if non-null
  /// 2. Find bindings where binding.yAxisId == axis.id
  /// 3. Find first matching series by seriesId from those bindings
  /// 4. Return series.color if non-null
  /// 5. Return [defaultColor]
  ///
  /// For shared axes (multiple series bound to one axis), the color of the
  /// first bound series is used.
  ///
  /// [axis] is the Y-axis configuration to resolve color for.
  /// [bindings] is the list of series-to-axis bindings.
  /// [series] is the list of data series.
  /// [defaultColor] is the fallback color (defaults to [defaultAxisColor]).
  ///
  /// Returns the resolved color for the axis.
  ///
  /// Example:
  /// ```dart
  /// // Axis with explicit color - uses blue
  /// final powerAxis = YAxisConfig(
  ///   id: 'power',
  ///   position: YAxisPosition.left,
  ///   color: Colors.blue,
  /// );
  /// final color = AxisColorResolver.resolveAxisColor(powerAxis, [], []);
  /// // color == Colors.blue
  ///
  /// // Axis without color - derives from bound series
  /// final hrAxis = YAxisConfig(
  ///   id: 'heartrate',
  ///   position: YAxisPosition.right,
  ///   color: null,
  /// );
  /// final hrBinding = SeriesAxisBinding(seriesId: 'hr', yAxisId: 'heartrate');
  /// final hrSeries = ChartSeries(id: 'hr', points: [], color: Colors.red);
  /// final hrColor = AxisColorResolver.resolveAxisColor(
  ///   hrAxis,
  ///   [hrBinding],
  ///   [hrSeries],
  /// );
  /// // hrColor == Colors.red
  /// ```
  static Color resolveAxisColor(
    YAxisConfig axis,
    List<SeriesAxisBinding> bindings,
    List<ChartSeries> series, {
    Color defaultColor = defaultAxisColor,
  }) {
    // Priority 1: Explicit axis color
    if (axis.color != null) {
      return axis.color!;
    }

    // Priority 2-4: Find color from bound series
    // Find all bindings for this axis
    for (final binding in bindings) {
      if (binding.yAxisId == axis.id) {
        // Find the series with matching ID
        for (final s in series) {
          if (s.id == binding.seriesId) {
            // Return series color if set
            if (s.color != null) {
              return s.color!;
            }
            // Series found but has no color - continue to check other bindings
            break;
          }
        }
      }
    }

    // Priority 5: Default color
    return defaultColor;
  }
}
