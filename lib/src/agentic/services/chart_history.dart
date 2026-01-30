import '../models/chart_configuration.dart';

/// Service for managing chart modification history with undo/redo support.
///
/// Maintains a circular buffer of up to 20 chart states. When the buffer is full,
/// the oldest state is discarded to make room for new states.
///
/// The service provides purely functional undo/redo operations - it returns
/// ChartConfiguration instances without side effects. The caller is responsible
/// for updating UI state.
class ChartHistory {
  /// Maximum number of states to keep in history
  final int maxDepth;

  /// Internal buffer storing chart states
  final List<ChartConfiguration> _history = [];

  /// Current position in history (points to the current state)
  int _position = 0;

  /// Creates a new ChartHistory with the specified maximum depth
  ChartHistory({this.maxDepth = 20});

  /// Records a new chart state in history.
  ///
  /// Performs a deep copy to ensure immutability. If currently in the middle
  /// of history (after undo), this clears all redo states. When the buffer is
  /// full (maxDepth), the oldest state is removed.
  void record(ChartConfiguration chart) {
    // If we're in the middle of history, clear redo states
    if (_position < _history.length) {
      _history.removeRange(_position, _history.length);
    }

    // Add the new state (deep copy via JSON serialization)
    _history.add(_deepCopy(chart));
    _position = _history.length; // Point to the newly added state

    // If we've exceeded maxDepth, remove the oldest state
    if (_history.length > maxDepth) {
      _history.removeAt(0);
      _position--; // Adjust position since all indices shifted down by 1
    }
  }

  /// Returns the previous chart state if available, otherwise null.
  ///
  /// Does not modify state - caller must update UI.
  ChartConfiguration? undo() {
    if (!canUndo) return null;

    if (_position == 1) {
      // At the oldest state - return it but don't move position
      // Further undos will return null
      _position = 0;
      return _history[0];
    }

    _position--;
    return _history[_position - 1];
  }

  /// Returns the next chart state if available, otherwise null.
  ///
  /// Does not modify state - caller must update UI.
  ChartConfiguration? redo() {
    if (!canRedo) return null;

    _position++;
    return _history[_position - 1];
  }

  /// Clears all history
  void clear() {
    _history.clear();
    _position = 0;
  }

  /// Whether undo is possible (can move back in history)
  bool get canUndo => _position > 0;

  /// Whether redo is possible (we've undone and haven't recorded new state)
  bool get canRedo => _position < _history.length;

  /// Current position in history (0-based, 0 means no states recorded)
  int get position => _position;

  /// Total number of states in history
  int get size => _history.length;

  /// Performs a deep copy of a ChartConfiguration using JSON serialization
  ChartConfiguration _deepCopy(ChartConfiguration chart) {
    final json = chart.toJson();
    return ChartConfiguration.fromJson(json);
  }
}
