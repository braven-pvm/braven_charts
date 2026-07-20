import '../models/polar_chart_config.dart';
import '../models/polar_column_chart_series.dart';

/// Validates the shared-axis contract for a Polar Column composition.
///
/// Compatible series share category identity, preset, unit, and radial scale.
/// Layered series reuse a category band; grouped series divide it into stable
/// declaration-order sub-bands. Stacking remains a separate contract.
abstract final class PolarColumnComposition {
  /// Capability required by artifacts containing more than one Polar Column
  /// series.
  static const multipleSeriesCapability = 'chart.polar.multiple-series.v1';

  /// Capability required by grouped Polar Column artifacts.
  static const groupedSeriesCapability = 'chart.polar.grouped-series.v1';

  /// Throws when [series] cannot share one polar axis system.
  static void validate(
    List<PolarColumnChartSeries> series, {
    PolarChartConfig? config,
  }) {
    if (series.isEmpty) {
      throw ArgumentError.value(
        series,
        'series',
        'A Polar Column composition requires at least one series',
      );
    }

    final ids = <String>{};
    final reference = series.first;
    for (final candidate in series) {
      if (!ids.add(candidate.id)) {
        throw ArgumentError.value(
          candidate.id,
          'series',
          'Polar Column series IDs must be unique',
        );
      }
      if (!_sameCategories(reference.categories, candidate.categories)) {
        throw ArgumentError.value(
          candidate.id,
          'series',
          'Multiple Polar Column series must use the same categories in the '
              'same order',
        );
      }
      if (candidate.preset != reference.preset) {
        throw ArgumentError.value(
          candidate.id,
          'series',
          'Multiple Polar Column series must use the same preset',
        );
      }
      if (_normalizedUnit(candidate.unit) != _normalizedUnit(reference.unit)) {
        throw ArgumentError.value(
          candidate.id,
          'series',
          'Multiple Polar Column series must use the same unit',
        );
      }
    }
    if (config?.composition.mode == PolarColumnCompositionMode.grouped &&
        series.length < 2) {
      throw ArgumentError.value(
        series.length,
        'series',
        'Grouped Polar Column composition requires at least two series',
      );
    }
  }

  static bool _sameCategories(List<String> left, List<String> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  static String _normalizedUnit(String? unit) => (unit ?? '').trim();
}
