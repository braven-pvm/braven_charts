// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

import '../meta/chart_surface.dart';

/// Entrance motion available to path-based Cartesian series.
enum PathEntranceAnimationMode {
  /// Render the final path immediately.
  none,

  /// Reveal the path from the leading edge of the plot.
  reveal,
}

/// Data-update motion available to path-based Cartesian series.
enum PathDataUpdateAnimationMode {
  /// Render updated points immediately.
  none,

  /// Interpolate compatible point geometry through the standard renderer.
  ///
  /// Ordered value changes interpolate in place. Stable-identity points may
  /// also enter or leave at a series boundary, including rolling-window
  /// updates. Interior topology edits and reordered identities are not
  /// interpolated.
  interpolate,
}

/// Timing for one path-animation phase on a single series.
///
/// A null [duration] inherits
/// `ChartTheme.animationTheme.dataUpdateDuration`. Delays and explicit
/// durations are non-negative. Reduced motion and a zero-duration chart theme
/// still render the final series synchronously.
@immutable
// `copyWith` spells the unset flag `inheritDuration`, not `clearDuration`,
// so the derived-clear-flag convention needs an explicit override here.
@ChartSurface(clearFlags: {'duration': 'inheritDuration'})
class PathAnimationTiming {
  const PathAnimationTiming({this.delay = Duration.zero, this.duration});

  /// Time to hold the valid phase-start geometry before motion begins.
  final Duration delay;

  /// Per-series duration, or null to inherit the chart theme duration.
  final Duration? duration;

  PathAnimationTiming copyWith({
    Duration? delay,
    Duration? duration,
    bool inheritDuration = false,
  }) {
    assert(
      !inheritDuration || duration == null,
      'duration cannot be supplied when inheritDuration is true',
    );
    return PathAnimationTiming(
      delay: delay ?? this.delay,
      duration: inheritDuration ? null : duration ?? this.duration,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PathAnimationTiming &&
          delay == other.delay &&
          duration == other.duration;

  @override
  int get hashCode => Object.hash(delay, duration);

  @override
  String toString() =>
      'PathAnimationTiming(delay: $delay, duration: $duration)';
}

/// Motion configuration shared by Line and Area series.
///
/// Motion is opt-in so existing, streaming, and very large charts keep their
/// current behavior. Each phase inherits the chart theme duration unless its
/// [PathAnimationTiming.duration] overrides it. The chart theme supplies the
/// easing curve and remains the reduced-motion and zero-duration authority.
@immutable
@chartSurface
class PathAnimationStyle {
  const PathAnimationStyle({
    this.entranceMode = PathEntranceAnimationMode.none,
    this.dataUpdateMode = PathDataUpdateAnimationMode.none,
    this.entranceTiming = const PathAnimationTiming(),
    this.dataUpdateTiming = const PathAnimationTiming(),
  });

  final PathEntranceAnimationMode entranceMode;

  /// How mounted snapshot updates animate after the entrance phase.
  final PathDataUpdateAnimationMode dataUpdateMode;

  /// Per-series entrance delay and duration.
  final PathAnimationTiming entranceTiming;

  /// Per-series compatible-update delay and duration.
  final PathAnimationTiming dataUpdateTiming;

  PathAnimationStyle copyWith({
    PathEntranceAnimationMode? entranceMode,
    PathDataUpdateAnimationMode? dataUpdateMode,
    PathAnimationTiming? entranceTiming,
    PathAnimationTiming? dataUpdateTiming,
  }) => PathAnimationStyle(
    entranceMode: entranceMode ?? this.entranceMode,
    dataUpdateMode: dataUpdateMode ?? this.dataUpdateMode,
    entranceTiming: entranceTiming ?? this.entranceTiming,
    dataUpdateTiming: dataUpdateTiming ?? this.dataUpdateTiming,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PathAnimationStyle &&
          entranceMode == other.entranceMode &&
          dataUpdateMode == other.dataUpdateMode &&
          entranceTiming == other.entranceTiming &&
          dataUpdateTiming == other.dataUpdateTiming;

  @override
  int get hashCode => Object.hash(
    entranceMode,
    dataUpdateMode,
    entranceTiming,
    dataUpdateTiming,
  );

  @override
  String toString() =>
      'PathAnimationStyle(entranceMode: $entranceMode, '
      'dataUpdateMode: $dataUpdateMode, entranceTiming: $entranceTiming, '
      'dataUpdateTiming: $dataUpdateTiming)';
}
