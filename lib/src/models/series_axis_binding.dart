/// Series-to-axis binding model for multi-axis charts.
///
/// This library provides the [SeriesAxisBinding] class that associates
/// a data series with a Y-axis by their string IDs.
library;

/// Associates a data series with a Y-axis by their IDs.
///
/// This is a lightweight value object that binds series to axes using
/// string IDs rather than object references. This keeps the binding
/// model simple and flexible.
///
/// Multiple series can share the same axis by using the same [yAxisId].
///
/// Example:
/// ```dart
/// // Bind power series to left axis
/// const powerBinding = SeriesAxisBinding(
///   seriesId: 'power',
///   yAxisId: 'power-axis',
/// );
///
/// // Multiple series can share an axis
/// const hrBinding = SeriesAxisBinding(
///   seriesId: 'heartrate',
///   yAxisId: 'shared-axis',
/// );
///
/// const cadenceBinding = SeriesAxisBinding(
///   seriesId: 'cadence',
///   yAxisId: 'shared-axis',  // Same axis as heartrate
/// );
/// ```
class SeriesAxisBinding {
  /// Creates a binding between a series and a Y-axis.
  ///
  /// Both [seriesId] and [yAxisId] must be non-empty strings.
  ///
  /// - [seriesId] should match the `id` property of a `ChartSeries`
  /// - [yAxisId] should match the `id` property of a `YAxisConfig`
  const SeriesAxisBinding({required this.seriesId, required this.yAxisId})
    : assert(seriesId != '', 'seriesId must be non-empty'),
      assert(yAxisId != '', 'yAxisId must be non-empty');

  /// ID of the data series.
  ///
  /// This should match the `id` property of the corresponding `ChartSeries`.
  final String seriesId;

  /// ID of the Y-axis.
  ///
  /// This should match the `id` property of the corresponding `YAxisConfig`.
  final String yAxisId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeriesAxisBinding &&
        other.seriesId == seriesId &&
        other.yAxisId == yAxisId;
  }

  @override
  int get hashCode => Object.hash(seriesId, yAxisId);

  @override
  String toString() =>
      'SeriesAxisBinding(seriesId: $seriesId, yAxisId: $yAxisId)';
}
