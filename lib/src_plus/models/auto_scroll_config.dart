// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter/foundation.dart';

/// Configuration for automatic scrolling in real-time streaming charts.
///
/// When enabled, the chart automatically pans to keep the most recent data
/// points visible as new data arrives. Once the total data points exceed
/// [maxVisiblePoints], older data is scrolled off-screen to the left.
///
/// **Behavior:**
/// - Data keeps accumulating (nothing is deleted)
/// - Pan offset automatically adjusts to show latest N points
/// - User can manually pan to view historical data
/// - Scrolling resumes when new data arrives (if enabled)
///
/// **Example:**
/// ```dart
/// BravenChart(
///   chartType: ChartType.line,
///   series: [ChartSeries(id: 'sensor', points: const [])],
///   controller: _controller,
///   autoScrollConfig: AutoScrollConfig(
///     enabled: true,
///     maxVisiblePoints: 50,  // Show last 50 points
///     resumeOnNewData: true,  // Resume auto-scroll after manual pan
///   ),
/// )
/// ```
@immutable
class AutoScrollConfig {
  /// Creates an auto-scroll configuration.
  const AutoScrollConfig({
    this.enabled = false,
    this.maxVisiblePoints = 100,
    this.resumeOnNewData = true,
    this.animateScroll = true,
    this.scrollAnimationDuration = const Duration(milliseconds: 300),
  }) : assert(maxVisiblePoints > 0, 'maxVisiblePoints must be positive');

  /// Whether auto-scrolling is enabled.
  ///
  /// When false, chart behaves normally (no automatic panning).
  final bool enabled;

  /// Maximum number of data points to display in the viewport.
  ///
  /// Once the total data count exceeds this value, the chart automatically
  /// pans to show the most recent [maxVisiblePoints] points.
  ///
  /// Must be positive.
  final int maxVisiblePoints;

  /// Whether to resume auto-scrolling after manual pan.
  ///
  /// - `true`: New data arrival resumes auto-scroll (default)
  /// - `false`: Manual pan disables auto-scroll until explicitly re-enabled
  ///
  /// This allows users to inspect historical data without constant interruption.
  final bool resumeOnNewData;

  /// Whether to animate the scroll transition.
  ///
  /// - `true`: Smooth animated pan (default)
  /// - `false`: Instant jump to new position
  ///
  /// Animation uses the duration specified in [scrollAnimationDuration].
  final bool animateScroll;

  /// Duration of scroll animation.
  ///
  /// Only applies when [animateScroll] is true.
  /// Shorter durations (100-200ms) feel more responsive for high-frequency data.
  /// Longer durations (300-500ms) are smoother for low-frequency updates.
  final Duration scrollAnimationDuration;

  /// Creates a disabled configuration (no auto-scrolling).
  static const AutoScrollConfig disabled = AutoScrollConfig(enabled: false);

  /// Creates a configuration optimized for high-frequency data (10+ updates/sec).
  ///
  /// Shows last 50 points with fast, smooth scrolling.
  static const AutoScrollConfig highFrequency = AutoScrollConfig(
    enabled: true,
    maxVisiblePoints: 50,
    resumeOnNewData: true,
    animateScroll: true,
    scrollAnimationDuration: Duration(milliseconds: 150),
  );

  /// Creates a configuration optimized for low-frequency data (< 1 update/sec).
  ///
  /// Shows last 100 points with slower, more noticeable scrolling.
  static const AutoScrollConfig lowFrequency = AutoScrollConfig(
    enabled: true,
    maxVisiblePoints: 100,
    resumeOnNewData: true,
    animateScroll: true,
    scrollAnimationDuration: Duration(milliseconds: 500),
  );

  /// Creates a copy with optional parameter overrides.
  AutoScrollConfig copyWith({
    bool? enabled,
    int? maxVisiblePoints,
    bool? resumeOnNewData,
    bool? animateScroll,
    Duration? scrollAnimationDuration,
  }) {
    return AutoScrollConfig(
      enabled: enabled ?? this.enabled,
      maxVisiblePoints: maxVisiblePoints ?? this.maxVisiblePoints,
      resumeOnNewData: resumeOnNewData ?? this.resumeOnNewData,
      animateScroll: animateScroll ?? this.animateScroll,
      scrollAnimationDuration: scrollAnimationDuration ?? this.scrollAnimationDuration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is AutoScrollConfig &&
        other.enabled == enabled &&
        other.maxVisiblePoints == maxVisiblePoints &&
        other.resumeOnNewData == resumeOnNewData &&
        other.animateScroll == animateScroll &&
        other.scrollAnimationDuration == scrollAnimationDuration;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      maxVisiblePoints,
      resumeOnNewData,
      animateScroll,
      scrollAnimationDuration,
    );
  }

  @override
  String toString() {
    if (!enabled) return 'AutoScrollConfig.disabled';
    return 'AutoScrollConfig('
        'enabled: $enabled, '
        'maxVisiblePoints: $maxVisiblePoints, '
        'resumeOnNewData: $resumeOnNewData, '
        'animateScroll: $animateScroll, '
        'scrollAnimationDuration: $scrollAnimationDuration'
        ')';
  }
}
