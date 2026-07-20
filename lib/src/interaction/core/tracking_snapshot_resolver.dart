// Copyright 2025 Braven Charts
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart' show internal;

import '../../artifacts/chart_view_state.dart' show ChartPointRef;
import '../../axis/series_axis_resolver.dart';
import '../../coordinates/chart_transform.dart';
import '../../elements/annotation_elements.dart' show TrendAnnotationElement;
import '../../elements/series_element.dart' show SeriesElement;
import '../../formatting/multi_axis_value_formatter.dart';
import '../../models/chart_series.dart' show ScatterChartSeries;
import '../../models/interaction_config.dart' show CrosshairSeriesValue;
import '../../rendering/modules/crosshair_renderer.dart' show MultiAxisInfo;
import 'cartesian_tracking_snapshot.dart';
import 'chart_element.dart' show ChartElement;
import 'crosshair_tracker.dart';

/// Resolves Cartesian tracking state into published
/// [CartesianTrackingSnapshot]s with change suppression.
///
/// This is the single resolution point for tracking-mode crosshair values.
/// It ports the enrichment previously performed inside
/// `CrosshairRenderer._paintTrackingMode` — base tracking resolution via
/// [CrosshairTracker.calculateTrackingState], plot-space two-dimensional
/// Scatter replacement, and trend-annotation merging — and attaches the
/// display-ready formatting that `_paintTrackingTooltip` derives from
/// [MultiAxisInfo], so consumers never reach back into paint-coupled state.
///
/// **Change suppression** (two levels):
///
/// 1. *Input memoization* — re-resolving with unchanged inputs (cursor
///    position, plot area, transform, origin, trend inclusion, interpolation
///    flag, and data revision) returns the cached [current] snapshot without
///    recomputation. Element and axis-info instances are deliberately not
///    part of the cache key: both are rebuilt freely by the render pipeline,
///    so data or configuration changes must be signaled through
///    `dataRevision` or [invalidate].
/// 2. *Identity suppression* — a recomputed snapshot whose
///    [CartesianTrackingSnapshot.sameIdentityAs] matches [current] keeps the
///    previously published instance, so sub-pixel cursor movement over the
///    same snapped datum never republishes. Forced invalidation ([invalidate]
///    or a `dataRevision` change) bypasses this suppression: identity excludes
///    presentation fields, so a forced recomputation always publishes fresh.
///
/// [debugResolveCount] counts every [resolve] call; [debugPublishCount]
/// counts only publications (including the transition to a null snapshot when
/// tracking leaves the plot); [debugComputeCount] counts only actual snapshot
/// computations (memoized cache hits do not compute). All exist so tests and
/// benchmarks can prove the one-resolution-per-interaction-frame contract.
@internal
class CartesianTrackingSnapshotResolver {
  CartesianTrackingSnapshot? _current;
  int _debugResolveCount = 0;
  int _debugPublishCount = 0;
  int _debugComputeCount = 0;
  bool _publishedThisFrame = false;

  // Memoized resolve inputs. Null means no memoized resolution exists.
  Offset? _lastCursorPlotPosition;
  Rect? _lastPlotArea;
  ChartTransform? _lastTransform;
  CartesianTrackingOrigin? _lastOrigin;
  bool? _lastIncludeTrends;
  bool? _lastInterpolateValues;
  int? _lastDataRevision;

  /// The most recently published snapshot, or null when the last resolution
  /// produced no tracking state.
  CartesianTrackingSnapshot? get current => _current;

  /// Whether the most recent [resolve] call changed [current].
  bool get publishedThisFrame => _publishedThisFrame;

  /// Number of [resolve] calls made against this resolver.
  int get debugResolveCount => _debugResolveCount;

  /// Number of times [resolve] published a changed snapshot (including the
  /// transition from a snapshot to null).
  int get debugPublishCount => _debugPublishCount;

  /// Number of actual snapshot computations (input-cache misses). Memoized
  /// [resolve] calls with unchanged inputs never increment this.
  int get debugComputeCount => _debugComputeCount;

  /// Clears the memoized inputs so the next [resolve] recomputes.
  ///
  /// [current] is dropped (without publishing) so the forced recomputation
  /// always publishes its fresh instance, even when it matches the prior
  /// snapshot's [CartesianTrackingSnapshot.sameIdentityAs] identity. Identity
  /// excludes presentation fields such as the series color and name, so
  /// retaining the old instance here would keep painting stale theme state.
  /// Identity suppression continues to apply to recomputations that were not
  /// forced (cursor movement within the same snapped datum).
  void invalidate() {
    _clearMemoizedInputs();
    _current = null;
  }

  /// Publishes a null snapshot when the tracking source goes away without a
  /// [resolve] call — the tracking-mode gate turning off, the cursor leaving
  /// the chart, or resolution prerequisites (transform, plot area)
  /// disappearing.
  ///
  /// Clearing an already-null [current] is a no-op. The memoized inputs are
  /// reset with the snapshot so a later [resolve] with identical inputs
  /// recomputes instead of returning the cleared null through the cache.
  void clear() {
    final published = _current != null;
    if (published) {
      _current = null;
      _debugPublishCount++;
    }
    _publishedThisFrame = published;
    _clearMemoizedInputs();
  }

  void _clearMemoizedInputs() {
    _lastCursorPlotPosition = null;
    _lastPlotArea = null;
    _lastTransform = null;
    _lastOrigin = null;
    _lastIncludeTrends = null;
    _lastInterpolateValues = null;
    _lastDataRevision = null;
  }

  /// Resolves the tracking snapshot for [cursorPlotPosition].
  ///
  /// [cursorPlotPosition] is plot-local (the same space `dataHitAt` uses);
  /// [plotArea] is the plot rectangle in chart screen space, and together
  /// they reconstruct the screen-space cursor the tracker requires.
  /// [elements] is the current element list; series and trend-annotation
  /// elements are consumed, all others ignored. [axisInfo] supplies the
  /// per-series unit resolution used for display formatting. [origin]
  /// records the interaction source on the published snapshot.
  /// [includeTrends] controls whether trend-annotation values are appended
  /// (the value summary keeps them opt-in). [interpolateValues] mirrors
  /// `CrosshairConfig.interpolateValues`. [dataRevision] participates in the
  /// input cache key; bump it (or call [invalidate]) whenever series data
  /// changes without any other input changing.
  ///
  /// Returns the published snapshot, the identity-suppressed prior instance,
  /// or null when the cursor resolves no tracking state.
  CartesianTrackingSnapshot? resolve({
    required Offset cursorPlotPosition,
    required Rect plotArea,
    required ChartTransform transform,
    required List<ChartElement> elements,
    required MultiAxisInfo axisInfo,
    required CartesianTrackingOrigin origin,
    required bool includeTrends,
    bool interpolateValues = true,
    int dataRevision = 0,
  }) {
    _debugResolveCount++;

    final cacheHit =
        _lastCursorPlotPosition == cursorPlotPosition &&
        _lastPlotArea == plotArea &&
        _lastTransform == transform &&
        _lastOrigin == origin &&
        _lastIncludeTrends == includeTrends &&
        _lastInterpolateValues == interpolateValues &&
        _lastDataRevision == dataRevision;
    if (cacheHit) {
      _publishedThisFrame = false;
      return _current;
    }

    // A dataRevision change is a forced invalidation: the recomputed snapshot
    // must be published even when its identity matches [current], because
    // identity excludes presentation fields (series color/name, formatted X)
    // that the revision bump may have changed.
    final revisionForced =
        _lastDataRevision != null && _lastDataRevision != dataRevision;

    _lastCursorPlotPosition = cursorPlotPosition;
    _lastPlotArea = plotArea;
    _lastTransform = transform;
    _lastOrigin = origin;
    _lastIncludeTrends = includeTrends;
    _lastInterpolateValues = interpolateValues;
    _lastDataRevision = dataRevision;

    _debugComputeCount++;
    final snapshot = _resolveSnapshot(
      cursorPlotPosition: cursorPlotPosition,
      plotArea: plotArea,
      transform: transform,
      elements: elements,
      axisInfo: axisInfo,
      origin: origin,
      includeTrends: includeTrends,
      interpolateValues: interpolateValues,
    );

    if (snapshot == null) {
      _publishedThisFrame = _current != null;
      if (_current != null) {
        _current = null;
        _debugPublishCount++;
      }
      return null;
    }

    final previous = _current;
    if (!revisionForced &&
        previous != null &&
        snapshot.sameIdentityAs(previous)) {
      _publishedThisFrame = false;
      return previous;
    }

    _current = snapshot;
    _debugPublishCount++;
    _publishedThisFrame = true;
    return snapshot;
  }

  CartesianTrackingSnapshot? _resolveSnapshot({
    required Offset cursorPlotPosition,
    required Rect plotArea,
    required ChartTransform transform,
    required List<ChartElement> elements,
    required MultiAxisInfo axisInfo,
    required CartesianTrackingOrigin origin,
    required bool includeTrends,
    required bool interpolateValues,
  }) {
    final seriesElements = <SeriesElement>[
      for (final element in elements)
        if (element is SeriesElement) element,
    ];

    // Calculate tracking state — ported from
    // CrosshairRenderer._paintTrackingMode. The renderer works in chart
    // screen space, so the screen-space cursor is reconstructed from the
    // plot-local position.
    final cursorPosition = plotArea.topLeft + cursorPlotPosition;
    final seriesList = [for (final element in seriesElements) element.series];
    final categoryScreenPosition = transform.transposed
        ? cursorPosition.dy
        : cursorPosition.dx;
    final trackingBounds = transform.transposed
        ? Rect.fromLTWH(plotArea.top, 0, plotArea.height, 1)
        : plotArea;
    final trackingState = CrosshairTracker.calculateTrackingState(
      screenX: categoryScreenPosition,
      chartBounds: trackingBounds,
      xMin: transform.dataXMin,
      xMax: transform.dataXMax,
      seriesList: seriesList,
      interpolate: interpolateValues,
      includeScatterXFallback: false,
    );

    if (trackingState == null) return null;

    // Line and Area tracking is X-oriented, while Scatter is an unordered
    // two-dimensional sample. Replace the fallback nearest-X Scatter values
    // with plot-space nearest points using each element's effective transform
    // (including per-series multi-axis normalization).
    for (final element in seriesElements) {
      final scatter = element.series;
      if (scatter is! ScatterChartSeries) continue;
      final hit = element.dataHitAt(
        cursorPlotPosition,
        maxDistance: double.infinity,
      );
      final nearest = hit == null
          ? null
          : CrosshairSeriesValue(
              seriesId: scatter.id,
              seriesName: scatter.displayName,
              seriesColor: hit.markerColor ?? element.themeColor,
              x: hit.point.x,
              y: hit.point.y,
              dataPointIndex: hit.pointIndex,
              isInterpolated: false,
              pointLabel: hit.point.label,
              magnitudeValue: hit.radiusValue,
              formattedMagnitudeValue: hit.formattedRadiusValue,
              magnitudeLabel: hit.radiusLabel,
              colorValue: hit.colorValue,
              formattedColorValue: hit.formattedColorValue,
              colorLabel: hit.colorLabel,
              opacityValue: hit.opacityValue,
              formattedOpacityValue: hit.formattedOpacityValue,
              opacityLabel: hit.opacityLabel,
              categoryValue: hit.categoryValue,
              categoryLabel: hit.categoryLabel,
            );
      final existingIndex = trackingState.seriesValues.indexWhere(
        (value) => value.seriesId == scatter.id,
      );
      if (nearest == null) {
        if (existingIndex >= 0) {
          trackingState.seriesValues.removeAt(existingIndex);
        }
      } else if (existingIndex >= 0) {
        trackingState.seriesValues[existingIndex] = nearest;
      } else {
        trackingState.seriesValues.add(nearest);
      }
    }

    // Append trend annotation values to tracking state.
    if (includeTrends) {
      for (final element in elements) {
        if (element is! TrendAnnotationElement) continue;
        final trendY = element.evaluateAt(trackingState.dataX);
        if (trendY == null) continue;

        final label = element.annotation.label;
        final displayName = (label != null && label.isNotEmpty)
            ? label
            : '${element.annotation.trendType.name} trend';

        trackingState.seriesValues.add(
          CrosshairSeriesValue(
            seriesId: element.annotation.id,
            seriesName: displayName,
            seriesColor: element.annotation.lineColor,
            x: trackingState.dataX,
            y: trendY,
            dataPointIndex: -1,
            isInterpolated: true,
            linkedSeriesId: element.annotation.seriesId,
            isTrend: true,
          ),
        );
      }
    }

    // Attach display-ready formatting — ported from
    // CrosshairRenderer._paintTrackingTooltip so the strings match what the
    // tooltip renders today.
    final values = <CartesianTrackedSeriesValue>[];
    for (final value in trackingState.seriesValues) {
      // Get unit from axis config for multi-axis mode.
      String? yUnit;
      if (axisInfo.effectiveAxes.length > 1) {
        final axisConfig = SeriesAxisResolver.resolveAxis(
          value.axisSeriesId,
          axisInfo.effectiveBindings,
          axisInfo.effectiveAxes,
        );
        yUnit = axisConfig?.unit;
      }

      values.add(
        CartesianTrackedSeriesValue.fromCrosshairValue(
          value,
          formattedX: _formatDataValue(value.x),
          formattedY: MultiAxisValueFormatter.format(
            value: value.y,
            unit: yUnit,
          ),
          unitLabel: yUnit,
        ),
      );
    }

    ChartPointRef? primaryPoint;
    for (final value in trackingState.seriesValues) {
      if (!value.isTrend && value.dataPointIndex >= 0) {
        primaryPoint = ChartPointRef(
          seriesId: value.seriesId,
          pointIndex: value.dataPointIndex,
        );
        break;
      }
    }

    final plotX =
        trackingState.screenX -
        (transform.transposed ? plotArea.top : plotArea.left);
    return CartesianTrackingSnapshot(
      dataX: trackingState.dataX,
      plotX: plotX,
      values: values,
      origin: origin,
      primaryPoint: primaryPoint,
    );
  }

  /// Formats data values for display.
  ///
  /// Ported verbatim from `CrosshairRenderer._formatDataValue` so per-value
  /// X formatting matches the tracking tooltip exactly.
  static String _formatDataValue(double value) {
    if ((value - value.round()).abs() < 0.0001) {
      return value.round().toString();
    }

    if (value.abs() < 0.01) {
      return value.toStringAsExponential(1);
    } else if (value.abs() < 1) {
      return value.toStringAsFixed(2);
    } else if (value.abs() < 100) {
      return value.toStringAsFixed(1);
    } else {
      return value.round().toString();
    }
  }
}
