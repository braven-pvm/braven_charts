/// Crosshair configuration model for chart interactions.
///
/// Defines the appearance and behavior of crosshairs that track the
/// cursor/touch position on the chart.
///
/// This model is immutable and uses copyWith for updates.
library;

import 'dart:ui' show Color;

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
    this.dashPattern = const [5.0, 5.0],
    this.labelBackgroundColor = const Color(0xFF333333),
    this.labelTextColor = const Color(0xFFFFFFFF),
    this.labelPadding = 4.0,
  }) : assert(lineWidth > 0, 'lineWidth must be greater than 0'),
       assert(labelPadding >= 0, 'labelPadding must be non-negative');

  /// The color of the crosshair lines.
  final Color lineColor;

  /// The width of the crosshair lines in pixels.
  ///
  /// Must be greater than 0.
  final double lineWidth;

  /// The dash pattern for the crosshair lines.
  ///
  /// Empty list means solid line. Pattern values are in pixels:
  /// [dash length, gap length, dash length, gap length, ...]
  final List<double> dashPattern;

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
    Color? labelBackgroundColor,
    Color? labelTextColor,
    double? labelPadding,
  }) {
    return CrosshairStyle(
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      dashPattern: dashPattern ?? this.dashPattern,
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
        other.labelBackgroundColor == labelBackgroundColor &&
        other.labelTextColor == labelTextColor &&
        other.labelPadding == labelPadding;
  }

  @override
  int get hashCode {
    return Object.hash(
      lineColor,
      lineWidth,
      Object.hashAll(dashPattern),
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
///   snapToDataPoints: true,
/// );
/// ```
class CrosshairConfig {
  /// Creates a crosshair configuration with the specified properties.
  const CrosshairConfig({
    this.enabled = true,
    this.mode = CrosshairMode.both,
    this.snapToDataPoints = false,
    this.snapRadius = 20.0,
    this.showCoordinateLabels = true,
    this.style = const CrosshairStyle(),
  }) : assert(snapRadius >= 0, 'snapRadius must be non-negative');

  /// Creates a default crosshair configuration.
  ///
  /// Enables crosshair with both vertical and horizontal lines,
  /// no snapping, and default styling.
  factory CrosshairConfig.defaultConfig() {
    return const CrosshairConfig();
  }

  /// Whether the crosshair is enabled.
  final bool enabled;

  /// The display mode of the crosshair.
  final CrosshairMode mode;

  /// Whether to snap the crosshair to nearby data points.
  final bool snapToDataPoints;

  /// The radius in pixels within which to snap to data points.
  ///
  /// Only used when [snapToDataPoints] is true. Must be non-negative.
  final double snapRadius;

  /// Whether to show coordinate labels on the crosshair lines.
  final bool showCoordinateLabels;

  /// The visual style of the crosshair.
  final CrosshairStyle style;

  /// Creates a copy of this configuration with the specified properties updated.
  ///
  /// All properties are optional. Omitted properties retain their current values.
  CrosshairConfig copyWith({
    bool? enabled,
    CrosshairMode? mode,
    bool? snapToDataPoints,
    double? snapRadius,
    bool? showCoordinateLabels,
    CrosshairStyle? style,
  }) {
    return CrosshairConfig(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      snapToDataPoints: snapToDataPoints ?? this.snapToDataPoints,
      snapRadius: snapRadius ?? this.snapRadius,
      showCoordinateLabels:
          showCoordinateLabels ?? this.showCoordinateLabels,
      style: style ?? this.style,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is CrosshairConfig &&
        other.enabled == enabled &&
        other.mode == mode &&
        other.snapToDataPoints == snapToDataPoints &&
        other.snapRadius == snapRadius &&
        other.showCoordinateLabels == showCoordinateLabels &&
        other.style == style;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      mode,
      snapToDataPoints,
      snapRadius,
      showCoordinateLabels,
      style,
    );
  }
}
