import '../models/chart_series.dart';
import '../models/candlestick_chart_series.dart';
import '../models/donut_chart_series.dart';
import '../models/pie_chart_series.dart';
import '../models/polar_column_chart_series.dart';
import '../models/radial_bar_chart_series.dart';
import '../models/radial_category_series.dart';
import '../models/range_area_chart_series.dart';
import 'polar_column_composition.dart';

/// Internal coordinate/composition family selected for a chart.
///
/// Only [cartesian] and [partitionRadial] have public series implementations
/// today. The remaining values reserve distinct runtime branches for approved
/// chart families; they are not enabled by [ChartLayoutResolver] until their
/// validated public models exist.
enum ChartLayoutKind {
  cartesian,
  partitionRadial,
  polarAxis,
  hierarchicalRadial,
  gauge,
}

/// Resolves and validates the coordinate family for a chart composition.
class ChartLayoutResolver {
  const ChartLayoutResolver._();

  /// Returns the required layout and rejects unsupported mixed compositions.
  static ChartLayoutKind resolve(Iterable<ChartSeries> series) {
    final allSeries = List<ChartSeries>.unmodifiable(series);
    final radialSeries = allSeries.whereType<RadialCategorySeries>().toList();
    final polarSeries = allSeries.whereType<PolarColumnChartSeries>().toList();
    final radialBarSeries = allSeries
        .whereType<RadialBarChartSeries>()
        .toList();
    final invalidRadialHints = allSeries.where(
      (candidate) => switch (candidate.style) {
        SeriesStyle.pie => candidate is! PieChartSeries,
        SeriesStyle.donut => candidate is! DonutChartSeries,
        SeriesStyle.polarColumn => candidate is! PolarColumnChartSeries,
        SeriesStyle.radialBar => candidate is! RadialBarChartSeries,
        SeriesStyle.candlestick => candidate is! CandlestickChartSeries,
        SeriesStyle.rangeArea => candidate is! RangeAreaChartSeries,
        _ => false,
      },
    );

    if (invalidRadialHints.isNotEmpty) {
      final invalid = invalidRadialHints.first;
      throw ArgumentError.value(
        invalid.runtimeType,
        'series',
        switch (invalid.style) {
          SeriesStyle.pie => 'SeriesStyle.pie requires a PieChartSeries',
          SeriesStyle.donut => 'SeriesStyle.donut requires a DonutChartSeries',
          SeriesStyle.polarColumn =>
            'SeriesStyle.polarColumn requires a PolarColumnChartSeries',
          SeriesStyle.radialBar =>
            'SeriesStyle.radialBar requires a RadialBarChartSeries',
          SeriesStyle.candlestick =>
            'SeriesStyle.candlestick requires a CandlestickChartSeries',
          SeriesStyle.rangeArea =>
            'SeriesStyle.rangeArea requires a RangeAreaChartSeries',
          _ => 'Series style does not match its concrete series type',
        },
      );
    }
    if (radialBarSeries.isNotEmpty) {
      if (allSeries.length != radialBarSeries.length) {
        throw ArgumentError.value(
          allSeries.length,
          'series',
          'Radial Bar cannot be mixed with Cartesian, Polar Column, Pie, or '
              'Donut series',
        );
      }
      if (radialBarSeries.length != 1) {
        throw ArgumentError.value(
          radialBarSeries.length,
          'series',
          'Radial Bar v0.1 accepts exactly one RadialBarChartSeries',
        );
      }
      return ChartLayoutKind.polarAxis;
    }
    if (polarSeries.isNotEmpty) {
      if (allSeries.length != polarSeries.length) {
        throw ArgumentError.value(
          allSeries.length,
          'series',
          'Polar Column cannot be mixed with Cartesian, Pie, or Donut series',
        );
      }
      PolarColumnComposition.validate(polarSeries);
      return ChartLayoutKind.polarAxis;
    }
    if (radialSeries.isNotEmpty && allSeries.length != radialSeries.length) {
      throw ArgumentError.value(
        allSeries.length,
        'series',
        'Pie, Donut, and Cartesian series cannot be mixed in one chart',
      );
    }
    if (radialSeries.length > 1) {
      final pies = radialSeries.whereType<PieChartSeries>().length;
      final donuts = radialSeries.whereType<DonutChartSeries>().length;
      if (pies > 0 && donuts > 0) {
        throw ArgumentError.value(
          radialSeries.length,
          'series',
          'Pie and Donut series cannot be mixed in one radial chart',
        );
      }
      if (pies > 1) {
        throw ArgumentError.value(
          pies,
          'series',
          'A Pie chart accepts exactly one PieChartSeries',
        );
      }
      final ids = <String>{};
      for (final donut in radialSeries.whereType<DonutChartSeries>()) {
        if (!ids.add(donut.id)) {
          throw ArgumentError.value(
            donut.id,
            'series',
            'Concentric Donut series IDs must be unique',
          );
        }
      }
    }
    final candlestickSeries = allSeries
        .whereType<CandlestickChartSeries>()
        .toList(growable: false);
    if (candlestickSeries.length > 1) {
      throw ArgumentError.value(
        candlestickSeries.length,
        'series',
        'A Cartesian chart accepts at most one CandlestickChartSeries in v1',
      );
    }
    if (candlestickSeries.isNotEmpty &&
        allSeries.any((candidate) => candidate is BarChartSeries)) {
      throw ArgumentError.value(
        allSeries.length,
        'series',
        'Candlestick and Bar series cannot share one plot in v1',
      );
    }
    return radialSeries.isEmpty
        ? ChartLayoutKind.cartesian
        : ChartLayoutKind.partitionRadial;
  }
}
