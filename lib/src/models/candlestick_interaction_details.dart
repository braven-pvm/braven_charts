// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'candlestick_chart_style.dart';
import 'candlestick_data_point.dart';

/// Renderer-neutral OHLC values carried by hover, tracking, and semantics.
class CandlestickInteractionDetails {
  const CandlestickInteractionDetails({
    required this.open,
    required this.high,
    required this.low,
    required this.close,
    required this.formattedOpen,
    required this.formattedHigh,
    required this.formattedLow,
    required this.formattedClose,
    required this.change,
    required this.changePercent,
    required this.formattedChange,
    required this.direction,
    this.timestamp,
    this.formattedTimestamp,
  });

  factory CandlestickInteractionDetails.fromPoint(
    CandlestickDataPoint point, {
    String? unit,
    String? formattedTimestamp,
  }) {
    final suffix = unit == null || unit.isEmpty ? '' : ' $unit';
    String format(double value) => '${value.toStringAsFixed(2)}$suffix';
    final change = point.close - point.open;
    final changePercent = point.open == 0 ? 0.0 : change / point.open * 100;
    final sign = change > 0 ? '+' : '';
    return CandlestickInteractionDetails(
      open: point.open,
      high: point.high,
      low: point.low,
      close: point.close,
      formattedOpen: format(point.open),
      formattedHigh: format(point.high),
      formattedLow: format(point.low),
      formattedClose: format(point.close),
      change: change,
      changePercent: changePercent,
      formattedChange:
          '$sign${change.toStringAsFixed(2)}$suffix ($sign${changePercent.toStringAsFixed(2)}%)',
      direction: point.direction,
      timestamp: point.timestamp,
      formattedTimestamp: formattedTimestamp,
    );
  }

  final double open;
  final double high;
  final double low;
  final double close;
  final String formattedOpen;
  final String formattedHigh;
  final String formattedLow;
  final String formattedClose;
  final double change;
  final double changePercent;
  final String formattedChange;
  final CandlestickDirection direction;
  final DateTime? timestamp;
  final String? formattedTimestamp;

  /// Complete non-colour-only OHLC announcement.
  String get semanticLabel => [
    ?formattedTimestamp,
    'Open $formattedOpen',
    'High $formattedHigh',
    'Low $formattedLow',
    'Close $formattedClose',
    'Change $formattedChange',
    direction.name,
  ].join(', ');
}
