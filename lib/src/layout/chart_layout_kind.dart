import '../models/chart_series.dart';
import '../models/donut_chart_series.dart';
import '../models/pie_chart_series.dart';
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
    final invalidRadialHints = allSeries.where(
      (candidate) => switch (candidate.style) {
        SeriesStyle.pie => candidate is! PieChartSeries,
        SeriesStyle.donut => candidate is! DonutChartSeries,
        _ => false,
      },
    );

    if (invalidRadialHints.isNotEmpty) {
      final invalid = invalidRadialHints.first;
      throw ArgumentError.value(
        invalid.runtimeType,
        'series',
        invalid.style == SeriesStyle.pie
            ? 'SeriesStyle.pie requires a PieChartSeries'
            : 'SeriesStyle.donut requires a DonutChartSeries',
      );
    }
    if (radialSeries.length > 1) {
      throw ArgumentError.value(
        radialSeries.length,
        'series',
        'A radial chart accepts exactly one PieChartSeries or '
            'DonutChartSeries',
      );
    }
    if (radialSeries.isNotEmpty && allSeries.length != 1) {
      throw ArgumentError.value(
        allSeries.length,
        'series',
        'Pie, Donut, and Cartesian series cannot be mixed in one chart',
      );
    }
    return radialSeries.isEmpty
        ? ChartLayoutKind.cartesian
        : ChartLayoutKind.partitionRadial;
  }
}
