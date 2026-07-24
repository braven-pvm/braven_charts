import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart'
    show ValueListenable, ValueNotifier, setEquals;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding, SchedulerPhase;
import 'package:flutter/services.dart';

import '../artifacts/chart_artifact.dart';
import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_artifact_extractor.dart';
import '../artifacts/chart_document_extractor.dart';
import '../artifacts/chart_view_state.dart';
import '../models/braven_chart_controller.dart';
import '../models/chart_context_action.dart';
import '../models/chart_selection_expression.dart';
import '../source/chart_dart_source_generator.dart';
import '../source/chart_grammar_source_generator.dart';
import '../source/chart_source_models.dart';
import '../source/chart_source_view.dart';
import '../table/chart_data_table.dart';
import '../table/chart_data_table_theme.dart';
import '../table/chart_table_controller.dart';
import '../table/chart_table_csv_download.dart';
import '../table/chart_table_export.dart';
import '../table/chart_table_model.dart';
import '../table/chart_table_options.dart';
import 'chart_workbench_models.dart';
import 'chart_workbench_group.dart';
import 'chart_workbench_context_scope.dart';

/// Builds the chart managed by a [BravenChartWorkbench].
typedef BravenChartBuilder =
    Widget Function(
      BuildContext context,
      BravenChartController chartController,
    );

/// Builds storage-agnostic host actions for a chart workbench.
typedef ChartWorkbenchActionsBuilder =
    List<Widget> Function(BuildContext context, ChartWorkbenchHandle handle);

/// Builds native context-menu actions with the mounted Workbench handle.
typedef ChartWorkbenchContextActionsBuilder =
    List<ChartContextAction> Function(
      BuildContext context,
      ChartWorkbenchHandle handle,
      ChartContextInvocation invocation,
    );

/// Builds one optional compact chart-overlay action with the mounted handle.
typedef ChartWorkbenchOverlayActionBuilder =
    ChartOverlayAction? Function(
      BuildContext context,
      ChartWorkbenchHandle handle,
    );

/// Receives a portable chart artifact created from the durable selection.
typedef ChartWorkbenchSelectionArtifactCallback = ValueChanged<ChartArtifact>;

/// Receives a selection-only tabular projection before package delivery.
typedef ChartWorkbenchSelectionExportCallback =
    ValueChanged<ChartTableCsvExport>;

/// Stable, observable access to a mounted chart workbench.
abstract interface class ChartWorkbenchHandle implements Listenable {
  /// Controller attached to the workbench's mounted chart.
  BravenChartController get chartController;

  /// Chart, Data, or Split mode selected by the user or host.
  ChartDisplayMode get requestedMode;

  /// Presentation currently shown after responsive fallback is applied.
  ChartDisplayMode get effectiveMode;

  /// Effective document snapshot used to build [tableModel], when available.
  ChartDocumentSnapshot? get tableSnapshot;

  /// Current native table projection, when extraction has succeeded.
  ChartTableModel? get tableModel;

  /// Whether [tableModel] was retained after its latest refresh failed.
  bool get tableIsStale;

  /// Whether a document extraction for the table is active.
  bool get isExtractingDocument;

  /// Whether an artifact and optional preview extraction is active.
  bool get isExtractingArtifact;

  /// Operation-scoped state for the workbench table.
  ChartWorkbenchTableState get tableState;

  /// Operation-scoped state for host-requested artifact extraction.
  ChartWorkbenchArtifactState get artifactState;

  /// Operation-scoped state for generated Dart source.
  ChartWorkbenchSourceState get sourceState;

  /// Most recent usable generated Dart source.
  ChartGeneratedSource? get generatedSource;

  /// Whether [generatedSource] represents an older chart revision.
  bool get sourceIsStale;

  /// Which form the Source pane currently reads the chart in.
  ChartSourceForm get sourceForm;

  /// Switches the Source form, re-emitting from the snapshot already held.
  void setSourceForm(ChartSourceForm form);

  /// Requests a display [mode] without throwing for a disabled mode.
  ChartArtifactResult<ChartDisplayMode> setDisplayMode(ChartDisplayMode mode);

  /// Coalesces concurrent requests and rebuilds the table from mounted state.
  Future<ChartArtifactResult<ChartDocumentSnapshot>> refreshTable();

  /// Coalesces concurrent requests and regenerates Dart from mounted state.
  Future<ChartArtifactResult<ChartGeneratedSource>> refreshSource();

  /// Atomically extracts the effective document and optional preview.
  Future<ChartArtifactResult<ChartArtifact>> extractArtifact(
    ChartArtifactExtractOptions options,
  );
}

/// Imperative controller and stable action handle for a chart workbench.
class ChartWorkbenchController extends ChangeNotifier
    implements ChartWorkbenchHandle {
  /// Creates a controller that may be attached to one workbench at a time.
  ChartWorkbenchController();

  BravenChartController? _chartController;
  Object? _attachment;
  bool _configured = false;
  bool _disposed = false;
  ChartDisplayMode _requestedMode = ChartDisplayMode.chart;
  ChartDisplayMode _effectiveMode = ChartDisplayMode.chart;
  Set<ChartDisplayMode> _availableModes = const {ChartDisplayMode.chart};
  ChartDocumentExtractOptions _documentOptions =
      const ChartDocumentExtractOptions(includeViewState: true);
  ChartTableOptions _tableOptions = const ChartTableOptions();
  ChartTableRefreshPolicy _refreshPolicy = ChartTableRefreshPolicy.onModeEntry;
  ChartDartSourceOptions _sourceOptions = const ChartDartSourceOptions();
  ChartGrammarSourceOptions _grammarSourceOptions =
      const ChartGrammarSourceOptions();
  ChartSourceRefreshPolicy _sourceRefreshPolicy =
      ChartSourceRefreshPolicy.onDocumentRevision;
  ChartSourceForm _sourceForm = ChartSourceForm.config;
  ValueChanged<ChartWorkbenchStatus>? _onStatusChanged;
  ChartWorkbenchTableState _tableState = const ChartWorkbenchTableState();
  ChartWorkbenchArtifactState _artifactState =
      const ChartWorkbenchArtifactState();
  ChartWorkbenchSourceState _sourceState = const ChartWorkbenchSourceState();
  Future<ChartArtifactResult<ChartDocumentSnapshot>>? _refreshFuture;
  Future<ChartArtifactResult<ChartGeneratedSource>>? _sourceRefreshFuture;
  Future<ChartArtifactResult<ChartArtifact>>? _artifactFuture;
  ChartDocumentRevision? _observedDocumentRevision;
  Timer? _revisionRefreshTimer;
  Timer? _sourceRevisionRefreshTimer;
  bool _statusNotificationFrameScheduled = false;
  ChartArtifactResult<ChartDisplayMode> Function(ChartDisplayMode)?
  _groupModeDelegate;

  @override
  BravenChartController get chartController {
    final controller = _chartController;
    if (controller == null) {
      throw StateError(
        'The ChartWorkbenchController is not attached to a workbench.',
      );
    }
    return controller;
  }

  @override
  ChartDisplayMode get requestedMode => _requestedMode;

  @override
  ChartDisplayMode get effectiveMode => _effectiveMode;

  @override
  ChartDocumentSnapshot? get tableSnapshot => _tableState.snapshot;

  @override
  ChartTableModel? get tableModel => _tableState.model;

  @override
  bool get tableIsStale => _tableState.isStale;

  @override
  bool get isExtractingDocument => _tableState.isLoading;

  @override
  bool get isExtractingArtifact => _artifactState.isExtracting;

  @override
  ChartWorkbenchTableState get tableState => _tableState;

  @override
  ChartWorkbenchArtifactState get artifactState => _artifactState;

  @override
  ChartWorkbenchSourceState get sourceState => _sourceState;

  @override
  ChartGeneratedSource? get generatedSource => _sourceState.generated;

  @override
  bool get sourceIsStale => _sourceState.isStale;

  @override
  ChartSourceForm get sourceForm => _sourceForm;

  @override
  void setSourceForm(ChartSourceForm form) {
    if (_sourceForm == form) return;
    _sourceForm = form;
    final snapshot = _sourceState.snapshot;
    if (snapshot == null) {
      unawaited(refreshSource());
      return;
    }
    // Both forms READ one captured document, so a form switch re-emits from
    // the snapshot already in hand instead of re-extracting the chart. That
    // keeps staleness meaning exactly what it meant before -- "the chart moved
    // on since this snapshot" -- rather than being reset by a toggle.
    final generated = _generateSource(snapshot);
    switch (generated) {
      case ChartArtifactFailure<ChartGeneratedSource>():
        _applySourceFailure(generated.error, generated.warnings, _sourceState);
      case ChartArtifactSuccess<ChartGeneratedSource>():
        _sourceState = ChartWorkbenchSourceState(
          phase: ChartWorkbenchSourcePhase.ready,
          form: form,
          snapshot: snapshot,
          generated: generated.value,
          isStale: _sourceState.isStale,
          warnings: generated.warnings,
        );
        _notifyStatus();
    }
  }

  /// Emits [snapshot] in whichever form the pane is showing.
  ChartArtifactResult<ChartGeneratedSource> _generateSource(
    ChartDocumentSnapshot snapshot,
  ) => switch (_sourceForm) {
    ChartSourceForm.config => ChartDartSourceGenerator.generate(
      snapshot,
      options: _sourceOptions,
    ),
    ChartSourceForm.grammar => ChartGrammarSourceGenerator.generate(
      snapshot,
      options: _grammarSourceOptions,
    ),
  };

  /// Current combined status snapshot.
  ChartWorkbenchStatus get status => ChartWorkbenchStatus(
    requestedMode: _requestedMode,
    effectiveMode: _effectiveMode,
    table: _tableState,
    artifact: _artifactState,
    source: _sourceState,
  );

  @override
  ChartArtifactResult<ChartDisplayMode> setDisplayMode(ChartDisplayMode mode) {
    final delegate = _groupModeDelegate;
    if (delegate != null) return delegate(mode);
    return _setDisplayModeLocally(mode);
  }

  ChartArtifactResult<ChartDisplayMode> _setDisplayModeLocally(
    ChartDisplayMode mode,
  ) {
    if (!_availableModes.contains(mode)) {
      return ChartArtifactFailure(
        error: ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.requestedDisplayModeUnavailable,
          message:
              '${_modeLabel(mode)} mode is not available in this workbench.',
        ),
      );
    }
    if (_requestedMode != mode) {
      _requestedMode = mode;
      _notifyStatus();
    }
    return ChartArtifactSuccess(value: mode);
  }

  @override
  Future<ChartArtifactResult<ChartDocumentSnapshot>> refreshTable() {
    final active = _refreshFuture;
    if (active != null) return active;
    final future = _performTableRefresh();
    _refreshFuture = future;
    unawaited(future.whenComplete(() => _refreshFuture = null));
    return future;
  }

  @override
  Future<ChartArtifactResult<ChartGeneratedSource>> refreshSource() {
    final active = _sourceRefreshFuture;
    if (active != null) return active;
    final future = _performSourceRefresh();
    _sourceRefreshFuture = future;
    unawaited(future.whenComplete(() => _sourceRefreshFuture = null));
    return future;
  }

  Future<ChartArtifactResult<ChartGeneratedSource>>
  _performSourceRefresh() async {
    final previous = _sourceState;
    _sourceState = ChartWorkbenchSourceState(
      phase: previous.hasUsableSource
          ? ChartWorkbenchSourcePhase.refreshing
          : ChartWorkbenchSourcePhase.loading,
      form: previous.form,
      snapshot: previous.snapshot,
      generated: previous.generated,
      isStale: previous.isStale,
      warnings: previous.warnings,
    );
    _notifyStatus();

    // Allow a newly built chart one frame to attach before extraction.
    await Future<void>.delayed(Duration.zero);
    final controller = _chartController;
    if (controller == null) {
      final failure = ChartArtifactFailure<ChartGeneratedSource>(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.chartNotAttached,
          message: 'The workbench is not attached to a mounted chart.',
        ),
      );
      _applySourceFailure(failure.error, failure.warnings, previous);
      return failure;
    }

    final extracted = controller.extractSourceDocument(_documentOptions);
    if (extracted case ChartArtifactFailure<ChartDocumentSnapshot>()) {
      final failure = ChartArtifactFailure<ChartGeneratedSource>(
        error: extracted.error,
        warnings: extracted.warnings,
      );
      _applySourceFailure(failure.error, failure.warnings, previous);
      return failure;
    }
    final snapshot =
        (extracted as ChartArtifactSuccess<ChartDocumentSnapshot>).value;
    final generated = _generateSource(snapshot);
    switch (generated) {
      case ChartArtifactFailure<ChartGeneratedSource>():
        final warnings = [...extracted.warnings, ...generated.warnings];
        _applySourceFailure(generated.error, warnings, previous);
        return ChartArtifactFailure(error: generated.error, warnings: warnings);
      case ChartArtifactSuccess<ChartGeneratedSource>():
        final warnings = [...extracted.warnings, ...generated.warnings];
        _sourceState = ChartWorkbenchSourceState(
          phase: ChartWorkbenchSourcePhase.ready,
          form: _sourceForm,
          snapshot: snapshot,
          generated: generated.value,
          isStale: _isSnapshotStale(snapshot),
          warnings: warnings,
        );
        _notifyStatus();
        if (_sourceState.isStale &&
            _sourceRefreshPolicy ==
                ChartSourceRefreshPolicy.onDocumentRevision) {
          _scheduleSourceRevisionRefresh();
        }
        return ChartArtifactSuccess(value: generated.value, warnings: warnings);
    }
  }

  void _applySourceFailure(
    ChartArtifactError error,
    List<ChartArtifactWarning> warnings,
    ChartWorkbenchSourceState previous,
  ) {
    _sourceState = ChartWorkbenchSourceState(
      phase: ChartWorkbenchSourcePhase.failed,
      form: previous.form,
      snapshot: previous.snapshot,
      generated: previous.generated,
      isStale: previous.hasUsableSource,
      warnings: warnings,
      error: error,
    );
    _notifyStatus();
  }

  Future<ChartArtifactResult<ChartDocumentSnapshot>>
  _performTableRefresh() async {
    final previous = _tableState;
    _tableState = ChartWorkbenchTableState(
      phase: previous.hasUsableTable
          ? ChartWorkbenchTablePhase.refreshing
          : ChartWorkbenchTablePhase.loading,
      snapshot: previous.snapshot,
      model: previous.model,
      isStale: previous.isStale,
      warnings: previous.warnings,
    );
    _notifyStatus();

    // Give the loading state one frame and allow a newly built chart to attach.
    await Future<void>.delayed(Duration.zero);
    final controller = _chartController;
    if (controller == null) {
      final failure = ChartArtifactFailure<ChartDocumentSnapshot>(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.chartNotAttached,
          message: 'The workbench is not attached to a mounted chart.',
        ),
      );
      _applyTableFailure(failure.error, failure.warnings, previous);
      return failure;
    }

    final extracted = controller.extractDocument(_documentOptions);
    switch (extracted) {
      case ChartArtifactFailure<ChartDocumentSnapshot>():
        _applyTableFailure(extracted.error, extracted.warnings, previous);
        return extracted;
      case ChartArtifactSuccess<ChartDocumentSnapshot>():
        try {
          final model = ChartTableModel.fromDocument(
            extracted.value.document,
            viewState: extracted.value.viewState,
            options: _tableOptions,
          );
          final warnings = [...extracted.warnings, ...model.warnings];
          _tableState = ChartWorkbenchTableState(
            phase: ChartWorkbenchTablePhase.ready,
            snapshot: extracted.value,
            model: model,
            isStale: _isSnapshotStale(extracted.value),
            warnings: warnings,
          );
          _notifyStatus();
          if (_tableState.isStale &&
              _refreshPolicy == ChartTableRefreshPolicy.onDocumentRevision) {
            _scheduleRevisionRefresh();
          }
          return ChartArtifactSuccess(
            value: extracted.value,
            warnings: warnings,
          );
        } on Object catch (error) {
          final failure = ChartArtifactFailure<ChartDocumentSnapshot>(
            error: ChartArtifactError(
              code: ChartArtifactDiagnosticCodes.tableProjectionFailed,
              message: 'The chart data table could not be prepared: $error',
            ),
            warnings: extracted.warnings,
          );
          _applyTableFailure(failure.error, failure.warnings, previous);
          return failure;
        }
    }
  }

  void _applyTableFailure(
    ChartArtifactError error,
    List<ChartArtifactWarning> warnings,
    ChartWorkbenchTableState previous,
  ) {
    _tableState = ChartWorkbenchTableState(
      phase: ChartWorkbenchTablePhase.failed,
      snapshot: previous.snapshot,
      model: previous.model,
      isStale: previous.hasUsableTable,
      warnings: warnings,
      error: error,
    );
    _notifyStatus();
  }

  @override
  Future<ChartArtifactResult<ChartArtifact>> extractArtifact(
    ChartArtifactExtractOptions options,
  ) {
    if (_artifactFuture != null) {
      return Future.value(
        ChartArtifactFailure(
          error: const ChartArtifactError(
            code: ChartArtifactDiagnosticCodes.captureInProgress,
            message: 'A chart artifact extraction is already in progress.',
          ),
        ),
      );
    }
    final future = _performArtifactExtraction(options);
    _artifactFuture = future;
    unawaited(future.whenComplete(() => _artifactFuture = null));
    return future;
  }

  Future<ChartArtifactResult<ChartArtifact>> _performArtifactExtraction(
    ChartArtifactExtractOptions options,
  ) async {
    _artifactState = const ChartWorkbenchArtifactState(
      phase: ChartWorkbenchArtifactPhase.extracting,
    );
    _notifyStatus();
    final controller = _chartController;
    if (controller == null) {
      final failure = ChartArtifactFailure<ChartArtifact>(
        error: const ChartArtifactError(
          code: ChartArtifactDiagnosticCodes.chartNotAttached,
          message: 'The workbench is not attached to a mounted chart.',
        ),
      );
      _artifactState = ChartWorkbenchArtifactState(
        phase: ChartWorkbenchArtifactPhase.failed,
        error: failure.error,
      );
      _notifyStatus();
      return failure;
    }

    final result = await controller.extractArtifact(options);
    switch (result) {
      case ChartArtifactSuccess<ChartArtifact>():
        _artifactState = ChartWorkbenchArtifactState(
          phase: ChartWorkbenchArtifactPhase.succeeded,
          artifact: result.value,
          warnings: result.warnings,
        );
      case ChartArtifactFailure<ChartArtifact>():
        _artifactState = ChartWorkbenchArtifactState(
          phase: ChartWorkbenchArtifactPhase.failed,
          warnings: result.warnings,
          error: result.error,
        );
    }
    _notifyStatus();
    return result;
  }

  void _attach(
    Object attachment, {
    required BravenChartController chartController,
    required ChartDisplayMode initialMode,
    required Set<ChartDisplayMode> availableModes,
    required ChartDocumentExtractOptions documentOptions,
    required ChartTableOptions tableOptions,
    required ChartTableRefreshPolicy refreshPolicy,
    required ChartDartSourceOptions sourceOptions,
    required ChartGrammarSourceOptions grammarSourceOptions,
    required ChartSourceRefreshPolicy sourceRefreshPolicy,
    required ChartSourceForm initialSourceForm,
    required ValueChanged<ChartWorkbenchStatus>? onStatusChanged,
  }) {
    if (_attachment != null && !identical(_attachment, attachment)) {
      throw StateError(
        'A ChartWorkbenchController can be attached to only one workbench.',
      );
    }
    _attachment = attachment;
    _chartController = chartController;
    _listenToChartController(chartController);
    _onStatusChanged = onStatusChanged;
    _configure(
      initialMode: initialMode,
      availableModes: availableModes,
      documentOptions: documentOptions,
      tableOptions: tableOptions,
      refreshPolicy: refreshPolicy,
      sourceOptions: sourceOptions,
      grammarSourceOptions: grammarSourceOptions,
      sourceRefreshPolicy: sourceRefreshPolicy,
      initialSourceForm: initialSourceForm,
    );
  }

  void _configure({
    required ChartDisplayMode initialMode,
    required Set<ChartDisplayMode> availableModes,
    required ChartDocumentExtractOptions documentOptions,
    required ChartTableOptions tableOptions,
    required ChartTableRefreshPolicy refreshPolicy,
    required ChartDartSourceOptions sourceOptions,
    required ChartGrammarSourceOptions grammarSourceOptions,
    required ChartSourceRefreshPolicy sourceRefreshPolicy,
    required ChartSourceForm initialSourceForm,
  }) {
    var statusChanged = false;
    _availableModes = Set.unmodifiable(availableModes);
    _documentOptions = documentOptions;
    _tableOptions = tableOptions;
    _refreshPolicy = refreshPolicy;
    _sourceOptions = sourceOptions;
    _grammarSourceOptions = grammarSourceOptions;
    _sourceRefreshPolicy = sourceRefreshPolicy;
    if (!_configured) {
      _configured = true;
      _sourceForm = initialSourceForm;
      _requestedMode = _availableModes.contains(initialMode)
          ? initialMode
          : _firstAvailableMode(_availableModes);
      _effectiveMode = _requestedMode;
      statusChanged = true;
    } else if (!_availableModes.contains(_requestedMode)) {
      _requestedMode = _firstAvailableMode(_availableModes);
      statusChanged = true;
    }
    if (_refreshPolicy == ChartTableRefreshPolicy.onDocumentRevision &&
        _tableState.isStale) {
      _scheduleRevisionRefresh();
    }
    if (_sourceRefreshPolicy == ChartSourceRefreshPolicy.onDocumentRevision &&
        _sourceState.isStale) {
      _scheduleSourceRevisionRefresh();
    }
    if (statusChanged) _scheduleStatusNotification();
  }

  void _replaceChartController(BravenChartController controller) {
    _stopListeningToChartController();
    _chartController = controller;
    _listenToChartController(controller);
    if (_tableState.hasUsableTable) {
      _tableState = ChartWorkbenchTableState(
        phase: _tableState.phase,
        snapshot: _tableState.snapshot,
        model: _tableState.model,
        isStale: true,
        warnings: _tableState.warnings,
        error: _tableState.error,
      );
    }
    if (_sourceState.hasUsableSource) {
      _sourceState = ChartWorkbenchSourceState(
        phase: _sourceState.phase,
        form: _sourceState.form,
        snapshot: _sourceState.snapshot,
        generated: _sourceState.generated,
        isStale: true,
        warnings: _sourceState.warnings,
        error: _sourceState.error,
      );
    }
    _notifyStatus();
  }

  void _setEffectiveMode(ChartDisplayMode mode) {
    if (_effectiveMode == mode) return;
    final previous = _effectiveMode;
    _effectiveMode = mode;
    _notifyStatus();

    final tableBecameVisible =
        _modeShowsTable(mode) && !_modeShowsTable(previous);
    final firstUse = tableBecameVisible && _tableState.snapshot == null;
    final refreshOnEntry =
        tableBecameVisible &&
        _refreshPolicy == ChartTableRefreshPolicy.onModeEntry;
    final refreshStaleRevision =
        tableBecameVisible &&
        _refreshPolicy == ChartTableRefreshPolicy.onDocumentRevision &&
        _tableState.isStale;
    if (firstUse || refreshOnEntry || refreshStaleRevision) {
      unawaited(refreshTable());
    }

    final sourceBecameVisible =
        _modeShowsSource(mode) && !_modeShowsSource(previous);
    final firstSourceUse = sourceBecameVisible && _sourceState.snapshot == null;
    final refreshSourceOnEntry =
        sourceBecameVisible &&
        _sourceRefreshPolicy == ChartSourceRefreshPolicy.onModeEntry;
    final refreshStaleSource =
        sourceBecameVisible &&
        _sourceRefreshPolicy == ChartSourceRefreshPolicy.onDocumentRevision &&
        _sourceState.isStale;
    if (firstSourceUse || refreshSourceOnEntry || refreshStaleSource) {
      unawaited(refreshSource());
    }
  }

  void _ensureInitialSurfacesIfNeeded() {
    if (_modeShowsTable(_effectiveMode) &&
        _tableState.snapshot == null &&
        _tableState.phase == ChartWorkbenchTablePhase.uninitialized &&
        _refreshFuture == null) {
      unawaited(refreshTable());
    }
    if (_modeShowsSource(_effectiveMode) &&
        _sourceState.snapshot == null &&
        _sourceState.phase == ChartWorkbenchSourcePhase.uninitialized &&
        _sourceRefreshFuture == null) {
      unawaited(refreshSource());
    }
  }

  void _detach(Object attachment) {
    if (!identical(_attachment, attachment)) return;
    _revisionRefreshTimer?.cancel();
    _revisionRefreshTimer = null;
    _sourceRevisionRefreshTimer?.cancel();
    _sourceRevisionRefreshTimer = null;
    _stopListeningToChartController();
    _attachment = null;
    _chartController = null;
    _onStatusChanged = null;
  }

  void _notifyStatus() {
    if (_disposed) return;
    // A status change can originate from inside a frame the framework is still
    // building: a remounted chart attaches its controller from `initState`,
    // which publishes an effective document revision while this workbench's
    // own subtree is under construction. Rebuilding a listening widget from
    // there is illegal, so publish once the frame is finished instead. Every
    // state change stays synchronous — only the notification moves.
    if (_isInsideFrame) {
      _scheduleStatusNotification();
      return;
    }
    notifyListeners();
    _onStatusChanged?.call(status);
  }

  /// Whether the framework is currently building, laying out, or painting.
  ///
  /// Marking a widget dirty during those phases throws; every other phase
  /// (idle, transient callbacks, post-frame callbacks) simply schedules the
  /// next frame.
  static bool get _isInsideFrame =>
      switch (WidgetsBinding.instance.schedulerPhase) {
        SchedulerPhase.persistentCallbacks ||
        SchedulerPhase.midFrameMicrotasks => true,
        SchedulerPhase.idle ||
        SchedulerPhase.transientCallbacks ||
        SchedulerPhase.postFrameCallbacks => false,
      };

  void _scheduleStatusNotification() {
    if (_statusNotificationFrameScheduled || _disposed) return;
    _statusNotificationFrameScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _statusNotificationFrameScheduled = false;
      if (!_disposed && _attachment != null) _notifyStatus();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    _revisionRefreshTimer?.cancel();
    _sourceRevisionRefreshTimer?.cancel();
    _stopListeningToChartController();
    _attachment = null;
    _chartController = null;
    _onStatusChanged = null;
    super.dispose();
  }

  void _listenToChartController(BravenChartController controller) {
    _observedDocumentRevision = controller.effectiveDocumentRevision.value;
    controller.effectiveDocumentRevision.addListener(
      _handleEffectiveDocumentRevision,
    );
  }

  void _stopListeningToChartController() {
    _chartController?.effectiveDocumentRevision.removeListener(
      _handleEffectiveDocumentRevision,
    );
    _observedDocumentRevision = null;
  }

  void _handleEffectiveDocumentRevision() {
    final revision = _chartController?.effectiveDocumentRevision.value;
    if (revision == null || revision == _observedDocumentRevision) return;
    _observedDocumentRevision = revision;
    var changed = false;
    final tableSnapshot = _tableState.snapshot;
    if (tableSnapshot != null && tableSnapshot.revision != revision) {
      _tableState = ChartWorkbenchTableState(
        phase: _tableState.phase,
        snapshot: tableSnapshot,
        model: _tableState.model,
        isStale: true,
        warnings: _tableState.warnings,
        error: _tableState.error,
      );
      changed = true;
      if (_refreshPolicy == ChartTableRefreshPolicy.onDocumentRevision &&
          _modeShowsTable(_effectiveMode)) {
        _scheduleRevisionRefresh();
      }
    }
    final sourceSnapshot = _sourceState.snapshot;
    if (sourceSnapshot != null && sourceSnapshot.revision != revision) {
      _sourceState = ChartWorkbenchSourceState(
        phase: _sourceState.phase,
        form: _sourceState.form,
        snapshot: sourceSnapshot,
        generated: _sourceState.generated,
        isStale: true,
        warnings: _sourceState.warnings,
        error: _sourceState.error,
      );
      changed = true;
      if (_sourceRefreshPolicy == ChartSourceRefreshPolicy.onDocumentRevision &&
          _modeShowsSource(_effectiveMode)) {
        _scheduleSourceRevisionRefresh();
      }
    }
    if (changed) _notifyStatus();
  }

  bool _isSnapshotStale(ChartDocumentSnapshot snapshot) {
    final revision = _chartController?.effectiveDocumentRevision.value;
    return revision != null && snapshot.revision != revision;
  }

  void _scheduleRevisionRefresh() {
    if (_revisionRefreshTimer != null ||
        !_modeShowsTable(_effectiveMode) ||
        _tableState.snapshot == null) {
      return;
    }
    _revisionRefreshTimer = Timer(const Duration(milliseconds: 250), () {
      _revisionRefreshTimer = null;
      if (!_disposed &&
          _attachment != null &&
          _modeShowsTable(_effectiveMode) &&
          _tableState.isStale) {
        unawaited(refreshTable());
      }
    });
  }

  void _scheduleSourceRevisionRefresh() {
    if (_sourceRevisionRefreshTimer != null ||
        !_modeShowsSource(_effectiveMode) ||
        _sourceState.snapshot == null) {
      return;
    }
    _sourceRevisionRefreshTimer = Timer(const Duration(milliseconds: 250), () {
      _sourceRevisionRefreshTimer = null;
      if (!_disposed &&
          _attachment != null &&
          _modeShowsSource(_effectiveMode) &&
          _sourceState.isStale) {
        unawaited(refreshSource());
      }
    });
  }
}

/// Package-owned Chart/Data/Split composition for one mounted chart.
class BravenChartWorkbench extends StatefulWidget {
  /// Creates a reusable Chart/Data/Split composition around one mounted chart.
  ///
  /// The [chartBuilder] must attach its supplied controller to the chart it
  /// returns. Controllers supplied by the caller remain caller-owned.
  const BravenChartWorkbench({
    super.key,
    required this.chartBuilder,
    this.chartController,
    this.workbenchController,
    this.tableController,
    this.groupController,
    this.initialDisplayMode = ChartDisplayMode.chart,
    this.availableDisplayModes = const {
      ChartDisplayMode.chart,
      ChartDisplayMode.data,
      ChartDisplayMode.split,
    },
    this.documentOptions = const ChartDocumentExtractOptions(
      includeViewState: true,
    ),
    this.tableOptions = const ChartTableOptions(),
    this.tableRefreshPolicy = ChartTableRefreshPolicy.onModeEntry,
    this.sourceOptions = const ChartDartSourceOptions(),
    this.grammarSourceOptions = const ChartGrammarSourceOptions(),
    this.sourceRefreshPolicy = ChartSourceRefreshPolicy.onDocumentRevision,
    this.initialSourceForm = ChartSourceForm.config,
    this.actionsBuilder,
    this.contextActionsBuilder,
    this.chartActionButtonBuilder,
    this.chartActionButtonConfig = const ChartOverlayActionButtonConfig(),
    this.showSelectionActions = false,
    this.selectionProjection = const ChartSelectionProjectionOptions(),
    this.selectionZoomPaddingFraction = 0.08,
    this.selectionCsvFileName = 'chart-selection.csv',
    this.onSelectionArtifactCreated,
    this.onSelectionCopied,
    this.onSelectionCsvExported,
    this.linkTableRowsToChart = true,
    this.onTableRowFocused,
    this.onTableRowFocusCleared,
    this.onTableRowHoverChanged,
    this.onTableRowActivation,
    this.onTableRowActivated,
    this.onTableSelectAllPoints,
    this.onTableSelectionCleared,
    this.onPointLinkError,
    this.showModeSwitcher = true,
    this.splitBreakpoint = 900,
    this.splitAxis = Axis.horizontal,
    this.splitRatio = 0.5,
    this.isSplitResizable = true,
    this.autoFitTablePane = false,
    this.minimumChartPaneExtent = 320,
    this.minimumTablePaneExtent = 360,
    this.maximumAutoTablePaneExtent = 640,
    this.splitGap = 16,
    this.onSplitRatioChanged,
    this.onStatusChanged,
  }) : assert(availableDisplayModes.length > 0),
       assert(
         selectionZoomPaddingFraction >= 0 &&
             selectionZoomPaddingFraction < double.infinity,
       ),
       assert(selectionCsvFileName != ''),
       assert(splitBreakpoint > 0),
       assert(splitRatio > 0 && splitRatio < 1),
       assert(minimumChartPaneExtent >= 0),
       assert(minimumTablePaneExtent >= 0),
       assert(maximumAutoTablePaneExtent > 0),
       assert(splitGap >= 0);

  /// Builds the chart with the controller owned or adopted by this workbench.
  final BravenChartBuilder chartBuilder;

  /// Optional caller-owned controller attached to the mounted chart.
  final BravenChartController? chartController;

  /// Optional caller-owned workbench controller and action handle.
  final ChartWorkbenchController? workbenchController;

  /// Optional caller-owned controller for table sort and focus state.
  final ChartTableController? tableController;

  /// Optional shared presentation controller.
  ///
  /// When omitted, the nearest [ChartWorkbenchScope] is used. An explicit
  /// controller takes precedence over an inherited scope.
  final ChartWorkbenchGroupController? groupController;

  /// Mode selected when a newly attached controller has no prior state.
  final ChartDisplayMode initialDisplayMode;

  /// Modes the user or host may request.
  final Set<ChartDisplayMode> availableDisplayModes;

  /// Rules used when extracting the effective document for the table.
  final ChartDocumentExtractOptions documentOptions;

  /// Scope, row layout, alignment, and formatter rules for the table.
  final ChartTableOptions tableOptions;

  /// Determines when the table snapshot is refreshed automatically.
  final ChartTableRefreshPolicy tableRefreshPolicy;

  /// Formatting, data-volume, and view-state rules for generated Dart.
  final ChartDartSourceOptions sourceOptions;

  /// Naming and data-volume rules for the generated grammar chain.
  final ChartGrammarSourceOptions grammarSourceOptions;

  /// Determines when generated source is refreshed automatically.
  ///
  /// Defaults to [ChartSourceRefreshPolicy.onDocumentRevision] so visible
  /// Source always follows the chart's current effective configuration.
  final ChartSourceRefreshPolicy sourceRefreshPolicy;

  /// The form the Source pane opens in.
  ///
  /// The pane always offers BOTH forms; this only chooses which one is shown
  /// first, so a host whose charts are grammar-authored can open on the chain.
  final ChartSourceForm initialSourceForm;

  /// Builds storage-agnostic host actions with a stable imperative handle.
  final ChartWorkbenchActionsBuilder? actionsBuilder;

  /// Builds host commands for the mounted chart's native context menu.
  ///
  /// The callback receives the same stable handle as [actionsBuilder], so a
  /// visible action and its context-menu accelerator can share one extraction
  /// and persistence path.
  final ChartWorkbenchContextActionsBuilder? contextActionsBuilder;

  /// Builds one compact host action over the mounted chart viewport.
  ///
  /// This is independent of [actionsBuilder] and [contextActionsBuilder]. The
  /// host may expose the same operation in any one, two, or all three places.
  final ChartWorkbenchOverlayActionBuilder? chartActionButtonBuilder;

  /// Placement and Material presentation of [chartActionButtonBuilder].
  final ChartOverlayActionButtonConfig chartActionButtonConfig;

  /// Whether a summary and action strip is shown for durable selections.
  final bool showSelectionActions;

  /// Data-boundary rules used by selection-only artifacts and exports.
  final ChartSelectionProjectionOptions selectionProjection;

  /// Fractional padding applied by the package-owned selection Zoom action.
  ///
  /// The value is applied independently to the selected X and Y spans.
  final double selectionZoomPaddingFraction;

  /// Browser download name used by the package-owned CSV action.
  final String selectionCsvFileName;

  /// Receives the portable selection-only artifact created by "Create chart".
  ///
  /// The artifact also remains available through
  /// [ChartWorkbenchHandle.artifactState].
  final ChartWorkbenchSelectionArtifactCallback? onSelectionArtifactCreated;

  /// Overrides package-owned clipboard delivery for selection data.
  final ChartWorkbenchSelectionExportCallback? onSelectionCopied;

  /// Overrides package-owned web CSV delivery for selection data.
  final ChartWorkbenchSelectionExportCallback? onSelectionCsvExported;

  /// Enables revision-safe keyboard focus and activation linking by default.
  final bool linkTableRowsToChart;

  /// Overrides the default transient focus behavior when supplied.
  final ChartTableRowCallback? onTableRowFocused;

  /// Overrides the default focus-clear behavior when supplied.
  final VoidCallback? onTableRowFocusCleared;

  /// Overrides the default transient pointer-hover linking when supplied.
  final ChartTableRowHoverCallback? onTableRowHoverChanged;

  /// Overrides modifier-aware durable point selection when supplied.
  ///
  /// This takes precedence over [onTableRowActivated].
  final ChartTableRowActivationCallback? onTableRowActivation;

  /// Legacy durable-selection override used when [onTableRowActivation] is null.
  final ChartTableRowCallback? onTableRowActivated;

  /// Overrides Ctrl/Command+A selection of the displayed table dataset.
  final ChartTableRowCallback? onTableSelectAllPoints;

  /// Overrides the package-owned table action that clears point selection.
  final VoidCallback? onTableSelectionCleared;

  /// Receives structured stale/invalid point-link failures.
  final ValueChanged<ChartArtifactError>? onPointLinkError;

  /// Whether the package-owned Chart/Data/Split control is shown.
  final bool showModeSwitcher;

  /// Minimum content width at which a requested Split is shown side by side.
  final double splitBreakpoint;

  /// Direction in which chart and table panes are arranged.
  final Axis splitAxis;

  /// Fraction of the available split dimension assigned to the chart.
  ///
  /// This is the fallback before a table is ready, when [autoFitTablePane] is
  /// disabled, and after a host rebuild resets this workbench state.
  final double splitRatio;

  /// Whether the user can drag or keyboard-adjust the Split divider.
  final bool isSplitResizable;

  /// Sizes a horizontal table pane to its native column footprint when true.
  ///
  /// The estimate is capped by [maximumAutoTablePaneExtent] and constrained by
  /// both minimum pane extents. A manual resize takes precedence until the
  /// divider is reset with Escape or a double click.
  final bool autoFitTablePane;

  /// Smallest chart width or height retained while Split is active.
  final double minimumChartPaneExtent;

  /// Smallest data-table width or height retained while Split is active.
  final double minimumTablePaneExtent;

  /// Largest automatic width assigned to the table before it scrolls.
  final double maximumAutoTablePaneExtent;

  /// Visual space between the chart and table panes.
  final double splitGap;

  /// Reports the effective chart share after a user resize or reset.
  final ValueChanged<double>? onSplitRatioChanged;

  /// Reports mode, table, and artifact status without owning host messaging.
  final ValueChanged<ChartWorkbenchStatus>? onStatusChanged;

  @override
  State<BravenChartWorkbench> createState() => _BravenChartWorkbenchState();
}

class _BravenChartWorkbenchState extends State<BravenChartWorkbench> {
  late BravenChartController _chartController;
  late ChartWorkbenchController _workbenchController;
  late ChartTableController _tableController;
  late bool _ownsChartController;
  late bool _ownsWorkbenchController;
  late bool _ownsTableController;
  ChartDisplayMode _compactSplitPane = ChartDisplayMode.chart;
  ChartDisplayMode? _scheduledEffectiveMode;
  ChartArtifactError? _pointLinkError;
  _TablePointFocus? _keyboardTableFocus;
  _TablePointFocus? _hoveredTableFocus;
  double? _manualSplitRatio;
  ChartWorkbenchGroupController? _groupController;
  final ValueNotifier<bool> _selectionActionInProgress = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _acquireControllers();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncGroupController();
  }

  void _acquireControllers() {
    _ownsChartController = widget.chartController == null;
    _chartController = widget.chartController ?? BravenChartController();
    _ownsWorkbenchController = widget.workbenchController == null;
    _workbenchController =
        widget.workbenchController ?? ChartWorkbenchController();
    _ownsTableController = widget.tableController == null;
    _tableController = widget.tableController ?? ChartTableController();
    _workbenchController._attach(
      this,
      chartController: _chartController,
      initialMode: widget.initialDisplayMode,
      availableModes: widget.availableDisplayModes,
      documentOptions: widget.documentOptions,
      tableOptions: widget.tableOptions,
      refreshPolicy: widget.tableRefreshPolicy,
      sourceOptions: widget.sourceOptions,
      grammarSourceOptions: widget.grammarSourceOptions,
      sourceRefreshPolicy: widget.sourceRefreshPolicy,
      initialSourceForm: widget.initialSourceForm,
      onStatusChanged: widget.onStatusChanged,
    );
  }

  @override
  void didUpdateWidget(BravenChartWorkbench oldWidget) {
    super.didUpdateWidget(oldWidget);
    final workbenchChanged =
        oldWidget.workbenchController != widget.workbenchController;
    final chartChanged = oldWidget.chartController != widget.chartController;
    final tableChanged = oldWidget.tableController != widget.tableController;
    if (oldWidget.splitAxis != widget.splitAxis) {
      _manualSplitRatio = null;
    }

    if (workbenchChanged) {
      final oldController = _workbenchController;
      final owned = _ownsWorkbenchController;
      oldController._groupModeDelegate = null;
      oldController._detach(this);
      _ownsWorkbenchController = widget.workbenchController == null;
      _workbenchController =
          widget.workbenchController ?? ChartWorkbenchController();
      if (owned) oldController.dispose();
      _workbenchController._attach(
        this,
        chartController: _chartController,
        initialMode: widget.initialDisplayMode,
        availableModes: widget.availableDisplayModes,
        documentOptions: widget.documentOptions,
        tableOptions: widget.tableOptions,
        refreshPolicy: widget.tableRefreshPolicy,
        sourceOptions: widget.sourceOptions,
        grammarSourceOptions: widget.grammarSourceOptions,
        sourceRefreshPolicy: widget.sourceRefreshPolicy,
        initialSourceForm: widget.initialSourceForm,
        onStatusChanged: widget.onStatusChanged,
      );
    }

    if (chartChanged) {
      final oldController = _chartController;
      final owned = _ownsChartController;
      _ownsChartController = widget.chartController == null;
      _chartController = widget.chartController ?? BravenChartController();
      _workbenchController._replaceChartController(_chartController);
      if (owned) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          oldController.dispose();
        });
      }
    }

    if (tableChanged) {
      final oldController = _tableController;
      final owned = _ownsTableController;
      _ownsTableController = widget.tableController == null;
      _tableController = widget.tableController ?? ChartTableController();
      if (owned) oldController.dispose();
    }

    _workbenchController
      .._onStatusChanged = widget.onStatusChanged
      .._configure(
        initialMode: widget.initialDisplayMode,
        availableModes: widget.availableDisplayModes,
        documentOptions: widget.documentOptions,
        tableOptions: widget.tableOptions,
        refreshPolicy: widget.tableRefreshPolicy,
        sourceOptions: widget.sourceOptions,
        grammarSourceOptions: widget.grammarSourceOptions,
        sourceRefreshPolicy: widget.sourceRefreshPolicy,
        initialSourceForm: widget.initialSourceForm,
      );
    _syncGroupController(force: workbenchChanged);
    _groupController?.updateWorkbench(this, widget.availableDisplayModes);
  }

  @override
  void dispose() {
    _disconnectGroupController();
    _workbenchController._detach(this);
    if (_ownsWorkbenchController) _workbenchController.dispose();
    if (_ownsTableController) _tableController.dispose();
    if (_ownsChartController) _chartController.dispose();
    _selectionActionInProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chart = ChartWorkbenchContextActionScope(
      actionsBuilder: widget.contextActionsBuilder == null
          ? null
          : (actionContext, invocation) => widget.contextActionsBuilder!(
              actionContext,
              _workbenchController,
              invocation,
            ),
      overlayActionBuilder: widget.chartActionButtonBuilder == null
          ? null
          : (actionContext) => widget.chartActionButtonBuilder!(
              actionContext,
              _workbenchController,
            ),
      overlayActionConfig: widget.chartActionButtonConfig,
      actionListenable: _workbenchController,
      child: KeyedSubtree(
        key: const ValueKey('chart-workbench-chart'),
        child: widget.chartBuilder(context, _chartController),
      ),
    );
    return AnimatedBuilder(
      animation: _workbenchController,
      child: chart,
      builder: (context, chart) {
        final actions =
            widget.actionsBuilder?.call(context, _workbenchController) ??
            const <Widget>[];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_showModeSwitcher || actions.isNotEmpty)
              _buildControls(context, actions),
            if (widget.showSelectionActions)
              _ChartSelectionActionsHost(
                controller: _chartController,
                busy: _selectionActionInProgress,
                builder: _buildSelectionActions,
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < widget.splitBreakpoint;
                  final requested = _workbenchController.requestedMode;
                  final effective =
                      compact && requested == ChartDisplayMode.split
                      ? _compactSplitPane
                      : requested;
                  _scheduleEffectiveMode(effective);
                  return _buildStage(context, constraints, chart!, effective);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(BuildContext context, List<Widget> actions) {
    final requested = _workbenchController.requestedMode;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < widget.splitBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_showModeSwitcher)
                    _ModeSwitcher(
                      availableModes: _availableDisplayModes,
                      selectedMode: requested,
                      onSelected: _workbenchController.setDisplayMode,
                    ),
                  ...actions,
                ],
              ),
              if (compact && requested == ChartDisplayMode.split) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SegmentedButton<ChartDisplayMode>(
                      key: const ValueKey('compact-split-pane-switcher'),
                      segments: const [
                        ButtonSegment(
                          value: ChartDisplayMode.chart,
                          icon: Icon(Icons.show_chart),
                          label: Text('Chart pane'),
                        ),
                        ButtonSegment(
                          value: ChartDisplayMode.data,
                          icon: Icon(Icons.table_rows_outlined),
                          label: Text('Data pane'),
                        ),
                      ],
                      selected: {_compactSplitPane},
                      onSelectionChanged: (selection) {
                        setState(() => _compactSplitPane = selection.single);
                      },
                      style: const ButtonStyle(
                        minimumSize: WidgetStatePropertyAll(Size(0, 48)),
                      ),
                    ),
                    SizedBox(
                      width: math.min(420, constraints.maxWidth),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Split resumes when more space is available',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildSelectionActions(BuildContext context) {
    final snapshot = _chartController.selectionSnapshot;
    final hasSelection = snapshot != null && snapshot.isNotEmpty;
    final colors = Theme.of(context).colorScheme;
    final summary = hasSelection
        ? _selectionSummary(snapshot)
        : 'Nothing selected';
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: Semantics(
        container: true,
        liveRegion: true,
        label: 'Chart selection actions. $summary',
        child: Material(
          key: const ValueKey('chart-selection-action-strip'),
          color: colors.secondaryContainer.withValues(alpha: 0.42),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: colors.outlineVariant),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 176),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.select_all_outlined,
                        size: 20,
                        color: colors.onSecondaryContainer,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          summary,
                          key: const ValueKey('chart-selection-summary'),
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: colors.onSecondaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  key: const ValueKey('chart-selection-create-chart'),
                  onPressed: !hasSelection || _selectionActionInProgress.value
                      ? null
                      : _createChartFromSelection,
                  icon: _selectionActionInProgress.value
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_chart_outlined),
                  label: Text(
                    _selectionActionInProgress.value
                        ? 'Creating…'
                        : 'Create chart',
                  ),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('chart-selection-zoom'),
                  onPressed: hasSelection ? _zoomToSelection : null,
                  icon: const Icon(Icons.zoom_in_map_outlined),
                  label: const Text('Zoom'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('chart-selection-copy'),
                  onPressed: hasSelection ? _copySelection : null,
                  icon: const Icon(Icons.copy_outlined),
                  label: const Text('Copy'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('chart-selection-export-csv'),
                  onPressed: hasSelection ? _exportSelectionCsv : null,
                  icon: const Icon(Icons.download_outlined),
                  label: const Text('CSV'),
                ),
                OutlinedButton.icon(
                  key: const ValueKey('chart-selection-invert'),
                  onPressed: hasSelection ? _invertSelection : null,
                  icon: const Icon(Icons.flip_outlined),
                  label: const Text('Invert'),
                ),
                TextButton.icon(
                  key: const ValueKey('chart-selection-clear'),
                  onPressed: hasSelection ? _clearSelection : null,
                  icon: const Icon(Icons.close),
                  label: const Text('Clear'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _selectionSummary(ChartSelectionSnapshot snapshot) {
    final statistics = snapshot.statistics;
    final pointCount = statistics.pointCount;
    final seriesCount = statistics.seriesCount;
    final parts = <String>[
      pointCount == 1 ? '1 point' : '$pointCount points',
      seriesCount == 1 ? '1 series' : '$seriesCount series',
    ];
    final extents = snapshot.extents;
    if (extents != null) {
      parts.add(
        'X ${_compactNumber(extents.minimumX)}–${_compactNumber(extents.maximumX)}',
      );
    }
    return parts.join(' · ');
  }

  String _compactNumber(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(0);
    return value.toStringAsFixed(2);
  }

  ChartDocumentExtractOptions get _selectionDocumentOptions =>
      widget.documentOptions.copyWith(
        dataScope: ChartDataScope.selection,
        selectionProjection: widget.selectionProjection,
        includeViewState: true,
      );

  Future<void> _createChartFromSelection() async {
    _selectionActionInProgress.value = true;
    final result = await _workbenchController.extractArtifact(
      ChartArtifactExtractOptions(documentOptions: _selectionDocumentOptions),
    );
    if (!mounted) return;
    _selectionActionInProgress.value = false;
    switch (result) {
      case ChartArtifactFailure<ChartArtifact>():
        _showSelectionError(result.error);
      case ChartArtifactSuccess<ChartArtifact>():
        widget.onSelectionArtifactCreated?.call(result.value);
        _showSelectionMessage('Selection chart ready');
    }
  }

  void _zoomToSelection() => _handleSelectionCommand(
    _chartController.zoomToSelection(
      paddingFraction: widget.selectionZoomPaddingFraction,
    ),
  );

  void _invertSelection() =>
      _handleSelectionCommand(_chartController.invertSelection());

  void _clearSelection() {
    _chartController
      ..clearSelection()
      ..clearPointSelection();
  }

  void _handleSelectionCommand(ChartArtifactResult<void> result) {
    if (result case ChartArtifactFailure<void>()) {
      _showSelectionError(result.error);
    }
  }

  Future<void> _copySelection() async {
    final result = _selectionExport();
    switch (result) {
      case ChartArtifactFailure<ChartTableCsvExport>():
        _showSelectionError(result.error);
      case ChartArtifactSuccess<ChartTableCsvExport>():
        final callback = widget.onSelectionCopied;
        if (callback != null) {
          callback(result.value);
        } else {
          await Clipboard.setData(
            ClipboardData(text: result.value.tabSeparatedText),
          );
        }
        if (mounted) _showSelectionMessage('Selection copied');
    }
  }

  Future<void> _exportSelectionCsv() async {
    final result = _selectionExport();
    switch (result) {
      case ChartArtifactFailure<ChartTableCsvExport>():
        _showSelectionError(result.error);
      case ChartArtifactSuccess<ChartTableCsvExport>():
        final callback = widget.onSelectionCsvExported;
        if (callback != null) {
          callback(result.value);
          _showSelectionMessage('Selection CSV ready');
          return;
        }
        final downloaded = await downloadChartTableCsv(
          csv: result.value.csv,
          fileName: widget.selectionCsvFileName,
        );
        if (!mounted) return;
        _showSelectionMessage(
          downloaded
              ? 'Selection CSV downloaded'
              : 'CSV download is unavailable on this platform',
        );
    }
  }

  ChartArtifactResult<ChartTableCsvExport> _selectionExport() {
    final result = _chartController.extractDocument(_selectionDocumentOptions);
    switch (result) {
      case ChartArtifactFailure<ChartDocumentSnapshot>():
        return ChartArtifactFailure(
          error: result.error,
          warnings: result.warnings,
        );
      case ChartArtifactSuccess<ChartDocumentSnapshot>():
        try {
          final model = ChartTableModel.fromDocument(
            result.value.document,
            viewState: result.value.viewState,
            options: widget.tableOptions,
          );
          return ChartArtifactSuccess(
            value: ChartTableExporter.csvForDisplayedRows(
              model,
              longRows: model.longRows,
              wideRows: model.wideRows,
              pieRows: model.pieRows,
              polarRows: model.polarRows,
              candlestickRows: model.candlestickRows,
            ),
            warnings: result.warnings,
          );
        } on Object catch (error) {
          return ChartArtifactFailure(
            error: ChartArtifactError(
              code: ChartArtifactDiagnosticCodes.invalidArtifact,
              message: 'Selection export could not be prepared: $error',
            ),
            warnings: result.warnings,
          );
        }
    }
  }

  void _showSelectionError(ChartArtifactError error) =>
      _showSelectionMessage(error.message);

  void _showSelectionMessage(String message) {
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool get _showModeSwitcher =>
      widget.showModeSwitcher && (_groupController?.showModeSwitcher ?? true);

  Set<ChartDisplayMode> get _availableDisplayModes =>
      _groupController?.availableDisplayModes ?? widget.availableDisplayModes;

  void _syncGroupController({bool force = false}) {
    final next =
        widget.groupController ??
        ChartWorkbenchScope.maybeControllerOf(context);
    if (!force && identical(next, _groupController)) return;
    _disconnectGroupController();
    _groupController = next;
    if (next == null) return;
    _workbenchController._groupModeDelegate = next.setDisplayMode;
    next
      ..addListener(_handleGroupChanged)
      ..attachWorkbench(this, widget.availableDisplayModes);
    _applyGroupMode();
  }

  void _disconnectGroupController() {
    final current = _groupController;
    if (current == null) return;
    current
      ..removeListener(_handleGroupChanged)
      ..detachWorkbench(this);
    _workbenchController._groupModeDelegate = null;
    _groupController = null;
  }

  void _handleGroupChanged() {
    _applyGroupMode();
    if (mounted) setState(() {});
  }

  void _applyGroupMode() {
    final group = _groupController;
    if (group == null) return;
    _workbenchController._setDisplayModeLocally(group.displayMode);
  }

  Widget _buildStage(
    BuildContext context,
    BoxConstraints constraints,
    Widget chart,
    ChartDisplayMode effective,
  ) {
    final size = constraints.biggest;
    final gap = widget.splitGap;
    var chartRect = Offset.zero & size;
    var tableRect = Offset.zero & size;
    Rect? dividerRect;
    var effectiveSplitRatio = widget.splitRatio;
    if (effective == ChartDisplayMode.split) {
      effectiveSplitRatio = _resolveSplitRatio(context, size);
      if (widget.splitAxis == Axis.horizontal) {
        final available = math.max(0.0, size.width - gap);
        final chartWidth = available * effectiveSplitRatio;
        chartRect = Rect.fromLTWH(0, 0, chartWidth, size.height);
        tableRect = Rect.fromLTWH(
          chartWidth + gap,
          0,
          available - chartWidth,
          size.height,
        );
        dividerRect = Rect.fromCenter(
          center: Offset(chartWidth + gap / 2, size.height / 2),
          width: 48,
          height: size.height,
        );
      } else {
        final available = math.max(0.0, size.height - gap);
        final chartHeight = available * effectiveSplitRatio;
        chartRect = Rect.fromLTWH(0, 0, size.width, chartHeight);
        tableRect = Rect.fromLTWH(
          0,
          chartHeight + gap,
          size.width,
          available - chartHeight,
        );
        dividerRect = Rect.fromCenter(
          center: Offset(size.width / 2, chartHeight + gap / 2),
          width: size.width,
          height: 48,
        );
      }
    }

    final tableHasBeenRequested =
        _modeShowsTable(effective) ||
        _workbenchController.tableState.phase !=
            ChartWorkbenchTablePhase.uninitialized;
    final sourceHasBeenRequested =
        _modeShowsSource(effective) ||
        _workbenchController.sourceState.phase !=
            ChartWorkbenchSourcePhase.uninitialized;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fromRect(
          rect: chartRect,
          child: IgnorePointer(
            ignoring: !_modeShowsChart(effective),
            child: ExcludeSemantics(
              excluding: !_modeShowsChart(effective),
              child: chart,
            ),
          ),
        ),
        // A pane that has been requested once stays mounted so returning to it
        // is instant, but a hidden pane must stop animating: its indeterminate
        // progress bar would otherwise schedule frames for as long as the
        // workbench lives.
        if (tableHasBeenRequested)
          Positioned.fromRect(
            rect: tableRect,
            child: TickerMode(
              enabled: _modeShowsTable(effective),
              child: Offstage(
                offstage: !_modeShowsTable(effective),
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: _buildTableSurface(context),
                ),
              ),
            ),
          ),
        if (sourceHasBeenRequested)
          Positioned.fill(
            child: TickerMode(
              enabled: _modeShowsSource(effective),
              child: Offstage(
                offstage: !_modeShowsSource(effective),
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: _buildSourceSurface(context),
                ),
              ),
            ),
          ),
        if (effective == ChartDisplayMode.split &&
            widget.isSplitResizable &&
            dividerRect != null)
          Positioned.fromRect(
            rect: dividerRect,
            child: _WorkbenchSplitHandle(
              axis: widget.splitAxis,
              chartRatio: effectiveSplitRatio,
              onDelta: (delta) => _resizeSplit(size, delta),
              onReset: () => _resetSplitRatio(size),
            ),
          ),
      ],
    );
  }

  Widget _buildSourceSurface(BuildContext context) {
    final state = _workbenchController.sourceState;
    final generated = state.generated;
    final followsDocumentRevision =
        widget.sourceRefreshPolicy ==
        ChartSourceRefreshPolicy.onDocumentRevision;
    final isAwaitingAutomaticRefresh =
        followsDocumentRevision && state.isStale && state.error == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.phase == ChartWorkbenchSourcePhase.refreshing ||
            isAwaitingAutomaticRefresh)
          const LinearProgressIndicator(minHeight: 2),
        if (state.error != null && generated != null)
          _WorkbenchTableMessage(
            icon: Icons.warning_amber_rounded,
            message:
                '${state.error!.message} The previous source is still shown.',
            actionLabel: 'Retry refresh',
            onAction: _workbenchController.refreshSource,
            tone: _WorkbenchMessageTone.error,
          )
        else if (state.error != null)
          _WorkbenchTableMessage(
            icon: Icons.error_outline,
            message: state.error!.message,
            actionLabel: 'Retry source',
            onAction: _workbenchController.refreshSource,
            tone: _WorkbenchMessageTone.error,
          )
        else if (state.isStale && generated != null && !followsDocumentRevision)
          _WorkbenchTableMessage(
            icon: Icons.update_outlined,
            message: 'The chart changed after this source was generated.',
            actionLabel: state.phase == ChartWorkbenchSourcePhase.refreshing
                ? 'Refreshing…'
                : 'Refresh source',
            onAction: state.phase == ChartWorkbenchSourcePhase.refreshing
                ? null
                : _workbenchController.refreshSource,
            tone: _WorkbenchMessageTone.warning,
          )
        else if (state.warnings.isNotEmpty && generated != null)
          _WorkbenchTableMessage(
            icon: Icons.info_outline,
            message: state.warnings.length == 1
                ? state.warnings.first.message
                : '${state.warnings.first.message} '
                      '${state.warnings.length - 1} more extraction warnings.',
            tone: _WorkbenchMessageTone.info,
          ),
        Expanded(
          child: generated == null
              ? const Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: 'Generating chart source',
                  ),
                )
              : ChartSourceView(
                  generated: generated,
                  form: state.form,
                  onFormChanged: _workbenchController.setSourceForm,
                  isStale: state.isStale && !followsDocumentRevision,
                  isRefreshing:
                      state.phase == ChartWorkbenchSourcePhase.refreshing,
                  onRefresh: _workbenchController.refreshSource,
                ),
        ),
      ],
    );
  }

  double _resolveSplitRatio(BuildContext context, Size size) {
    final available = math.max(
      0.0,
      (widget.splitAxis == Axis.horizontal ? size.width : size.height) -
          widget.splitGap,
    );
    if (available <= 0) return widget.splitRatio;
    final bounds = _splitRatioBounds(available);
    final manual = _manualSplitRatio;
    if (manual != null) return manual.clamp(bounds.$1, bounds.$2);
    if (!widget.autoFitTablePane || widget.splitAxis == Axis.vertical) {
      return widget.splitRatio.clamp(bounds.$1, bounds.$2);
    }

    final tableTheme =
        Theme.of(context).extension<ChartDataTableTheme>() ??
        const ChartDataTableTheme();
    final model = _workbenchController.tableModel;
    final preferredTableWidth = math.min(
      widget.maximumAutoTablePaneExtent,
      model == null
          ? 560.0
          : ChartDataTable.preferredWidthFor(model: model, theme: tableTheme),
    );
    final tableWidth = preferredTableWidth.clamp(
      widget.minimumTablePaneExtent,
      math.max(
        widget.minimumTablePaneExtent,
        available - bounds.$1 * available,
      ),
    );
    return ((available - tableWidth) / available).clamp(bounds.$1, bounds.$2);
  }

  (double, double) _splitRatioBounds(double available) {
    if (available <= 0) return (widget.splitRatio, widget.splitRatio);
    final requestedTotal =
        widget.minimumChartPaneExtent + widget.minimumTablePaneExtent;
    if (requestedTotal >= available && requestedTotal > 0) {
      final fixed = widget.minimumChartPaneExtent / requestedTotal;
      return (fixed, fixed);
    }
    return (
      (widget.minimumChartPaneExtent / available).clamp(0.0, 1.0),
      (1 - widget.minimumTablePaneExtent / available).clamp(0.0, 1.0),
    );
  }

  void _resizeSplit(Size size, double delta) {
    final dimension = widget.splitAxis == Axis.horizontal
        ? size.width
        : size.height;
    final available = math.max(0.0, dimension - widget.splitGap);
    if (available <= 0) return;
    final current = _resolveSplitRatio(context, size);
    final bounds = _splitRatioBounds(available);
    final next = (current + delta / available).clamp(bounds.$1, bounds.$2);
    if (next == _manualSplitRatio) return;
    setState(() => _manualSplitRatio = next);
    widget.onSplitRatioChanged?.call(next);
  }

  void _resetSplitRatio(Size size) {
    if (_manualSplitRatio == null) return;
    setState(() => _manualSplitRatio = null);
    widget.onSplitRatioChanged?.call(_resolveSplitRatio(context, size));
  }

  Widget _buildTableSurface(BuildContext context) {
    final state = _workbenchController.tableState;
    final model = state.model;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_pointLinkError != null && model != null)
          _WorkbenchTableMessage(
            icon: Icons.link_off_outlined,
            message: _pointLinkError!.message,
            actionLabel: 'Refresh table',
            onAction: () {
              setState(() => _pointLinkError = null);
              _workbenchController.refreshTable();
            },
            tone: _WorkbenchMessageTone.warning,
          )
        else if (state.error != null && model != null)
          _WorkbenchTableMessage(
            icon: Icons.warning_amber_rounded,
            message:
                '${state.error!.message} The previous table is still shown.',
            actionLabel: 'Retry refresh',
            onAction: _workbenchController.refreshTable,
            tone: _WorkbenchMessageTone.error,
          )
        else if (state.error != null)
          _WorkbenchTableMessage(
            icon: Icons.error_outline,
            message: state.error!.message,
            actionLabel: 'Retry table',
            onAction: _workbenchController.refreshTable,
            tone: _WorkbenchMessageTone.error,
          )
        else if (state.isStale &&
            model != null &&
            widget.tableRefreshPolicy !=
                ChartTableRefreshPolicy.onDocumentRevision)
          _WorkbenchTableMessage(
            icon: Icons.update_outlined,
            message:
                'The chart changed after this table snapshot was captured.',
            actionLabel: state.phase == ChartWorkbenchTablePhase.refreshing
                ? 'Refreshing…'
                : 'Refresh table',
            onAction: state.phase == ChartWorkbenchTablePhase.refreshing
                ? null
                : _workbenchController.refreshTable,
            tone: _WorkbenchMessageTone.warning,
          )
        else if (state.warnings.isNotEmpty && model != null)
          _WorkbenchTableMessage(
            icon: Icons.info_outline,
            message: state.warnings.length == 1
                ? state.warnings.first.message
                : '${state.warnings.first.message} '
                      '${state.warnings.length - 1} more warnings.',
            tone: _WorkbenchMessageTone.info,
          ),
        Expanded(
          child: ListenableBuilder(
            listenable: _chartController,
            builder: (context, child) {
              final detailedActivation =
                  widget.onTableRowActivation ??
                  (widget.onTableRowActivated == null &&
                          widget.linkTableRowsToChart
                      ? _activateTablePoints
                      : null);
              return ChartDataTable(
                key: const ValueKey('chart-workbench-data-table'),
                model: model,
                controller: _tableController,
                isLoading:
                    model == null &&
                    (state.phase == ChartWorkbenchTablePhase.uninitialized ||
                        state.phase == ChartWorkbenchTablePhase.loading),
                isRefreshing:
                    model != null &&
                    state.phase == ChartWorkbenchTablePhase.refreshing,
                errorMessage: model == null ? state.error?.message : null,
                focusedPointRefs: _chartController.focusedPointRefs,
                selectedPointRefs: model == null
                    ? _chartController.selectedPointRefs
                    : _effectiveTableSelectedPointRefs(model),
                onSelectAllPoints:
                    widget.onTableSelectAllPoints ??
                    (widget.linkTableRowsToChart
                        ? _selectAllTablePoints
                        : null),
                onClearSelection:
                    widget.onTableSelectionCleared ??
                    (widget.linkTableRowsToChart
                        ? _clearTablePointSelection
                        : null),
                onRowFocused:
                    widget.onTableRowFocused ??
                    (widget.linkTableRowsToChart ? _focusTablePoints : null),
                onRowFocusCleared:
                    widget.onTableRowFocusCleared ??
                    (widget.linkTableRowsToChart
                        ? _clearKeyboardTableFocus
                        : null),
                onRowHoverChanged:
                    widget.onTableRowHoverChanged ??
                    (widget.linkTableRowsToChart ? _hoverTablePoints : null),
                onRowActivation: detailedActivation,
                onRowActivated: widget.onTableRowActivation == null
                    ? widget.onTableRowActivated
                    : null,
              );
            },
          ),
        ),
      ],
    );
  }

  Set<ChartPointRef> _effectiveTableSelectedPointRefs(ChartTableModel model) {
    final selectedRefs = <ChartPointRef>{..._chartController.selectedPointRefs};
    final selectedSeriesIds = _chartController.selectedSeriesIds;
    if (selectedSeriesIds.isEmpty) return selectedRefs;

    for (final row in model.longRows) {
      if (selectedSeriesIds.contains(row.reference.seriesId)) {
        selectedRefs.add(row.reference);
      }
    }
    return selectedRefs;
  }

  void _focusTablePoints(List<ChartPointRef> points) {
    final revision = _workbenchController.tableSnapshot?.revision;
    if (revision == null) return;
    _keyboardTableFocus = _TablePointFocus(points, revision);
    _applyTablePointFocus();
  }

  void _clearKeyboardTableFocus() {
    _keyboardTableFocus = null;
    _applyTablePointFocus();
  }

  void _hoverTablePoints(List<ChartPointRef>? points) {
    final revision = _workbenchController.tableSnapshot?.revision;
    _hoveredTableFocus = points == null || revision == null
        ? null
        : _TablePointFocus(points, revision);
    _applyTablePointFocus();
  }

  void _applyTablePointFocus() {
    final revision = _workbenchController.tableSnapshot?.revision;
    final hovered = _hoveredTableFocus;
    final keyboard = _keyboardTableFocus;
    final focus = hovered?.revision == revision
        ? hovered
        : keyboard?.revision == revision
        ? keyboard
        : null;
    if (focus == null || revision == null) {
      _chartController.clearPointFocus();
      return;
    }
    _handlePointLinkResult(
      _chartController.focusPoints(focus.points, revision: revision),
    );
  }

  void _activateTablePoints(ChartTableRowActivationDetails details) {
    final revision = _workbenchController.tableSnapshot?.revision;
    if (revision == null) return;
    final previousSelection = _chartController.selectedPointRefs;
    final points = details.points.toSet();
    final nextSelection = <ChartPointRef>{};
    if (details.additive) {
      nextSelection.addAll(previousSelection);
      if (points.every(previousSelection.contains)) {
        nextSelection.removeAll(points);
      } else {
        nextSelection.addAll(points);
      }
    } else {
      nextSelection.addAll(points);
    }
    final result = _chartController.selectPoints(
      nextSelection,
      revision: revision,
    );
    _handlePointLinkResult(result);
    if (result is ChartArtifactSuccess<void> &&
        !setEquals(previousSelection, _chartController.selectedPointRefs)) {
      // Durable selection is part of the captured document, so it advances the
      // effective revision. Rebase the package-owned table immediately to keep
      // its remaining row references usable even under the manual policy.
      // Independent chart/data mutations retain their configured refresh
      // semantics and still surface as stale.
      unawaited(_workbenchController.refreshTable());
    }
  }

  void _clearTablePointSelection() {
    if (_chartController.selectedPointRefs.isEmpty) return;
    _chartController.clearPointSelection();
    // Durable selection advances the effective document revision. Refresh the
    // package-owned snapshot so subsequent row references remain current.
    unawaited(_workbenchController.refreshTable());
  }

  void _selectAllTablePoints(List<ChartPointRef> points) {
    _activateTablePoints(ChartTableRowActivationDetails(points: points));
  }

  void _handlePointLinkResult(ChartArtifactResult<void> result) {
    switch (result) {
      case ChartArtifactSuccess<void>():
        if (_pointLinkError != null) setState(() => _pointLinkError = null);
      case ChartArtifactFailure<void>():
        setState(() => _pointLinkError = result.error);
        widget.onPointLinkError?.call(result.error);
    }
  }

  void _scheduleEffectiveMode(ChartDisplayMode mode) {
    if (_scheduledEffectiveMode == mode) {
      return;
    }
    if (_workbenchController.effectiveMode == mode) {
      final tableNeedsInitialization =
          _modeShowsTable(mode) &&
          _workbenchController.tableSnapshot == null &&
          _workbenchController.tableState.phase ==
              ChartWorkbenchTablePhase.uninitialized;
      final sourceNeedsInitialization =
          _modeShowsSource(mode) &&
          _workbenchController.sourceState.snapshot == null &&
          _workbenchController.sourceState.phase ==
              ChartWorkbenchSourcePhase.uninitialized;
      if (tableNeedsInitialization || sourceNeedsInitialization) {
        _scheduledEffectiveMode = mode;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _scheduledEffectiveMode != mode) return;
          _scheduledEffectiveMode = null;
          _workbenchController._ensureInitialSurfacesIfNeeded();
        });
      }
      return;
    }
    _scheduledEffectiveMode = mode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scheduledEffectiveMode != mode) return;
      _scheduledEffectiveMode = null;
      _workbenchController._setEffectiveMode(mode);
      _workbenchController._ensureInitialSurfacesIfNeeded();
    });
  }
}

class _WorkbenchSplitHandle extends StatefulWidget {
  const _WorkbenchSplitHandle({
    required this.axis,
    required this.chartRatio,
    required this.onDelta,
    required this.onReset,
  });

  final Axis axis;
  final double chartRatio;
  final ValueChanged<double> onDelta;
  final VoidCallback onReset;

  @override
  State<_WorkbenchSplitHandle> createState() => _WorkbenchSplitHandleState();
}

class _ChartSelectionActionsHost extends StatefulWidget {
  const _ChartSelectionActionsHost({
    required this.controller,
    required this.busy,
    required this.builder,
  });

  final BravenChartController controller;
  final ValueListenable<bool> busy;
  final WidgetBuilder builder;

  @override
  State<_ChartSelectionActionsHost> createState() =>
      _ChartSelectionActionsHostState();
}

class _ChartSelectionActionsHostState
    extends State<_ChartSelectionActionsHost> {
  bool _rebuildScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleChanged);
    widget.busy.addListener(_handleChanged);
  }

  @override
  void didUpdateWidget(_ChartSelectionActionsHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controller, widget.controller)) {
      oldWidget.controller.removeListener(_handleChanged);
      widget.controller.addListener(_handleChanged);
    }
    if (!identical(oldWidget.busy, widget.busy)) {
      oldWidget.busy.removeListener(_handleChanged);
      widget.busy.addListener(_handleChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleChanged);
    widget.busy.removeListener(_handleChanged);
    super.dispose();
  }

  void _handleChanged() {
    if (!mounted || _rebuildScheduled) return;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      setState(() {});
      return;
    }
    _rebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _rebuildScheduled = false;
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

class _WorkbenchSplitHandleState extends State<_WorkbenchSplitHandle> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'workbench-split-handle');
  bool _focused = false;

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final chartPercent = (widget.chartRatio * 100).round();
    final dataPercent = 100 - chartPercent;
    return Semantics(
      container: true,
      focusable: true,
      label: 'Resize chart and data panes',
      value: 'Chart $chartPercent percent, data $dataPercent percent',
      increasedValue:
          'Chart ${math.min(100, chartPercent + 2)} percent, data ${math.max(0, dataPercent - 2)} percent',
      decreasedValue:
          'Chart ${math.max(0, chartPercent - 2)} percent, data ${math.min(100, dataPercent + 2)} percent',
      hint:
          'Drag or use arrow keys to resize. Press Escape or double click to fit the table.',
      onIncrease: () => widget.onDelta(16),
      onDecrease: () => widget.onDelta(-16),
      child: Focus(
        focusNode: _focusNode,
        onFocusChange: (focused) => setState(() => _focused = focused),
        onKeyEvent: _handleKeyEvent,
        child: Center(
          child: MouseRegion(
            cursor: widget.axis == Axis.horizontal
                ? SystemMouseCursors.resizeColumn
                : SystemMouseCursors.resizeRow,
            child: GestureDetector(
              key: const ValueKey('chart-workbench-split-handle'),
              behavior: HitTestBehavior.opaque,
              onTap: _focusNode.requestFocus,
              onDoubleTap: widget.onReset,
              onHorizontalDragStart: widget.axis == Axis.horizontal
                  ? (_) => _focusNode.requestFocus()
                  : null,
              onHorizontalDragUpdate: widget.axis == Axis.horizontal
                  ? (details) => widget.onDelta(details.delta.dx)
                  : null,
              onVerticalDragStart: widget.axis == Axis.vertical
                  ? (_) => _focusNode.requestFocus()
                  : null,
              onVerticalDragUpdate: widget.axis == Axis.vertical
                  ? (details) => widget.onDelta(details.delta.dy)
                  : null,
              child: SizedBox(
                width: widget.axis == Axis.horizontal ? 12 : double.infinity,
                height: widget.axis == Axis.horizontal ? double.infinity : 12,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: widget.axis == Axis.horizontal ? 6 : 32,
                    height: widget.axis == Axis.horizontal ? 32 : 6,
                    decoration: BoxDecoration(
                      color: _focused ? colors.primary : colors.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: _focused ? colors.onPrimary : colors.outline,
                      ),
                      boxShadow: _focused
                          ? [
                              BoxShadow(
                                color: colors.primary.withValues(alpha: 0.22),
                                blurRadius: 6,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape) {
      widget.onReset();
      return KeyEventResult.handled;
    }
    final decrease = widget.axis == Axis.horizontal
        ? key == LogicalKeyboardKey.arrowLeft
        : key == LogicalKeyboardKey.arrowUp;
    final increase = widget.axis == Axis.horizontal
        ? key == LogicalKeyboardKey.arrowRight
        : key == LogicalKeyboardKey.arrowDown;
    if (decrease) {
      widget.onDelta(-16);
      return KeyEventResult.handled;
    }
    if (increase) {
      widget.onDelta(16);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

class _ModeSwitcher extends StatelessWidget {
  const _ModeSwitcher({
    required this.availableModes,
    required this.selectedMode,
    required this.onSelected,
  });

  final Set<ChartDisplayMode> availableModes;
  final ChartDisplayMode selectedMode;
  final ValueChanged<ChartDisplayMode> onSelected;

  @override
  Widget build(BuildContext context) {
    final modes = [
      for (final mode in ChartDisplayMode.values)
        if (availableModes.contains(mode)) mode,
    ];
    final button = SegmentedButton<ChartDisplayMode>(
      key: const ValueKey('chart-workbench-mode-switcher'),
      segments: [
        for (final mode in modes)
          ButtonSegment(
            value: mode,
            icon: Icon(_modeIcon(mode)),
            label: Text(_modeLabel(mode)),
          ),
      ],
      selected: {selectedMode},
      onSelectionChanged: (selection) => onSelected(selection.single),
      style: const ButtonStyle(
        minimumSize: WidgetStatePropertyAll(Size(0, 48)),
      ),
    );
    return Semantics(
      container: true,
      label: 'Chart presentation',
      child: modes.length <= 3
          ? button
          : LayoutBuilder(
              builder: (context, constraints) {
                // Leave enough room for icon + label + segment padding. On
                // narrower hosts the control remains horizontally scrollable.
                final preferredWidth = modes.length * 144.0;
                return SizedBox(
                  width: math.min(constraints.maxWidth, preferredWidth),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: button,
                  ),
                );
              },
            ),
    );
  }
}

class _WorkbenchTableMessage extends StatelessWidget {
  const _WorkbenchTableMessage({
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onAction,
    required this.tone,
  });

  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final _WorkbenchMessageTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      _WorkbenchMessageTone.error => (
        colors.errorContainer,
        colors.onErrorContainer,
      ),
      _WorkbenchMessageTone.warning => (
        colors.tertiaryContainer,
        colors.onTertiaryContainer,
      ),
      _WorkbenchMessageTone.info => (
        colors.secondaryContainer,
        colors.onSecondaryContainer,
      ),
    };
    return Semantics(
      liveRegion: true,
      child: ColoredBox(
        color: background,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(message, style: TextStyle(color: foreground)),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: 8),
                TextButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

enum _WorkbenchMessageTone { error, warning, info }

class _TablePointFocus {
  _TablePointFocus(Iterable<ChartPointRef> points, this.revision)
    : points = List.unmodifiable(points);

  final List<ChartPointRef> points;
  final ChartDocumentRevision revision;
}

ChartDisplayMode _firstAvailableMode(Set<ChartDisplayMode> modes) {
  for (final mode in ChartDisplayMode.values) {
    if (modes.contains(mode)) return mode;
  }
  throw StateError('A chart workbench requires at least one display mode.');
}

String _modeLabel(ChartDisplayMode mode) => switch (mode) {
  ChartDisplayMode.chart => 'Chart',
  ChartDisplayMode.data => 'Data',
  ChartDisplayMode.split => 'Split',
  ChartDisplayMode.source => 'Source',
};

IconData _modeIcon(ChartDisplayMode mode) => switch (mode) {
  ChartDisplayMode.chart => Icons.show_chart,
  ChartDisplayMode.data => Icons.table_rows_outlined,
  ChartDisplayMode.split => Icons.vertical_split_outlined,
  ChartDisplayMode.source => Icons.code_outlined,
};

bool _modeShowsChart(ChartDisplayMode mode) =>
    mode == ChartDisplayMode.chart || mode == ChartDisplayMode.split;

bool _modeShowsTable(ChartDisplayMode mode) =>
    mode == ChartDisplayMode.data || mode == ChartDisplayMode.split;

bool _modeShowsSource(ChartDisplayMode mode) => mode == ChartDisplayMode.source;
