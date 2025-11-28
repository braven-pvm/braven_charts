/// A binding that associates a data series with a Y-axis configuration.
///
/// In multi-axis charts, each data series needs to know which Y-axis it
/// belongs to for proper scaling and rendering. This class provides a
/// simple mapping between a series identifier and an axis identifier.
///
/// Multiple series can bind to the same axis if they have compatible
/// data ranges or units. The chart uses these bindings to look up the
/// appropriate [YAxisConfig] for each series during rendering.
///
/// Example:
/// ```dart
/// final binding = SeriesAxisBinding(
///   seriesId: 'power-series',
///   axisId: 'power-axis',
/// );
/// ```
///
/// See also:
/// - [YAxisConfig] - The axis configuration that [axisId] references
/// - [YAxisPosition] - The positions where axes can be rendered
class SeriesAxisBinding {
  /// Creates a binding between a data series and a Y-axis.
  ///
  /// Both [seriesId] and [axisId] are required and should match
  /// the identifiers used in your chart's data series and axis
  /// configurations respectively.
  const SeriesAxisBinding({
    required this.seriesId,
    required this.axisId,
  });

  /// The identifier of the data series.
  ///
  /// This should match the ID used to identify the series in your
  /// chart's data configuration.
  final String seriesId;

  /// The identifier of the Y-axis configuration.
  ///
  /// This should match the [YAxisConfig.id] of the axis that this
  /// series should be scaled against.
  final String axisId;

  /// Creates a copy of this binding with the given fields replaced.
  SeriesAxisBinding copyWith({
    String? seriesId,
    String? axisId,
  }) {
    return SeriesAxisBinding(
      seriesId: seriesId ?? this.seriesId,
      axisId: axisId ?? this.axisId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeriesAxisBinding && other.seriesId == seriesId && other.axisId == axisId;
  }

  @override
  int get hashCode => Object.hash(seriesId, axisId);

  @override
  String toString() => 'SeriesAxisBinding(seriesId: $seriesId, axisId: $axisId)';
}
