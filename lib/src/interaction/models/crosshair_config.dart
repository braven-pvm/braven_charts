/// Crosshair configuration model for chart interactions.
///
/// Defines the appearance and behavior of crosshairs that track the
/// cursor/touch position on the chart.
///
/// This model is immutable and uses copyWith for updates.
library;

import 'dart:ui' show Color, StrokeCap;

import 'package:flutter/widgets.dart' show TextStyle;

/// The mode of crosshair display.
enum CrosshairMode {
  /// Show only vertical crosshair line.
  vertical,

  /// Show only horizontal crosshair line.
  horizontal,

  /// Show both vertical and horizontal crosshair lines.
  both,

  /// Disable crosshair display.
  none,
}

/// Style configuration for crosshair lines.
class CrosshairStyle {
  /// Creates a crosshair style with the specified properties.
  const CrosshairStyle({
    this.lineColor = const Color(0xFF666666),
    this.lineWidth = 1.0,
    this.dashPattern = const [5, 3],  // Default dashed pattern per spec
    this.strokeCap = StrokeCap.round,
    this.labelBackgroundColor = const Color(0xFF333333),
    this.labelTextColor = const Color(0xFFFFFFFF),
    this.labelPadding = 4.0,
  })  : assert(lineWidth > 0, 'lineWidth must be greater than 0'),
        assert(labelPadding >= 0, 'labelPadding must be non-negative');

  /// The color of the crosshair lines.
  final Color lineColor;

  /// The width of the crosshair lines in pixels.
  ///
  /// Must be greater than 0.
  final double lineWidth;

  /// The dash pattern for the crosshair lines.
  ///
  /// Null or empty list means solid line. Pattern values are in pixels:
  /// [dash length, gap length, dash length, gap length, ...]
  final List<double>? dashPattern;

  /// The stroke cap style for crosshair lines.
  final StrokeCap strokeCap;

  /// The background color of coordinate labels.
  final Color labelBackgroundColor;

  /// The text color of coordinate labels.
  final Color labelTextColor;

  /// The padding around coordinate label text.
  ///
  /// Must be non-negative.
  final double labelPadding;

  /// Creates a copy of this style with the specified properties updated.
  CrosshairStyle copyWith({
    Color? lineColor,
    double? lineWidth,
    List<double>? dashPattern,
    StrokeCap? strokeCap,
    Color? labelBackgroundColor,
    Color? labelTextColor,
    double? labelPadding,
  }) {
    return CrosshairStyle(
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      dashPattern: dashPattern ?? this.dashPattern,
      strokeCap: strokeCap ?? this.strokeCap,
      labelBackgroundColor: labelBackgroundColor ?? this.labelBackgroundColor,
      labelTextColor: labelTextColor ?? this.labelTextColor,
      labelPadding: labelPadding ?? this.labelPadding,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CrosshairStyle &&
        other.lineColor == lineColor &&
        other.lineWidth == lineWidth &&
        _listEquals(other.dashPattern, dashPattern) &&
        other.strokeCap == strokeCap &&
        other.labelBackgroundColor == labelBackgroundColor &&
        other.labelTextColor == labelTextColor &&
        other.labelPadding == labelPadding;
  }

  @override
  int get hashCode {
    return Object.hash(
      lineColor,
      lineWidth,
      dashPattern == null ? null : Object.hashAll(dashPattern!),
      strokeCap,
      labelBackgroundColor,
      labelTextColor,
      labelPadding,
    );
  }

  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Configuration for crosshair behavior and appearance.
///
/// This immutable model defines how crosshairs are displayed and behave
/// when tracking the cursor position on the chart.
///
/// Example:
/// ```dart
/// final config = CrosshairConfig.defaultConfig();
/// final custom = config.copyWith(
///   mode: CrosshairMode.both,
///   snapToDataPoint: true,
/// );
/// ```
class CrosshairConfig {
  /// Creates a crosshair configuration with the specified properties.
  const CrosshairConfig({
    this.enabled = true,
    this.mode = CrosshairMode.both,
    this.snapToDataPoint = true,  // Changed to true to match spec
    this.snapRadius = 20.0,
    this.showCoordinateLabels = true,
    this.coordinateLabelStyle,
    this.style = const CrosshairStyle(),
  }) : assert(snapRadius >= 0, 'snapRadius must be non-negative');

  /// Creates a default crosshair configuration.
  ///
  /// Enables crosshair with both vertical and horizontal lines,
  /// snapping enabled, and default styling per specification.
  factory CrosshairConfig.defaultConfig() {
    return const CrosshairConfig(
      coordinateLabelStyle: TextStyle(
        fontSize: 12,
        color: Color(0xDE000000), // Colors.black87
      ),
    );
  }

  /// Whether the crosshair is enabled.
  final bool enabled;

  /// The display mode of the crosshair.
  final CrosshairMode mode;

  /// Whether to snap the crosshair to nearby data points.
  final bool snapToDataPoint;

  /// The radius in pixels within which to snap to data points.
  ///
  /// Only used when [snapToDataPoint] is true. Must be non-negative.
  final double snapRadius;

  /// Whether to show coordinate labels on the crosshair lines.
  final bool showCoordinateLabels;

  /// The text style for coordinate labels.
  final TextStyle? coordinateLabelStyle;

  /// The visual style of the crosshair.
  final CrosshairStyle style;

  /// Creates a copy of this configuration with the specified properties updated.
  ///
  /// All properties are optional. Omitted properties retain their current values.
  CrosshairConfig copyWith({
    bool? enabled,
    CrosshairMode? mode,
    bool? snapToDataPoint,
    double? snapRadius,
    bool? showCoordinateLabels,
    TextStyle? coordinateLabelStyle,
    CrosshairStyle? style,
  }) {
    return CrosshairConfig(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      snapToDataPoint: snapToDataPoint ?? this.snapToDataPoint,
      snapRadius: snapRadius ?? this.snapRadius,
      showCoordinateLabels: showCoordinateLabels ?? this.showCoordinateLabels,
      coordinateLabelStyle: coordinateLabelStyle ?? this.coordinateLabelStyle,
      style: style ?? this.style,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CrosshairConfig &&
        other.enabled == enabled &&
        other.mode == mode &&
        other.snapToDataPoint == snapToDataPoint &&
        other.snapRadius == snapRadius &&
        other.showCoordinateLabels == showCoordinateLabels &&
        other.coordinateLabelStyle == coordinateLabelStyle &&
        other.style == style;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      mode,
      snapToDataPoint,
      snapRadius,
      showCoordinateLabels,
      coordinateLabelStyle,
      style,
    );
  }
}
