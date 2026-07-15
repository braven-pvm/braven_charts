/// Self-contained storage projections supported by schema v1 extraction.
enum ChartDataStorage {
  inlinePoints('inlinePoints'),
  inlineColumns('inlineColumns');

  const ChartDataStorage(this.wireName);

  /// Stable schema identifier, independent of the Dart enum member name.
  final String wireName;
}
