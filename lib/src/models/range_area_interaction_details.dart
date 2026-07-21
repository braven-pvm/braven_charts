// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'range_area_data_point.dart';

/// Renderer-neutral interval values carried by Range Area interaction.
///
/// One instance represents the complete low/high identity at a tracked X.
/// Consumers must not infer either boundary from the inherited midpoint Y.
class RangeAreaInteractionDetails {
  const RangeAreaInteractionDetails({
    required this.low,
    required this.high,
    required this.midpoint,
    required this.span,
    required this.formattedLow,
    required this.formattedHigh,
    required this.formattedMidpoint,
    required this.formattedSpan,
    this.timestamp,
    this.formattedTimestamp,
  }) : assert(low <= high),
       assert(midpoint >= low && midpoint <= high),
       assert(span >= 0);

  factory RangeAreaInteractionDetails.fromPoint(
    RangeAreaDataPoint point, {
    String? unit,
    String? formattedTimestamp,
  }) {
    if (point.isGap) {
      throw ArgumentError.value(point, 'point', 'must not be a gap');
    }
    return RangeAreaInteractionDetails.fromValues(
      low: point.low!,
      high: point.high!,
      unit: unit,
      timestamp: point.timestamp,
      formattedTimestamp: formattedTimestamp,
    );
  }

  factory RangeAreaInteractionDetails.fromValues({
    required double low,
    required double high,
    String? unit,
    DateTime? timestamp,
    String? formattedTimestamp,
  }) {
    RangeAreaDataPoint.validateInterval(x: 0, low: low, high: high);
    final suffix = unit == null || unit.isEmpty ? '' : ' $unit';
    String format(double value) => '${value.toStringAsFixed(2)}$suffix';
    final midpoint = (low + high) / 2;
    final span = high - low;
    return RangeAreaInteractionDetails(
      low: low,
      high: high,
      midpoint: midpoint,
      span: span,
      formattedLow: format(low),
      formattedHigh: format(high),
      formattedMidpoint: format(midpoint),
      formattedSpan: format(span),
      timestamp: timestamp,
      formattedTimestamp: formattedTimestamp,
    );
  }

  final double low;
  final double high;
  final double midpoint;
  final double span;
  final String formattedLow;
  final String formattedHigh;
  final String formattedMidpoint;
  final String formattedSpan;
  final DateTime? timestamp;
  final String? formattedTimestamp;

  /// Complete non-colour-only interval announcement.
  String get semanticLabel => [
    ?formattedTimestamp,
    'Low $formattedLow',
    'High $formattedHigh',
    'Midpoint $formattedMidpoint',
    'Span $formattedSpan',
  ].join(', ');
}
