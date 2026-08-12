import '../models/radar_chart_series.dart';

/// Identity-safe interpolation for Radar profiles.
///
/// Radar categories are identified by their visible labels. A value update may
/// reorder those labels, but it must never morph one category into another.
abstract final class RadarSeriesTransition {
  static bool isCompatible(RadarChartSeries from, RadarChartSeries to) {
    if (from.id != to.id || from.points.length != to.points.length) {
      return false;
    }
    return from.categories.toSet().containsAll(to.categories) &&
        to.categories.toSet().containsAll(from.categories);
  }

  static RadarChartSeries interpolate({
    required RadarChartSeries from,
    required RadarChartSeries to,
    required double progress,
  }) {
    if (!isCompatible(from, to)) {
      throw ArgumentError(
        'Radar transitions require the same series ID and category identities',
      );
    }
    final t = progress.clamp(0.0, 1.0);
    final fromValues = <String, double>{
      for (final point in from.points) point.label!.trim(): point.y,
    };
    return to.copyWith(
      points: [
        for (final point in to.points)
          point.copyWith(
            y:
                fromValues[point.label!.trim()]! +
                (point.y - fromValues[point.label!.trim()]!) * t,
          ),
      ],
    );
  }
}
