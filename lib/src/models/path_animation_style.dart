// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

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
  interpolate,
}

/// Motion configuration shared by Line and Area series.
///
/// Motion is opt-in so existing, streaming, and very large charts keep their
/// current behavior. Timing and easing come from `ChartTheme.animationTheme`.
@immutable
class PathAnimationStyle {
  const PathAnimationStyle({
    this.entranceMode = PathEntranceAnimationMode.none,
    this.dataUpdateMode = PathDataUpdateAnimationMode.none,
  });

  final PathEntranceAnimationMode entranceMode;
  final PathDataUpdateAnimationMode dataUpdateMode;

  PathAnimationStyle copyWith({
    PathEntranceAnimationMode? entranceMode,
    PathDataUpdateAnimationMode? dataUpdateMode,
  }) => PathAnimationStyle(
    entranceMode: entranceMode ?? this.entranceMode,
    dataUpdateMode: dataUpdateMode ?? this.dataUpdateMode,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PathAnimationStyle &&
          entranceMode == other.entranceMode &&
          dataUpdateMode == other.dataUpdateMode;

  @override
  int get hashCode => Object.hash(entranceMode, dataUpdateMode);

  @override
  String toString() =>
      'PathAnimationStyle(entranceMode: $entranceMode, dataUpdateMode: $dataUpdateMode)';
}
