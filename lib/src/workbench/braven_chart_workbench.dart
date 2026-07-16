import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/material.dart';

import '../artifacts/chart_artifact.dart';
import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_artifact_extractor.dart';
import '../artifacts/chart_document_extractor.dart';
import '../artifacts/chart_view_state.dart';
import '../models/braven_chart_controller.dart';
import '../table/chart_data_table.dart';
import '../table/chart_table_controller.dart';
import '../table/chart_table_model.dart';
import '../table/chart_table_options.dart';
import 'chart_workbench_models.dart';

/// Builds the chart managed by a [BravenChartWorkbench].
typedef BravenChartBuilder =
    Widget Function(
      BuildContext context,
      BravenChartController chartController,
    );

/// Builds storage-agnostic host actions for a chart workbench.
typedef ChartWorkbenchActionsBuilder =
    List<Widget> Function(BuildContext context, ChartWorkbenchHandle handle);

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

  /// Requests a display [mode] without throwing for a disabled mode.
  ChartArtifactResult<ChartDisplayMode> setDisplayMode(ChartDisplayMode mode);

  /// Coalesces concurrent requests and rebuilds the table from mounted state.
  Future<ChartArtifactResult<ChartDocumentSnapshot>> refreshTable();

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
  ValueChanged<ChartWorkbenchStatus>? _onStatusChanged;
  ChartWorkbenchTableState _tableState = const ChartWorkbenchTableState();
  ChartWorkbenchArtifactState _artifactState =
      const ChartWorkbenchArtifactState();
  Future<ChartArtifactResult<ChartDocumentSnapshot>>? _refreshFuture;
  Future<ChartArtifactResult<ChartArtifact>>? _artifactFuture;
  ChartDocumentRevision? _observedDocumentRevision;
  Timer? _revisionRefreshTimer;
  bool _statusNotificationFrameScheduled = false;

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

  /// Current combined status snapshot.
  ChartWorkbenchStatus get status => ChartWorkbenchStatus(
    requestedMode: _requestedMode,
    effectiveMode: _effectiveMode,
    table: _tableState,
    artifact: _artifactState,
  );

  @override
  ChartArtifactResult<ChartDisplayMode> setDisplayMode(ChartDisplayMode mode) {
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
    );
  }

  void _configure({
    required ChartDisplayMode initialMode,
    required Set<ChartDisplayMode> availableModes,
    required ChartDocumentExtractOptions documentOptions,
    required ChartTableOptions tableOptions,
    required ChartTableRefreshPolicy refreshPolicy,
  }) {
    var statusChanged = false;
    _availableModes = Set.unmodifiable(availableModes);
    _documentOptions = documentOptions;
    _tableOptions = tableOptions;
    _refreshPolicy = refreshPolicy;
    if (!_configured) {
      _configured = true;
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
    _notifyStatus();
  }

  void _setEffectiveMode(ChartDisplayMode mode) {
    if (_effectiveMode == mode) return;
    final previous = _effectiveMode;
    _effectiveMode = mode;
    _notifyStatus();

    final tableBecameVisible =
        mode != ChartDisplayMode.chart && previous != mode;
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
  }

  void _ensureInitialTableIfNeeded() {
    if (_effectiveMode != ChartDisplayMode.chart &&
        _tableState.snapshot == null &&
        _tableState.phase == ChartWorkbenchTablePhase.uninitialized &&
        _refreshFuture == null) {
      unawaited(refreshTable());
    }
  }

  void _detach(Object attachment) {
    if (!identical(_attachment, attachment)) return;
    _revisionRefreshTimer?.cancel();
    _revisionRefreshTimer = null;
    _stopListeningToChartController();
    _attachment = null;
    _chartController = null;
    _onStatusChanged = null;
  }

  void _notifyStatus() {
    if (_disposed) return;
    notifyListeners();
    _onStatusChanged?.call(status);
  }

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
    final snapshot = _tableState.snapshot;
    if (snapshot == null || snapshot.revision == revision) return;
    _tableState = ChartWorkbenchTableState(
      phase: _tableState.phase,
      snapshot: snapshot,
      model: _tableState.model,
      isStale: true,
      warnings: _tableState.warnings,
      error: _tableState.error,
    );
    _notifyStatus();
    if (_refreshPolicy == ChartTableRefreshPolicy.onDocumentRevision &&
        _effectiveMode != ChartDisplayMode.chart) {
      _scheduleRevisionRefresh();
    }
  }

  bool _isSnapshotStale(ChartDocumentSnapshot snapshot) {
    final revision = _chartController?.effectiveDocumentRevision.value;
    return revision != null && snapshot.revision != revision;
  }

  void _scheduleRevisionRefresh() {
    if (_revisionRefreshTimer != null ||
        _effectiveMode == ChartDisplayMode.chart ||
        _tableState.snapshot == null) {
      return;
    }
    _revisionRefreshTimer = Timer(const Duration(milliseconds: 250), () {
      _revisionRefreshTimer = null;
      if (!_disposed &&
          _attachment != null &&
          _effectiveMode != ChartDisplayMode.chart &&
          _tableState.isStale) {
        unawaited(refreshTable());
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
    this.actionsBuilder,
    this.linkTableRowsToChart = true,
    this.onTableRowFocused,
    this.onTableRowFocusCleared,
    this.onTableRowActivated,
    this.onPointLinkError,
    this.showModeSwitcher = true,
    this.splitBreakpoint = 900,
    this.splitAxis = Axis.horizontal,
    this.splitRatio = 0.5,
    this.onStatusChanged,
  }) : assert(availableDisplayModes.length > 0),
       assert(splitBreakpoint > 0),
       assert(splitRatio > 0 && splitRatio < 1);

  /// Builds the chart with the controller owned or adopted by this workbench.
  final BravenChartBuilder chartBuilder;

  /// Optional caller-owned controller attached to the mounted chart.
  final BravenChartController? chartController;

  /// Optional caller-owned workbench controller and action handle.
  final ChartWorkbenchController? workbenchController;

  /// Optional caller-owned controller for table sort and focus state.
  final ChartTableController? tableController;

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

  /// Builds storage-agnostic host actions with a stable imperative handle.
  final ChartWorkbenchActionsBuilder? actionsBuilder;

  /// Enables revision-safe keyboard focus and activation linking by default.
  final bool linkTableRowsToChart;

  /// Overrides the default transient focus behavior when supplied.
  final ChartTableRowCallback? onTableRowFocused;

  /// Overrides the default focus-clear behavior when supplied.
  final VoidCallback? onTableRowFocusCleared;

  /// Overrides the default durable point-selection behavior when supplied.
  final ChartTableRowCallback? onTableRowActivated;

  /// Receives structured stale/invalid point-link failures.
  final ValueChanged<ChartArtifactError>? onPointLinkError;

  /// Whether the package-owned Chart/Data/Split control is shown.
  final bool showModeSwitcher;

  /// Minimum content width at which a requested Split is shown side by side.
  final double splitBreakpoint;

  /// Direction in which chart and table panes are arranged.
  final Axis splitAxis;

  /// Fraction of the available split dimension assigned to the chart.
  final double splitRatio;

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

  @override
  void initState() {
    super.initState();
    _acquireControllers();
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

    if (workbenchChanged) {
      final oldController = _workbenchController;
      final owned = _ownsWorkbenchController;
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
      );
  }

  @override
  void dispose() {
    _workbenchController._detach(this);
    if (_ownsWorkbenchController) _workbenchController.dispose();
    if (_ownsTableController) _tableController.dispose();
    if (_ownsChartController) _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chart = KeyedSubtree(
      key: const ValueKey('chart-workbench-chart'),
      child: widget.chartBuilder(context, _chartController),
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
            if (widget.showModeSwitcher || actions.isNotEmpty)
              _buildControls(context, actions),
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
                  if (widget.showModeSwitcher)
                    _ModeSwitcher(
                      availableModes: widget.availableDisplayModes,
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

  Widget _buildStage(
    BuildContext context,
    BoxConstraints constraints,
    Widget chart,
    ChartDisplayMode effective,
  ) {
    final size = constraints.biggest;
    const gap = 16.0;
    var chartRect = Offset.zero & size;
    var tableRect = Offset.zero & size;
    if (effective == ChartDisplayMode.split) {
      if (widget.splitAxis == Axis.horizontal) {
        final available = math.max(0.0, size.width - gap);
        final chartWidth = available * widget.splitRatio;
        chartRect = Rect.fromLTWH(0, 0, chartWidth, size.height);
        tableRect = Rect.fromLTWH(
          chartWidth + gap,
          0,
          available - chartWidth,
          size.height,
        );
      } else {
        final available = math.max(0.0, size.height - gap);
        final chartHeight = available * widget.splitRatio;
        chartRect = Rect.fromLTWH(0, 0, size.width, chartHeight);
        tableRect = Rect.fromLTWH(
          0,
          chartHeight + gap,
          size.width,
          available - chartHeight,
        );
      }
    }

    final tableHasBeenRequested =
        effective != ChartDisplayMode.chart ||
        _workbenchController.tableState.phase !=
            ChartWorkbenchTablePhase.uninitialized;
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fromRect(
          rect: chartRect,
          child: IgnorePointer(
            ignoring: effective == ChartDisplayMode.data,
            child: ExcludeSemantics(
              excluding: effective == ChartDisplayMode.data,
              child: chart,
            ),
          ),
        ),
        if (tableHasBeenRequested)
          Positioned.fromRect(
            rect: tableRect,
            child: Offstage(
              offstage: effective == ChartDisplayMode.chart,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: _buildTableSurface(context),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTableSurface(BuildContext context) {
    final state = _workbenchController.tableState;
    final model = state.model;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.phase == ChartWorkbenchTablePhase.refreshing)
          const LinearProgressIndicator(minHeight: 2),
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
            builder: (context, child) => ChartDataTable(
              model: model,
              controller: _tableController,
              isLoading:
                  model == null &&
                  (state.phase == ChartWorkbenchTablePhase.uninitialized ||
                      state.phase == ChartWorkbenchTablePhase.loading),
              errorMessage: model == null ? state.error?.message : null,
              selectedPointRefs: _chartController.selectedPointRefs,
              onRowFocused:
                  widget.onTableRowFocused ??
                  (widget.linkTableRowsToChart ? _focusTablePoints : null),
              onRowFocusCleared:
                  widget.onTableRowFocusCleared ??
                  (widget.linkTableRowsToChart
                      ? _chartController.clearPointFocus
                      : null),
              onRowActivated:
                  widget.onTableRowActivated ??
                  (widget.linkTableRowsToChart ? _selectTablePoints : null),
            ),
          ),
        ),
      ],
    );
  }

  void _focusTablePoints(List<ChartPointRef> points) {
    final revision = _workbenchController.tableSnapshot?.revision;
    if (revision == null) return;
    _handlePointLinkResult(
      _chartController.focusPoints(points, revision: revision),
    );
  }

  void _selectTablePoints(List<ChartPointRef> points) {
    final revision = _workbenchController.tableSnapshot?.revision;
    if (revision == null) return;
    final previousSelection = _chartController.selectedPointRefs;
    final result = _chartController.selectPoints(points, revision: revision);
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
      if (mode != ChartDisplayMode.chart &&
          _workbenchController.tableSnapshot == null &&
          _workbenchController.tableState.phase ==
              ChartWorkbenchTablePhase.uninitialized) {
        _scheduledEffectiveMode = mode;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || _scheduledEffectiveMode != mode) return;
          _scheduledEffectiveMode = null;
          _workbenchController._ensureInitialTableIfNeeded();
        });
      }
      return;
    }
    _scheduledEffectiveMode = mode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _scheduledEffectiveMode != mode) return;
      _scheduledEffectiveMode = null;
      _workbenchController._setEffectiveMode(mode);
      _workbenchController._ensureInitialTableIfNeeded();
    });
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
    return Semantics(
      container: true,
      label: 'Chart presentation',
      child: SegmentedButton<ChartDisplayMode>(
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
};

IconData _modeIcon(ChartDisplayMode mode) => switch (mode) {
  ChartDisplayMode.chart => Icons.show_chart,
  ChartDisplayMode.data => Icons.table_rows_outlined,
  ChartDisplayMode.split => Icons.vertical_split_outlined,
};
