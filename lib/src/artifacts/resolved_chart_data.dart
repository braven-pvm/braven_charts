import 'package:flutter/foundation.dart';

import '../models/chart_data_point.dart';
import '../models/chart_series.dart';

/// Creates a series for controller or live-stream data that has no matching
/// declarative series.
typedef ResolvedSeriesFactory =
    ChartSeries Function(
      String seriesId,
      List<ChartDataPoint> points,
      int seriesIndex,
    );

/// A synchronous snapshot of data committed through [LiveStreamController].
///
/// This is deliberately independent of the controller itself so resolution is
/// pure, deterministic, and straightforward to test.
@immutable
class ResolvedLiveSeriesData {
  const ResolvedLiveSeriesData({
    required this.seriesId,
    required this.points,
    required this.committedRevision,
    required this.pendingRevision,
    required this.pendingPointCount,
    this.pendingPoints = const [],
  });

  final String seriesId;
  final List<ChartDataPoint> points;
  final int committedRevision;
  final int pendingRevision;
  final int pendingPointCount;
  final List<ChartDataPoint> pendingPoints;
}

/// The chart's resolved data projections at one synchronous point in time.
///
/// The three projections intentionally have different responsibilities:
///
/// * [allSeries] is the full effective document data, including hidden series
///   and committed direct-stream points.
/// * [visibleSeries] applies the current visibility rules to [allSeries].
/// * [renderSeries] excludes direct-stream points because those are painted by
///   the RenderBox streaming path. Rendering them here would duplicate them.
///
/// The lists are unmodifiable. Their [ChartSeries] values remain the package's
/// existing immutable value objects; portable artifact extraction is
/// responsible for making a fully detached deep copy.
@immutable
class ResolvedChartData {
  ResolvedChartData._({
    required List<ChartSeries> allSeries,
    required List<ChartSeries> visibleSeries,
    required List<ChartSeries> renderSeries,
    required Set<String> hiddenSeriesIds,
    required this.controllerRevision,
    required this.committedStreamRevision,
    required this.pendingStreamRevision,
    required this.pendingStreamPointCount,
  }) : allSeries = List.unmodifiable(allSeries),
       visibleSeries = List.unmodifiable(visibleSeries),
       renderSeries = List.unmodifiable(renderSeries),
       hiddenSeriesIds = Set.unmodifiable(hiddenSeriesIds);

  factory ResolvedChartData.resolve({
    required Iterable<ChartSeries> baseSeries,
    required Set<String> hiddenSeriesIds,
    Map<String, List<ChartDataPoint>>? controllerSeries,
    int controllerRevision = 0,
    Iterable<ChartDataPoint> legacyStreamingPoints = const [],
    ResolvedLiveSeriesData? liveSeries,
    ResolvedSeriesFactory? seriesFactory,
  }) {
    final base = baseSeries.toList(growable: false);
    final resolvedWithoutDirectStream = _resolveWidgetManagedSeries(
      baseSeries: base,
      controllerSeries: controllerSeries,
      legacyStreamingPoints: legacyStreamingPoints,
      seriesFactory: seriesFactory,
    );

    final allSeries = _mergeDirectStream(
      series: resolvedWithoutDirectStream,
      liveSeries: liveSeries,
      seriesFactory: seriesFactory,
    );

    bool isVisible(ChartSeries series) => !hiddenSeriesIds.contains(series.id);

    return ResolvedChartData._(
      allSeries: allSeries,
      visibleSeries: allSeries.where(isVisible).toList(growable: false),
      renderSeries: resolvedWithoutDirectStream
          .where(isVisible)
          .toList(growable: false),
      hiddenSeriesIds: hiddenSeriesIds,
      controllerRevision: controllerRevision,
      committedStreamRevision: liveSeries?.committedRevision ?? 0,
      pendingStreamRevision: liveSeries?.pendingRevision ?? 0,
      pendingStreamPointCount: liveSeries?.pendingPointCount ?? 0,
    );
  }

  static final ResolvedChartData empty = ResolvedChartData._(
    allSeries: const [],
    visibleSeries: const [],
    renderSeries: const [],
    hiddenSeriesIds: const {},
    controllerRevision: 0,
    committedStreamRevision: 0,
    pendingStreamRevision: 0,
    pendingStreamPointCount: 0,
  );

  final List<ChartSeries> allSeries;
  final List<ChartSeries> visibleSeries;
  final List<ChartSeries> renderSeries;
  final Set<String> hiddenSeriesIds;

  final int controllerRevision;
  final int committedStreamRevision;
  final int pendingStreamRevision;
  final int pendingStreamPointCount;

  static List<ChartSeries> _resolveWidgetManagedSeries({
    required List<ChartSeries> baseSeries,
    required Map<String, List<ChartDataPoint>>? controllerSeries,
    required Iterable<ChartDataPoint> legacyStreamingPoints,
    required ResolvedSeriesFactory? seriesFactory,
  }) {
    if (controllerSeries != null) {
      final result = <ChartSeries>[];
      final processedIds = <String>{};

      for (final series in baseSeries) {
        final additionalPoints = controllerSeries[series.id];
        result.add(
          additionalPoints == null || additionalPoints.isEmpty
              ? series
              : series.copyWith(
                  points: List.unmodifiable([
                    ...series.points,
                    ...additionalPoints,
                  ]),
                ),
        );
        processedIds.add(series.id);
      }

      for (final entry in controllerSeries.entries) {
        if (processedIds.contains(entry.key)) continue;
        result.add(
          _createSeries(
            seriesId: entry.key,
            points: entry.value,
            seriesIndex: result.length,
            seriesFactory: seriesFactory,
          ),
        );
      }
      return result;
    }

    final legacyPoints = legacyStreamingPoints.toList(growable: false);
    if (legacyPoints.isEmpty || baseSeries.isEmpty) return baseSeries;

    return [
      baseSeries.first.copyWith(
        points: List.unmodifiable([
          ...baseSeries.first.points,
          ...legacyPoints,
        ]),
      ),
      ...baseSeries.skip(1),
    ];
  }

  static List<ChartSeries> _mergeDirectStream({
    required List<ChartSeries> series,
    required ResolvedLiveSeriesData? liveSeries,
    required ResolvedSeriesFactory? seriesFactory,
  }) {
    if (liveSeries == null ||
        (liveSeries.points.isEmpty && liveSeries.pendingPoints.isEmpty)) {
      return series;
    }

    final livePoints = [...liveSeries.points, ...liveSeries.pendingPoints];

    final result = <ChartSeries>[];
    var matched = false;
    for (final item in series) {
      if (item.id != liveSeries.seriesId) {
        result.add(item);
        continue;
      }

      matched = true;
      result.add(
        item.copyWith(
          points: List.unmodifiable([...item.points, ...livePoints]),
        ),
      );
    }

    if (!matched) {
      result.add(
        _createSeries(
          seriesId: liveSeries.seriesId,
          points: livePoints,
          seriesIndex: result.length,
          seriesFactory: seriesFactory,
        ),
      );
    }
    return result;
  }

  static ChartSeries _createSeries({
    required String seriesId,
    required List<ChartDataPoint> points,
    required int seriesIndex,
    required ResolvedSeriesFactory? seriesFactory,
  }) {
    final immutablePoints = List<ChartDataPoint>.unmodifiable(points);
    return seriesFactory?.call(seriesId, immutablePoints, seriesIndex) ??
        LineChartSeries(id: seriesId, name: seriesId, points: immutablePoints);
  }
}
