// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:ui';

import '../models/candlestick_chart_series.dart';
import '../models/candlestick_data_point.dart';

/// Stable OHLC interpolation for identity-compatible candlestick revisions.
abstract final class CandlestickSeriesTransition {
  static bool isCompatible(
    CandlestickChartSeries from,
    CandlestickChartSeries to,
  ) {
    if (from.id != to.id || from.points.length != to.points.length) {
      return false;
    }
    for (var index = 0; index < from.points.length; index++) {
      final fromPoint = from.candleAt(index);
      final toPoint = to.candleAt(index);
      if (fromPoint.x != toPoint.x ||
          fromPoint.timestamp != toPoint.timestamp) {
        return false;
      }
    }
    return true;
  }

  static CandlestickChartSeries interpolate({
    required CandlestickChartSeries from,
    required CandlestickChartSeries to,
    required double progress,
  }) {
    if (!isCompatible(from, to)) {
      throw ArgumentError('Candlestick series must have stable point identity');
    }
    final t = progress.clamp(0.0, 1.0);
    if (t == 0) return from;
    if (t == 1) return to;
    return to.copyWith(
      points: <CandlestickDataPoint>[
        for (var index = 0; index < to.points.length; index++)
          _interpolatePoint(from.candleAt(index), to.candleAt(index), t),
      ],
    );
  }

  static CandlestickDataPoint _interpolatePoint(
    CandlestickDataPoint from,
    CandlestickDataPoint to,
    double progress,
  ) => to.copyWith(
    open: lerpDouble(from.open, to.open, progress),
    high: lerpDouble(from.high, to.high, progress),
    low: lerpDouble(from.low, to.low, progress),
    close: lerpDouble(from.close, to.close, progress),
  );
}
