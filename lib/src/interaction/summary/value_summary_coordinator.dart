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
import '../../elements/value_summary_annotation_element.dart';
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

/// Assistive-technology surface of the active value summary panel, consumed
/// by the render box's semantics assembly.
///
/// [label] is the grouped region's title + context (always prefixed
/// `Value summary` so traversal can never confuse the region with the
/// crosshair panel's canvas content), [value] the unit-carrying rows in
/// meaningful source order. The boolean capabilities gate which semantic
/// actions the render box attaches.
typedef ValueSummarySemanticsInfo = ({
  Rect bounds,
  String label,
  String value,
  bool focusable,
  bool focused,
  bool movable,
  bool canPin,
  bool canClearPin,
});

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

  /// Delivers a debounced assistive announcement (config `announceChanges`).
  ///
  /// Set by the render box, which owns the platform view needed to send it.
  /// Called from a post-frame callback, never during paint.
  ValueChanged<String>? onAnnounce;

  final ValueSummaryOverlayElement _overlayElement =
      ValueSummaryOverlayElement();

  final ValueSummaryAnnotationElement _annotationElement =
      ValueSummaryAnnotationElement();

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
  /// it; the draggable annotation presentation writes it live during drags
  /// and keyboard nudges, and [resetPlacementOverride] restores the
  /// configured placement.
  ChartOverlayPlacement? placementOverride;

  // Annotation presentation state (drag, keyboard, focus).
  bool _annotationActive = false;
  bool _annotationDraggable = false;
  bool _annotationFocused = false;
  ChartOverlayPlacement _annotationConfiguredPlacement =
      ChartOverlayPlacement.topLeft;
  Offset? _dragOrigin;
  ChartOverlayPlacement? _preDragOverride;
  Offset? _keyboardOrigin;
  bool _keyboardNudgePending = false;

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

  // Semantics + announcement state. The strings are recomputed only when the
  // displayed model changes (reduce cadence), never per repaint.
  CartesianValueSummaryConfig? _activeConfig;
  String _semanticsLabel = '';
  String _semanticsValue = '';
  CartesianTrackingSnapshot? _announcedSnapshot;
  String? _pendingAnnouncement;
  bool _announceScheduled = false;

  /// The active presentation element for one paint frame.
  ValueSummaryPanelElement get _activeElement =>
      _annotationActive ? _annotationElement : _overlayElement;

  /// The summary element to include in the foreground paint pass, or null
  /// when the summary is gated off (nothing is painted at all).
  ChartElement? get overlayElementForPaint =>
      _paintActive ? _activeElement : null;

  /// The policy-resolved snapshot behind the currently displayed content.
  CartesianTrackingSnapshot? get debugReducedSnapshot => _reducedSnapshot;

  /// The currently displayed content model, or null while hidden.
  CartesianValueSummaryContentModel? get debugModel => _model;

  /// Number of reduce+adapt executions. Repaints with unchanged inputs must
  /// not increment this.
  int get debugReduceCount => _reduceCount;

  /// The active panel's last painted bounds ([Rect.zero] while hidden).
  Rect get debugOverlayBounds => _activeElement.bounds;

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

  /// Reacts to any controller notification.
  ///
  /// Controllers are observed only as a generic [Listenable], so a
  /// `resetPlacement()` call is indistinguishable from a pin change — except
  /// for [DefaultCartesianValueSummaryController], which records the request
  /// in an internal handshake this coordinator consumes here. Host-initiated
  /// resets do not re-emit `onPlacementChanged`.
  void _handleControllerChanged() {
    final controller = _controller;
    if (controller is DefaultCartesianValueSummaryController &&
        controller.consumeResetPlacementRequest()) {
      _keyboardOrigin = null;
      _keyboardNudgePending = false;
      placementOverride = null;
    }
    onNeedsRepaint();
  }

  /// Clears the drag-committed placement override (controller
  /// `resetPlacement` semantics; consumed by the annotation presentation).
  void resetPlacementOverride() {
    if (placementOverride == null) return;
    placementOverride = null;
    onNeedsRepaint();
  }

  // ==========================================================================
  // Annotation presentation: drag, keyboard, and focus surface
  // ==========================================================================

  /// The annotation panel as a drag-acquisition target, or null when the
  /// annotation presentation is inactive, non-draggable, or not painted.
  ValueSummaryAnnotationElement? get annotationDragTarget =>
      _paintActive &&
          _annotationActive &&
          _annotationDraggable &&
          _annotationElement.bounds != Rect.zero
      ? _annotationElement
      : null;

  /// Whether the annotation panel currently owns keyboard focus.
  bool get annotationFocused => _annotationFocused;

  /// Grants or clears the panel's keyboard focus (pointer-driven).
  ///
  /// Returns whether the focus state actually changed, so callers can limit
  /// semantics re-flushes to real transitions.
  bool setAnnotationFocus(bool focused) {
    if (focused == _annotationFocused) return false;
    _annotationFocused = focused;
    if (!focused) {
      _keyboardOrigin = null;
      _keyboardNudgePending = false;
    }
    onNeedsRepaint();
    return true;
  }

  /// Captures pre-drag state when `EventHandlerManager` engages a drag.
  void beginAnnotationDrag() {
    _preDragOverride = placementOverride;
    _dragOrigin = _annotationElement.bounds.topLeft;
  }

  /// Live drag preview: updates the placement override for the panel
  /// top-left [origin] (plot-local) and requests a feedback repaint.
  void updateAnnotationDragOrigin(Offset origin) {
    _dragOrigin = origin;
    placementOverride = _annotationElement.placementForOrigin(
      origin,
      anchor: _annotationConfiguredPlacement.anchor,
    );
    onNeedsRepaint();
  }

  /// Commits an engaged drag: clamps the final origin (when configured),
  /// stores the committed anchor-relative placement as the override, and
  /// emits `onPlacementChanged` exactly once.
  ChartOverlayPlacement? commitAnnotationDrag() {
    final origin = _dragOrigin;
    _dragOrigin = null;
    _preDragOverride = null;
    if (origin == null) return null;
    final clamped = _annotationElement.clampToPlot
        ? _annotationElement.clampOriginToPlot(origin)
        : origin;
    final committed = _annotationElement.placementForOrigin(
      clamped,
      anchor: _annotationConfiguredPlacement.anchor,
    );
    placementOverride = committed;
    onNeedsRepaint();
    onPlacementChanged?.call(committed);
    return committed;
  }

  /// Abandons an engaged drag (pointer cancel), restoring the pre-drag
  /// placement without emitting a commit.
  void cancelAnnotationDrag() {
    if (_dragOrigin == null) return;
    _dragOrigin = null;
    placementOverride = _preDragOverride;
    _preDragOverride = null;
    onNeedsRepaint();
  }

  /// Moves the focused panel by [delta] logical pixels (keyboard).
  ///
  /// Nudges accumulate across a held key and clamp immediately (when
  /// configured); the pending result is committed once by
  /// [commitKeyboardNudge] on key release.
  void nudgeAnnotation(Offset delta) {
    final origin =
        (_keyboardOrigin ?? _annotationElement.bounds.topLeft) + delta;
    final clamped = _annotationElement.clampToPlot
        ? _annotationElement.clampOriginToPlot(origin)
        : origin;
    _keyboardOrigin = clamped;
    _keyboardNudgePending = true;
    placementOverride = _annotationElement.placementForOrigin(
      clamped,
      anchor: _annotationConfiguredPlacement.anchor,
    );
    onNeedsRepaint();
  }

  /// Commits a pending keyboard movement burst, emitting `onPlacementChanged`
  /// exactly once with the already-clamped anchor-relative placement.
  ChartOverlayPlacement? commitKeyboardNudge() {
    if (!_keyboardNudgePending) return null;
    _keyboardNudgePending = false;
    _keyboardOrigin = null;
    final committed = placementOverride;
    if (committed == null) return null;
    onPlacementChanged?.call(committed);
    return committed;
  }

  /// Restores the configured placement (Escape / semantic reset action).
  ///
  /// When [emit] is true and a drag override or pending keyboard nudge
  /// actually existed, the configured placement is surfaced through
  /// `onPlacementChanged` so hosts holding a dragged placement re-sync.
  /// An untouched panel never emits — there is nothing to re-sync, and a
  /// spurious commit would overwrite host state with a no-op placement.
  void resetAnnotationPlacement({required bool emit}) {
    final hadPlacementState =
        placementOverride != null || _keyboardNudgePending;
    _keyboardOrigin = null;
    _keyboardNudgePending = false;
    placementOverride = null;
    onNeedsRepaint();
    if (emit && hadPlacementState) {
      onPlacementChanged?.call(_annotationConfiguredPlacement);
    }
  }

  // ==========================================================================
  // Semantics surface (both presentations)
  // ==========================================================================

  /// Assistive info for the active summary panel, or null while no summary
  /// is painted.
  ///
  /// Both presentations expose the same grouped region: the fixed overlay as
  /// a passive labelled region, the annotation panel additionally focusable
  /// and movable while draggable. Bounds follow the painted panel at paint
  /// cadence (a mid-drag panel reports its live position).
  ValueSummarySemanticsInfo? get summarySemanticsInfo {
    if (!_paintActive || _activeElement.bounds == Rect.zero) return null;
    final model = _model;
    if (model == null || model.rows.isEmpty) return null;
    final controller = _controller;
    final policy = _activeConfig?.valuePolicy;
    final pinPolicy =
        policy == CartesianValueSummaryValuePolicy.pinnedThenTrackingThenLatest ||
        policy == CartesianValueSummaryValuePolicy.explicitOnly;
    final primary = _reducedSnapshot?.primaryPoint;
    final movable = _annotationActive && _annotationDraggable;
    return (
      bounds: _activeElement.bounds,
      label: _semanticsLabel,
      value: _semanticsValue,
      focusable: movable,
      focused: movable && _annotationFocused,
      movable: movable,
      canPin:
          controller != null &&
          pinPolicy &&
          primary != null &&
          controller.pinnedPoint != primary,
      canClearPin:
          controller != null && pinPolicy && controller.pinnedPoint != null,
    );
  }

  /// Moves the draggable annotation panel by [delta] and commits the
  /// placement once (semantic move action). No-op for the fixed overlay.
  void performSemanticMove(Offset delta) {
    if (!_annotationActive || !_annotationDraggable) return;
    nudgeAnnotation(delta);
    commitKeyboardNudge();
  }

  /// Pins the currently displayed datum through the attached controller
  /// (semantic pin action).
  void performSemanticPin() {
    final point = _reducedSnapshot?.primaryPoint;
    if (point == null) return;
    _controller?.pin(point);
  }

  /// Clears the controller pin (semantic clear-pin action).
  void performSemanticClearPin() => _controller?.clearPin();

  /// Rebuilds the cached semantics label/value strings from [_model].
  ///
  /// Called only when the displayed model changes, so the per-repaint
  /// semantics dirty check compares cached string references.
  void _updateSemanticsStrings() {
    final model = _model;
    if (model == null || model.rows.isEmpty) {
      _semanticsLabel = '';
      _semanticsValue = '';
      return;
    }
    _semanticsLabel = [
      'Value summary',
      if (model.title case final title? when title.isNotEmpty) title,
      if (model.subtitle case final subtitle? when subtitle.isNotEmpty)
        subtitle,
    ].join(', ');
    _semanticsValue = [
      for (final row in model.rows)
        switch (row.semanticValue ?? row.value) {
          '' => row.label,
          final value => '${row.label}: $value',
        },
    ].join(', ');
  }

  /// Emits one debounced announcement per resolved-datum identity change.
  ///
  /// Runs inside the reduce stage, so the announcement cadence can never
  /// exceed the reduce cadence; [CartesianTrackingSnapshot.sameIdentityAs]
  /// additionally suppresses re-announcing the same datum (for example a
  /// reduce caused by a config or theme change). The very first appearance
  /// announces nothing — it is not a change.
  void _maybeAnnounce(
    CartesianValueSummaryConfig config,
    CartesianTrackingSnapshot? snapshot,
  ) {
    if (snapshot == null || _model == null || _model!.rows.isEmpty) {
      _announcedSnapshot = null;
      return;
    }
    final previous = _announcedSnapshot;
    _announcedSnapshot = snapshot;
    if (!config.announceChanges) return;
    if (previous == null || snapshot.sameIdentityAs(previous)) return;
    _scheduleAnnouncement('$_semanticsLabel: $_semanticsValue');
  }

  /// Defers the announcement out of the paint phase, coalescing multiple
  /// datum changes within one frame into the last message.
  void _scheduleAnnouncement(String message) {
    _pendingAnnouncement = message;
    if (_announceScheduled) return;
    _announceScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _announceScheduled = false;
      final pending = _pendingAnnouncement;
      _pendingAnnouncement = null;
      if (pending != null) onAnnounce?.call(pending);
    }, debugLabel: 'ValueSummaryCoordinator.announce');
  }

  /// Detaches the controller listener and releases element resources.
  void dispose() {
    _detachControllerListener();
    _controller = null;
    onAnnounce = null;
    _pendingAnnouncement = null;
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
    if (config == null) {
      // Gated off. The disabled path must stay near-free: only tear down
      // when the panel was active.
      if (_paintActive) {
        _paintActive = false;
        _model = null;
        _reducedSnapshot = null;
        _lastConfig = null; // Re-enabling must re-reduce.
        _annotationFocused = false;
        _activeConfig = null;
        _announcedSnapshot = null;
        _updateSemanticsStrings();
        final style =
            _resolvedStyle ??
            ResolvedValueSummaryStyle.resolve(
              const CartesianValueSummaryStyle(),
              theme,
            );
        _overlayElement.updateContent(null, style);
        _annotationElement.updateContent(null, style);
      }
      return;
    }

    _paintActive = true;
    _activeConfig = config;
    switch (config.presentation) {
      case final CartesianValueSummaryOverlay presentation:
        _annotationActive = false;
        _annotationDraggable = false;
        _annotationFocused = false;
        _overlayElement.updateEnvironment(
          plotRect: Offset.zero & plotArea.size,
          textDirection: textDirection,
          textScale: textScale,
        );
        _overlayElement.updatePlacement(presentation.placement);
      case final CartesianValueSummaryAnnotation presentation:
        _annotationActive = true;
        _annotationDraggable = presentation.draggable;
        if (!presentation.draggable) _annotationFocused = false;
        _annotationConfiguredPlacement = presentation.placement;
        _annotationElement.updateEnvironment(
          plotRect: Offset.zero & plotArea.size,
          textDirection: textDirection,
          textScale: textScale,
        );
        _annotationElement.updateBehavior(
          draggable: presentation.draggable,
          clampToPlot: presentation.clampToPlot,
        );
        // A drag/keyboard override wins over the configured placement; both
        // keep flowing during drags (the suspended early-return below only
        // freezes the displayed content).
        _annotationElement.updatePlacement(
          placementOverride ?? presentation.placement,
        );
    }

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
    _activeElement.updateContent(_model, _resolvedStyle!);
    _updateSemanticsStrings();
    _maybeAnnounce(config, snapshot);
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
