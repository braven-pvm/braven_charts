// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/animation.dart';

import '../models/path_animation_style.dart';

/// Resolved timing window for one path series in an animation phase.
class PathAnimationWindow {
  const PathAnimationWindow({required this.start, required this.duration});

  final Duration start;
  final Duration duration;

  Duration get end => start + duration;

  bool get isImmediate => duration == Duration.zero;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PathAnimationWindow &&
          start == other.start &&
          duration == other.duration;

  @override
  int get hashCode => Object.hash(start, duration);
}

/// Pure elapsed-time resolver shared by path entrance and update motion.
abstract final class PathAnimationTimeline {
  /// Resolves explicit timings against the theme-level default duration.
  ///
  /// A zero theme duration is a global motion kill switch. A zero per-series
  /// duration also resolves immediately and ignores its configured delay.
  static Map<String, PathAnimationWindow> resolve({
    required Map<String, PathAnimationTiming> timings,
    required Duration themeDuration,
  }) => {
    for (final entry in timings.entries)
      entry.key: _resolveWindow(entry.value, themeDuration),
  };

  static PathAnimationWindow _resolveWindow(
    PathAnimationTiming timing,
    Duration themeDuration,
  ) {
    if (timing.delay.isNegative) {
      throw ArgumentError.value(
        timing.delay,
        'timing.delay',
        'must be >= Duration.zero',
      );
    }
    if (timing.duration?.isNegative ?? false) {
      throw ArgumentError.value(
        timing.duration,
        'timing.duration',
        'must be null or >= Duration.zero',
      );
    }
    if (themeDuration == Duration.zero) {
      return const PathAnimationWindow(
        start: Duration.zero,
        duration: Duration.zero,
      );
    }
    final duration = timing.duration ?? themeDuration;
    if (duration == Duration.zero) {
      return const PathAnimationWindow(
        start: Duration.zero,
        duration: Duration.zero,
      );
    }
    return PathAnimationWindow(start: timing.delay, duration: duration);
  }

  /// Duration required for every non-immediate window to complete.
  static Duration totalDuration(Iterable<PathAnimationWindow> windows) {
    var maximumMicroseconds = 0;
    for (final window in windows) {
      if (window.isImmediate) continue;
      maximumMicroseconds = maximumMicroseconds > window.end.inMicroseconds
          ? maximumMicroseconds
          : window.end.inMicroseconds;
    }
    return Duration(microseconds: maximumMicroseconds);
  }

  /// Resolves one series' curved local progress from phase-controller value.
  static double progress({
    required double controllerValue,
    required Duration timelineDuration,
    required PathAnimationWindow window,
    required Curve curve,
  }) {
    if (window.isImmediate || timelineDuration == Duration.zero) return 1;
    final elapsedMicroseconds =
        (timelineDuration.inMicroseconds * controllerValue.clamp(0.0, 1.0))
            .round();
    if (elapsedMicroseconds <= window.start.inMicroseconds) return 0;
    if (elapsedMicroseconds >= window.end.inMicroseconds) return 1;
    final local =
        (elapsedMicroseconds - window.start.inMicroseconds) /
        window.duration.inMicroseconds;
    return curve.transform(local.clamp(0.0, 1.0));
  }
}
