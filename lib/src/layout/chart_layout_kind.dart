import '../models/chart_series.dart';
import '../models/pie_chart_series.dart';

/// Internal chart-coordinate family selected for a series composition.
enum ChartLayoutKind { cartesian, radial }

/// Resolves and validates the coordinate family for a chart composition.
class ChartLayoutResolver {
  const ChartLayoutResolver._();

  /// Returns the required layout and rejects unsupported mixed compositions.
  static ChartLayoutKind resolve(Iterable<ChartSeries> series) {
    final allSeries = List<ChartSeries>.unmodifiable(series);
    final pieSeries = allSeries.whereType<PieChartSeries>().toList();
    final invalidPieHints = allSeries.where(
      (candidate) =>
          candidate.style == SeriesStyle.pie && candidate is! PieChartSeries,
    );

    if (invalidPieHints.isNotEmpty) {
      throw ArgumentError.value(
        invalidPieHints.first.runtimeType,
        'series',
        'SeriesStyle.pie requires a PieChartSeries',
      );
    }
    if (pieSeries.length > 1) {
      throw ArgumentError.value(
        pieSeries.length,
        'series',
        'A pie chart accepts exactly one PieChartSeries',
      );
    }
    if (pieSeries.isNotEmpty && allSeries.length != 1) {
      throw ArgumentError.value(
        allSeries.length,
        'series',
        'Pie and Cartesian series cannot be mixed in one chart',
      );
    }
    return pieSeries.isEmpty
        ? ChartLayoutKind.cartesian
        : ChartLayoutKind.radial;
  }
}
