import 'package:flutter/foundation.dart';

import '../artifacts/chart_artifact_diagnostics.dart';
import '../artifacts/chart_document_extractor.dart';
import '../artifacts/chart_view_state.dart';

/// Programmatic control over series selection and Y-axis slot state.
///
/// Attach to [BravenChartPlus.controller] to drive series selection
/// and axis swaps from outside the chart widget.
///
/// The controller is optional — charts without one still respond to
/// legend taps and data-point taps internally. Add a controller only
/// when you need to read slot state or trigger selection externally.
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

  // Slot state mirrored from MultiAxisManager (updated after every swap).
  String? _selectedSeriesId;
  List<String> _visibleAxisIds = const [];
  List<String> _overflowAxisIds = const [];
  Set<String> _hiddenSeriesIds = const {};

  // ---- Public read API ----

  /// Currently selected series ID, or null if nothing is selected.
  String? get selectedSeriesId => _selectedSeriesId;

  /// Axis IDs currently occupying visible slots, in slot order.
  List<String> get visibleAxisIds => List.unmodifiable(_visibleAxisIds);

  /// Axis IDs currently in overflow (voted out of visible slots).
  List<String> get overflowAxisIds => List.unmodifiable(_overflowAxisIds);

  /// Series IDs currently excluded from rendering by visibility state.
  Set<String> get hiddenSeriesIds => Set.unmodifiable(_hiddenSeriesIds);

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

  // ---- Internal state sync (called by _BravenChartPlusState) ----

  /// Attaches this controller to a chart state. Called by the state.
  void attach({
    required void Function(String) onSelect,
    required void Function(String) onDeselect,
    required void Function() onClear,
    void Function(String, bool)? onSetSeriesVisibility,
    ChartDocumentExtractionHandler? onExtractDocument,
    void Function(ChartViewState)? onRestoreViewState,
  }) {
    _selectHandler = onSelect;
    _deselectHandler = onDeselect;
    _clearHandler = onClear;
    _setVisibilityHandler = onSetSeriesVisibility;
    _extractDocumentHandler = onExtractDocument;
    _restoreViewStateHandler = onRestoreViewState;
  }

  /// Detaches from the chart state. Called in dispose.
  void detach() {
    _selectHandler = null;
    _deselectHandler = null;
    _clearHandler = null;
    _setVisibilityHandler = null;
    _extractDocumentHandler = null;
    _restoreViewStateHandler = null;
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
}
