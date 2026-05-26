import 'package:flutter/foundation.dart';

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

  // Slot state mirrored from MultiAxisManager (updated after every swap).
  String? _selectedSeriesId;
  List<String> _visibleAxisIds = const [];
  List<String> _overflowAxisIds = const [];

  // ---- Public read API ----

  /// Currently selected series ID, or null if nothing is selected.
  String? get selectedSeriesId => _selectedSeriesId;

  /// Axis IDs currently occupying visible slots, in slot order.
  List<String> get visibleAxisIds => List.unmodifiable(_visibleAxisIds);

  /// Axis IDs currently in overflow (voted out of visible slots).
  List<String> get overflowAxisIds => List.unmodifiable(_overflowAxisIds);

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

  // ---- Internal state sync (called by _BravenChartPlusState) ----

  /// Attaches this controller to a chart state. Called by the state.
  void attach({
    required void Function(String) onSelect,
    required void Function(String) onDeselect,
    required void Function() onClear,
  }) {
    _selectHandler = onSelect;
    _deselectHandler = onDeselect;
    _clearHandler = onClear;
  }

  /// Detaches from the chart state. Called in dispose.
  void detach() {
    _selectHandler = null;
    _deselectHandler = null;
    _clearHandler = null;
  }

  /// Updates mirrored slot state (called after every swap or selection change).
  void updateSlotState({
    required String? selectedSeriesId,
    required List<String> visibleAxisIds,
    required List<String> overflowAxisIds,
  }) {
    _selectedSeriesId = selectedSeriesId;
    _visibleAxisIds = visibleAxisIds;
    _overflowAxisIds = overflowAxisIds;
    notifyListeners();
  }
}
