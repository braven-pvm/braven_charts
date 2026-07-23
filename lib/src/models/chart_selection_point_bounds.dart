// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'candlestick_data_point.dart';
import 'chart_data_point.dart';
import 'range_area_data_point.dart';

/// The complete vertical data-space span represented by one selected datum.
///
/// Generic points occupy one Y value. Atomic interval families retain their
/// full tuple so selection zoom cannot crop Range Area boundaries or
/// Candlestick wicks around a midpoint/close value.
({double minimum, double maximum})? chartSelectionPointYBounds(
  ChartDataPoint point,
) {
  return switch (point) {
    RangeAreaDataPoint(:final isGap, :final low, :final high) =>
      isGap || low == null || high == null
          ? null
          : (minimum: low, maximum: high),
    CandlestickDataPoint(:final low, :final high) => (
      minimum: low,
      maximum: high,
    ),
    _ when point.y.isFinite => (minimum: point.y, maximum: point.y),
    _ => null,
  };
}

/// Whether the complete vertical tuple represented by [point] intersects a
/// closed data-space Y interval.
///
/// Atomic interval families such as Range Area and Candlestick must use their
/// full low/high tuple here. Resolving them through the inherited midpoint
/// would make durable selection disagree with the visible mark acquired by
/// the renderer.
bool chartSelectionPointIntersectsYInterval(
  ChartDataPoint point, {
  required double minimumYInclusive,
  required double maximumYInclusive,
}) {
  final bounds = chartSelectionPointYBounds(point);
  if (bounds == null) return false;
  return bounds.maximum >= minimumYInclusive &&
      bounds.minimum <= maximumYInclusive;
}
