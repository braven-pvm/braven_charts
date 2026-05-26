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
      // ignore: deprecated_member_use_from_same_package
      case YAxisPosition.leftOuter:
        // leftOuter axes stack from chartArea.left outward, amongst themselves.
        var precedingWidth = 0.0;
        for (final a in allAxes) {
          if (a.id == axis.id) break;
          // ignore: deprecated_member_use_from_same_package
          if (a.position == YAxisPosition.leftOuter && a.visible) {
            precedingWidth += axisWidths[a.id] ?? 0.0;
          }
        }
        return Rect.fromLTWH(
          chartArea.left + precedingWidth,
          chartArea.top,
          axisWidth,
          chartArea.height,
        );

      case YAxisPosition.left:
        // left axes stack after all leftOuter axes, outward from plot area.
        // Compute total leftOuter width to find the starting offset.
        var leftOuterTotal = 0.0;
        for (final a in allAxes) {
          // ignore: deprecated_member_use_from_same_package
          if (a.position == YAxisPosition.leftOuter && a.visible) {
            leftOuterTotal += axisWidths[a.id] ?? 0.0;
          }
        }
        // Count preceding left axes to stack this one after them.
        var precedingLeftWidth = 0.0;
        for (final a in allAxes) {
          if (a.id == axis.id) break;
          if (a.position == YAxisPosition.left && a.visible) {
            precedingLeftWidth += axisWidths[a.id] ?? 0.0;
          }
        }
        return Rect.fromLTWH(
          chartArea.left + leftOuterTotal + precedingLeftWidth,
          chartArea.top,
          axisWidth,
          chartArea.height,
        );

      case YAxisPosition.right:
        // right axes stack from the plot area edge outward (to the right).
        // Compute total rightOuter width so right axes don't overlap with them.
        var rightOuterTotal = 0.0;
        for (final a in allAxes) {
          // ignore: deprecated_member_use_from_same_package
          if (a.position == YAxisPosition.rightOuter && a.visible) {
            rightOuterTotal += axisWidths[a.id] ?? 0.0;
          }
        }
        // Count preceding right axes to stack this one outward from them.
        var precedingRightWidth = 0.0;
        for (final a in allAxes) {
          if (a.id == axis.id) break;
          if (a.position == YAxisPosition.right && a.visible) {
            precedingRightWidth += axisWidths[a.id] ?? 0.0;
          }
        }
        return Rect.fromLTWH(
          chartArea.right - rightOuterTotal - precedingRightWidth - axisWidth,
          chartArea.top,
          axisWidth,
          chartArea.height,
        );

      // ignore: deprecated_member_use_from_same_package
      case YAxisPosition.rightOuter:
        // rightOuter axes stack from chartArea.right inward, amongst themselves.
        var precedingWidth = 0.0;
        for (final a in allAxes) {
          if (a.id == axis.id) break;
          // ignore: deprecated_member_use_from_same_package
          if (a.position == YAxisPosition.rightOuter && a.visible) {
            precedingWidth += axisWidths[a.id] ?? 0.0;
          }
        }
        return Rect.fromLTWH(
          chartArea.right - precedingWidth - axisWidth,
          chartArea.top,
          axisWidth,
          chartArea.height,
        );

      case YAxisPosition.hidden:
        return Rect.zero;
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


}
