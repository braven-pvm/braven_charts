import '../models/chart_series.dart';
import '../models/donut_chart_series.dart';
import '../models/pie_chart_series.dart';
import '../models/polar_column_chart_series.dart';
import '../models/radial_category_series.dart';

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
    final invalidRadialHints = allSeries.where(
      (candidate) => switch (candidate.style) {
        SeriesStyle.pie => candidate is! PieChartSeries,
        SeriesStyle.donut => candidate is! DonutChartSeries,
        SeriesStyle.polarColumn => candidate is! PolarColumnChartSeries,
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
          _ => 'Unsupported series style',
        },
      );
    }
    if (polarSeries.isNotEmpty) {
      if (allSeries.length != polarSeries.length) {
        throw ArgumentError.value(
          allSeries.length,
          'series',
          'Polar Column cannot be mixed with Cartesian, Pie, or Donut series',
        );
      }
      if (polarSeries.length != 1) {
        throw ArgumentError.value(
          polarSeries.length,
          'series',
          'Polar Column V1 accepts exactly one PolarColumnChartSeries',
        );
      }
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
    return radialSeries.isEmpty
        ? ChartLayoutKind.cartesian
        : ChartLayoutKind.partitionRadial;
  }
}
