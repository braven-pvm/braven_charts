import '../../artifacts/chart_view_state.dart';
import '../../models/bar_chart_style.dart';
import '../../models/chart_series.dart';
import '../../models/heatmap_chart_series.dart';
import '../../models/interaction_config.dart';
import '../../models/polar_chart_config.dart';
import '../../models/polar_column_chart_series.dart';
import '../../models/radar_chart_series.dart';
import '../../models/radial_bar_chart_series.dart';
import '../../models/radial_category_series.dart';
import '../core/data_hit.dart';

/// Stable semantic identities produced after a gesture acquires chart hits.
class ChartSelectionTargets {
  const ChartSelectionTargets({
    this.pointRefs = const <ChartPointRef>{},
    this.seriesIds = const <String>{},
  });

  final Set<ChartPointRef> pointRefs;
  final Set<String> seriesIds;
}

/// Resolves renderer hits into durable source identities.
///
/// Acquisition remains renderer-specific, but selection meaning lives here so
/// tap, rectangle, lasso, keyboard, and future domain brushes share exactly
/// the same category and stack semantics.
class ChartSelectionResolver {
  const ChartSelectionResolver._();

  static ChartSelectionTargets resolve({
    required ChartSelectionScope scope,
    required Iterable<ChartDataHit> hits,
    required Iterable<ChartSeries> series,
    HeatmapSelectionExpansion heatmapExpansion = HeatmapSelectionExpansion.cell,
    PolarChartConfig? polarChartConfig,
  }) {
    final acquiredHits = hits.toList(growable: false);
    final allSeries = series.toList(growable: false);
    final seriesById = <String, ChartSeries>{
      for (final candidate in allSeries) candidate.id: candidate,
    };

    // Direct renderer hits describe marks. The dual-target scope therefore
    // resolves them as marks only; complete-series activation is committed by
    // the path-target branch before this resolver is called.
    final seriesIds = scope == ChartSelectionScope.wholeSeries
        ? <String>{for (final hit in acquiredHits) hit.seriesId}
        : <String>{};
    if (scope == ChartSelectionScope.wholeSeries) {
      return ChartSelectionTargets(seriesIds: seriesIds);
    }

    final refs = <ChartPointRef>{};
    for (final hit in acquiredHits) {
      final sourceSeries = seriesById[hit.seriesId];
      if (sourceSeries == null) continue;
      switch (scope) {
        case ChartSelectionScope.mark:
        case ChartSelectionScope.markOrWholeSeries:
          if (sourceSeries is HeatmapChartSeries &&
              heatmapExpansion != HeatmapSelectionExpansion.cell) {
            _addExpandedHeatmapRefs(refs, hit, sourceSeries, heatmapExpansion);
          } else {
            _addRepresentedRefs(refs, hit, sourceSeries);
          }
          break;
        case ChartSelectionScope.category:
          if (_usesLabelCategoryIdentity(sourceSeries)) {
            final categoryLabels = _representedCategoryLabels(
              hit,
              sourceSeries,
            );
            for (final candidate in allSeries.where(
              _usesLabelCategoryIdentity,
            )) {
              _addPointsAtCategoryLabels(refs, candidate, categoryLabels);
            }
          } else {
            final categoryValues = _representedXValues(hit, sourceSeries);
            for (final candidate in allSeries) {
              _addPointsAtXValues(refs, candidate, categoryValues);
            }
          }
          break;
        case ChartSelectionScope.categoryStack:
          if (sourceSeries case final BarChartSeries sourceBar) {
            final categoryValues = _representedXValues(hit, sourceBar);
            for (final candidate in allSeries.whereType<BarChartSeries>()) {
              if (_sharesBarCompositionSlot(sourceBar, candidate)) {
                _addPointsAtXValues(refs, candidate, categoryValues);
              }
            }
          } else if (sourceSeries case final PolarColumnChartSeries sourcePolar
              when polarChartConfig?.composition.mode ==
                  PolarColumnCompositionMode.stacked) {
            final stackKeys = _representedPolarStackKeys(hit, sourcePolar);
            for (final candidate
                in allSeries.whereType<PolarColumnChartSeries>()) {
              _addPolarPointsAtStackKeys(refs, candidate, stackKeys);
            }
          }
          break;
        case ChartSelectionScope.wholeSeries:
          throw StateError('Series scope is resolved before point scopes.');
      }
    }
    return ChartSelectionTargets(pointRefs: refs, seriesIds: seriesIds);
  }

  static void _addRepresentedRefs(
    Set<ChartPointRef> refs,
    ChartDataHit hit,
    ChartSeries sourceSeries,
  ) {
    for (final pointIndex in hit.effectiveSourcePointIndices) {
      if (pointIndex < 0 || pointIndex >= sourceSeries.points.length) continue;
      refs.add(ChartPointRef(seriesId: hit.seriesId, pointIndex: pointIndex));
    }
  }

  static void _addExpandedHeatmapRefs(
    Set<ChartPointRef> refs,
    ChartDataHit hit,
    HeatmapChartSeries sourceSeries,
    HeatmapSelectionExpansion expansion,
  ) {
    final coordinates = <double>{};
    for (final pointIndex in hit.effectiveSourcePointIndices) {
      if (pointIndex < 0 || pointIndex >= sourceSeries.cells.length) continue;
      final cell = sourceSeries.cellAt(pointIndex);
      coordinates.add(
        expansion == HeatmapSelectionExpansion.row ? cell.y : cell.x,
      );
    }
    if (coordinates.isEmpty) return;

    final filter = sourceSeries.valueFilter;
    for (
      var pointIndex = 0;
      pointIndex < sourceSeries.cells.length;
      pointIndex++
    ) {
      final cell = sourceSeries.cellAt(pointIndex);
      final coordinate = expansion == HeatmapSelectionExpansion.row
          ? cell.y
          : cell.x;
      if (!coordinates.contains(coordinate)) continue;
      if (filter != null &&
          filter.mode == HeatmapValueFilterMode.hide &&
          !filter.includes(cell)) {
        continue;
      }
      refs.add(
        ChartPointRef(seriesId: sourceSeries.id, pointIndex: pointIndex),
      );
    }
  }

  static Set<double> _representedXValues(
    ChartDataHit hit,
    ChartSeries sourceSeries,
  ) => <double>{
    for (final pointIndex in hit.effectiveSourcePointIndices)
      if (pointIndex >= 0 && pointIndex < sourceSeries.points.length)
        if (sourceSeries.points[pointIndex].x.isFinite)
          sourceSeries.points[pointIndex].x,
  };

  static Set<String> _representedCategoryLabels(
    ChartDataHit hit,
    ChartSeries sourceSeries,
  ) => <String>{
    for (final pointIndex in hit.effectiveSourcePointIndices)
      if (pointIndex >= 0 && pointIndex < sourceSeries.points.length)
        if (sourceSeries.points[pointIndex].label case final String label)
          if (label.isNotEmpty) label,
  };

  static Set<(String, int)> _representedPolarStackKeys(
    ChartDataHit hit,
    PolarColumnChartSeries sourceSeries,
  ) => <(String, int)>{
    for (final pointIndex in hit.effectiveSourcePointIndices)
      if (pointIndex >= 0 && pointIndex < sourceSeries.points.length)
        if (sourceSeries.points[pointIndex] case final point
            when point.isValid && point.hasLabel)
          (point.label!, point.y < 0 ? -1 : 1),
  };

  static void _addPointsAtXValues(
    Set<ChartPointRef> refs,
    ChartSeries series,
    Set<double> xValues,
  ) {
    if (xValues.isEmpty) return;
    for (var pointIndex = 0; pointIndex < series.points.length; pointIndex++) {
      final point = series.points[pointIndex];
      if (point.isValid && xValues.contains(point.x)) {
        refs.add(ChartPointRef(seriesId: series.id, pointIndex: pointIndex));
      }
    }
  }

  static void _addPointsAtCategoryLabels(
    Set<ChartPointRef> refs,
    ChartSeries series,
    Set<String> categoryLabels,
  ) {
    if (categoryLabels.isEmpty) return;
    for (var pointIndex = 0; pointIndex < series.points.length; pointIndex++) {
      final point = series.points[pointIndex];
      if (point.isValid && categoryLabels.contains(point.label)) {
        refs.add(ChartPointRef(seriesId: series.id, pointIndex: pointIndex));
      }
    }
  }

  static void _addPolarPointsAtStackKeys(
    Set<ChartPointRef> refs,
    PolarColumnChartSeries series,
    Set<(String, int)> stackKeys,
  ) {
    if (stackKeys.isEmpty) return;
    for (var pointIndex = 0; pointIndex < series.points.length; pointIndex++) {
      final point = series.points[pointIndex];
      if (point.isValid &&
          point.hasLabel &&
          stackKeys.contains((point.label!, point.y < 0 ? -1 : 1))) {
        refs.add(ChartPointRef(seriesId: series.id, pointIndex: pointIndex));
      }
    }
  }

  static bool _usesLabelCategoryIdentity(ChartSeries series) =>
      series is RadialCategorySeries ||
      series is PolarColumnChartSeries ||
      series is RadarChartSeries ||
      series is RadialBarChartSeries;

  static bool _sharesBarCompositionSlot(
    BarChartSeries source,
    BarChartSeries candidate,
  ) {
    if (source.orientation != candidate.orientation ||
        source.layoutMode != candidate.layoutMode) {
      return false;
    }
    if (source.layoutMode == BarLayoutMode.grouped ||
        source.layoutMode == BarLayoutMode.waterfall) {
      return source.id == candidate.id;
    }
    return _resolvedAxisId(source) == _resolvedAxisId(candidate) &&
        source.baselineValue == candidate.baselineValue &&
        (source.groupId ?? '__default__') ==
            (candidate.groupId ?? '__default__');
  }

  static String _resolvedAxisId(BarChartSeries series) =>
      series.yAxisId ?? series.yAxisConfig?.id ?? '__default__';
}
