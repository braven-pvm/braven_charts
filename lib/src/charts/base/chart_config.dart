/// Base chart configuration and styling options
library;

import 'package:flutter/animation.dart';

/// Shape of chart markers (data points)
///
/// Defines the visual representation of individual data points:
/// - [circle]: Circular marker
/// - [square]: Square marker
/// - [triangle]: Triangular marker pointing up
/// - [diamond]: Diamond/rhombus marker
/// - [cross]: Cross (+) marker
/// - [plus]: Plus (x) marker rotated 45°
/// - [none]: No marker (useful for line charts without points)
enum MarkerShape {
  /// Circular marker (●)
  circle,

  /// Square marker (■)
  square,

  /// Triangular marker (▲)
  triangle,

  /// Diamond marker (◆)
  diamond,

  /// Cross marker (+)
  cross,

  /// Plus marker (x) - cross rotated 45°
  plus,

  /// No marker - just the line
  none,
}

/// Animation configuration for chart data updates
///
/// Configures how the chart animates when data changes.
///
/// Constitutional requirement: Input validation (Testing Excellence)
class ChartAnimationConfig {
  /// Creates animation configuration
  ///
  /// Throws [ArgumentError] if:
  /// - [changeThreshold] < 0.0 or > 1.0
  const ChartAnimationConfig({
    this.enabled = true,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.changeThreshold = 0.01,
  }) : assert(
          changeThreshold >= 0.0 && changeThreshold <= 1.0,
          'changeThreshold must be between 0.0 and 1.0',
        );

  /// Creates configuration with animations disabled
  const ChartAnimationConfig.disabled()
      : enabled = false,
        duration = Duration.zero,
        curve = Curves.linear,
        changeThreshold = 0.0;

  /// Whether animations are enabled
  final bool enabled;

  /// Duration of the animation
  final Duration duration;

  /// Animation curve
  final Curve curve;

  /// Minimum relative change to trigger animation
  ///
  /// Value is between 0.0 and 1.0. A value of 0.01 means changes smaller
  /// than 1% of the value range won't trigger animation.
  final double changeThreshold;

  /// Creates a copy with modified properties
  ChartAnimationConfig copyWith({
    bool? enabled,
    Duration? duration,
    Curve? curve,
    double? changeThreshold,
  }) {
    return ChartAnimationConfig(
      enabled: enabled ?? this.enabled,
      duration: duration ?? this.duration,
      curve: curve ?? this.curve,
      changeThreshold: changeThreshold ?? this.changeThreshold,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartAnimationConfig &&
          runtimeType == other.runtimeType &&
          enabled == other.enabled &&
          duration == other.duration &&
          curve == other.curve &&
          changeThreshold == other.changeThreshold;

  @override
  int get hashCode => Object.hash(enabled, duration, curve, changeThreshold);

  @override
  String toString() {
    return 'ChartAnimationConfig(enabled: $enabled, duration: $duration, curve: $curve, changeThreshold: $changeThreshold)';
  }
}

/// Per-series style overrides
///
/// Allows individual series to override theme styling.
/// Null values fall back to theme defaults.
///
/// Constitutional requirement: Input validation (Testing Excellence)
class ChartSeriesStyle {
  /// Creates per-series style overrides
  ///
  /// Throws [ArgumentError] if:
  /// - [lineWidth] < 0
  /// - [markerSize] < 0
  /// - [fillOpacity] not in [0.0, 1.0]
  /// - [barWidthRatio] not in (0.0, 1.0]
  const ChartSeriesStyle({
    this.color,
    this.lineWidth,
    this.markerSize,
    this.fillOpacity,
    this.barWidthRatio,
  })  : assert(lineWidth == null || lineWidth >= 0, 'lineWidth must be >= 0'),
        assert(
            markerSize == null || markerSize >= 0, 'markerSize must be >= 0'),
        assert(
          fillOpacity == null || (fillOpacity >= 0.0 && fillOpacity <= 1.0),
          'fillOpacity must be between 0.0 and 1.0',
        ),
        assert(
          barWidthRatio == null ||
              (barWidthRatio > 0.0 && barWidthRatio <= 1.0),
          'barWidthRatio must be in (0.0, 1.0]',
        );

  /// Series color (overrides theme color)
  final Color? color;

  /// Line width for line/area charts
  final double? lineWidth;

  /// Marker size
  final double? markerSize;

  /// Fill opacity for area/bar charts (0.0 to 1.0)
  final double? fillOpacity;

  /// Bar width ratio for bar charts (0.0 to 1.0)
  final double? barWidthRatio;

  /// Creates a copy with modified properties
  ChartSeriesStyle copyWith({
    Color? color,
    double? lineWidth,
    double? markerSize,
    double? fillOpacity,
    double? barWidthRatio,
  }) {
    return ChartSeriesStyle(
      color: color ?? this.color,
      lineWidth: lineWidth ?? this.lineWidth,
      markerSize: markerSize ?? this.markerSize,
      fillOpacity: fillOpacity ?? this.fillOpacity,
      barWidthRatio: barWidthRatio ?? this.barWidthRatio,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSeriesStyle &&
          runtimeType == other.runtimeType &&
          color == other.color &&
          lineWidth == other.lineWidth &&
          markerSize == other.markerSize &&
          fillOpacity == other.fillOpacity &&
          barWidthRatio == other.barWidthRatio;

  @override
  int get hashCode =>
      Object.hash(color, lineWidth, markerSize, fillOpacity, barWidthRatio);

  @override
  String toString() {
    return 'ChartSeriesStyle(color: $color, lineWidth: $lineWidth, markerSize: $markerSize, fillOpacity: $fillOpacity, barWidthRatio: $barWidthRatio)';
  }
}

/// Color class placeholder (will use Flutter's Color in actual implementation)
typedef Color = int;
