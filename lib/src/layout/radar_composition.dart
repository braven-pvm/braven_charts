import '../models/radar_chart_series.dart';

/// Validates the one-domain contract shared by all Radar profiles in a pane.
class RadarComposition {
  const RadarComposition._();

  static void validate(List<RadarChartSeries> series) {
    if (series.isEmpty) return;
    final ids = <String>{};
    final expectedCategories = series.first.categories;
    final expectedUnit = _normalizedUnit(series.first.unit);
    for (final candidate in series) {
      if (!ids.add(candidate.id)) {
        throw ArgumentError.value(
          candidate.id,
          'series',
          'Radar series IDs must be unique',
        );
      }
      if (!_same(candidate.categories, expectedCategories)) {
        throw ArgumentError.value(
          candidate.categories,
          'series',
          'Every Radar series must use the same categories in the same order',
        );
      }
      if (_normalizedUnit(candidate.unit) != expectedUnit) {
        throw ArgumentError.value(
          candidate.unit,
          'series',
          'Every Radar series must use the same shared unit',
        );
      }
    }
  }
}

String _normalizedUnit(String? value) => value?.trim() ?? '';

bool _same(List<String> first, List<String> second) {
  if (first.length != second.length) return false;
  for (var index = 0; index < first.length; index++) {
    if (first[index] != second[index]) return false;
  }
  return true;
}
