import 'package:flutter/foundation.dart';

import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_artifact.dart';
import '../artifacts/chart_document_extractor.dart';
import '../table/chart_table_model.dart';
import '../table/chart_table_options.dart';
import '../source/chart_source_models.dart';

/// Determines when a chart workbench refreshes its document-backed table.
enum ChartTableRefreshPolicy {
  /// Capture on first use and only after an explicit refresh request.
  manual,

  /// Refresh whenever Data or Split presentation becomes effective.
  onModeEntry,

  /// Mark stale on effective revision changes and refresh on a bounded cadence.
  onDocumentRevision,
}

/// Determines when a chart workbench refreshes generated Dart source.
enum ChartSourceRefreshPolicy {
  /// Capture on first use and only after an explicit refresh request.
  manual,

  /// Refresh whenever Source presentation becomes effective.
  onModeEntry,

  /// Mark stale on effective revision changes and refresh on a bounded cadence.
  onDocumentRevision,
}

/// Current phase of the workbench's generated-source operation.
enum ChartWorkbenchSourcePhase {
  uninitialized,
  loading,
  ready,
  refreshing,
  failed,
}

/// Immutable generated source and diagnostics owned by a chart workbench.
@immutable
class ChartWorkbenchSourceState {
  const ChartWorkbenchSourceState({
    this.phase = ChartWorkbenchSourcePhase.uninitialized,
    this.snapshot,
    this.generated,
    this.isStale = false,
    this.warnings = const [],
    this.error,
  });

  final ChartWorkbenchSourcePhase phase;
  final ChartDocumentSnapshot? snapshot;
  final ChartGeneratedSource? generated;
  final bool isStale;
  final List<ChartArtifactWarning> warnings;
  final ChartArtifactError? error;

  bool get hasUsableSource => snapshot != null && generated != null;

  bool get isLoading =>
      phase == ChartWorkbenchSourcePhase.loading ||
      phase == ChartWorkbenchSourcePhase.refreshing;
}

/// Current phase of the workbench's table snapshot operation.
enum ChartWorkbenchTablePhase {
  uninitialized,
  loading,
  ready,
  refreshing,
  failed,
}

/// Immutable table projection and diagnostics owned by a chart workbench.
@immutable
class ChartWorkbenchTableState {
  /// Creates an immutable snapshot of a table operation.
  const ChartWorkbenchTableState({
    this.phase = ChartWorkbenchTablePhase.uninitialized,
    this.snapshot,
    this.model,
    this.isStale = false,
    this.warnings = const [],
    this.error,
  });

  /// Current table extraction or projection phase.
  final ChartWorkbenchTablePhase phase;

  /// Effective chart document used by [model].
  final ChartDocumentSnapshot? snapshot;

  /// Most recent usable table projection.
  final ChartTableModel? model;

  /// Whether [model] was retained after a failed refresh.
  final bool isStale;

  /// Non-fatal diagnostics from extraction and projection.
  final List<ChartArtifactWarning> warnings;

  /// Structured failure from the latest operation, if any.
  final ChartArtifactError? error;

  /// Whether both a document snapshot and projected model are available.
  bool get hasUsableTable => snapshot != null && model != null;

  /// Whether an initial load or refresh is active.
  bool get isLoading =>
      phase == ChartWorkbenchTablePhase.loading ||
      phase == ChartWorkbenchTablePhase.refreshing;
}

/// Current phase of host-requested artifact extraction.
enum ChartWorkbenchArtifactPhase { idle, extracting, succeeded, failed }

/// Immutable artifact-operation status kept separate from table diagnostics.
@immutable
class ChartWorkbenchArtifactState {
  /// Creates an immutable snapshot of an artifact extraction operation.
  const ChartWorkbenchArtifactState({
    this.phase = ChartWorkbenchArtifactPhase.idle,
    this.artifact,
    this.warnings = const [],
    this.error,
  });

  /// Current artifact extraction phase.
  final ChartWorkbenchArtifactPhase phase;

  /// Most recently extracted artifact when extraction succeeded.
  final ChartArtifact? artifact;

  /// Non-fatal diagnostics from the extraction.
  final List<ChartArtifactWarning> warnings;

  /// Structured failure from the latest extraction, if any.
  final ChartArtifactError? error;

  /// Whether document and optional preview extraction is active.
  bool get isExtracting => phase == ChartWorkbenchArtifactPhase.extracting;
}

/// One observable snapshot of a chart workbench's public state.
@immutable
class ChartWorkbenchStatus {
  /// Creates one combined observable workbench snapshot.
  const ChartWorkbenchStatus({
    required this.requestedMode,
    required this.effectiveMode,
    required this.table,
    required this.artifact,
    this.source = const ChartWorkbenchSourceState(),
  });

  /// Mode selected by the user or host.
  final ChartDisplayMode requestedMode;

  /// Presentation visible after responsive fallback.
  final ChartDisplayMode effectiveMode;

  /// Independent table operation state.
  final ChartWorkbenchTableState table;

  /// Independent artifact operation state.
  final ChartWorkbenchArtifactState artifact;

  /// Independent generated-source operation state.
  final ChartWorkbenchSourceState source;
}
