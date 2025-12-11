// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

import '../models/y_axis_config.dart';
import '../models/y_axis_position.dart';
import 'multi_axis_layout.dart';

/// Manages positioning of multiple Y-axes around the chart area.
///
/// Positions axes according to FR-001:
/// ```
/// [leftOuter] [left] | Chart Area | [right] [rightOuter]
/// ```
///
/// - leftOuter: Leftmost position
/// - left: Inside leftOuter, adjacent to plot area
/// - right: Right edge of plot area
/// - rightOuter: Rightmost position
///
/// Example:
/// ```dart
/// const manager = AxisLayoutManager();
/// final plotArea = manager.computePlotArea(
///   chartArea: chartRect,
///   axes: [axis1, axis2],
///   axisWidths: {'axis1': 50.0, 'axis2': 50.0},
/// );
/// ```
class AxisLayoutManager {
  /// Creates an axis layout manager.
  const AxisLayoutManager();

  final _layoutDelegate = const MultiAxisLayoutDelegate();

  /// Gets the rectangle for rendering a specific axis.
  ///
  /// [chartArea] is the total available chart area.
  /// [axis] is the axis configuration.
  /// [axisWidths] contains computed widths for all axes.
  /// [allAxes] is the complete list of axis configurations.
  ///
  /// Returns a [Rect] representing where the axis should be painted.
  /// The rect spans the full height of the chart area.
  Rect getAxisRect({
    required Rect chartArea,
    required YAxisConfig axis,
    required Map<String, double> axisWidths,
    required List<YAxisConfig> allAxes,
  }) {
    final axisWidth = axisWidths[axis.id] ?? axis.minWidth;

    switch (axis.position) {
      case YAxisPosition.leftOuter:
        // Leftmost position - starts at chartArea.left
        return Rect.fromLTWH(
          chartArea.left,
          chartArea.top,
          axisWidth,
          chartArea.height,
        );

      case YAxisPosition.left:
        // After leftOuter (if present)
        final leftOuterWidth = _getWidthAtPosition(
          YAxisPosition.leftOuter,
          allAxes,
          axisWidths,
        );
        return Rect.fromLTWH(
          chartArea.left + leftOuterWidth,
          chartArea.top,
          axisWidth,
          chartArea.height,
        );

      case YAxisPosition.right:
        // Before rightOuter (if present)
        final rightOuterWidth = _getWidthAtPosition(
          YAxisPosition.rightOuter,
          allAxes,
          axisWidths,
        );
        return Rect.fromLTWH(
          chartArea.right - rightOuterWidth - axisWidth,
          chartArea.top,
          axisWidth,
          chartArea.height,
        );

      case YAxisPosition.rightOuter:
        // Rightmost position - ends at chartArea.right
        return Rect.fromLTWH(
          chartArea.right - axisWidth,
          chartArea.top,
          axisWidth,
          chartArea.height,
        );
    }
  }

  /// Computes the plot area after reserving space for axes.
  ///
  /// Returns the rectangle available for chart data rendering
  /// after accounting for all axis widths.
  ///
  /// Parameters:
  /// - [chartArea]: The total available chart area
  /// - [axes]: List of axis configurations
  /// - [axisWidths]: Map from axis ID to computed width
  ///
  /// Returns a [Rect] that excludes space reserved for axes.
  Rect computePlotArea({
    required Rect chartArea,
    required List<YAxisConfig> axes,
    required Map<String, double> axisWidths,
  }) {
    if (axes.isEmpty) {
      return chartArea;
    }

    final totalLeftWidth = _layoutDelegate.getTotalLeftWidth(axes, axisWidths);
    final totalRightWidth =
        _layoutDelegate.getTotalRightWidth(axes, axisWidths);

    return Rect.fromLTRB(
      chartArea.left + totalLeftWidth,
      chartArea.top,
      chartArea.right - totalRightWidth,
      chartArea.bottom,
    );
  }

  /// Gets the total width of axes at a specific position.
  ///
  /// Only counts visible axes - invisible axes don't contribute to positioning.
  double _getWidthAtPosition(
    YAxisPosition position,
    List<YAxisConfig> allAxes,
    Map<String, double> axisWidths,
  ) {
    var total = 0.0;
    for (final axis in allAxes) {
      // Skip invisible axes - they don't take up space
      if (!axis.visible) continue;

      if (axis.position == position) {
        total += axisWidths[axis.id] ?? 0.0;
      }
    }
    return total;
  }
}
