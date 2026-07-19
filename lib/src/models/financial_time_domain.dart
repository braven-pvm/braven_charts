// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

/// How financial sessions are positioned along a Cartesian X axis.
enum FinancialTimeSpacing {
  /// Every observed session receives an equal-width slot.
  ordinal,

  /// UTC epoch milliseconds preserve weekends and other elapsed-time gaps.
  elapsed,
}

typedef FinancialDateLabelFormatter = String Function(DateTime timestamp);

/// Immutable mapping between ordered financial sessions and Cartesian X values.
///
/// The model deliberately stays locale-neutral. Bind [formatX] to the current
/// app locale at render time rather than storing locale-formatted labels in the
/// data model.
final class FinancialTimeDomain {
  FinancialTimeDomain(Iterable<DateTime> sessions)
    : _sessions = List<DateTime>.unmodifiable(
        sessions.map((session) => session.toUtc()),
      ) {
    for (var index = 1; index < _sessions.length; index++) {
      if (!_sessions[index].isAfter(_sessions[index - 1])) {
        throw ArgumentError.value(
          _sessions[index],
          'sessions[$index]',
          'must be strictly later than sessions[${index - 1}]',
        );
      }
    }
  }

  final List<DateTime> _sessions;

  int get length => _sessions.length;
  bool get isEmpty => _sessions.isEmpty;
  List<DateTime> get sessions => _sessions;

  DateTime timestampAt(int index) => _sessions[index];

  double xAt(int index, FinancialTimeSpacing spacing) => switch (spacing) {
    FinancialTimeSpacing.ordinal => index.toDouble(),
    FinancialTimeSpacing.elapsed =>
      _sessions[index].millisecondsSinceEpoch.toDouble(),
  };

  /// Resolves the nearest observed session in O(log n).
  int nearestIndex(double x, FinancialTimeSpacing spacing) {
    if (_sessions.isEmpty) {
      throw StateError('A financial time domain must contain a session');
    }
    if (!x.isFinite) throw ArgumentError.value(x, 'x', 'must be finite');
    if (spacing == FinancialTimeSpacing.ordinal) {
      return x.round().clamp(0, _sessions.length - 1);
    }

    var low = 0;
    var high = _sessions.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (_sessions[middle].millisecondsSinceEpoch < x) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    if (low == 0) return 0;
    if (low == _sessions.length) return _sessions.length - 1;
    final left = _sessions[low - 1].millisecondsSinceEpoch.toDouble();
    final right = _sessions[low].millisecondsSinceEpoch.toDouble();
    return x - left <= right - x ? low - 1 : low;
  }

  String formatX(
    double x,
    FinancialTimeSpacing spacing, {
    required FinancialDateLabelFormatter formatter,
  }) => formatter(timestampAt(nearestIndex(x, spacing)));
}
