import 'package:flutter/foundation.dart';

import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_artifact.dart';
import '../artifacts/chart_artifact_extractor.dart';
import '../artifacts/chart_document_extractor.dart';
import '../artifacts/chart_preview.dart';
import '../artifacts/chart_preview_capture.dart';
import '../artifacts/chart_view_state.dart';

/// Internal chart-state bridge for revision-bound point commands.
typedef ChartPointCommandHandler =
    ChartArtifactResult<void> Function(
      Iterable<ChartPointRef> points,
      ChartDocumentRevision revision, {
      required bool reveal,
      required bool additive,
    });

/// Programmatic control over series, point linking, and Y-axis slot state.
///
/// Attach to [BravenChartPlus.controller] to drive series selection
/// and axis swaps from outside the chart widget.
///
/// The controller is optional — charts without one still respond to
/// legend taps and data-point taps internally. Add a controller when you need
/// to read slot state, link another surface by [ChartPointRef], capture an
/// effective document, or trigger selection externally.
///
/// Example:
/// ```dart
/// final _controller = BravenChartController();
///
/// @override
/// void dispose() {
///   _controller.dispose();
///   super.dispose();
/// }
///
/// // Somewhere outside the chart:
/// _controller.selectSeries('heat_strain');
/// print(_controller.visibleAxisIds);
/// ```
class BravenChartController extends ChangeNotifier {
  // Internal hook set by _BravenChartPlusState in initState/didUpdateWidget.
  void Function(String seriesId)? _selectHandler;
  void Function(String seriesId)? _deselectHandler;
  void Function()? _clearHandler;
  void Function(String seriesId, bool visible)? _setVisibilityHandler;
  ChartDocumentExtractionHandler? _extractDocumentHandler;
  void Function(ChartViewState viewState)? _restoreViewStateHandler;
  ChartPreviewCaptureHandler? _capturePreviewHandler;
  ChartPointCommandHandler? _focusPointsHandler;
  ChartPointCommandHandler? _selectPointsHandler;
  void Function()? _clearPointFocusHandler;
  void Function()? _clearPointSelectionHandler;
  void Function()? _replayRadialEntranceHandler;
  void Function()? _replaySeriesEntranceHandler;
  final ValueNotifier<ChartDocumentRevision?> _effectiveDocumentRevision =
      ValueNotifier(null);
  bool _disposed = false;

  // Slot state mirrored from MultiAxisManager (updated after every swap).
  String? _selectedSeriesId;
  List<String> _visibleAxisIds = const [];
  List<String> _overflowAxisIds = const [];
  Set<String> _hiddenSeriesIds = const {};
  Set<ChartPointRef> _focusedPointRefs = const {};
  Set<ChartPointRef> _selectedPointRefs = const {};

  // ---- Public read API ----

  /// Currently selected series ID, or null if nothing is selected.
  String? get selectedSeriesId => _selectedSeriesId;

  /// Axis IDs currently occupying visible slots, in slot order.
  List<String> get visibleAxisIds => List.unmodifiable(_visibleAxisIds);

  /// Axis IDs currently in overflow (voted out of visible slots).
  List<String> get overflowAxisIds => List.unmodifiable(_overflowAxisIds);

  /// Series IDs currently excluded from rendering by visibility state.
  Set<String> get hiddenSeriesIds => Set.unmodifiable(_hiddenSeriesIds);

  /// Transient point focus currently rendered by the attached chart.
  Set<ChartPointRef> get focusedPointRefs =>
      Set.unmodifiable(_focusedPointRefs);

  /// Durable point selection currently rendered by the attached chart.
  Set<ChartPointRef> get selectedPointRefs =>
      Set.unmodifiable(_selectedPointRefs);

  /// Opaque revision of the effective document source attached to this chart.
  ///
  /// The value is null while the controller is detached. Compare a non-null
  /// value only with [ChartDocumentSnapshot.revision].
  ValueListenable<ChartDocumentRevision?> get effectiveDocumentRevision =>
      _effectiveDocumentRevision;

  // ---- Public command API ----

  /// Selects [seriesId]. If its axis is in overflow, promotes it to a visible
  /// slot by demoting the last-declared visible axis on the same side.
  ///
  /// Fires [BravenChartPlus.onSeriesSelected] and, if a swap occurred,
  /// [BravenChartPlus.onAxisSwapped]. No-op if the controller is not
  /// attached to a mounted chart.
  void selectSeries(String seriesId) => _selectHandler?.call(seriesId);

  /// Deselects [seriesId]. If [BravenChartPlus.axisSwapMode] is
  /// [AxisSwapMode.revert], restores the original slot order for that side.
  ///
  /// No-op if the controller is not attached to a mounted chart.
  void deselectSeries(String seriesId) => _deselectHandler?.call(seriesId);

  /// Deselects all series. Reverts slot order on both sides if mode is
  /// [AxisSwapMode.revert].
  ///
  /// No-op if the controller is not attached to a mounted chart.
  void clearSelection() => _clearHandler?.call();

  /// Shows or hides [seriesId] while retaining it in full-document exports.
  void setSeriesVisible(String seriesId, bool visible) =>
      _setVisibilityHandler?.call(seriesId, visible);

  /// Toggles [seriesId] using the latest visibility mirrored from the chart.
  void toggleSeriesVisibility(String seriesId) =>
      setSeriesVisible(seriesId, _hiddenSeriesIds.contains(seriesId));

  /// Focuses one point from a document captured at [revision].
  ///
  /// Focus is transient and is not included in [ChartViewState]. A stale or
  /// invalid reference returns a structured failure without changing the chart.
  ChartArtifactResult<void> focusPoint(
    ChartPointRef point, {
    required ChartDocumentRevision revision,
    bool reveal = false,
  }) => focusPoints([point], revision: revision, reveal: reveal);

  /// Focuses every point represented by one row or host interaction.
  ChartArtifactResult<void> focusPoints(
    Iterable<ChartPointRef> points, {
    required ChartDocumentRevision revision,
    bool reveal = false,
  }) {
    final handler = _focusPointsHandler;
    if (handler == null) return _pointCommandDetachedFailure();
    return handler(points, revision, reveal: reveal, additive: false);
  }

  /// Selects one durable point from a document captured at [revision].
  ChartArtifactResult<void> selectPoint(
    ChartPointRef point, {
    required ChartDocumentRevision revision,
    bool reveal = false,
    bool additive = false,
  }) => selectPoints(
    [point],
    revision: revision,
    reveal: reveal,
    additive: additive,
  );

  /// Selects every point represented by one row or host interaction.
  ///
  /// Unless [additive] is true, the supplied points replace the previous point
  /// selection. Selection is captured in [ChartViewState.selectedPointRefs].
  ChartArtifactResult<void> selectPoints(
    Iterable<ChartPointRef> points, {
    required ChartDocumentRevision revision,
    bool reveal = false,
    bool additive = false,
  }) {
    final handler = _selectPointsHandler;
    if (handler == null) return _pointCommandDetachedFailure();
    return handler(points, revision, reveal: reveal, additive: additive);
  }

  /// Clears transient point focus.
  void clearPointFocus() => _clearPointFocusHandler?.call();

  /// Clears durable point selection.
  void clearPointSelection() => _clearPointSelectionHandler?.call();

  /// Replays the configured Pie or Donut entrance animation.
  ///
  /// Reduced-motion preferences, `PieAnimationMode.none`, and zero-duration
  /// animation themes still render the final frame immediately. This is a
  /// no-op when the controller is detached or the attached chart is not
  /// radial.
  void replayRadialEntrance() => _replayRadialEntranceHandler?.call();

  /// Replays the configured entrance animation for Line, Area, Pie, or Donut.
  ///
  /// Reduced-motion preferences, a disabled series entrance mode, and
  /// zero-duration animation themes still render the final frame immediately.
  /// This is a no-op when the controller is detached.
  void replaySeriesEntrance() => _replaySeriesEntranceHandler?.call();

  /// Captures the chart's effective document and optional current view state.
  ChartArtifactResult<ChartDocumentSnapshot> extractDocument([
    ChartDocumentExtractOptions options = const ChartDocumentExtractOptions(),
  ]) {
    final handler = _extractDocumentHandler;
    if (handler == null) {
      return ChartArtifactFailure(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.chartNotAttached,
          message:
              'The BravenChartController is not attached to a mounted chart.',
        ),
      );
    }
    return handler(options);
  }

  /// Restores durable visibility, selection, viewport, and axis-slot state.
  void restoreViewState(ChartViewState viewState) =>
      _restoreViewStateHandler?.call(viewState);

  /// Captures a revision-bound PNG preview of the mounted chart.
  Future<ChartArtifactResult<ChartPreview>> capturePreview([
    ChartPreviewOptions options = const ChartPreviewOptions(),
  ]) {
    final handler = _capturePreviewHandler;
    if (handler == null) {
      return Future.value(
        ChartArtifactFailure(
          error: const ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.chartNotAttached,
            message:
                'The BravenChartController is not attached to a mounted chart.',
          ),
        ),
      );
    }
    return handler(options);
  }

  /// Extracts one portable artifact and optionally a hash-matched preview.
  ///
  /// Preview failure is reported as a warning on a document-only success so
  /// callers never lose a usable native artifact because raster capture failed.
  Future<ChartArtifactResult<ChartArtifact>> extractArtifact([
    ChartArtifactExtractOptions options = const ChartArtifactExtractOptions(),
  ]) {
    final documentHandler = _extractDocumentHandler;
    if (documentHandler == null) {
      return Future.value(
        ChartArtifactFailure(
          error: const ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.chartNotAttached,
            message:
                'The BravenChartController is not attached to a mounted chart.',
          ),
        ),
      );
    }
    return ChartArtifactExtractor.extract(
      options: options,
      extractDocument: documentHandler,
      capturePreview: _capturePreviewHandler,
    );
  }

  // ---- Internal state sync (called by _BravenChartPlusState) ----

  /// Attaches this controller to a chart state. Called by the state.
  void attach({
    required void Function(String) onSelect,
    required void Function(String) onDeselect,
    required void Function() onClear,
    void Function(String, bool)? onSetSeriesVisibility,
    ChartDocumentExtractionHandler? onExtractDocument,
    void Function(ChartViewState)? onRestoreViewState,
    ChartPreviewCaptureHandler? onCapturePreview,
    ChartPointCommandHandler? onFocusPoints,
    ChartPointCommandHandler? onSelectPoints,
    void Function()? onClearPointFocus,
    void Function()? onClearPointSelection,
    void Function()? onReplayRadialEntrance,
    void Function()? onReplaySeriesEntrance,
    ChartDocumentRevision? effectiveDocumentRevision,
  }) {
    _selectHandler = onSelect;
    _deselectHandler = onDeselect;
    _clearHandler = onClear;
    _setVisibilityHandler = onSetSeriesVisibility;
    _extractDocumentHandler = onExtractDocument;
    _restoreViewStateHandler = onRestoreViewState;
    _capturePreviewHandler = onCapturePreview;
    _focusPointsHandler = onFocusPoints;
    _selectPointsHandler = onSelectPoints;
    _clearPointFocusHandler = onClearPointFocus;
    _clearPointSelectionHandler = onClearPointSelection;
    _replayRadialEntranceHandler = onReplayRadialEntrance;
    _replaySeriesEntranceHandler = onReplaySeriesEntrance;
    if (!_disposed) {
      _effectiveDocumentRevision.value = effectiveDocumentRevision;
    }
  }

  /// Detaches from the chart state. Called in dispose.
  void detach() {
    _selectHandler = null;
    _deselectHandler = null;
    _clearHandler = null;
    _setVisibilityHandler = null;
    _extractDocumentHandler = null;
    _restoreViewStateHandler = null;
    _capturePreviewHandler = null;
    _focusPointsHandler = null;
    _selectPointsHandler = null;
    _clearPointFocusHandler = null;
    _clearPointSelectionHandler = null;
    _replayRadialEntranceHandler = null;
    _replaySeriesEntranceHandler = null;
    if (!_disposed) _effectiveDocumentRevision.value = null;
  }

  /// Publishes an effective source revision from the attached chart state.
  @internal
  void updateEffectiveDocumentRevision(ChartDocumentRevision revision) {
    if (_disposed) return;
    if (_effectiveDocumentRevision.value == revision) return;
    _effectiveDocumentRevision.value = revision;
  }

  /// Updates mirrored slot state (called after every swap or selection change).
  void updateSlotState({
    required String? selectedSeriesId,
    required List<String> visibleAxisIds,
    required List<String> overflowAxisIds,
    Set<String> hiddenSeriesIds = const {},
  }) {
    _selectedSeriesId = selectedSeriesId;
    _visibleAxisIds = visibleAxisIds;
    _overflowAxisIds = overflowAxisIds;
    _hiddenSeriesIds = Set.unmodifiable(hiddenSeriesIds);
    notifyListeners();
  }

  /// Mirrors transient and durable linked-point state from the mounted chart.
  @internal
  void updatePointState({
    required Set<ChartPointRef> focusedPointRefs,
    required Set<ChartPointRef> selectedPointRefs,
  }) {
    if (_disposed) return;
    if (setEquals(_focusedPointRefs, focusedPointRefs) &&
        setEquals(_selectedPointRefs, selectedPointRefs)) {
      return;
    }
    _focusedPointRefs = Set.unmodifiable(focusedPointRefs);
    _selectedPointRefs = Set.unmodifiable(selectedPointRefs);
    notifyListeners();
  }

  ChartArtifactResult<void> _pointCommandDetachedFailure() =>
      ChartArtifactFailure(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.chartNotAttached,
          message:
              'The BravenChartController is not attached to a mounted chart.',
        ),
      );

  @override
  void dispose() {
    _disposed = true;
    _effectiveDocumentRevision.dispose();
    super.dispose();
  }
}
