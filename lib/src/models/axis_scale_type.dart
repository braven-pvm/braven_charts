// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// How an axis maps data values to positions and generates ticks.
enum AxisScaleType {
  /// Values map linearly to positions (the default; unchanged behavior).
  linear,

  /// Values map on a log scale (base [XAxisConfig.logBase]); ticks are decades.
  log,

  /// Values are epoch-milliseconds; ticks land on calendar boundaries with
  /// date labels.
  time,
}
