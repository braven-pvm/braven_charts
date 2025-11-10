// Copyright 2025 Braven Charts - Simplified for BravenChartPlus
// SPDX-License-Identifier: MIT

/// Simplified AxisConfig for BravenChartPlus.
class AxisConfig {
  const AxisConfig({
    this.label,
    this.min,
    this.max,
    this.showGrid = true,
    this.showLabels = true,
  });
  final String? label;
  final double? min;
  final double? max;
  final bool showGrid;
  final bool showLabels;

  static const AxisConfig defaults = AxisConfig();
}
