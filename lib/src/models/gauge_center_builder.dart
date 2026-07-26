import 'package:flutter/material.dart';

import 'gauge_chart_series.dart';

/// Builds runtime-only content inside a Gauge's resolved center opening.
typedef GaugeCenterBuilder =
    Widget Function(BuildContext context, GaugeCenterContext center);

/// Immutable measurement and presentation state supplied to a Gauge center.
@immutable
class GaugeCenterContext {
  const GaugeCenterContext({
    required this.seriesId,
    required this.seriesName,
    required this.metric,
    required this.unit,
    required this.value,
    required this.formattedValue,
    required this.minimum,
    required this.maximum,
    required this.normalizedProgress,
    required this.target,
    required this.activeZone,
    required this.status,
    required this.indicatorColor,
    required this.availableSize,
  });

  final String seriesId;
  final String? seriesName;
  final String metric;
  final String? unit;
  final double value;
  final String formattedValue;
  final double minimum;
  final double maximum;
  final double normalizedProgress;
  final GaugeTarget? target;
  final GaugeZone? activeZone;
  final String? status;
  final Color indicatorColor;
  final Size availableSize;
}
