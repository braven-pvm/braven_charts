import '../models/donut_chart_series.dart';
import '../models/radial_category_series.dart';
import 'multi_axis_value_formatter.dart';

/// Shared display formatting for every package-owned radial surface.
abstract final class RadialValueFormatters {
  /// Formats the primary contribution value.
  static String value(RadialCategorySeries series, double value) {
    final custom = series.dataLabels.valueFormatter;
    if (custom != null) return custom(value);
    final unit = series.unit == null || series.unit!.isEmpty
        ? ''
        : ' ${series.unit}';
    return '${value.toStringAsFixed(2)}$unit';
  }

  /// Formats a fractional contribution in the range zero to one.
  static String share(RadialCategorySeries series, double share) {
    final custom = series.dataLabels.percentageFormatter;
    if (custom != null) return custom(share);
    return '${(share * 100).toStringAsFixed(1)}%';
  }

  /// Formats the optional second metric controlling radial extent.
  static String radius(RadialCategorySeries series, double value) {
    final config = series.sliceRadiusConfig!;
    final custom = config.formatter;
    if (custom != null) return custom(value);
    final unit = config.unit == null || config.unit!.isEmpty
        ? ''
        : ' ${config.unit}';
    return '${value.toStringAsFixed(2)}$unit';
  }

  /// Formats a numeric Donut center value.
  static String center(RadialCategorySeries series, double value) {
    final custom = series is DonutChartSeries
        ? series.centerContent.valueFormatter
        : null;
    if (custom != null) return custom(value);
    return MultiAxisValueFormatter.format(value: value, unit: series.unit);
  }
}
