import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../models/polar_column_chart_series.dart';

/// Cumulative radial start and end values for one stacked source series.
@immutable
class PolarColumnStackSeriesLayout {
  PolarColumnStackSeriesLayout({
    required this.seriesId,
    required List<double> starts,
    required List<double> ends,
  }) : starts = UnmodifiableListView(starts),
       ends = UnmodifiableListView(ends);

  final String seriesId;
  final List<double> starts;
  final List<double> ends;
}

/// Resolved positive/negative stack geometry before conversion to radii.
///
/// Positive and negative values use independent accumulators that both begin
/// at zero. Opposite signs never cancel each other. Source values and row
/// identity remain on the original series; this layout only supplies radial
/// start and end positions to the renderer.
@immutable
class PolarColumnStackLayout {
  PolarColumnStackLayout._({
    required List<PolarColumnStackSeriesLayout> series,
    required this.minimum,
    required this.maximum,
  }) : series = UnmodifiableListView(series);

  final List<PolarColumnStackSeriesLayout> series;
  final double minimum;
  final double maximum;

  PolarColumnStackSeriesLayout forSeries(String seriesId) =>
      series.firstWhere((layout) => layout.seriesId == seriesId);

  /// Resolves one diverging radial stack in declaration order.
  factory PolarColumnStackLayout.resolve(List<PolarColumnChartSeries> series) {
    if (series.length < 2) {
      throw ArgumentError.value(
        series.length,
        'series',
        'Stacked Polar Column composition requires at least two series',
      );
    }
    final categoryCount = series.first.points.length;
    final positive = List<double>.filled(categoryCount, 0);
    final negative = List<double>.filled(categoryCount, 0);
    final layouts = <PolarColumnStackSeriesLayout>[];
    var minimum = 0.0;
    var maximum = 0.0;

    for (final source in series) {
      if (source.points.length != categoryCount) {
        throw ArgumentError.value(
          source.id,
          'series',
          'Stacked Polar Column series must use the same category count',
        );
      }
      final starts = <double>[];
      final ends = <double>[];
      for (final (index, point) in source.points.indexed) {
        final value = point.y;
        final start = value >= 0 ? positive[index] : negative[index];
        final end = start + value;
        starts.add(start);
        ends.add(end);
        if (value >= 0) {
          positive[index] = end;
          if (end > maximum) maximum = end;
        } else {
          negative[index] = end;
          if (end < minimum) minimum = end;
        }
      }
      layouts.add(
        PolarColumnStackSeriesLayout(
          seriesId: source.id,
          starts: starts,
          ends: ends,
        ),
      );
    }

    return PolarColumnStackLayout._(
      series: layouts,
      minimum: minimum,
      maximum: maximum,
    );
  }
}
