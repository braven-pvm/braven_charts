// Copyright (c) 2025 braven_charts. All rights reserved.

import 'dart:async';

import 'package:flutter/animation.dart';

typedef _VisibilityTarget = ({double from, double to, Duration elapsed});

/// Smooths changes in the set of series callouts accepted by collision layout.
///
/// Position remains owned by the deterministic layout pass. This animator only
/// fades labels in and out, so a label never appears to belong to a different
/// series value while collision priority changes.
class SeriesCalloutVisibilityAnimator {
  SeriesCalloutVisibilityAnimator({required this.onRepaint});

  static const _stepDuration = Duration(milliseconds: 16);

  final void Function() onRepaint;
  final Map<String, double> _opacities = {};
  final Map<String, _VisibilityTarget> _transitions = {};

  Timer? _timer;
  Duration _duration = Duration.zero;
  bool _initialized = false;
  bool _disposed = false;

  double opacityFor(String id) => _opacities[id] ?? 0;

  bool get isAnimating => _timer?.isActive ?? false;

  /// Updates the accepted callout IDs without restarting unchanged fades.
  void update({
    required Set<String> allIds,
    required Set<String> visibleIds,
    required Duration duration,
    required bool animate,
  }) {
    if (_disposed) return;
    _duration = duration;

    _opacities.removeWhere((id, _) => !allIds.contains(id));
    _transitions.removeWhere((id, _) => !allIds.contains(id));

    if (!_initialized || !animate || duration.inMicroseconds <= 0) {
      _initialized = true;
      _timer?.cancel();
      _timer = null;
      _transitions.clear();
      for (final id in allIds) {
        _opacities[id] = visibleIds.contains(id) ? 1 : 0;
      }
      return;
    }

    for (final id in allIds) {
      final target = visibleIds.contains(id) ? 1.0 : 0.0;
      final current = _opacities[id] ?? 0;
      final transition = _transitions[id];
      if (transition?.to == target) continue;
      if ((current - target).abs() < 0.001) {
        _opacities[id] = target;
        _transitions.remove(id);
        continue;
      }
      _transitions[id] = (from: current, to: target, elapsed: Duration.zero);
    }
    _ensureTimer();
  }

  /// Clears retained visibility when callouts leave the render pipeline.
  void reset() {
    _timer?.cancel();
    _timer = null;
    _opacities.clear();
    _transitions.clear();
    _initialized = false;
  }

  void dispose() {
    _disposed = true;
    reset();
  }

  void _ensureTimer() {
    if (_transitions.isEmpty || _timer?.isActive == true) return;
    _timer = Timer.periodic(_stepDuration, _tick);
  }

  void _tick(Timer timer) {
    if (_disposed || _transitions.isEmpty) {
      timer.cancel();
      _timer = null;
      return;
    }
    final durationMicros = _duration.inMicroseconds;
    final completed = <String>[];
    for (final entry in _transitions.entries.toList(growable: false)) {
      final transition = entry.value;
      final elapsed = transition.elapsed + _stepDuration;
      final progress = durationMicros <= 0
          ? 1.0
          : (elapsed.inMicroseconds / durationMicros).clamp(0.0, 1.0);
      final eased = transition.to > transition.from
          ? Curves.easeOutCubic.transform(progress)
          : Curves.easeInCubic.transform(progress);
      _opacities[entry.key] =
          transition.from + (transition.to - transition.from) * eased;
      if (progress >= 1) {
        _opacities[entry.key] = transition.to;
        completed.add(entry.key);
      } else {
        _transitions[entry.key] = (
          from: transition.from,
          to: transition.to,
          elapsed: elapsed,
        );
      }
    }
    for (final id in completed) {
      _transitions.remove(id);
    }
    if (_transitions.isEmpty) {
      timer.cancel();
      _timer = null;
    }
    onRepaint();
  }
}
