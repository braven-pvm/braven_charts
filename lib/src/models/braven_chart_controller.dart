import 'package:flutter/foundation.dart';

import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_artifact.dart';
import '../artifacts/chart_artifact_extractor.dart';
import '../artifacts/chart_document_extractor.dart';
import '../artifacts/chart_preview.dart';
import '../artifacts/chart_preview_capture.dart';
import '../artifacts/chart_view_state.dart';
import '../meta/chart_surface.dart';
import 'chart_selection_result.dart';
import 'chart_selection_expression.dart';
import 'interaction_config.dart'
    show
        ChartSelectionAcquisitionMode,
        ChartSelectionBrushBox,
        ChartSelectionBrushRange,
        ChartSelectionOperation;

/// Internal chart-state bridge for semantic multi-series selection commands.
typedef ChartSeriesCommandHandler =
    void Function(
      Iterable<String> seriesIds,
      ChartSelectionOperation operation,
    );

/// Internal chart-state bridge for revision-bound point commands.
typedef ChartPointCommandHandler =
    ChartArtifactResult<void> Function(
      Iterable<ChartPointRef> points,
      ChartDocumentRevision revision, {
      required bool reveal,
      required bool additive,
    });

/// Internal chart-state bridge for one revision-bound selection expression.
typedef ChartSelectionExpressionCommandHandler =
    ChartArtifactResult<void> Function(
      ChartSelectionExpression expression,
      ChartDocumentRevision revision, {
      required bool reveal,
    });

/// Internal chart-state bridge for selection-wide commands.
typedef ChartSelectionCommandHandler = ChartArtifactResult<void> Function();

/// Internal chart-state bridge for fitting the viewport to durable selection.
typedef ChartSelectionZoomCommandHandler =
    ChartArtifactResult<void> Function(double paddingFraction);

/// Internal chart-state bridge for viewport scaling.
typedef ChartViewportZoomCommandHandler = bool Function(double factor);

/// Internal chart-state bridge for viewport translation in logical pixels.
typedef ChartViewportPanCommandHandler =
    bool Function(double horizontalPixels, double verticalPixels);

/// Internal chart-state bridge for restoring the complete data viewport.
typedef ChartViewportFitCommandHandler = bool Function();

/// Internal chart-state bridge for renderer-aware boolean commands.
typedef ChartBooleanCommandHandler = bool Function();

/// Internal chart-state bridge for setting a persistent selection brush.
typedef ChartSelectionBrushSetCommandHandler =
    ChartArtifactResult<void> Function(
      ChartSelectionBrushRange range, {
      required bool visible,
    });

typedef ChartSelectionBrushBoxSetCommandHandler =
    ChartArtifactResult<void> Function(
      ChartSelectionBrushBox box, {
      required bool visible,
    });

/// Internal chart-state bridge for changing persistent brush visibility.
typedef ChartSelectionBrushVisibilityCommandHandler =
    ChartArtifactResult<void> Function(bool visible);

/// Current renderer-neutral state of a persistent interval-selection brush.
@immutable
@ChartSurfaceExempt(
  'Controller-mirrored runtime state, not an authoring configuration: the '
  'chart creates and updates this value after pointer, keyboard, semantic, '
  'view-state, or controller commands. Consumers configure persistence and '
  'initial bounds through ChartSelectionBrushConfig, then read this immutable '
  'snapshot from BravenChartController.',
)
class ChartSelectionBrushState {
  const ChartSelectionBrushState({
    required this.acquisitionMode,
    required this.range,
    this.box,
    required this.visible,
  }) : assert(
         acquisitionMode == ChartSelectionAcquisitionMode.xInterval ||
             acquisitionMode == ChartSelectionAcquisitionMode.yInterval ||
             acquisitionMode == ChartSelectionAcquisitionMode.rectangle,
       ),
       assert(
         acquisitionMode == ChartSelectionAcquisitionMode.rectangle
             ? box != null
             : box == null,
       );

  /// Whether the brush controls an X interval, Y interval, or rectangle.
  final ChartSelectionAcquisitionMode acquisitionMode;

  /// Current ordered data-domain interval.
  ///
  /// For a rectangle this mirrors the X bounds in [box], preserving the
  /// interval summary used by existing controller listeners.
  final ChartSelectionBrushRange range;

  /// Current ordered two-dimensional data-domain bounds.
  final ChartSelectionBrushBox? box;

  /// Whether the brush geometry is currently painted and interactive.
  final bool visible;

  ChartSelectionBrushState copyWith({
    ChartSelectionAcquisitionMode? acquisitionMode,
    ChartSelectionBrushRange? range,
    ChartSelectionBrushBox? box,
    bool? visible,
  }) => ChartSelectionBrushState(
    acquisitionMode: acquisitionMode ?? this.acquisitionMode,
    range: range ?? this.range,
    box: box ?? this.box,
    visible: visible ?? this.visible,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSelectionBrushState &&
          other.acquisitionMode == acquisitionMode &&
          other.range == range &&
          other.box == box &&
          other.visible == visible;

  @override
  int get hashCode => Object.hash(acquisitionMode, range, box, visible);
}

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
  ChartSeriesCommandHandler? _selectSeriesIdsHandler;
  void Function(String seriesId)? _deselectHandler;
  void Function()? _clearHandler;
  void Function(String seriesId, bool visible)? _setVisibilityHandler;
  ChartDocumentExtractionHandler? _extractDocumentHandler;
  ChartDocumentExtractionHandler? _extractSourceDocumentHandler;
  void Function(ChartViewState viewState)? _restoreViewStateHandler;
  ChartPreviewCaptureHandler? _capturePreviewHandler;
  ChartPointCommandHandler? _focusPointsHandler;
  ChartPointCommandHandler? _selectPointsHandler;
  ChartSelectionExpressionCommandHandler? _selectExpressionHandler;
  ChartSelectionCommandHandler? _invertSelectionHandler;
  ChartSelectionZoomCommandHandler? _zoomToSelectionHandler;
  ChartViewportZoomCommandHandler? _zoomViewportHandler;
  ChartViewportPanCommandHandler? _panViewportHandler;
  ChartViewportFitCommandHandler? _fitDataHandler;
  ChartBooleanCommandHandler? _selectAllDataHandler;
  ChartBooleanCommandHandler? _clearAllSelectionHandler;
  ChartBooleanCommandHandler? _returnToLiveHandler;
  ChartSelectionBrushSetCommandHandler? _setSelectionBrushHandler;
  ChartSelectionBrushBoxSetCommandHandler? _setSelectionBrushBoxHandler;
  ChartSelectionBrushVisibilityCommandHandler?
  _setSelectionBrushVisibilityHandler;
  ChartSelectionCommandHandler? _clearSelectionBrushHandler;
  void Function()? _clearPointFocusHandler;
  void Function()? _clearPointSelectionHandler;
  void Function()? _replayRadialEntranceHandler;
  void Function()? _replaySeriesEntranceHandler;
  final ValueNotifier<ChartDocumentRevision?> _effectiveDocumentRevision =
      ValueNotifier(null);
  Object? _attachment;
  bool _disposed = false;

  // Slot state mirrored from MultiAxisManager (updated after every swap).
  String? _selectedSeriesId;
  Set<String> _selectedSeriesIds = const {};
  List<String> _visibleAxisIds = const [];
  List<String> _overflowAxisIds = const [];
  Set<String> _hiddenSeriesIds = const {};
  Set<ChartPointRef> _focusedPointRefs = const {};
  Set<ChartPointRef> _selectedPointRefs = const {};
  ChartSelectionResult _selectionResult = const ChartSelectionResult.empty();
  ChartSelectionExpression _selectionExpression =
      const ChartSelectionExpression.empty();
  ChartSelectionSnapshot? _selectionSnapshot;
  ChartSelectionBrushState? _selectionBrushState;

  // ---- Public read API ----

  /// Currently selected series ID, or null if nothing is selected.
  ///
  /// This legacy singular value identifies the series currently active for
  /// Y-axis slot promotion. Use [selectedSeriesIds] for durable chart
  /// selection.
  String? get selectedSeriesId => _selectedSeriesId;

  /// Series currently included in durable semantic selection.
  Set<String> get selectedSeriesIds => Set.unmodifiable(_selectedSeriesIds);

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
  ///
  /// Compact interval/span intent is materialized only when this getter is
  /// read. Whole-series clauses remain represented by [selectedSeriesIds].
  Set<ChartPointRef> get selectedPointRefs {
    final snapshot = _selectionSnapshot;
    if (snapshot == null || !_hasCompactPointClauses(snapshot.expression)) {
      return Set.unmodifiable(_selectedPointRefs);
    }
    final wholeSeriesIds = {
      for (final clause in snapshot.expression.clauses)
        if (clause is ChartSelectionWholeSeriesClause) clause.seriesId,
    };
    return Set.unmodifiable(
      snapshot.pointRefs.where(
        (reference) => !wholeSeriesIds.contains(reference.seriesId),
      ),
    );
  }

  /// Latest stable identities, extents, and statistics for point selection.
  ///
  /// Compact intent is materialized only when this getter is read.
  ChartSelectionResult get selectionResult {
    final snapshot = _selectionSnapshot;
    return snapshot != null && _hasCompactPointClauses(snapshot.expression)
        ? snapshot.result
        : _selectionResult;
  }

  /// Compact renderer-neutral intent for the current durable selection.
  ChartSelectionExpression get selectionExpression => _selectionExpression;

  /// Current revision-bound selection, resolved lazily on demand.
  ChartSelectionSnapshot? get selectionSnapshot => _selectionSnapshot;

  /// Current persistent interval brush, or null when no brush exists.
  ChartSelectionBrushState? get selectionBrushState => _selectionBrushState;

  /// Whether the attached selection has allocated concrete point identities.
  @visibleForTesting
  bool get debugSelectionPointRefsMaterialized =>
      _selectionSnapshot?.debugPointRefsMaterialized ?? false;

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

  /// Applies [operation] to every supplied series in one atomic command.
  void selectSeriesIds(
    Iterable<String> seriesIds, {
    ChartSelectionOperation operation = ChartSelectionOperation.replace,
  }) => _selectSeriesIdsHandler?.call(seriesIds, operation);

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

  /// Replaces durable selection with renderer-neutral [expression] intent.
  ///
  /// Interval and rectangle clauses retain their exact boundaries. Interval
  /// selection can therefore project continuous Line/Area edges, while a
  /// rectangle remains compact conjunctive X-and-Y intent instead of reducing
  /// the selection to enclosed source identities.
  ChartArtifactResult<void> selectExpression(
    ChartSelectionExpression expression, {
    required ChartDocumentRevision revision,
    bool reveal = false,
  }) {
    final handler = _selectExpressionHandler;
    if (handler == null) return _pointCommandDetachedFailure();
    return handler(expression, revision, reveal: reveal);
  }

  /// Selects every valid source datum not currently selected.
  ///
  /// The complement is resolved atomically against the mounted chart's
  /// current effective document revision.
  ChartArtifactResult<void> invertSelection() {
    final handler = _invertSelectionHandler;
    if (handler == null) return _pointCommandDetachedFailure();
    return handler();
  }

  /// Fits the Cartesian viewport to the current durable selection.
  ///
  /// [paddingFraction] is applied independently to the selected X and Y spans.
  /// Single-point selections receive a stable viewport-relative minimum span.
  ChartArtifactResult<void> zoomToSelection({double paddingFraction = 0.08}) {
    if (!paddingFraction.isFinite || paddingFraction < 0) {
      return ChartArtifactFailure(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message: 'Selection zoom padding must be finite and non-negative.',
        ),
      );
    }
    final handler = _zoomToSelectionHandler;
    if (handler == null) return _pointCommandDetachedFailure();
    return handler(paddingFraction);
  }

  /// Scales the mounted Cartesian viewport around its plot centre.
  ///
  /// Values greater than one zoom in and values between zero and one zoom out.
  /// Returns false when detached or attached to a non-Cartesian chart.
  bool zoomViewport(double factor) {
    if (!factor.isFinite || factor <= 0) {
      throw ArgumentError.value(
        factor,
        'factor',
        'must be finite and positive',
      );
    }
    return _zoomViewportHandler?.call(factor) ?? false;
  }

  /// Translates the mounted Cartesian viewport in logical pixels.
  ///
  /// Positive horizontal values pan right and positive vertical values pan
  /// down. Returns false when detached or attached to a non-Cartesian chart.
  bool panViewport({
    required double horizontalPixels,
    required double verticalPixels,
  }) {
    if (!horizontalPixels.isFinite || !verticalPixels.isFinite) {
      throw ArgumentError(
        'Viewport pan distances must be finite logical-pixel values.',
      );
    }
    return _panViewportHandler?.call(horizontalPixels, verticalPixels) ?? false;
  }

  /// Restores the mounted Cartesian chart's complete data viewport.
  ///
  /// Returns false when detached or attached to a non-Cartesian chart.
  bool fitData() => _fitDataHandler?.call() ?? false;

  /// Selects all chart data when the mounted renderer can do so safely.
  ///
  /// Point selection is bounded by the package's accessibility and keyboard
  /// limits. Whole-series selection remains compact. Returns false when the
  /// command is unsupported or would require an unbounded point allocation.
  bool selectAllData() => _selectAllDataHandler?.call() ?? false;

  /// Clears durable point, series, expression, and brush selection together.
  ///
  /// Returns false when detached or when the chart has no durable selection.
  bool clearAllSelection() => _clearAllSelectionHandler?.call() ?? false;

  /// Returns a managed streaming viewport to follow-latest mode.
  ///
  /// Returns false when detached, when the chart does not manage a live
  /// viewport, or when it is already following current data.
  bool returnToLive() => _returnToLiveHandler?.call() ?? false;

  /// Sets the persistent interval brush to [minimum] and [maximum].
  ///
  /// The attached chart's selection acquisition mode determines whether the
  /// bounds belong to X or Y. Y brushes can name [referenceSeriesId] when
  /// independent axes are present.
  ChartArtifactResult<void> setSelectionBrush({
    required double minimum,
    required double maximum,
    String? referenceSeriesId,
    bool visible = true,
  }) {
    if (!minimum.isFinite || !maximum.isFinite || minimum > maximum) {
      return ChartArtifactFailure(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Selection brush bounds must be finite and ordered from minimum to maximum.',
        ),
      );
    }
    final handler = _setSelectionBrushHandler;
    if (handler == null) return _pointCommandDetachedFailure();
    return handler(
      ChartSelectionBrushRange(
        minimum: minimum,
        maximum: maximum,
        referenceSeriesId: referenceSeriesId,
      ),
      visible: visible,
    );
  }

  /// Sets a persistent box brush in the attached chart's X and Y domains.
  ChartArtifactResult<void> setSelectionBrushBox({
    required double minimumX,
    required double maximumX,
    required double minimumY,
    required double maximumY,
    String? referenceSeriesId,
    bool visible = true,
  }) {
    final values = [minimumX, maximumX, minimumY, maximumY];
    if (values.any((value) => !value.isFinite) ||
        minimumX > maximumX ||
        minimumY > maximumY) {
      return ChartArtifactFailure(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.invalidArtifact,
          message:
              'Selection box bounds must be finite and ordered on both axes.',
        ),
      );
    }
    final handler = _setSelectionBrushBoxHandler;
    if (handler == null) return _pointCommandDetachedFailure();
    return handler(
      ChartSelectionBrushBox(
        minimumX: minimumX,
        maximumX: maximumX,
        minimumY: minimumY,
        maximumY: maximumY,
        referenceSeriesId: referenceSeriesId,
      ),
      visible: visible,
    );
  }

  /// Shows an existing persistent brush without changing its selection.
  ChartArtifactResult<void> showSelectionBrush() =>
      _setSelectionBrushVisibility(true);

  /// Hides an existing persistent brush while retaining its selection.
  ChartArtifactResult<void> hideSelectionBrush() =>
      _setSelectionBrushVisibility(false);

  ChartArtifactResult<void> _setSelectionBrushVisibility(bool visible) {
    final handler = _setSelectionBrushVisibilityHandler;
    if (handler == null) return _pointCommandDetachedFailure();
    return handler(visible);
  }

  /// Clears the persistent brush and its semantic selection.
  ChartArtifactResult<void> clearSelectionBrush() {
    final handler = _clearSelectionBrushHandler;
    if (handler == null) return _pointCommandDetachedFailure();
    return handler();
  }

  /// Clears transient point focus.
  void clearPointFocus() => _clearPointFocusHandler?.call();

  /// Clears durable point selection.
  void clearPointSelection() => _clearPointSelectionHandler?.call();

  /// Replays the configured Pie, Donut, or Polar Column entrance animation.
  ///
  /// Reduced-motion preferences, `PieAnimationMode.none`,
  /// `PolarColumnAnimationMode.none`, and zero-duration animation themes still
  /// render the final frame immediately. This is a no-op when the controller
  /// is detached or the attached chart is not radial.
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

  /// Captures the chart document for readable Dart source generation.
  ///
  /// Unlike [extractDocument], this source-only path may describe runtime
  /// callbacks and formatters with explicit placeholders. Portable artifact
  /// extraction remains fail-closed when those descriptors are not supplied.
  ChartArtifactResult<ChartDocumentSnapshot> extractSourceDocument([
    ChartDocumentExtractOptions options = const ChartDocumentExtractOptions(),
  ]) {
    final handler = _extractSourceDocumentHandler;
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
    Object? attachment,
    required void Function(String) onSelect,
    required ChartSeriesCommandHandler onSelectSeriesIds,
    required void Function(String) onDeselect,
    required void Function() onClear,
    void Function(String, bool)? onSetSeriesVisibility,
    ChartDocumentExtractionHandler? onExtractDocument,
    ChartDocumentExtractionHandler? onExtractSourceDocument,
    void Function(ChartViewState)? onRestoreViewState,
    ChartPreviewCaptureHandler? onCapturePreview,
    ChartPointCommandHandler? onFocusPoints,
    ChartPointCommandHandler? onSelectPoints,
    ChartSelectionExpressionCommandHandler? onSelectExpression,
    ChartSelectionCommandHandler? onInvertSelection,
    ChartSelectionZoomCommandHandler? onZoomToSelection,
    ChartViewportZoomCommandHandler? onZoomViewport,
    ChartViewportPanCommandHandler? onPanViewport,
    ChartViewportFitCommandHandler? onFitData,
    ChartBooleanCommandHandler? onSelectAllData,
    ChartBooleanCommandHandler? onClearAllSelection,
    ChartBooleanCommandHandler? onReturnToLive,
    ChartSelectionBrushSetCommandHandler? onSetSelectionBrush,
    ChartSelectionBrushBoxSetCommandHandler? onSetSelectionBrushBox,
    ChartSelectionBrushVisibilityCommandHandler? onSetSelectionBrushVisibility,
    ChartSelectionCommandHandler? onClearSelectionBrush,
    void Function()? onClearPointFocus,
    void Function()? onClearPointSelection,
    void Function()? onReplayRadialEntrance,
    void Function()? onReplaySeriesEntrance,
    ChartDocumentRevision? effectiveDocumentRevision,
  }) {
    _attachment = attachment;
    _selectHandler = onSelect;
    _selectSeriesIdsHandler = onSelectSeriesIds;
    _deselectHandler = onDeselect;
    _clearHandler = onClear;
    _setVisibilityHandler = onSetSeriesVisibility;
    _extractDocumentHandler = onExtractDocument;
    _extractSourceDocumentHandler = onExtractSourceDocument;
    _restoreViewStateHandler = onRestoreViewState;
    _capturePreviewHandler = onCapturePreview;
    _focusPointsHandler = onFocusPoints;
    _selectPointsHandler = onSelectPoints;
    _selectExpressionHandler = onSelectExpression;
    _invertSelectionHandler = onInvertSelection;
    _zoomToSelectionHandler = onZoomToSelection;
    _zoomViewportHandler = onZoomViewport;
    _panViewportHandler = onPanViewport;
    _fitDataHandler = onFitData;
    _selectAllDataHandler = onSelectAllData;
    _clearAllSelectionHandler = onClearAllSelection;
    _returnToLiveHandler = onReturnToLive;
    _setSelectionBrushHandler = onSetSelectionBrush;
    _setSelectionBrushBoxHandler = onSetSelectionBrushBox;
    _setSelectionBrushVisibilityHandler = onSetSelectionBrushVisibility;
    _clearSelectionBrushHandler = onClearSelectionBrush;
    _clearPointFocusHandler = onClearPointFocus;
    _clearPointSelectionHandler = onClearPointSelection;
    _replayRadialEntranceHandler = onReplayRadialEntrance;
    _replaySeriesEntranceHandler = onReplaySeriesEntrance;
    if (!_disposed) {
      _effectiveDocumentRevision.value = effectiveDocumentRevision;
    }
  }

  /// Detaches from the chart state. Called in dispose.
  ///
  /// When [attachment] is supplied, a stale chart state cannot detach a newer
  /// state that has already taken ownership of this controller.
  void detach([Object? attachment]) {
    if (attachment != null && !identical(_attachment, attachment)) return;
    _attachment = null;
    _selectHandler = null;
    _selectSeriesIdsHandler = null;
    _deselectHandler = null;
    _clearHandler = null;
    _setVisibilityHandler = null;
    _extractDocumentHandler = null;
    _extractSourceDocumentHandler = null;
    _restoreViewStateHandler = null;
    _capturePreviewHandler = null;
    _focusPointsHandler = null;
    _selectPointsHandler = null;
    _selectExpressionHandler = null;
    _invertSelectionHandler = null;
    _zoomToSelectionHandler = null;
    _zoomViewportHandler = null;
    _panViewportHandler = null;
    _fitDataHandler = null;
    _selectAllDataHandler = null;
    _clearAllSelectionHandler = null;
    _returnToLiveHandler = null;
    _setSelectionBrushHandler = null;
    _setSelectionBrushBoxHandler = null;
    _setSelectionBrushVisibilityHandler = null;
    _clearSelectionBrushHandler = null;
    _clearPointFocusHandler = null;
    _clearPointSelectionHandler = null;
    _replayRadialEntranceHandler = null;
    _replaySeriesEntranceHandler = null;
    _selectionSnapshot = null;
    _selectionBrushState = null;
    if (!_disposed) _effectiveDocumentRevision.value = null;
  }

  /// Publishes an effective source revision from the attached chart state.
  @internal
  void updateEffectiveDocumentRevision(
    ChartDocumentRevision revision, {
    Object? attachment,
  }) {
    if (_disposed) return;
    if (attachment != null && !identical(_attachment, attachment)) return;
    if (_effectiveDocumentRevision.value == revision) return;
    _effectiveDocumentRevision.value = revision;
  }

  /// Updates mirrored slot state (called after every swap or selection change).
  void updateSlotState({
    required String? selectedSeriesId,
    required Set<String> selectedSeriesIds,
    required List<String> visibleAxisIds,
    required List<String> overflowAxisIds,
    Set<String> hiddenSeriesIds = const {},
  }) {
    if (_disposed) return;
    if (_selectedSeriesId == selectedSeriesId &&
        setEquals(_selectedSeriesIds, selectedSeriesIds) &&
        listEquals(_visibleAxisIds, visibleAxisIds) &&
        listEquals(_overflowAxisIds, overflowAxisIds) &&
        setEquals(_hiddenSeriesIds, hiddenSeriesIds)) {
      return;
    }
    _selectedSeriesId = selectedSeriesId;
    _selectedSeriesIds = Set.unmodifiable(selectedSeriesIds);
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
    ChartSelectionResult selectionResult = const ChartSelectionResult.empty(),
  }) {
    if (_disposed) return;
    if (setEquals(_focusedPointRefs, focusedPointRefs) &&
        setEquals(_selectedPointRefs, selectedPointRefs) &&
        _selectionResult == selectionResult) {
      return;
    }
    _focusedPointRefs = Set.unmodifiable(focusedPointRefs);
    _selectedPointRefs = Set.unmodifiable(selectedPointRefs);
    _selectionResult = selectionResult;
    notifyListeners();
  }

  /// Mirrors compact selection intent from the mounted chart.
  @internal
  void updateSelectionSnapshot(ChartSelectionSnapshot snapshot) {
    if (_disposed) return;
    if (_selectionExpression == snapshot.expression &&
        _selectionSnapshot?.revision == snapshot.revision) {
      return;
    }
    _selectionExpression = snapshot.expression;
    _selectionSnapshot = snapshot;
    notifyListeners();
  }

  /// Mirrors persistent brush state from the mounted chart.
  @internal
  void updateSelectionBrushState(ChartSelectionBrushState? state) {
    if (_disposed || _selectionBrushState == state) return;
    _selectionBrushState = state;
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
    _attachment = null;
    _effectiveDocumentRevision.dispose();
    super.dispose();
  }
}

bool _hasCompactPointClauses(ChartSelectionExpression expression) => expression
    .clauses
    .any((clause) => clause is! ChartSelectionWholeSeriesClause);
