// Copyright 2025 Braven Charts - Axis Color Resolution
// SPDX-License-Identifier: MIT
//
// T034 [US3] Axis color resolver implementation
// Resolves axis colors from explicit config or bound series colors.

import 'package:flutter/painting.dart' show Color;

import '../models/chart_series.dart';
import 'y_axis_config.dart';

/// Resolves colors for Y-axes based on configuration or bound series.
///
/// Color resolution priority:
/// 1. Explicit [YAxisConfig.color] if provided
/// 2. Color of first series bound to this axis
/// 3. [neutralColor] if no series bound
///
/// Example:
/// ```dart
/// // Resolve color for a single axis
/// final color = AxisColorResolver.resolveAxisColor(
///   axisConfig: powerAxis,
///   series: allSeries,
/// );
///
/// // Resolve colors for all axes at once
/// final colorMap = AxisColorResolver.resolveAllAxisColors(
///   axes: yAxes,
///   series: allSeries,
/// );
/// ```
class AxisColorResolver {
  /// Private constructor - use static methods only
  AxisColorResolver._();

  /// Neutral grey color for axes with no bound series.
  ///
  /// This is a medium grey that works well on both light and dark backgrounds.
  static const Color neutralColor = Color(0xFF9E9E9E); // Grey 500

  /// Resolves the color for a single axis.
  ///
  /// Resolution order:
  /// 1. [axisConfig.color] if explicitly set
  /// 2. Color of first series bound to this axis (by yAxisId match)
  /// 3. Color of unbound series if this is the first axis (default axis)
  /// 4. [neutralColor] if no match found
  ///
  /// [axisConfig] - The axis configuration to resolve color for
  /// [series] - All series in the chart
  /// [allAxes] - Optional list of all axes (to determine if this is first/default)
  static Color resolveAxisColor({
    required YAxisConfig axisConfig,
    required List<ChartSeries> series,
    List<YAxisConfig>? allAxes,
  }) {
    // Priority 1: Explicit color from config
    if (axisConfig.hasExplicitColor) {
      return axisConfig.color!;
    }

    // Determine if this is the first (default) axis
    final isFirstAxis = allAxes == null ||
        allAxes.isEmpty ||
        (allAxes.isNotEmpty && allAxes.first.id == axisConfig.id);

    // Priority 2 & 3: Get bound series and use first one's color
    final boundSeries = getBoundSeries(
      axisId: axisConfig.id,
      series: series,
      isFirstAxis: isFirstAxis,
    );

    if (boundSeries.isNotEmpty) {
      final firstSeriesColor = boundSeries.first.color;
      if (firstSeriesColor != null) {
        return firstSeriesColor;
      }
    }

    // Priority 4: Neutral color
    return neutralColor;
  }

  /// Resolves colors for all axes and returns a map of axis ID to color.
  ///
  /// This is more efficient than calling [resolveAxisColor] for each axis
  /// when you need colors for multiple axes.
  ///
  /// Returns: Map<String axisId, Color resolvedColor>
  static Map<String, Color> resolveAllAxisColors({
    required List<YAxisConfig> axes,
    required List<ChartSeries> series,
  }) {
    final colorMap = <String, Color>{};

    for (final axis in axes) {
      colorMap[axis.id] = resolveAxisColor(
        axisConfig: axis,
        series: series,
        allAxes: axes,
      );
    }

    return colorMap;
  }

  /// Gets all series bound to a specific axis.
  ///
  /// A series is considered bound to an axis if:
  /// 1. Its [yAxisId] matches the axis id exactly, OR
  /// 2. Its [yAxisId] is null AND this axis is the first (default)
  ///
  /// [axisId] - The axis identifier to find series for
  /// [series] - All series to search through
  /// [isFirstAxis] - Whether this is the first/default axis
  static List<ChartSeries> getBoundSeries({
    required String axisId,
    required List<ChartSeries> series,
    required bool isFirstAxis,
  }) {
    return series.where((s) {
      // Explicit binding to this axis
      if (s.yAxisId == axisId) {
        return true;
      }

      // Unbound series bind to first/default axis
      if (s.yAxisId == null && isFirstAxis) {
        return true;
      }

      return false;
    }).toList();
  }

  /// Determines if an axis should use a derived color from series.
  ///
  /// Returns true if:
  /// - The axis has no explicit color
  /// - There is at least one series bound to this axis
  static bool shouldDeriveColor({
    required YAxisConfig axisConfig,
    required List<ChartSeries> series,
    List<YAxisConfig>? allAxes,
  }) {
    if (axisConfig.hasExplicitColor) {
      return false;
    }

    final isFirstAxis = allAxes == null ||
        allAxes.isEmpty ||
        (allAxes.isNotEmpty && allAxes.first.id == axisConfig.id);

    final boundSeries = getBoundSeries(
      axisId: axisConfig.id,
      series: series,
      isFirstAxis: isFirstAxis,
    );

    return boundSeries.isNotEmpty;
  }
}
