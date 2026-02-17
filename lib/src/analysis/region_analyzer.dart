// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Stateless utility for analyzing data within chart regions.
///
/// Provides methods for filtering data points by X-range, computing
/// per-series statistical summaries, and aggregating results into
/// [RegionSummary] objects.
///
/// All methods are stateless — data is provided by the caller and
/// analysis is performed on-demand. No internal caching or persistence.
///
/// Method implementations will be added in subsequent phases.
library;

/// Stateless utility class for region data analysis.
///
/// Computes statistical summaries for data points within a
/// specified X-axis range. Supports binary search for sorted
/// data and linear scan for unsorted data.
///
/// Example:
/// ```dart
/// const analyzer = RegionAnalyzer();
/// // Method implementations coming in later phases.
/// ```
class RegionAnalyzer {
  /// Creates a [RegionAnalyzer] instance.
  const RegionAnalyzer();
}
