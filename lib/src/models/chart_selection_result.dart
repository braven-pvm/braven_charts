import 'package:flutter/foundation.dart';

import '../artifacts/chart_view_state.dart';
import 'chart_data_point.dart';
import 'chart_selection_point_bounds.dart';

/// One selected datum paired with its stable chart reference.
@immutable
class ChartSelectionPoint {
  const ChartSelectionPoint({
    required this.reference,
    required this.point,
    required this.seriesName,
  });

  /// Stable series and source-point identity.
  final ChartPointRef reference;

  /// Source datum represented by [reference].
  final ChartDataPoint point;

  /// Human-readable series name at the time the result was produced.
  final String seriesName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSelectionPoint &&
          other.reference == reference &&
          other.point == point &&
          other.seriesName == seriesName;

  @override
  int get hashCode => Object.hash(reference, point, seriesName);
}

/// Inclusive two-dimensional bounds of the selected finite data points.
@immutable
class ChartSelectionDataExtents {
  const ChartSelectionDataExtents({
    required this.minimumX,
    required this.maximumX,
    required this.minimumY,
    required this.maximumY,
  });

  final double minimumX;
  final double maximumX;
  final double minimumY;
  final double maximumY;

  double get width => maximumX - minimumX;
  double get height => maximumY - minimumY;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSelectionDataExtents &&
          other.minimumX == minimumX &&
          other.maximumX == maximumX &&
          other.minimumY == minimumY &&
          other.maximumY == maximumY;

  @override
  int get hashCode => Object.hash(minimumX, maximumX, minimumY, maximumY);
}

/// Descriptive statistics for one finite numeric selection channel.
@immutable
class ChartSelectionMetricSummary {
  const ChartSelectionMetricSummary({
    required this.count,
    required this.minimum,
    required this.maximum,
    required this.sum,
    required this.mean,
  });

  final int count;
  final double minimum;
  final double maximum;
  final double sum;
  final double mean;

  /// Summarizes finite values and ignores null, NaN, and infinite entries.
  static ChartSelectionMetricSummary? summarize(Iterable<double?> values) {
    var count = 0;
    var minimum = double.infinity;
    var maximum = double.negativeInfinity;
    var sum = 0.0;
    for (final value in values) {
      if (value == null || !value.isFinite) continue;
      count++;
      minimum = value < minimum ? value : minimum;
      maximum = value > maximum ? value : maximum;
      sum += value;
    }
    if (count == 0) return null;
    return ChartSelectionMetricSummary(
      count: count,
      minimum: minimum,
      maximum: maximum,
      sum: sum,
      mean: sum / count,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSelectionMetricSummary &&
          other.count == count &&
          other.minimum == minimum &&
          other.maximum == maximum &&
          other.sum == sum &&
          other.mean == mean;

  @override
  int get hashCode => Object.hash(count, minimum, maximum, sum, mean);
}

/// Aggregate statistics derived from the complete durable selection.
@immutable
class ChartSelectionStatistics {
  const ChartSelectionStatistics({
    required this.pointCount,
    required this.seriesCount,
    this.x,
    this.y,
    this.magnitude,
    this.colorValue,
    this.opacityValue,
    this.categoryCounts = const {},
  });

  final int pointCount;
  final int seriesCount;
  final ChartSelectionMetricSummary? x;
  final ChartSelectionMetricSummary? y;
  final ChartSelectionMetricSummary? magnitude;
  final ChartSelectionMetricSummary? colorValue;
  final ChartSelectionMetricSummary? opacityValue;

  /// Frequency of each non-empty categorical Scatter value.
  final Map<String, int> categoryCounts;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSelectionStatistics &&
          other.pointCount == pointCount &&
          other.seriesCount == seriesCount &&
          other.x == x &&
          other.y == y &&
          other.magnitude == magnitude &&
          other.colorValue == colorValue &&
          other.opacityValue == opacityValue &&
          mapEquals(other.categoryCounts, categoryCounts);

  @override
  int get hashCode => Object.hash(
    pointCount,
    seriesCount,
    x,
    y,
    magnitude,
    colorValue,
    opacityValue,
    Object.hashAllUnordered(
      categoryCounts.entries.map(
        (entry) => Object.hash(entry.key, entry.value),
      ),
    ),
  );
}

/// Stable identities, source values, extents, and aggregates for a selection.
@immutable
class ChartSelectionResult {
  const ChartSelectionResult.empty()
    : points = const [],
      pointRefs = const [],
      extents = null,
      statistics = const ChartSelectionStatistics(
        pointCount: 0,
        seriesCount: 0,
      );

  const ChartSelectionResult._({
    required this.points,
    required this.pointRefs,
    required this.extents,
    required this.statistics,
  });

  /// Builds a result from points already ordered by stable chart identity.
  factory ChartSelectionResult.fromPoints(
    Iterable<ChartSelectionPoint> selectedPoints,
  ) {
    final points = List<ChartSelectionPoint>.unmodifiable(selectedPoints);
    if (points.isEmpty) return const ChartSelectionResult.empty();

    final x = ChartSelectionMetricSummary.summarize(
      points.map((selection) => selection.point.x),
    );
    final y = ChartSelectionMetricSummary.summarize(
      points.map((selection) => selection.point.y),
    );
    final yBounds = <({double minimum, double maximum})>[
      for (final selection in points)
        ?chartSelectionPointYBounds(selection.point),
    ];
    final minimumY = yBounds.isEmpty
        ? null
        : yBounds
              .map((bounds) => bounds.minimum)
              .reduce((first, second) => first < second ? first : second);
    final maximumY = yBounds.isEmpty
        ? null
        : yBounds
              .map((bounds) => bounds.maximum)
              .reduce((first, second) => first > second ? first : second);
    final categories = <String, int>{};
    for (final selection in points) {
      final category = selection.point.categoryValue;
      if (category == null || category.isEmpty) continue;
      categories.update(category, (count) => count + 1, ifAbsent: () => 1);
    }

    return ChartSelectionResult._(
      points: points,
      pointRefs: List<ChartPointRef>.unmodifiable(
        points.map((selection) => selection.reference),
      ),
      extents: x == null || minimumY == null || maximumY == null
          ? null
          : ChartSelectionDataExtents(
              minimumX: x.minimum,
              maximumX: x.maximum,
              minimumY: minimumY,
              maximumY: maximumY,
            ),
      statistics: ChartSelectionStatistics(
        pointCount: points.length,
        seriesCount: points
            .map((selection) => selection.reference.seriesId)
            .toSet()
            .length,
        x: x,
        y: y,
        magnitude: ChartSelectionMetricSummary.summarize(
          points.map((selection) => selection.point.magnitude),
        ),
        colorValue: ChartSelectionMetricSummary.summarize(
          points.map((selection) => selection.point.colorValue),
        ),
        opacityValue: ChartSelectionMetricSummary.summarize(
          points.map((selection) => selection.point.opacityValue),
        ),
        categoryCounts: Map<String, int>.unmodifiable(categories),
      ),
    );
  }

  /// Selected points in deterministic series/source-index order.
  final List<ChartSelectionPoint> points;

  /// Stable identities in the same order as [points].
  ///
  /// Pair these with the attached controller's current effective document
  /// revision when issuing revision-bound focus or selection commands.
  final List<ChartPointRef> pointRefs;

  /// Finite X/Y bounds, or null when the selection has no finite coordinates.
  final ChartSelectionDataExtents? extents;

  final ChartSelectionStatistics statistics;

  bool get isEmpty => points.isEmpty;
  bool get isNotEmpty => points.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSelectionResult &&
          listEquals(other.points, points) &&
          listEquals(other.pointRefs, pointRefs) &&
          other.extents == extents &&
          other.statistics == statistics;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(points),
    Object.hashAll(pointRefs),
    extents,
    statistics,
  );
}
