import 'package:flutter/foundation.dart';

/// X-only data-space viewport shared by synchronized Cartesian charts.
@immutable
class ChartXViewport {
  /// Creates finite, ordered X bounds.
  const ChartXViewport({required this.min, required this.max})
    : assert(min < max, 'min must be less than max');

  /// Left edge of the visible data domain.
  final double min;

  /// Right edge of the visible data domain.
  final double max;

  /// Whether both bounds are finite and ordered.
  bool get isValid => min.isFinite && max.isFinite && min < max;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartXViewport && other.min == min && other.max == max;

  @override
  int get hashCode => Object.hash(min, max);

  @override
  String toString() => 'ChartXViewport(min: $min, max: $max)';
}

/// Per-chart synchronization capabilities within an interaction group.
@immutable
class ChartInteractionGroupOptions {
  /// Creates participant synchronization options.
  const ChartInteractionGroupOptions({
    this.synchronizeCursor = true,
    this.synchronizeViewport = true,
  });

  /// Whether this chart sends and receives shared data-X cursor changes.
  final bool synchronizeCursor;

  /// Whether this chart sends and receives shared X viewport changes.
  final bool synchronizeViewport;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartInteractionGroupOptions &&
          other.synchronizeCursor == synchronizeCursor &&
          other.synchronizeViewport == synchronizeViewport;

  @override
  int get hashCode => Object.hash(synchronizeCursor, synchronizeViewport);
}

/// Coordinates transient data-X interaction across independent charts.
///
/// Supply the same caller-owned controller to multiple `BravenChartPlus`
/// widgets. The charts keep independent Y domains, tooltips, selection,
/// annotations, and artifacts. Dispose this controller when its host is
/// disposed.
class ChartInteractionGroupController {
  final Map<Object, _ChartInteractionGroupMember> _members = {};
  double? _cursorX;
  ChartXViewport? _viewport;
  final ValueNotifier<ChartXViewport?> _viewportNotifier = ValueNotifier(null);
  bool _broadcastingCursor = false;
  bool _broadcastingViewport = false;
  bool _disposed = false;

  /// Current shared data-X cursor, or null when no interaction is active.
  double? get cursorX => _cursorX;

  /// Most recently shared X viewport, or null before the first viewport event.
  ChartXViewport? get viewport => _viewport;

  /// Observable viewport state for navigator and range-control composition.
  ValueListenable<ChartXViewport?> get viewportListenable => _viewportNotifier;

  /// Applies one host-owned X viewport to every synchronized participant.
  ///
  /// Range controls, navigators, and other composition surfaces use this
  /// command without pretending to be a chart participant. Each chart keeps
  /// its independent Y domain and feedback from the resulting update is
  /// suppressed while the command fans out.
  void setViewport(ChartXViewport viewport) {
    if (_disposed) return;
    if (!viewport.isValid) {
      throw ArgumentError.value(
        viewport,
        'viewport',
        'bounds must be finite and ordered',
      );
    }
    if (_viewport == viewport) return;
    _viewport = viewport;
    _viewportNotifier.value = viewport;
    if (_broadcastingViewport) return;
    _broadcastingViewport = true;
    try {
      for (final entry
          in List<MapEntry<Object, _ChartInteractionGroupMember>>.of(
            _members.entries,
          )) {
        if (identical(_members[entry.key], entry.value) &&
            entry.value.options.synchronizeViewport) {
          entry.value.onViewportChanged(viewport);
        }
      }
    } finally {
      _broadcastingViewport = false;
    }
  }

  /// Clears remembered cursor and viewport state for a fresh composition.
  ///
  /// Mounted charts receive cursor cleanup immediately. Viewports remain local;
  /// reset or remount them separately when starting a new composition.
  void reset() {
    if (_disposed) return;
    final hadCursor = _cursorX != null;
    _cursorX = null;
    _viewport = null;
    _viewportNotifier.value = null;
    if (!hadCursor || _broadcastingCursor) return;
    _broadcastingCursor = true;
    try {
      for (final entry
          in List<MapEntry<Object, _ChartInteractionGroupMember>>.of(
            _members.entries,
          )) {
        if (identical(_members[entry.key], entry.value) &&
            entry.value.options.synchronizeCursor) {
          entry.value.onCursorChanged(null);
        }
      }
    } finally {
      _broadcastingCursor = false;
    }
  }

  /// Registers one mounted chart.
  ///
  /// Managed by `BravenChartPlus`; exposed for package integrations and tests.
  @internal
  ChartInteractionGroupParticipant attachChart({
    required Object attachment,
    ChartInteractionGroupOptions options = const ChartInteractionGroupOptions(),
    required ValueChanged<double?> onCursorChanged,
    required ValueChanged<ChartXViewport> onViewportChanged,
  }) {
    if (_disposed) {
      throw StateError(
        'Cannot attach a chart to a disposed '
        'ChartInteractionGroupController.',
      );
    }
    final member = _ChartInteractionGroupMember(
      options: options,
      onCursorChanged: onCursorChanged,
      onViewportChanged: onViewportChanged,
    );
    _members[attachment] = member;
    final participant = ChartInteractionGroupParticipant._(
      controller: this,
      attachment: attachment,
    );
    if (options.synchronizeCursor && _cursorX != null) {
      onCursorChanged(_cursorX);
    }
    if (options.synchronizeViewport && _viewport != null) {
      onViewportChanged(_viewport!);
    }
    return participant;
  }

  void _publishCursor(Object attachment, double? dataX) {
    if (_disposed || !_members.containsKey(attachment)) return;
    if (dataX != null && !dataX.isFinite) {
      throw ArgumentError.value(dataX, 'dataX', 'must be finite or null');
    }
    final source = _members[attachment]!;
    if (!source.options.synchronizeCursor || _broadcastingCursor) return;
    if (_cursorX == dataX) return;
    _cursorX = dataX;
    _broadcastingCursor = true;
    try {
      for (final entry
          in List<MapEntry<Object, _ChartInteractionGroupMember>>.of(
            _members.entries,
          )) {
        if (identical(_members[entry.key], entry.value) &&
            entry.value.options.synchronizeCursor) {
          entry.value.onCursorChanged(dataX);
        }
      }
    } finally {
      _broadcastingCursor = false;
    }
  }

  void _publishViewport(Object attachment, ChartXViewport viewport) {
    if (_disposed || !_members.containsKey(attachment)) return;
    if (!viewport.isValid) {
      throw ArgumentError.value(
        viewport,
        'viewport',
        'bounds must be finite and ordered',
      );
    }
    final source = _members[attachment]!;
    if (!source.options.synchronizeViewport || _broadcastingViewport) return;
    if (_viewport == viewport) return;
    _viewport = viewport;
    _viewportNotifier.value = viewport;
    _broadcastingViewport = true;
    try {
      for (final entry
          in List<MapEntry<Object, _ChartInteractionGroupMember>>.of(
            _members.entries,
          )) {
        if (identical(_members[entry.key], entry.value) &&
            entry.value.options.synchronizeViewport) {
          entry.value.onViewportChanged(viewport);
        }
      }
    } finally {
      _broadcastingViewport = false;
    }
  }

  void _detach(Object attachment) {
    if (_disposed) return;
    _members.remove(attachment);
  }

  /// Releases every participant and ignores subsequent registration events.
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _members.clear();
    _cursorX = null;
    _viewport = null;
    _viewportNotifier.dispose();
  }
}

/// Mounted-chart handle managed by `BravenChartPlus`.
///
/// Application code normally supplies only [ChartInteractionGroupController]
/// to chart widgets and never creates this object directly.
@internal
class ChartInteractionGroupParticipant {
  ChartInteractionGroupParticipant._({
    required ChartInteractionGroupController controller,
    required Object attachment,
  }) : _controller = controller,
       _attachment = attachment;

  ChartInteractionGroupController? _controller;
  final Object _attachment;

  /// Publishes one local data-space X cursor.
  @internal
  void publishCursor(double dataX) =>
      _controller?._publishCursor(_attachment, dataX);

  /// Clears the shared cursor after pointer exit or touch completion.
  @internal
  void clearCursor() => _controller?._publishCursor(_attachment, null);

  /// Publishes local visible X bounds.
  @internal
  void publishViewport(ChartXViewport viewport) =>
      _controller?._publishViewport(_attachment, viewport);

  /// Detaches this chart immediately. Safe to call more than once.
  @internal
  void dispose() {
    _controller?._detach(_attachment);
    _controller = null;
  }
}

class _ChartInteractionGroupMember {
  const _ChartInteractionGroupMember({
    required this.options,
    required this.onCursorChanged,
    required this.onViewportChanged,
  });

  final ChartInteractionGroupOptions options;
  final ValueChanged<double?> onCursorChanged;
  final ValueChanged<ChartXViewport> onViewportChanged;
}
