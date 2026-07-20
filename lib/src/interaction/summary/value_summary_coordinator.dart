// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// Frame-driven pipeline glue between the chart's tracking resolution and the
/// value summary overlay element.
///
/// The render box owns one [ValueSummaryCoordinator] and feeds it once per
/// paint frame with the already-resolved pointer/synchronized tracking
/// snapshot and the frame's resolution context. The coordinator applies the
/// value-source policy ([ValueSummaryReducer]), adapts the winning snapshot
/// into typed rows ([ValueSummaryAdapter]), and feeds the equality-guarded
/// [ValueSummaryOverlayElement] the render box paints in its foreground
/// element pass.
library;

import 'dart:ui' show Offset, Rect, TextDirection;

import 'package:flutter/foundation.dart'
    show Listenable, ValueChanged, VoidCallback, internal;
import 'package:flutter/scheduler.dart' show SchedulerBinding;

import '../../artifacts/chart_view_state.dart' show ChartPointRef;
import '../../coordinates/chart_transform.dart';
import '../../elements/series_element.dart' show SeriesElement;
import '../../elements/value_summary_layout.dart'
    show ResolvedValueSummaryStyle;
import '../../elements/value_summary_overlay_element.dart';
import '../../models/cartesian_value_summary_config.dart';
import '../../models/cartesian_value_summary_style.dart';
import '../../models/chart_overlay_placement.dart';
import '../../rendering/modules/crosshair_renderer.dart' show MultiAxisInfo;
import '../../theming/components/cartesian_value_summary_theme.dart';
import '../core/cartesian_tracking_snapshot.dart';
import '../core/chart_element.dart' show ChartElement;
import '../core/tracking_snapshot_resolver.dart';
import 'value_summary_adapters.dart';
import 'value_summary_reducer.dart';

/// Owns the value summary pipeline state for one chart.
///
/// Responsibilities, in frame order:
///
/// 1. **Gating** — a null config (outer `InteractionConfig.enabled` false,
///    nested `valueSummary.enabled` false, or `InteractionConfig.none()`)
///    hides the panel and prices the disabled path at a few null checks.
/// 2. **Policy reduction** — [ValueSummaryReducer.reduce] with lazily invoked
///    providers. The pinned/point provider and the deterministic fallback
///    providers resolve through two dedicated
///    [CartesianTrackingSnapshotResolver] instances so their input memos
///    never fight the render box's pointer-path resolver: each resolver sees
///    a stable synthetic-cursor key per (data revision, transform) and
///    returns its memoized snapshot on unchanged frames.
/// 3. **Adaptation** — [ValueSummaryAdapter.build] into the content model.
/// 4. **Element feeding** — equality-guarded `updateContent` /
///    `updateEnvironment` / `updatePlacement` on the overlay element.
///
/// Reduction and adaptation run only when an input changed: the tracking
/// snapshot instance (the resolver republishes only on datum-identity
/// change), the summary config, the theme component, the data revision, the
/// viewport transform, the plot rect, the controller pin, or the selection.
/// A repaint with unchanged inputs never re-reduces (hot-path contract D10).
///
/// While the chart is dragging, panning, or zooming, [update] freezes the
/// displayed content entirely (spec lifecycle: transient tracking is
/// suspended; pinned or fallback content may remain visible). Resolution
/// resumes on the first settled frame because the transform/data keys have
/// changed by then.
@internal
class ValueSummaryCoordinator {
  /// Creates a coordinator that reports out-of-frame state changes (a
  /// controller pin/unpin) through [onNeedsRepaint].
  ValueSummaryCoordinator({required this.onNeedsRepaint});

  /// Requests a repaint of the owning render box.
  final VoidCallback onNeedsRepaint;

  final ValueSummaryOverlayElement _overlayElement =
      ValueSummaryOverlayElement();

  /// Resolves pinned/selected [ChartPointRef]s (origin `pinned`).
  final CartesianTrackingSnapshotResolver _pointResolver =
      CartesianTrackingSnapshotResolver();

  /// Resolves the deterministic latest/first-visible fallbacks (origin
  /// `fallback`).
  final CartesianTrackingSnapshotResolver _fallbackResolver =
      CartesianTrackingSnapshotResolver();

  CartesianValueSummaryController? _controller;
  bool _listeningToController = false;

  /// The committed-drag placement callback of the active config.
  ///
  /// Stored by reference (callbacks are excluded from config equality) for
  /// the annotation presentation's drag commit (Task 10). The fixed overlay
  /// never emits placement changes.
  ValueChanged<ChartOverlayPlacement>? onPlacementChanged;

  /// A drag-committed placement override for the annotation presentation.
  ///
  /// Null means "use the configured placement". The fixed overlay ignores
  /// it; the draggable annotation presentation (Task 10) writes it during
  /// drags and [resetPlacementOverride] restores the configured placement.
  ChartOverlayPlacement? placementOverride;

  // Change-gate keys for the reduce/adapt stage.
  CartesianValueSummaryConfig? _lastConfig;
  CartesianValueSummaryTheme? _lastTheme;
  CartesianTrackingSnapshot? _lastTracking;
  int? _lastDataRevision;
  ChartTransform? _lastTransform;
  Rect? _lastPlotArea;
  ChartPointRef? _lastPinned;
  ChartPointRef? _lastSelection;

  // Style resolution cache (config style x theme -> effective style).
  CartesianValueSummaryStyle? _resolvedStyleSource;
  CartesianValueSummaryTheme? _resolvedStyleTheme;
  ResolvedValueSummaryStyle? _resolvedStyle;

  // Visible data-X extent memo for the fallback providers.
  int? _extentDataRevision;
  ChartTransform? _extentTransform;
  double? _minVisibleDataX;
  double? _maxVisibleDataX;

  // Latest pipeline products, exposed for tests.
  CartesianTrackingSnapshot? _reducedSnapshot;
  CartesianValueSummaryContentModel? _model;
  int _reduceCount = 0;

  bool _paintActive = false;
  bool _pinClearScheduled = false;

  /// The overlay element to include in the foreground paint pass, or null
  /// when the summary is gated off (nothing is painted at all).
  ChartElement? get overlayElementForPaint =>
      _paintActive ? _overlayElement : null;

  /// The policy-resolved snapshot behind the currently displayed content.
  CartesianTrackingSnapshot? get debugReducedSnapshot => _reducedSnapshot;

  /// The currently displayed content model, or null while hidden.
  CartesianValueSummaryContentModel? get debugModel => _model;

  /// Number of reduce+adapt executions. Repaints with unchanged inputs must
  /// not increment this.
  int get debugReduceCount => _reduceCount;

  /// The overlay element's last painted bounds ([Rect.zero] while hidden).
  Rect get debugOverlayBounds => _overlayElement.bounds;

  /// Attaches [controller] by reference.
  ///
  /// Controllers are excluded from config equality, so the render box calls
  /// this on every `setInteractionConfig`, before the config equality
  /// early-return. [Listenable] controllers are observed so `pin`/`clearPin`
  /// trigger a repaint (and thereby a re-reduction); non-listenable
  /// controllers are picked up on the next repaint from any source.
  void attachController(CartesianValueSummaryController? controller) {
    if (identical(controller, _controller)) return;
    _detachControllerListener();
    _controller = controller;
    final Object? listenable = controller;
    if (listenable is Listenable) {
      listenable.addListener(_handleControllerChanged);
      _listeningToController = true;
    }
  }

  void _detachControllerListener() {
    final Object? listenable = _controller;
    if (_listeningToController && listenable is Listenable) {
      listenable.removeListener(_handleControllerChanged);
    }
    _listeningToController = false;
  }

  void _handleControllerChanged() => onNeedsRepaint();

  /// Clears the drag-committed placement override (controller
  /// `resetPlacement` semantics; consumed by the annotation presentation).
  void resetPlacementOverride() {
    if (placementOverride == null) return;
    placementOverride = null;
    onNeedsRepaint();
  }

  /// Detaches the controller listener and releases element resources.
  void dispose() {
    _detachControllerListener();
    _controller = null;
  }

  /// Runs one frame of the summary pipeline.
  ///
  /// [config] must already encode the full enable gate: the render box
  /// passes null when the outer `InteractionConfig.enabled` is false or the
  /// nested summary is disabled. [tracking] is the frame's pointer or
  /// synchronized snapshot resolved by the render box's shared resolver
  /// (null when there is no live tracking source). [suspended] freezes the
  /// displayed content during drags and pan/zoom.
  void update({
    required CartesianValueSummaryConfig? config,
    required CartesianValueSummaryTheme theme,
    required CartesianTrackingSnapshot? tracking,
    required bool suspended,
    required Rect plotArea,
    required ChartTransform? transform,
    required List<ChartElement> elements,
    required MultiAxisInfo Function() axisInfoBuilder,
    required int dataRevision,
    required TextDirection textDirection,
    required double textScale,
    ChartPointRef? selection,
  }) {
    if (config == null ||
        config.presentation is! CartesianValueSummaryOverlay) {
      // Gated off (or a presentation this slice does not render). The
      // disabled path must stay near-free: only tear down when the panel
      // was active.
      if (_paintActive) {
        _paintActive = false;
        _model = null;
        _reducedSnapshot = null;
        _lastConfig = null; // Re-enabling must re-reduce.
        final style =
            _resolvedStyle ??
            ResolvedValueSummaryStyle.resolve(
              const CartesianValueSummaryStyle(),
              theme,
            );
        _overlayElement.updateContent(null, style);
      }
      return;
    }

    _paintActive = true;
    final presentation = config.presentation as CartesianValueSummaryOverlay;
    _overlayElement.updateEnvironment(
      plotRect: Offset.zero & plotArea.size,
      textDirection: textDirection,
      textScale: textScale,
    );
    _overlayElement.updatePlacement(presentation.placement);

    // Effective style resolves only on config-style or theme change.
    if (_resolvedStyle == null ||
        _resolvedStyleSource != config.style ||
        _resolvedStyleTheme != theme) {
      _resolvedStyleSource = config.style;
      _resolvedStyleTheme = theme;
      _resolvedStyle = ResolvedValueSummaryStyle.resolve(config.style, theme);
    }

    if (suspended) {
      // Transient tracking is suspended; pinned/fallback content remains
      // as-is and re-resolves after the transform settles (the transform/
      // data keys will have changed by then).
      return;
    }

    final pinned = _controller?.pinnedPoint;
    final needsReduce =
        config != _lastConfig ||
        theme != _lastTheme ||
        !identical(tracking, _lastTracking) ||
        dataRevision != _lastDataRevision ||
        transform != _lastTransform ||
        plotArea != _lastPlotArea ||
        pinned != _lastPinned ||
        selection != _lastSelection;
    if (!needsReduce) return;

    _lastConfig = config;
    _lastTheme = theme;
    _lastTracking = tracking;
    _lastDataRevision = dataRevision;
    _lastTransform = transform;
    _lastPlotArea = plotArea;
    _lastPinned = pinned;
    _lastSelection = selection;

    CartesianTrackingSnapshot? snapshot;
    if (transform != null) {
      final reduction = ValueSummaryReducer.reduce(
        policy: config.valuePolicy,
        tracking: tracking,
        pinned: pinned,
        selection: selection,
        resolvePoint: (point) => _resolvePointRef(
          point,
          plotArea: plotArea,
          transform: transform,
          elements: elements,
          axisInfoBuilder: axisInfoBuilder,
          dataRevision: dataRevision,
        ),
        latestVisible: () => _resolveVisibleEdge(
          latest: true,
          plotArea: plotArea,
          transform: transform,
          elements: elements,
          axisInfoBuilder: axisInfoBuilder,
          dataRevision: dataRevision,
        ),
        firstVisible: () => _resolveVisibleEdge(
          latest: false,
          plotArea: plotArea,
          transform: transform,
          elements: elements,
          axisInfoBuilder: axisInfoBuilder,
          dataRevision: dataRevision,
        ),
      );
      snapshot = reduction.snapshot;
      if (reduction.clearedInvalidPin) _schedulePinClear();
    }

    _reduceCount++;
    _reducedSnapshot = snapshot;
    _model = snapshot == null
        ? null
        : ValueSummaryAdapter.build(
            snapshot,
            content: config.content,
            showSeriesAccent: config.showSeriesAccent,
          );
    _overlayElement.updateContent(_model, _resolvedStyle!);
  }

  /// Clears an invalidated pin on the controller after the current frame.
  ///
  /// The reduction that reported the invalid pin already carries the
  /// fall-through snapshot, so the displayed content is correct this frame.
  /// Clearing post-frame keeps arbitrary application controller listeners
  /// (which may call `setState` or `markNeedsPaint`) out of the paint phase.
  void _schedulePinClear() {
    if (_pinClearScheduled) return;
    final controller = _controller;
    if (controller == null) return;
    _pinClearScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _pinClearScheduled = false;
      _controller?.clearPin();
    }, debugLabel: 'ValueSummaryCoordinator.clearInvalidPin');
  }

  /// Resolves a stable point reference into a snapshot at that point's X,
  /// stamped with origin [CartesianTrackingOrigin.pinned], or null when the
  /// point no longer exists (removed or replaced data).
  ///
  /// The synthetic cursor sits at the referenced datum's own plot position,
  /// so the Scatter two-dimensional replacement also snaps the referenced
  /// point rather than a nearer neighbor at the plot's vertical center.
  CartesianTrackingSnapshot? _resolvePointRef(
    ChartPointRef ref, {
    required Rect plotArea,
    required ChartTransform transform,
    required List<ChartElement> elements,
    required MultiAxisInfo Function() axisInfoBuilder,
    required int dataRevision,
  }) {
    SeriesElement? match;
    for (final element in elements) {
      if (element is SeriesElement && element.series.id == ref.seriesId) {
        match = element;
        break;
      }
    }
    if (match == null) return null;
    final points = match.series.points;
    if (ref.pointIndex < 0 || ref.pointIndex >= points.length) return null;
    final point = points[ref.pointIndex];
    if (!point.isValid) return null;

    final pointPlot = match.dataToCurrentPlot(point.x, point.y);
    final cursor = transform.transposed
        ? Offset(
            pointPlot.dx,
            _nudgeTowardCenter(pointPlot.dy, plotArea.height),
          )
        : Offset(
            _nudgeTowardCenter(pointPlot.dx, plotArea.width),
            pointPlot.dy,
          );
    final snapshot = _pointResolver.resolve(
      cursorPlotPosition: cursor,
      plotArea: plotArea,
      transform: transform,
      elements: elements,
      axisInfo: axisInfoBuilder(),
      origin: CartesianTrackingOrigin.pinned,
      includeTrends: true,
      // Non-pointer origins snap to actual data: a pinned point must
      // resolve the datum itself, never an interpolated neighbor sample.
      interpolateValues: false,
      dataRevision: dataRevision,
    );
    if (snapshot == null) return null;

    // Verify the resolution actually snapped the referenced datum; a miss
    // (for example a pin whose X now sits outside the visible viewport)
    // reports the pin as unresolvable.
    final containsRef = snapshot.values.any(
      (value) =>
          !value.isTrend &&
          value.seriesId == ref.seriesId &&
          (value.dataPointIndex == ref.pointIndex ||
              value.sourcePointIndices.contains(ref.pointIndex)),
    );
    if (!containsRef) return null;
    if (snapshot.primaryPoint == ref) return snapshot;
    return CartesianTrackingSnapshot(
      dataX: snapshot.dataX,
      plotX: snapshot.plotX,
      values: snapshot.values,
      origin: snapshot.origin,
      primaryPoint: ref,
    );
  }

  /// Resolves the deterministic latest/first-visible fallback snapshot, or
  /// null when no visible datum exists (empty data or all series hidden).
  CartesianTrackingSnapshot? _resolveVisibleEdge({
    required bool latest,
    required Rect plotArea,
    required ChartTransform transform,
    required List<ChartElement> elements,
    required MultiAxisInfo Function() axisInfoBuilder,
    required int dataRevision,
  }) {
    _ensureVisibleExtent(
      transform: transform,
      elements: elements,
      dataRevision: dataRevision,
    );
    final dataX = latest ? _maxVisibleDataX : _minVisibleDataX;
    if (dataX == null) return null;

    final range = transform.dataXMax - transform.dataXMin;
    final normalized = range > 0
        ? ((dataX - transform.dataXMin) / range).clamp(0.0, 1.0)
        : 0.5;
    final cursor = transform.transposed
        ? Offset(
            plotArea.width / 2,
            _nudgeTowardCenter(normalized * plotArea.height, plotArea.height),
          )
        : Offset(
            _nudgeTowardCenter(normalized * plotArea.width, plotArea.width),
            plotArea.height / 2,
          );
    return _fallbackResolver.resolve(
      cursorPlotPosition: cursor,
      plotArea: plotArea,
      transform: transform,
      elements: elements,
      axisInfo: axisInfoBuilder(),
      origin: CartesianTrackingOrigin.fallback,
      includeTrends: true,
      // Fallbacks show the actual edge datum, never an interpolated sample.
      interpolateValues: false,
      dataRevision: dataRevision,
    );
  }

  /// Nudges a synthetic cursor coordinate toward the plot interior by a
  /// relative epsilon (one part in 10^9 of the plot extent).
  ///
  /// Non-pointer resolutions place the cursor at a datum's own mapped
  /// position, and the tracker reconstructs the data X from that pixel with
  /// a float roundtrip. Without the nudge the reconstructed X can overshoot
  /// the series' first/last point by a few ulps, which
  /// `CrosshairTracker.calculateTrackingState` treats as "past the data" and
  /// resolves to nothing. The nudge is orders of magnitude above the float
  /// error and orders of magnitude below any datum spacing, so the
  /// non-interpolated nearest-snap deterministically lands on the intended
  /// edge datum.
  static double _nudgeTowardCenter(double coordinate, double extent) {
    final nudge = extent * 1e-9;
    return coordinate > extent / 2 ? coordinate - nudge : coordinate + nudge;
  }

  /// Memoizes the min/max visible data X per (data revision, transform).
  void _ensureVisibleExtent({
    required ChartTransform transform,
    required List<ChartElement> elements,
    required int dataRevision,
  }) {
    if (_extentDataRevision == dataRevision && _extentTransform == transform) {
      return;
    }
    _extentDataRevision = dataRevision;
    _extentTransform = transform;
    _minVisibleDataX = null;
    _maxVisibleDataX = null;

    final xMin = transform.dataXMin;
    final xMax = transform.dataXMax;
    double? minX;
    double? maxX;
    for (final element in elements) {
      if (element is! SeriesElement) continue;
      for (final point in element.series.points) {
        if (!point.isValid) continue;
        final x = point.x;
        if (x < xMin || x > xMax) continue;
        if (minX == null || x < minX) minX = x;
        if (maxX == null || x > maxX) maxX = x;
      }
    }
    _minVisibleDataX = minX;
    _maxVisibleDataX = maxX;
  }
}
