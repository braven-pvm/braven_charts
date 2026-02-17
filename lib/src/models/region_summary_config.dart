// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'region_summary.dart';

/// Position of the region summary overlay relative to the region.
///
/// Controls where computed statistics are displayed when a user
/// selects or highlights a region on the chart.
enum RegionSummaryPosition {
  /// Display the summary above the selected region.
  aboveRegion,

  /// Display the summary inside the region, aligned to the top.
  insideTop,

  /// Display the summary inside the region, aligned to the bottom.
  insideBottom,
}

/// Configuration for region summary display and computation.
///
/// Controls which [RegionMetric]s are computed and displayed,
/// how values are formatted, and where the summary overlay appears.
///
/// Example:
/// ```dart
/// final config = RegionSummaryConfig(
///   metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.average},
///   valueFormatter: (value, unit) =>
///       '${value.toStringAsFixed(1)}${unit != null ? ' $unit' : ''}',
///   position: RegionSummaryPosition.aboveRegion,
/// );
/// ```
class RegionSummaryConfig {
  /// Creates a [RegionSummaryConfig] with optional overrides.
  ///
  /// [metrics] defaults to `{RegionMetric.min, RegionMetric.max, RegionMetric.average}`.
  /// [valueFormatter] defaults to `null` (uses default formatting).
  /// [position] defaults to [RegionSummaryPosition.aboveRegion].
  RegionSummaryConfig({
    this.metrics = const {
      RegionMetric.min,
      RegionMetric.max,
      RegionMetric.average,
    },
    this.valueFormatter,
    this.position = RegionSummaryPosition.aboveRegion,
  });

  /// The set of metrics to compute and display for selected regions.
  ///
  /// Defaults to `{RegionMetric.min, RegionMetric.max, RegionMetric.average}`.
  /// Can be empty to suppress all metric display.
  final Set<RegionMetric> metrics;

  /// Optional custom formatter for metric values.
  ///
  /// Receives the numeric value and an optional unit string.
  /// Returns a formatted string for display.
  ///
  /// When null, a default formatting strategy is used.
  final String Function(double, String?)? valueFormatter;

  /// Where to position the summary overlay relative to the region.
  ///
  /// Defaults to [RegionSummaryPosition.aboveRegion].
  final RegionSummaryPosition position;
}
