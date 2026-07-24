/// Interaction configuration wrapper model.
///
/// This library provides configuration models for chart interaction features,
/// including crosshair, tooltip, zoom/pan, gestures, and keyboard navigation.
library;

import 'dart:ui' show Color, StrokeCap;

import 'package:flutter/widgets.dart' show TextStyle, Widget, BuildContext;

import '../meta/chart_surface.dart';
import 'cartesian_value_summary_config.dart';
import 'interaction_callbacks.dart';
import 'candlestick_interaction_details.dart';
import 'range_area_interaction_details.dart';

// ==============================================================================
// Crosshair Configuration
// ==============================================================================

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

/// Display mode for high-density data visualization.
enum CrosshairDisplayMode {
  /// Standard mode: Show data point markers and pop-up tooltips on hover.
  standard,

  /// Tracking mode: Hide markers, show persistent tooltip following cursor.
  tracking,

  /// Auto mode: Switch between standard and tracking based on data point count.
  auto,
}

/// Represents a series value at a specific X position during tracking mode.
class CrosshairSeriesValue {
  const CrosshairSeriesValue({
    required this.seriesId,
    required this.seriesName,
    required this.seriesColor,
    required this.x,
    required this.y,
    required this.dataPointIndex,
    this.sourcePointIndices = const <int>[],
    required this.isInterpolated,
    this.linkedSeriesId,
    this.isTrend = false,
    this.pointLabel,
    this.magnitudeValue,
    this.formattedMagnitudeValue,
    this.magnitudeLabel,
    this.colorValue,
    this.formattedColorValue,
    this.colorLabel,
    this.opacityValue,
    this.formattedOpacityValue,
    this.opacityLabel,
    this.candlestick,
    this.rangeArea,
    this.categoryValue,
    this.categoryLabel,
  });

  final String seriesId;
  final String seriesName;
  final Color seriesColor;
  final double x;
  final double y;
  final int dataPointIndex;
  final List<int> sourcePointIndices;
  final bool isInterpolated;

  /// For trend annotations, the ID of the data series this trend is linked to.
  /// Used for axis resolution so the trend dot aligns with the correct Y axis.
  final String? linkedSeriesId;

  /// Whether this value represents a trend annotation rather than a data series.
  final bool isTrend;

  /// Optional source-point label for discrete Scatter tracking.
  final String? pointLabel;

  /// Optional third quantitative Scatter value represented by marker area.
  final double? magnitudeValue;

  /// Display-ready [magnitudeValue], including its unit.
  final String? formattedMagnitudeValue;

  /// Human-readable name for [magnitudeValue].
  final String? magnitudeLabel;

  /// Optional quantitative Scatter value represented through marker color.
  final double? colorValue;

  /// Display-ready [colorValue], including its unit.
  final String? formattedColorValue;

  /// Human-readable name for [colorValue].
  final String? colorLabel;

  /// Optional quantitative Scatter value represented through marker opacity.
  final double? opacityValue;

  /// Display-ready [opacityValue], including its unit.
  final String? formattedOpacityValue;

  /// Human-readable name for [opacityValue].
  final String? opacityLabel;

  /// Typed OHLC values when this tracked sample is a Candlestick.
  final CandlestickInteractionDetails? candlestick;

  /// Typed low/high values when this tracked sample is a Range Area.
  final RangeAreaInteractionDetails? rangeArea;

  /// Display-ready categorical Scatter value.
  final String? categoryValue;

  /// Human-readable name for [categoryValue].
  final String? categoryLabel;

  /// Returns the series ID to use for axis resolution (linked series for trends).
  String get axisSeriesId => linkedSeriesId ?? seriesId;
}

/// Complete tracking state for crosshair rendering.
class CrosshairTrackingState {
  const CrosshairTrackingState({
    required this.dataX,
    required this.screenX,
    required this.seriesValues,
  });

  final double dataX;
  final double screenX;
  final List<CrosshairSeriesValue> seriesValues;
}

/// Style configuration for crosshair lines.
@chartSurface
class CrosshairStyle {
  /// Creates a crosshair style with the specified properties.
  const CrosshairStyle({
    this.lineColor = const Color(0xFF666666),
    this.lineWidth = 1.0,
    this.dashPattern = const [5, 3], // Default dashed pattern per spec
    this.strokeCap = StrokeCap.round,
    this.bandColor = const Color(0x00000000),
    this.bandWidth = 0.0,
    this.labelBackgroundColor = const Color(0xFF333333),
    this.labelTextColor = const Color(0xFFFFFFFF),
    this.labelPadding = 4.0,
  }) : assert(lineWidth > 0, 'lineWidth must be greater than 0'),
       assert(bandWidth >= 0, 'bandWidth must be non-negative'),
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
  /// `[dash length, gap length, dash length, gap length, ...]`
  final List<double>? dashPattern;

  /// The stroke cap style for crosshair lines.
  final StrokeCap strokeCap;

  /// Fill painted symmetrically around each visible crosshair guide.
  ///
  /// Keep this transparent, or set [bandWidth] to zero, to disable the band.
  /// The band is clipped to the plot and painted behind the center line.
  final Color bandColor;

  /// Width of the translucent guide band in logical pixels.
  ///
  /// The same width is used for a vertical band's horizontal span and a
  /// horizontal band's vertical span.
  final double bandWidth;

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
    Color? bandColor,
    double? bandWidth,
    Color? labelBackgroundColor,
    Color? labelTextColor,
    double? labelPadding,
    bool clearDashPattern = false,
  }) {
    return CrosshairStyle(
      lineColor: lineColor ?? this.lineColor,
      lineWidth: lineWidth ?? this.lineWidth,
      dashPattern: clearDashPattern ? null : (dashPattern ?? this.dashPattern),
      strokeCap: strokeCap ?? this.strokeCap,
      bandColor: bandColor ?? this.bandColor,
      bandWidth: bandWidth ?? this.bandWidth,
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
        other.bandColor == bandColor &&
        other.bandWidth == bandWidth &&
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
      bandColor,
      bandWidth,
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
@ChartSurface(presetFactories: ['tracking', 'defaultConfig'])
class CrosshairConfig {
  /// Creates a CrosshairConfig optimized for tracking mode.
  factory CrosshairConfig.tracking({
    bool interpolate = true,
    bool showTooltip = true,
    bool showMarkers = true,
    double markerRadius = 4.0,
  }) {
    return CrosshairConfig(
      displayMode: CrosshairDisplayMode.tracking,
      interpolateValues: interpolate,
      showTrackingTooltip: showTooltip,
      showIntersectionMarkers: showMarkers,
      intersectionMarkerRadius: markerRadius,
    );
  }

  /// Creates a crosshair configuration with the specified properties.
  const CrosshairConfig({
    this.enabled = true,
    this.mode = CrosshairMode.both,
    this.snapToDataPoint = true, // Changed to true to match spec
    this.snapRadius = 20.0,
    this.showCoordinateLabels = true,
    this.coordinateLabelStyle,
    this.style = const CrosshairStyle(),
    // Tracking mode properties for high-density data
    this.displayMode = CrosshairDisplayMode.auto,
    this.trackingModeThreshold = 250,
    this.interpolateValues = true,
    this.showTrackingTooltip = true,
    this.showIntersectionMarkers = true,
    this.intersectionMarkerRadius = 4.0,
    this.persistOnPointerExit = false,
  }) : assert(snapRadius >= 0, 'snapRadius must be non-negative'),
       assert(
         trackingModeThreshold > 0,
         'trackingModeThreshold must be positive',
       ),
       assert(
         intersectionMarkerRadius > 0,
         'intersectionMarkerRadius must be positive',
       );

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

  /// Whether to show the axis value labels while the crosshair tracks.
  ///
  /// The labels are their own feedback layer, independent of the crosshair
  /// lines: with [mode] set to [CrosshairMode.none] the labels can still
  /// paint, and clearing this flag removes them while the lines remain.
  /// In tracking mode a vertical-only crosshair keeps X-only labels and a
  /// horizontal-only crosshair keeps Y-only labels; [CrosshairMode.both] and
  /// [CrosshairMode.none] show both. Per-axis `showCrosshairLabel` flags
  /// continue to filter individual axes.
  final bool showCoordinateLabels;

  /// The text style for coordinate labels.
  final TextStyle? coordinateLabelStyle;

  /// The visual style of the crosshair.
  final CrosshairStyle style;

  // ===========================================================================
  // Tracking Mode Properties (for high-density data visualization)
  // ===========================================================================

  /// The display mode for crosshair visualization.
  ///
  /// - [CrosshairDisplayMode.standard]: Show individual data point markers
  /// - [CrosshairDisplayMode.tracking]: Hide markers, show tracking tooltip
  /// - [CrosshairDisplayMode.auto]: Switch based on [trackingModeThreshold]
  final CrosshairDisplayMode displayMode;

  /// The threshold for auto-switching to tracking mode.
  ///
  /// When [displayMode] is [CrosshairDisplayMode.auto], tracking mode
  /// activates when total data points exceed this threshold.
  final int trackingModeThreshold;

  /// Whether to interpolate Y values between data points.
  ///
  /// When true, calculates the exact Y value at the cursor X position
  /// using linear interpolation. When false, shows the nearest data point.
  final bool interpolateValues;

  /// Whether to show the tracking tooltip in tracking mode.
  final bool showTrackingTooltip;

  /// Whether to show intersection markers on series lines.
  ///
  /// In tracking mode, small colored circles appear at the intersection
  /// of the vertical crosshair line and each series line.
  final bool showIntersectionMarkers;

  /// The radius of intersection markers in pixels.
  final double intersectionMarkerRadius;

  /// Whether the last tracking guide remains visible after pointer exit.
  ///
  /// When enabled, the chart retains its most recently resolved cursor,
  /// coordinate labels, intersection markers, and tracking tooltip when the
  /// pointer leaves the chart or the chart loses focus. This is useful for
  /// synchronized analytical panes where the last inspected sample should
  /// remain available while the user interacts with adjacent controls.
  ///
  /// Defaults to false so existing charts keep their transient hover behavior.
  final bool persistOnPointerExit;

  /// Determines if tracking mode should be used based on configuration
  /// and data point count.
  bool shouldUseTrackingMode(int totalDataPoints) {
    switch (displayMode) {
      case CrosshairDisplayMode.standard:
        return false;
      case CrosshairDisplayMode.tracking:
        return true;
      case CrosshairDisplayMode.auto:
        return totalDataPoints > trackingModeThreshold;
    }
  }

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
    CrosshairDisplayMode? displayMode,
    int? trackingModeThreshold,
    bool? interpolateValues,
    bool? showTrackingTooltip,
    bool? showIntersectionMarkers,
    double? intersectionMarkerRadius,
    bool? persistOnPointerExit,
    bool clearCoordinateLabelStyle = false,
  }) {
    return CrosshairConfig(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      snapToDataPoint: snapToDataPoint ?? this.snapToDataPoint,
      snapRadius: snapRadius ?? this.snapRadius,
      showCoordinateLabels: showCoordinateLabels ?? this.showCoordinateLabels,
      coordinateLabelStyle: clearCoordinateLabelStyle
          ? null
          : (coordinateLabelStyle ?? this.coordinateLabelStyle),
      style: style ?? this.style,
      displayMode: displayMode ?? this.displayMode,
      trackingModeThreshold:
          trackingModeThreshold ?? this.trackingModeThreshold,
      interpolateValues: interpolateValues ?? this.interpolateValues,
      showTrackingTooltip: showTrackingTooltip ?? this.showTrackingTooltip,
      showIntersectionMarkers:
          showIntersectionMarkers ?? this.showIntersectionMarkers,
      intersectionMarkerRadius:
          intersectionMarkerRadius ?? this.intersectionMarkerRadius,
      persistOnPointerExit: persistOnPointerExit ?? this.persistOnPointerExit,
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
        other.style == style &&
        other.displayMode == displayMode &&
        other.trackingModeThreshold == trackingModeThreshold &&
        other.interpolateValues == interpolateValues &&
        other.showTrackingTooltip == showTrackingTooltip &&
        other.showIntersectionMarkers == showIntersectionMarkers &&
        other.intersectionMarkerRadius == intersectionMarkerRadius &&
        other.persistOnPointerExit == persistOnPointerExit;
  }

  @override
  int get hashCode {
    return Object.hashAll([
      enabled,
      mode,
      snapToDataPoint,
      snapRadius,
      showCoordinateLabels,
      coordinateLabelStyle,
      style,
      displayMode,
      trackingModeThreshold,
      interpolateValues,
      showTrackingTooltip,
      showIntersectionMarkers,
      intersectionMarkerRadius,
      persistOnPointerExit,
    ]);
  }
}

// ==============================================================================
// Tooltip Configuration
// ==============================================================================

/// The trigger mode for showing tooltips.
enum TooltipTriggerMode {
  /// Show tooltip on hover (mouse) or tap-and-hold (touch).
  hover,

  /// Show tooltip on tap/click only.
  tap,

  /// Show tooltip on both hover and tap.
  both,
}

/// The position of the tooltip relative to the data point.
enum TooltipPosition {
  /// Automatically position the tooltip to avoid chart edges.
  auto,

  /// Position the tooltip above/on top of the data point.
  top,

  /// Position the tooltip below/at bottom of the data point.
  bottom,

  /// Position the tooltip to the left of the data point.
  left,

  /// Position the tooltip to the right of the data point.
  right,
}

/// Style configuration for tooltip appearance.
@chartSurface
class TooltipStyle {
  /// Creates a tooltip style with the specified properties.
  const TooltipStyle({
    this.backgroundColor = const Color(0xE6FFFFFF),
    this.borderColor = const Color(0xFF999999),
    this.borderWidth = 1.0,
    this.borderRadius = 4.0,
    this.shadowColor = const Color(0x00000000), // Colors.transparent
    this.shadowBlurRadius = 4.0,
    this.padding = 8.0,
    this.textColor = const Color(0xFF333333),
    this.fontSize = 12.0,
  }) : assert(borderWidth >= 0, 'borderWidth must be non-negative'),
       assert(borderRadius >= 0, 'borderRadius must be non-negative'),
       assert(shadowBlurRadius >= 0, 'shadowBlurRadius must be non-negative'),
       assert(padding >= 0, 'padding must be non-negative'),
       assert(fontSize > 0, 'fontSize must be greater than 0');

  /// The background color of the tooltip.
  final Color backgroundColor;

  /// The border color of the tooltip.
  final Color borderColor;

  /// The width of the tooltip border in pixels.
  ///
  /// Must be non-negative.
  final double borderWidth;

  /// The border radius of the tooltip in pixels.
  ///
  /// Must be non-negative.
  final double borderRadius;

  /// The color of the tooltip shadow.
  final Color shadowColor;

  /// The blur radius of the tooltip shadow in pixels.
  ///
  /// Must be non-negative.
  final double shadowBlurRadius;

  /// The padding inside the tooltip in pixels.
  ///
  /// Must be non-negative.
  final double padding;

  /// The text color inside the tooltip.
  final Color textColor;

  /// The font size of tooltip text in pixels.
  ///
  /// Must be greater than 0.
  final double fontSize;

  /// Creates a copy of this style with the specified properties updated.
  TooltipStyle copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    Color? shadowColor,
    double? shadowBlurRadius,
    double? padding,
    Color? textColor,
    double? fontSize,
  }) {
    return TooltipStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowBlurRadius: shadowBlurRadius ?? this.shadowBlurRadius,
      padding: padding ?? this.padding,
      textColor: textColor ?? this.textColor,
      fontSize: fontSize ?? this.fontSize,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TooltipStyle &&
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.borderRadius == borderRadius &&
        other.shadowColor == shadowColor &&
        other.shadowBlurRadius == shadowBlurRadius &&
        other.padding == padding &&
        other.textColor == textColor &&
        other.fontSize == fontSize;
  }

  @override
  int get hashCode {
    return Object.hash(
      backgroundColor,
      borderColor,
      borderWidth,
      borderRadius,
      shadowColor,
      shadowBlurRadius,
      padding,
      textColor,
      fontSize,
    );
  }
}

/// Signature for a custom tooltip builder function.
///
/// Takes a `BuildContext` and a [dataPoint] map containing the data
/// to display, and returns a `Widget` representing the custom tooltip.
typedef TooltipBuilder =
    Widget Function(BuildContext context, Map<String, dynamic> dataPoint);

/// Configuration for tooltip behavior and appearance.
///
/// This immutable model defines how tooltips are displayed and behave
/// when showing data point information on the chart.
///
/// Example:
/// ```dart
/// final config = TooltipConfig.defaultConfig();
/// final custom = config.copyWith(
///   triggerMode: TooltipTriggerMode.tap,
///   position: TooltipPosition.above,
/// );
/// ```
@chartSurface
class TooltipConfig {
  /// Creates a tooltip configuration with the specified properties.
  ///
  /// Constraints:
  /// - [offsetFromPoint] must be non-negative
  /// - [showDelay] and [hideDelay] should be reasonable durations (no validation enforced in const constructor)
  const TooltipConfig({
    this.enabled = true,
    this.triggerMode = TooltipTriggerMode.hover,
    this.preferredPosition = TooltipPosition.auto,
    this.showDelay = Duration.zero,
    this.hideDelay = const Duration(milliseconds: 200),
    this.followCursor = false,
    this.offsetFromPoint = 8.0,
    this.style = const TooltipStyle(),
    this.customBuilder,
  }) : assert(offsetFromPoint >= 0, 'offsetFromPoint must be non-negative');

  /// Creates a default tooltip configuration.
  ///
  /// Enables tooltip with hover trigger, auto positioning,
  /// standard delays, and default styling.
  factory TooltipConfig.defaultConfig() {
    return const TooltipConfig();
  }

  /// Whether the tooltip is enabled.
  final bool enabled;

  /// The trigger mode for showing tooltips.
  final TooltipTriggerMode triggerMode;

  /// The preferred position of the tooltip relative to the data point.
  final TooltipPosition preferredPosition;

  /// The delay before showing the tooltip.
  ///
  /// Must be non-negative.
  final Duration showDelay;

  /// The delay before hiding the tooltip.
  ///
  /// Must be non-negative.
  final Duration hideDelay;

  /// Whether the tooltip should follow the cursor/touch position.
  ///
  /// When true, tooltip moves with the cursor. When false, it stays
  /// anchored to the data point.
  final bool followCursor;

  /// The distance in pixels between the tooltip and the data point.
  ///
  /// Used when positioning the tooltip. Must be non-negative.
  final double offsetFromPoint;

  /// The visual style of the tooltip.
  final TooltipStyle style;

  /// Optional custom builder for tooltip content.
  ///
  /// When provided, this function is called to build the tooltip widget
  /// instead of using the default tooltip rendering.
  final TooltipBuilder? customBuilder;

  /// Creates a copy of this configuration with the specified properties updated.
  ///
  /// All properties are optional. Omitted properties retain their current values.
  TooltipConfig copyWith({
    bool? enabled,
    TooltipTriggerMode? triggerMode,
    TooltipPosition? preferredPosition,
    Duration? showDelay,
    Duration? hideDelay,
    bool? followCursor,
    double? offsetFromPoint,
    TooltipStyle? style,
    TooltipBuilder? customBuilder,
  }) {
    return TooltipConfig(
      enabled: enabled ?? this.enabled,
      triggerMode: triggerMode ?? this.triggerMode,
      preferredPosition: preferredPosition ?? this.preferredPosition,
      showDelay: showDelay ?? this.showDelay,
      hideDelay: hideDelay ?? this.hideDelay,
      followCursor: followCursor ?? this.followCursor,
      offsetFromPoint: offsetFromPoint ?? this.offsetFromPoint,
      style: style ?? this.style,
      customBuilder: customBuilder ?? this.customBuilder,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is TooltipConfig &&
        other.enabled == enabled &&
        other.triggerMode == triggerMode &&
        other.preferredPosition == preferredPosition &&
        other.showDelay == showDelay &&
        other.hideDelay == hideDelay &&
        other.followCursor == followCursor &&
        other.offsetFromPoint == offsetFromPoint &&
        other.style == style &&
        other.customBuilder == customBuilder;
  }

  @override
  int get hashCode {
    return Object.hash(
      enabled,
      triggerMode,
      preferredPosition,
      showDelay,
      hideDelay,
      followCursor,
      offsetFromPoint,
      style,
      customBuilder,
    );
  }
}

// ==============================================================================
// Gesture Configuration
// ==============================================================================

/// Configuration for gesture recognition.
///
/// Controls timeouts and thresholds for detecting tap, long-press, pan, and
/// pinch gestures on charts.
///
/// Example:
/// ```dart
/// const gestureConfig = GestureConfig(
///   tapTimeout: Duration(milliseconds: 200),
///   longPressTimeout: Duration(milliseconds: 500),
///   panThreshold: 10.0, // pixels
///   pinchThreshold: 0.1, // scale factor
/// );
/// ```
@chartSurface
class GestureConfig {
  const GestureConfig({
    this.tapTimeout = const Duration(milliseconds: 200),
    this.longPressTimeout = const Duration(milliseconds: 500),
    this.panThreshold = 10.0,
    this.pinchThreshold = 0.1,
  });

  /// Maximum time between pointer down and up for tap recognition.
  final Duration tapTimeout;

  /// Duration pointer must be held for long-press recognition.
  final Duration longPressTimeout;

  /// Minimum movement distance (pixels) to trigger pan gesture.
  final double panThreshold;

  /// Minimum scale change to trigger pinch gesture.
  final double pinchThreshold;

  /// Creates a copy with some properties replaced.
  GestureConfig copyWith({
    Duration? tapTimeout,
    Duration? longPressTimeout,
    double? panThreshold,
    double? pinchThreshold,
  }) {
    return GestureConfig(
      tapTimeout: tapTimeout ?? this.tapTimeout,
      longPressTimeout: longPressTimeout ?? this.longPressTimeout,
      panThreshold: panThreshold ?? this.panThreshold,
      pinchThreshold: pinchThreshold ?? this.pinchThreshold,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GestureConfig &&
        other.tapTimeout == tapTimeout &&
        other.longPressTimeout == longPressTimeout &&
        other.panThreshold == panThreshold &&
        other.pinchThreshold == pinchThreshold;
  }

  @override
  int get hashCode =>
      Object.hash(tapTimeout, longPressTimeout, panThreshold, pinchThreshold);
}

// ==============================================================================
// Touch Configuration
// ==============================================================================

/// Determines how direct touch gestures share the surface with a parent
/// scrollable.
enum TouchInteractionProfile {
  /// Preserve one-finger dragging for the surrounding page.
  ///
  /// The chart only claims viewport gestures after a second touch pointer is
  /// present.
  browse,

  /// Give a chart-focused surface one-finger panning after drag slop.
  ///
  /// Taps remain available for inspection and selection.
  explore,
}

/// Touch-specific viewport gesture policy.
///
/// This policy does not replace [InteractionConfig.enableZoom] or
/// [InteractionConfig.enablePan]. Those top-level flags remain the final
/// feature gates. It only defines which touch gestures may request them.
@chartSurface
class TouchInteractionConfig {
  const TouchInteractionConfig({
    this.enabled = true,
    this.profile = TouchInteractionProfile.browse,
    this.enablePinchZoom = true,
    this.enablePan = true,
    this.enablePanInertia = false,
    this.panInertiaDeceleration = 6.0,
    this.maximumPanInertiaVelocity = 3200.0,
    this.enableLongPressTracking = true,
    this.enableHapticFeedback = true,
  }) : assert(
         panInertiaDeceleration > 0 && panInertiaDeceleration < double.infinity,
       ),
       assert(
         maximumPanInertiaVelocity > 0 &&
             maximumPanInertiaVelocity < double.infinity,
       );

  /// Whether direct touch viewport gestures are enabled.
  final bool enabled;

  /// How the chart arbitrates one-finger drags with surrounding content.
  final TouchInteractionProfile profile;

  /// Whether two-finger scale changes may zoom the chart.
  final bool enablePinchZoom;

  /// Whether touch translation may pan the chart.
  ///
  /// Browse mode requires two pointers. Explore mode permits one pointer after
  /// the configured pan threshold is crossed.
  final bool enablePan;

  /// Whether a released touch pan may continue with bounded inertial motion.
  ///
  /// Disabled by default to preserve the deterministic phase-1 behavior.
  /// Inertia remains subordinate to [enabled], [enablePan], and the top-level
  /// `InteractionConfig.enablePan` gate.
  final bool enablePanInertia;

  /// Exponential velocity decay applied during touch pan inertia.
  ///
  /// The value is measured per second. Higher values stop sooner.
  final double panInertiaDeceleration;

  /// Maximum release velocity admitted by touch pan inertia, in pixels/second.
  ///
  /// Limiting the release velocity prevents short noisy gestures from
  /// producing an unexpectedly large viewport displacement.
  final double maximumPanInertiaVelocity;

  /// Whether holding one finger may activate transient tracking inspection.
  ///
  /// Once active, dragging scrubs the existing crosshair and tracking tooltip.
  /// The transient inspection clears when the pointer lifts.
  final bool enableLongPressTracking;

  /// Whether touch tracking may request platform haptic feedback.
  ///
  /// Haptics are requested when tracking activates and when it crosses to a
  /// different snapped X observation. Platforms without haptic support safely
  /// ignore the request.
  final bool enableHapticFeedback;

  TouchInteractionConfig copyWith({
    bool? enabled,
    TouchInteractionProfile? profile,
    bool? enablePinchZoom,
    bool? enablePan,
    bool? enablePanInertia,
    double? panInertiaDeceleration,
    double? maximumPanInertiaVelocity,
    bool? enableLongPressTracking,
    bool? enableHapticFeedback,
  }) {
    return TouchInteractionConfig(
      enabled: enabled ?? this.enabled,
      profile: profile ?? this.profile,
      enablePinchZoom: enablePinchZoom ?? this.enablePinchZoom,
      enablePan: enablePan ?? this.enablePan,
      enablePanInertia: enablePanInertia ?? this.enablePanInertia,
      panInertiaDeceleration:
          panInertiaDeceleration ?? this.panInertiaDeceleration,
      maximumPanInertiaVelocity:
          maximumPanInertiaVelocity ?? this.maximumPanInertiaVelocity,
      enableLongPressTracking:
          enableLongPressTracking ?? this.enableLongPressTracking,
      enableHapticFeedback: enableHapticFeedback ?? this.enableHapticFeedback,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TouchInteractionConfig &&
        other.enabled == enabled &&
        other.profile == profile &&
        other.enablePinchZoom == enablePinchZoom &&
        other.enablePan == enablePan &&
        other.enablePanInertia == enablePanInertia &&
        other.panInertiaDeceleration == panInertiaDeceleration &&
        other.maximumPanInertiaVelocity == maximumPanInertiaVelocity &&
        other.enableLongPressTracking == enableLongPressTracking &&
        other.enableHapticFeedback == enableHapticFeedback;
  }

  @override
  int get hashCode => Object.hash(
    enabled,
    profile,
    enablePinchZoom,
    enablePan,
    enablePanInertia,
    panInertiaDeceleration,
    maximumPanInertiaVelocity,
    enableLongPressTracking,
    enableHapticFeedback,
  );
}

// ==============================================================================
// Keyboard Configuration
// ==============================================================================

/// Configuration for keyboard navigation.
///
/// Controls keyboard-based chart interaction. Arrow keys traverse selectable
/// marks for Bar, Scatter, Candlestick, Range Area, Line, and Area charts;
/// Line/Area and mixed Range Area compositions use left/right for observations
/// and up/down for series. Bar navigation follows its orientation. When a
/// family does not own point navigation, arrows pan the Cartesian viewport.
/// Plus and minus zoom, while Home or `R` restores the live viewport. Enter or
/// Space applies the configured semantic scope, Shift+Space extends an ordered
/// selection from its keyboard anchor, Ctrl/Command+A selects all marks only
/// when the result is bounded (or every complete series for whole-series
/// scope), and Escape clears focus plus durable selection.
///
/// Example:
/// ```dart
/// const keyboardConfig = KeyboardConfig(
///   enabled: true,
///   panStep: 10.0, // pixels per arrow key press
///   zoomStep: 0.1, // 10% zoom per +/- key
///   enableArrowKeys: true,
///   enablePlusMinusKeys: true,
///   enableHomeEndKeys: true,
/// );
/// ```
@chartSurface
class KeyboardConfig {
  const KeyboardConfig({
    this.enabled = true,
    this.panStep = 10.0,
    this.zoomStep = 0.1,
    this.enableArrowKeys = true,
    this.enablePlusMinusKeys = true,
    this.enableHomeEndKeys = true,
  });

  /// Whether keyboard navigation is enabled.
  final bool enabled;

  /// Distance (pixels) to pan per arrow key press.
  final double panStep;

  /// Zoom factor change per +/- key press (0.1 = 10% zoom).
  final double zoomStep;

  /// Whether arrow keys can pan the chart.
  final bool enableArrowKeys;

  /// Whether +/- keys can zoom the chart.
  final bool enablePlusMinusKeys;

  /// Whether Home/End keys jump to boundaries.
  final bool enableHomeEndKeys;

  /// Creates a copy with some properties replaced.
  KeyboardConfig copyWith({
    bool? enabled,
    double? panStep,
    double? zoomStep,
    bool? enableArrowKeys,
    bool? enablePlusMinusKeys,
    bool? enableHomeEndKeys,
  }) {
    return KeyboardConfig(
      enabled: enabled ?? this.enabled,
      panStep: panStep ?? this.panStep,
      zoomStep: zoomStep ?? this.zoomStep,
      enableArrowKeys: enableArrowKeys ?? this.enableArrowKeys,
      enablePlusMinusKeys: enablePlusMinusKeys ?? this.enablePlusMinusKeys,
      enableHomeEndKeys: enableHomeEndKeys ?? this.enableHomeEndKeys,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is KeyboardConfig &&
        other.enabled == enabled &&
        other.panStep == panStep &&
        other.zoomStep == zoomStep &&
        other.enableArrowKeys == enableArrowKeys &&
        other.enablePlusMinusKeys == enablePlusMinusKeys &&
        other.enableHomeEndKeys == enableHomeEndKeys;
  }

  @override
  int get hashCode => Object.hash(
    enabled,
    panStep,
    zoomStep,
    enableArrowKeys,
    enablePlusMinusKeys,
    enableHomeEndKeys,
  );
}

// ==============================================================================
// Interaction Configuration
// ==============================================================================

/// Comprehensive interaction configuration for charts.
///
/// This class integrates all interaction features including crosshair, tooltip,
/// zoom/pan, gestures, and keyboard navigation. It supports both simple boolean
/// flags for quick setup and advanced sub-configuration objects for fine-tuned
/// control.
///
/// **Dual Configuration Mode:**
/// - **Simple mode**: Use boolean flags (`enableCrosshair`, `enableTooltip`, etc.)
/// - **Advanced mode**: Use sub-config objects (`crosshair`, `tooltip`, etc.)
///
/// **Usage Examples:**
///
/// 1. Enable all features with defaults:
/// ```dart
/// InteractionConfig.all()
/// ```
///
/// 2. Disable all interactions:
/// ```dart
/// InteractionConfig.none()
/// ```
///
/// 3. Simple boolean configuration:
/// ```dart
/// InteractionConfig(
///   enableZoom: true,
///   enablePan: true,
/// )
/// ```
///
/// 4. Advanced configuration with custom crosshair:
/// ```dart
/// InteractionConfig(
///   crosshair: CrosshairConfig(
///     enabled: true,
///     mode: CrosshairMode.both,
///     snapToDataPoint: true,
///     style: CrosshairStyle(lineColor: Colors.blue),
///   ),
///   tooltip: TooltipConfig.defaultConfig(),
///   enableZoom: true,
///   enablePan: true,
///   onDataPointTap: (point, position) {
///     print('Tapped: ${point.x}, ${point.y}');
///   },
/// )
/// ```
///
/// 5. Keyboard navigation with custom bindings:
/// ```dart
/// InteractionConfig(
///   keyboard: KeyboardConfig(
///     enabled: true,
///     panStep: 15.0, // pixels per arrow press
///     zoomStep: 0.2, // 20% zoom per +/-
///   ),
/// )
/// ```
///
/// **Callback Integration:**
/// All 8 callback types are supported (DataPointCallback, SelectionCallback,
/// ZoomCallback, PanCallback, CrosshairChangeCallback, TooltipChangeCallback,
/// KeyboardActionCallback, InteractionModeChangeCallback).
///
/// **Validation:**
/// - Conflicting settings are resolved (advanced configs take precedence)
/// - Null values use sensible defaults
/// - All properties validated on construction
/// Geometry used to acquire chart points.
///
/// [point] is activated by a direct marker tap. [xInterval] and [yInterval]
/// acquire marks by one data-domain dimension while spanning the complete
/// orthogonal plot dimension. [rectangle] acquires marker centers inside a
/// dragged box, while [lasso] follows a free-form polygon. Every acquisition
/// mode commits through the same durable selection contract.
enum ChartSelectionAcquisitionMode {
  point,
  xInterval,
  yInterval,
  rectangle,
  lasso,
}

/// Semantic target resolved from an acquired chart hit.
///
/// [mark] selects the source datum or source rows represented by one visual
/// mark. [category] selects every compatible datum sharing the acquired
/// semantic X/category identity. [categoryStack] selects contributors sharing
/// one category and composition stack. [wholeSeries] selects every mark owned
/// by the acquired series. [markOrWholeSeries] enables both direct-mark and
/// complete-series acquisition, but each gesture resolves to exactly one target
/// type. A mark inside [ChartSelectionConfig.dataPointHitRadius] wins; otherwise
/// the complete path may win inside
/// [ChartSelectionConfig.completeSeriesHitRadius].
///
/// Scope is independent from acquisition geometry: a tap, rectangle, or lasso
/// first acquires hits and then resolves each hit through this policy.
enum ChartSelectionScope {
  mark,
  category,
  categoryStack,
  wholeSeries,
  markOrWholeSeries,
}

extension ChartSelectionScopeCapabilities on ChartSelectionScope {
  /// Whether hover and activation target individual data marks.
  bool get includesMarks =>
      this == ChartSelectionScope.mark ||
      this == ChartSelectionScope.markOrWholeSeries;

  /// Whether hover and activation target complete series paths.
  bool get includesWholeSeries =>
      this == ChartSelectionScope.wholeSeries ||
      this == ChartSelectionScope.markOrWholeSeries;
}

/// Set operation applied when a selection gesture resolves point references.
enum ChartSelectionOperation { replace, add, subtract, toggle }

/// Pointer chord that allows a drag-selection mode to own primary-button drag.
///
/// This policy is deliberately separate from viewport pan and zoom gestures.
/// Point selection never owns drag, regardless of this value.
enum ChartSelectionDragActivation { primaryButton, shiftPrimaryButton }

/// Data-domain bounds used to initialize or programmatically position a
/// persistent interval-selection brush.
///
/// The owning [ChartSelectionConfig.acquisitionMode] determines whether these
/// values belong to the X or Y domain. For a Y interval on a multi-axis chart,
/// [referenceSeriesId] identifies the series transform used to place the
/// visual band.
@ChartSurface(
  combinedSetters: [
    CombinedSetter('withBounds', ['minimum', 'maximum']),
  ],
  clearFlags: {'referenceSeriesId': 'clearReferenceSeriesId'},
)
class ChartSelectionBrushRange {
  const ChartSelectionBrushRange({
    required this.minimum,
    required this.maximum,
    this.referenceSeriesId,
  }) : assert(minimum == minimum),
       assert(minimum > double.negativeInfinity),
       assert(minimum < double.infinity),
       assert(maximum == maximum),
       assert(maximum > double.negativeInfinity),
       assert(maximum < double.infinity),
       assert(minimum <= maximum);

  /// Inclusive lower data-domain bound.
  final double minimum;

  /// Inclusive upper data-domain bound.
  final double maximum;

  /// Optional reference series for mapping a Y interval to plot space.
  final String? referenceSeriesId;

  ChartSelectionBrushRange copyWith({
    double? minimum,
    double? maximum,
    String? referenceSeriesId,
    bool clearReferenceSeriesId = false,
  }) => ChartSelectionBrushRange(
    minimum: minimum ?? this.minimum,
    maximum: maximum ?? this.maximum,
    referenceSeriesId: clearReferenceSeriesId
        ? null
        : (referenceSeriesId ?? this.referenceSeriesId),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSelectionBrushRange &&
          other.minimum == minimum &&
          other.maximum == maximum &&
          other.referenceSeriesId == referenceSeriesId;

  @override
  int get hashCode => Object.hash(minimum, maximum, referenceSeriesId);
}

/// Two-dimensional data-domain bounds for a persistent box-selection brush.
///
/// [referenceSeriesId] selects the Y transform on multi-axis charts. X always
/// uses the chart's primary Cartesian X transform.
@ChartSurface(
  combinedSetters: [
    CombinedSetter('withBounds', [
      'minimumX',
      'maximumX',
      'minimumY',
      'maximumY',
    ]),
  ],
  clearFlags: {'referenceSeriesId': 'clearReferenceSeriesId'},
)
class ChartSelectionBrushBox {
  const ChartSelectionBrushBox({
    required this.minimumX,
    required this.maximumX,
    required this.minimumY,
    required this.maximumY,
    this.referenceSeriesId,
  }) : assert(minimumX == minimumX),
       assert(minimumX > double.negativeInfinity),
       assert(minimumX < double.infinity),
       assert(maximumX == maximumX),
       assert(maximumX > double.negativeInfinity),
       assert(maximumX < double.infinity),
       assert(minimumX <= maximumX),
       assert(minimumY == minimumY),
       assert(minimumY > double.negativeInfinity),
       assert(minimumY < double.infinity),
       assert(maximumY == maximumY),
       assert(maximumY > double.negativeInfinity),
       assert(maximumY < double.infinity),
       assert(minimumY <= maximumY);

  final double minimumX;
  final double maximumX;
  final double minimumY;
  final double maximumY;
  final String? referenceSeriesId;

  ChartSelectionBrushBox copyWith({
    double? minimumX,
    double? maximumX,
    double? minimumY,
    double? maximumY,
    String? referenceSeriesId,
    bool clearReferenceSeriesId = false,
  }) => ChartSelectionBrushBox(
    minimumX: minimumX ?? this.minimumX,
    maximumX: maximumX ?? this.maximumX,
    minimumY: minimumY ?? this.minimumY,
    maximumY: maximumY ?? this.maximumY,
    referenceSeriesId: clearReferenceSeriesId
        ? null
        : (referenceSeriesId ?? this.referenceSeriesId),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSelectionBrushBox &&
          other.minimumX == minimumX &&
          other.maximumX == maximumX &&
          other.minimumY == minimumY &&
          other.maximumY == maximumY &&
          other.referenceSeriesId == referenceSeriesId;

  @override
  int get hashCode =>
      Object.hash(minimumX, maximumX, minimumY, maximumY, referenceSeriesId);
}

/// Axes on which visual subdivision lines are drawn inside a brush.
enum ChartSelectionBrushGridDirection { none, horizontal, vertical, both }

/// Portable stroke pattern for visual subdivision lines.
enum ChartSelectionBrushGridPattern { solid, dashed, dotted }

/// Optional visual subdivisions inside a persistent selection brush.
///
/// [rows] and [columns] describe cell counts, not line counts. For example,
/// two rows and two columns create four quadrants using one horizontal and one
/// vertical interior line. Grid lines are visual only and never affect hits.
@chartSurface
class ChartSelectionBrushGridStyle {
  const ChartSelectionBrushGridStyle({
    this.direction = ChartSelectionBrushGridDirection.none,
    this.rows = 2,
    this.columns = 2,
    this.color,
    this.lineWidth = 1,
    this.pattern = ChartSelectionBrushGridPattern.solid,
  }) : assert(rows >= 1),
       assert(columns >= 1),
       assert(lineWidth >= 0);

  final ChartSelectionBrushGridDirection direction;
  final int rows;
  final int columns;
  final Color? color;
  final double lineWidth;
  final ChartSelectionBrushGridPattern pattern;

  bool get showsHorizontal =>
      direction == ChartSelectionBrushGridDirection.horizontal ||
      direction == ChartSelectionBrushGridDirection.both;

  bool get showsVertical =>
      direction == ChartSelectionBrushGridDirection.vertical ||
      direction == ChartSelectionBrushGridDirection.both;

  ChartSelectionBrushGridStyle copyWith({
    ChartSelectionBrushGridDirection? direction,
    int? rows,
    int? columns,
    Color? color,
    double? lineWidth,
    ChartSelectionBrushGridPattern? pattern,
    bool clearColor = false,
  }) => ChartSelectionBrushGridStyle(
    direction: direction ?? this.direction,
    rows: rows ?? this.rows,
    columns: columns ?? this.columns,
    color: clearColor ? null : (color ?? this.color),
    lineWidth: lineWidth ?? this.lineWidth,
    pattern: pattern ?? this.pattern,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSelectionBrushGridStyle &&
          other.direction == direction &&
          other.rows == rows &&
          other.columns == columns &&
          other.color == color &&
          other.lineWidth == lineWidth &&
          other.pattern == pattern;

  @override
  int get hashCode =>
      Object.hash(direction, rows, columns, color, lineWidth, pattern);
}

/// Visual treatment for a persistent interval-selection brush.
///
/// Null colours inherit from the chart's interaction theme. The visible
/// handles remain compact while [handleHitSize] supplies a forgiving pointer
/// target.
@ChartSurface(
  combinedSetters: [
    CombinedSetter('withHandleGeometry', ['handleSize', 'handleHitSize']),
  ],
  clearFlags: {
    'fillColor': 'clearFillColor',
    'borderColor': 'clearBorderColor',
    'handleFillColor': 'clearHandleFillColor',
    'handleBorderColor': 'clearHandleBorderColor',
    'keyboardFocusBorderColor': 'clearKeyboardFocusBorderColor',
  },
)
class ChartSelectionBrushStyle {
  const ChartSelectionBrushStyle({
    this.fillColor,
    this.fillOpacity = 0.18,
    this.borderColor,
    this.borderWidth = 1.5,
    this.borderRadius = 0,
    this.handleFillColor,
    this.handleBorderColor,
    this.keyboardFocusBorderColor,
    this.handleBorderWidth = 1.5,
    this.handleSize = 10,
    this.handleHitSize = 44,
    this.hoverOpacity = 0.24,
    this.activeOpacity = 0.30,
    this.grid = const ChartSelectionBrushGridStyle(),
  }) : assert(fillOpacity >= 0 && fillOpacity <= 1),
       assert(borderWidth >= 0),
       assert(borderRadius >= 0),
       assert(handleBorderWidth >= 0),
       assert(handleSize > 0),
       assert(handleHitSize >= handleSize),
       assert(hoverOpacity >= 0 && hoverOpacity <= 1),
       assert(activeOpacity >= 0 && activeOpacity <= 1);

  /// Optional fill colour. Defaults to the interaction selection colour.
  final Color? fillColor;

  /// Resting fill opacity.
  final double fillOpacity;

  /// Optional outline colour. Defaults to the interaction selection colour.
  final Color? borderColor;

  /// Outline width in logical pixels.
  final double borderWidth;

  /// Corner radius in logical pixels.
  final double borderRadius;

  /// Optional handle fill colour. Defaults to the selection colour.
  final Color? handleFillColor;

  /// Optional handle outline colour. Defaults to the chart background.
  final Color? handleBorderColor;

  /// Optional keyboard-focus outline colour.
  ///
  /// Defaults to [borderColor], then the interaction selection colour.
  final Color? keyboardFocusBorderColor;

  /// Handle outline width in logical pixels.
  final double handleBorderWidth;

  /// Visible handle diameter in logical pixels.
  final double handleSize;

  /// Pointer hit-target extent around each handle.
  final double handleHitSize;

  /// Fill opacity while the pointer hovers the brush.
  final double hoverOpacity;

  /// Fill opacity while the brush is being moved or resized.
  final double activeOpacity;

  /// Optional visual subdivisions drawn inside the brush.
  final ChartSelectionBrushGridStyle grid;

  ChartSelectionBrushStyle copyWith({
    Color? fillColor,
    double? fillOpacity,
    Color? borderColor,
    double? borderWidth,
    double? borderRadius,
    Color? handleFillColor,
    Color? handleBorderColor,
    Color? keyboardFocusBorderColor,
    double? handleBorderWidth,
    double? handleSize,
    double? handleHitSize,
    double? hoverOpacity,
    double? activeOpacity,
    ChartSelectionBrushGridStyle? grid,
    bool clearFillColor = false,
    bool clearBorderColor = false,
    bool clearHandleFillColor = false,
    bool clearHandleBorderColor = false,
    bool clearKeyboardFocusBorderColor = false,
  }) => ChartSelectionBrushStyle(
    fillColor: clearFillColor ? null : (fillColor ?? this.fillColor),
    fillOpacity: fillOpacity ?? this.fillOpacity,
    borderColor: clearBorderColor ? null : (borderColor ?? this.borderColor),
    borderWidth: borderWidth ?? this.borderWidth,
    borderRadius: borderRadius ?? this.borderRadius,
    handleFillColor: clearHandleFillColor
        ? null
        : (handleFillColor ?? this.handleFillColor),
    handleBorderColor: clearHandleBorderColor
        ? null
        : (handleBorderColor ?? this.handleBorderColor),
    keyboardFocusBorderColor: clearKeyboardFocusBorderColor
        ? null
        : (keyboardFocusBorderColor ?? this.keyboardFocusBorderColor),
    handleBorderWidth: handleBorderWidth ?? this.handleBorderWidth,
    handleSize: handleSize ?? this.handleSize,
    handleHitSize: handleHitSize ?? this.handleHitSize,
    hoverOpacity: hoverOpacity ?? this.hoverOpacity,
    activeOpacity: activeOpacity ?? this.activeOpacity,
    grid: grid ?? this.grid,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSelectionBrushStyle &&
          other.fillColor == fillColor &&
          other.fillOpacity == fillOpacity &&
          other.borderColor == borderColor &&
          other.borderWidth == borderWidth &&
          other.borderRadius == borderRadius &&
          other.handleFillColor == handleFillColor &&
          other.handleBorderColor == handleBorderColor &&
          other.keyboardFocusBorderColor == keyboardFocusBorderColor &&
          other.handleBorderWidth == handleBorderWidth &&
          other.handleSize == handleSize &&
          other.handleHitSize == handleHitSize &&
          other.hoverOpacity == hoverOpacity &&
          other.activeOpacity == activeOpacity &&
          other.grid == grid;

  @override
  int get hashCode => Object.hash(
    fillColor,
    fillOpacity,
    borderColor,
    borderWidth,
    borderRadius,
    handleFillColor,
    handleBorderColor,
    keyboardFocusBorderColor,
    handleBorderWidth,
    handleSize,
    handleHitSize,
    hoverOpacity,
    activeOpacity,
    grid,
  );
}

/// Opt-in persistence and initial state for an interval or box-selection brush.
@ChartSurface(
  clearFlags: {
    'initialRange': 'clearInitialRange',
    'initialBox': 'clearInitialBox',
  },
)
class ChartSelectionBrushConfig {
  const ChartSelectionBrushConfig({
    this.enabled = false,
    this.keyboardEnabled = false,
    this.initialVisible = false,
    this.initialRange,
    this.initialBox,
    this.style = const ChartSelectionBrushStyle(),
  });

  /// Whether completed X/Y interval or box selections remain interactive.
  final bool enabled;

  /// Whether keyboard focus, movement, and resizing are enabled for the brush.
  ///
  /// This is opt-in so pointer-only brushes do not show a second focus outline.
  /// The chart-level [KeyboardConfig.enabled] must also be true.
  final bool keyboardEnabled;

  /// Whether the initial geometry for the active acquisition mode is visible
  /// on the first mounted frame.
  ///
  /// Interval modes use [initialRange], while rectangle mode uses
  /// [initialBox]. If no matching geometry exists, the brush remains hidden.
  final bool initialVisible;

  /// Optional initial data-domain interval.
  final ChartSelectionBrushRange? initialRange;

  /// Optional initial two-dimensional box.
  final ChartSelectionBrushBox? initialBox;

  /// Brush appearance and handle sizing.
  final ChartSelectionBrushStyle style;

  /// Replaces the initial interval and its first-frame visibility together.
  ///
  /// This convenience method preserves the original fluent API while keeping
  /// [initialVisible] independent in the schema: rectangle configurations use
  /// [initialBox] with the same visibility flag.
  ChartSelectionBrushConfig withInitialState(
    ChartSelectionBrushRange initialRange,
    bool initialVisible,
  ) => copyWith(
    initialRange: initialRange,
    initialVisible: initialVisible,
  );

  ChartSelectionBrushConfig copyWith({
    bool? enabled,
    bool? keyboardEnabled,
    bool? initialVisible,
    ChartSelectionBrushRange? initialRange,
    ChartSelectionBrushBox? initialBox,
    ChartSelectionBrushStyle? style,
    bool clearInitialRange = false,
    bool clearInitialBox = false,
  }) => ChartSelectionBrushConfig(
    enabled: enabled ?? this.enabled,
    keyboardEnabled: keyboardEnabled ?? this.keyboardEnabled,
    initialVisible: initialVisible ?? this.initialVisible,
    initialRange: clearInitialRange
        ? null
        : (initialRange ?? this.initialRange),
    initialBox: clearInitialBox ? null : (initialBox ?? this.initialBox),
    style: style ?? this.style,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSelectionBrushConfig &&
          other.enabled == enabled &&
          other.keyboardEnabled == keyboardEnabled &&
          other.initialVisible == initialVisible &&
          other.initialRange == initialRange &&
          other.initialBox == initialBox &&
          other.style == style;

  @override
  int get hashCode => Object.hash(
    enabled,
    keyboardEnabled,
    initialVisible,
    initialRange,
    initialBox,
    style,
  );
}

/// Portable policy for chart point selection.
@chartSurface
class ChartSelectionConfig {
  const ChartSelectionConfig({
    this.acquisitionMode = ChartSelectionAcquisitionMode.point,
    this.scope = ChartSelectionScope.mark,
    this.operation = ChartSelectionOperation.replace,
    this.dragActivation = ChartSelectionDragActivation.primaryButton,
    this.clearOnBackgroundTap = true,
    this.useModifierKeys = true,
    this.dataPointHitRadius = 20,
    this.completeSeriesHitRadius = 22,
    this.dataPointHoverScale = 1.5,
    this.dataPointSelectionScale = 2.67,
    this.completeSeriesHoverStrokeScale = 1.75,
    this.completeSeriesSelectionStrokeScale = 1.5,
    this.brush = const ChartSelectionBrushConfig(),
  }) : assert(dataPointHitRadius >= 0),
       assert(completeSeriesHitRadius >= 0),
       assert(dataPointHoverScale >= 1),
       assert(dataPointHoverScale < double.infinity),
       assert(dataPointSelectionScale >= 1),
       assert(dataPointSelectionScale < double.infinity),
       assert(completeSeriesHoverStrokeScale >= 1),
       assert(completeSeriesHoverStrokeScale < double.infinity),
       assert(completeSeriesSelectionStrokeScale >= 1),
       assert(completeSeriesSelectionStrokeScale < double.infinity);

  /// Geometry used to acquire points.
  final ChartSelectionAcquisitionMode acquisitionMode;

  /// Semantic target resolved after [acquisitionMode] acquires a hit.
  final ChartSelectionScope scope;

  /// Default set operation for a completed selection gesture.
  final ChartSelectionOperation operation;

  /// Pointer chord that activates drag selection for drag-capable
  /// [acquisitionMode] values.
  final ChartSelectionDragActivation dragActivation;

  /// Whether tapping outside a data point clears ordinary durable selection.
  ///
  /// An active persistent [brush] remains authoritative until it is explicitly
  /// cleared, so background taps do not dismiss its bounds or selected data.
  final bool clearOnBackgroundTap;

  /// Whether platform modifiers temporarily override [operation].
  ///
  /// Ctrl/Command toggles, Shift adds, and Alt/Option subtracts. Alt has the
  /// highest precedence, followed by Shift and then Ctrl/Command.
  final bool useModifierKeys;

  /// Screen-space radius around a data marker used for hover and direct
  /// point acquisition.
  final double dataPointHitRadius;

  /// Screen-space radius around complete rendered series geometry used when
  /// [scope] includes complete-series selection.
  final double completeSeriesHitRadius;

  /// Scale applied to a data mark while it is hovered.
  final double dataPointHoverScale;

  /// Scale applied to the durable selection halo around a data mark.
  final double dataPointSelectionScale;

  /// Stroke-width scale applied to a hovered complete path or band series.
  final double completeSeriesHoverStrokeScale;

  /// Stroke-width scale applied to a selected complete path or band series.
  final double completeSeriesSelectionStrokeScale;

  /// Optional persistent interval-selection brush.
  final ChartSelectionBrushConfig brush;

  /// Whether this selection policy owns the current primary-button drag.
  ///
  /// Direct point selection is tap-only. Interval, rectangle, and lasso
  /// policies can reserve either every primary drag or only Shift+primary
  /// drag.
  bool ownsPrimaryDrag({bool shift = false}) {
    if (acquisitionMode == ChartSelectionAcquisitionMode.point) return false;
    return switch (dragActivation) {
      ChartSelectionDragActivation.primaryButton => true,
      ChartSelectionDragActivation.shiftPrimaryButton => shift,
    };
  }

  /// Resolves the operation for the current platform modifier state.
  ChartSelectionOperation resolveOperation({
    bool controlOrMeta = false,
    bool shift = false,
    bool alt = false,
  }) {
    if (!useModifierKeys) return operation;
    if (alt) return ChartSelectionOperation.subtract;
    if (shift) return ChartSelectionOperation.add;
    if (controlOrMeta) return ChartSelectionOperation.toggle;
    return operation;
  }

  ChartSelectionConfig copyWith({
    ChartSelectionAcquisitionMode? acquisitionMode,
    ChartSelectionScope? scope,
    ChartSelectionOperation? operation,
    ChartSelectionDragActivation? dragActivation,
    bool? clearOnBackgroundTap,
    bool? useModifierKeys,
    double? dataPointHitRadius,
    double? completeSeriesHitRadius,
    double? dataPointHoverScale,
    double? dataPointSelectionScale,
    double? completeSeriesHoverStrokeScale,
    double? completeSeriesSelectionStrokeScale,
    ChartSelectionBrushConfig? brush,
  }) => ChartSelectionConfig(
    acquisitionMode: acquisitionMode ?? this.acquisitionMode,
    scope: scope ?? this.scope,
    operation: operation ?? this.operation,
    dragActivation: dragActivation ?? this.dragActivation,
    clearOnBackgroundTap: clearOnBackgroundTap ?? this.clearOnBackgroundTap,
    useModifierKeys: useModifierKeys ?? this.useModifierKeys,
    dataPointHitRadius: dataPointHitRadius ?? this.dataPointHitRadius,
    completeSeriesHitRadius:
        completeSeriesHitRadius ?? this.completeSeriesHitRadius,
    dataPointHoverScale: dataPointHoverScale ?? this.dataPointHoverScale,
    dataPointSelectionScale:
        dataPointSelectionScale ?? this.dataPointSelectionScale,
    completeSeriesHoverStrokeScale:
        completeSeriesHoverStrokeScale ?? this.completeSeriesHoverStrokeScale,
    completeSeriesSelectionStrokeScale:
        completeSeriesSelectionStrokeScale ??
        this.completeSeriesSelectionStrokeScale,
    brush: brush ?? this.brush,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartSelectionConfig &&
          other.acquisitionMode == acquisitionMode &&
          other.scope == scope &&
          other.operation == operation &&
          other.dragActivation == dragActivation &&
          other.clearOnBackgroundTap == clearOnBackgroundTap &&
          other.useModifierKeys == useModifierKeys &&
          other.dataPointHitRadius == dataPointHitRadius &&
          other.completeSeriesHitRadius == completeSeriesHitRadius &&
          other.dataPointHoverScale == dataPointHoverScale &&
          other.dataPointSelectionScale == dataPointSelectionScale &&
          other.completeSeriesHoverStrokeScale ==
              completeSeriesHoverStrokeScale &&
          other.completeSeriesSelectionStrokeScale ==
              completeSeriesSelectionStrokeScale &&
          other.brush == brush;

  @override
  int get hashCode => Object.hash(
    acquisitionMode,
    scope,
    operation,
    dragActivation,
    clearOnBackgroundTap,
    useModifierKeys,
    dataPointHitRadius,
    completeSeriesHitRadius,
    dataPointHoverScale,
    dataPointSelectionScale,
    completeSeriesHoverStrokeScale,
    completeSeriesSelectionStrokeScale,
    brush,
  );
}

@chartSurface
class InteractionConfig {
  /// Creates an interaction configuration.
  ///
  /// All parameters are optional and default to sensible values.
  /// Use [InteractionConfig.all] for all features enabled,
  /// or [InteractionConfig.none] for all features disabled.
  const InteractionConfig({
    this.enabled = true,
    this.crosshair = const CrosshairConfig(),
    this.tooltip = const TooltipConfig(),
    this.gesture = const GestureConfig(),
    this.touch = const TouchInteractionConfig(),
    this.keyboard = const KeyboardConfig(),
    this.enableZoom = true,
    this.enablePan = true,
    this.enableSelection = true,
    this.selection = const ChartSelectionConfig(),
    this.valueSummary = const CartesianValueSummaryConfig(),
    this.showFocusBorder = false,
    this.enableFocusOnHover = true,
    this.showXScrollbar = false,
    this.showYScrollbar = false,
    this.keyboardZoomPercent = 25,
    // Callback functions for user interaction events (FR-007)
    this.onDataPointTap,
    this.onDataPointHover,
    this.onDataPointLongPress,
    this.onSelectionChanged,
    this.onSelectionResultChanged,
    this.onZoomChanged,
    this.onPanChanged,
    this.onViewportChanged,
    this.onCrosshairChanged,
    this.onTooltipChanged,
    this.onKeyboardAction,
  }) : assert(
         keyboardZoomPercent > 0 && keyboardZoomPercent <= 100,
         'keyboardZoomPercent must be between 1 and 100',
       );

  /// Creates a configuration with all interaction features enabled.
  ///
  /// This factory enables:
  /// - Crosshair with default settings
  /// - Tooltip on hover/tap
  /// - Zoom and pan
  /// - All gesture recognition
  /// - Keyboard navigation
  ///
  /// Example:
  /// ```dart
  /// BravenChart(
  ///   interactionConfig: InteractionConfig.all(),
  ///   // ... other properties
  /// )
  /// ```
  factory InteractionConfig.all() => const InteractionConfig(
    enabled: true,
    crosshair: CrosshairConfig(enabled: true),
    tooltip: TooltipConfig(enabled: true),
    gesture: GestureConfig(),
    touch: TouchInteractionConfig(),
    keyboard: KeyboardConfig(enabled: true),
    enableZoom: true,
    enablePan: true,
    enableSelection: true,
    showFocusBorder: false,
    enableFocusOnHover: true,
    showXScrollbar: true,
    showYScrollbar: true,
    keyboardZoomPercent: 25,
  );

  /// Creates a focused tap interaction profile without navigation gestures.
  ///
  /// This profile is useful for compact dashboards and touch-first charts:
  /// crosshair tracking, zoom, pan, scrollbars, keyboard navigation, and hover
  /// focus are disabled. Callers independently choose whether tapping shows a
  /// data-point tooltip, creates a durable selection, or does both.
  ///
  /// Use [InteractionConfig.none] when the chart must be completely static.
  factory InteractionConfig.tap({
    bool enableTooltip = true,
    bool enableSelection = true,
    ChartSelectionConfig selection = const ChartSelectionConfig(),
  }) => InteractionConfig(
    enabled: true,
    crosshair: const CrosshairConfig(enabled: false),
    tooltip: TooltipConfig(
      enabled: enableTooltip,
      triggerMode: TooltipTriggerMode.tap,
    ),
    keyboard: const KeyboardConfig(enabled: false),
    enableZoom: false,
    enablePan: false,
    enableSelection: enableSelection,
    selection: selection,
    valueSummary: const CartesianValueSummaryConfig(enabled: false),
    showFocusBorder: false,
    enableFocusOnHover: false,
    showXScrollbar: false,
    showYScrollbar: false,
  );

  /// Creates a configuration with all interaction features disabled.
  ///
  /// This factory disables all interactions, useful for static/non-interactive
  /// charts or when you want to build up a configuration from scratch.
  ///
  /// Example:
  /// ```dart
  /// BravenChart(
  ///   interactionConfig: InteractionConfig.none(),
  ///   // Chart is completely static
  /// )
  /// ```
  factory InteractionConfig.none() => const InteractionConfig(
    enabled: false,
    crosshair: CrosshairConfig(enabled: false),
    tooltip: TooltipConfig(enabled: false),
    gesture: GestureConfig(),
    touch: TouchInteractionConfig(enabled: false),
    keyboard: KeyboardConfig(enabled: false),
    enableZoom: false,
    enablePan: false,
    enableSelection: false,
    valueSummary: CartesianValueSummaryConfig(enabled: false),
    showFocusBorder: false,
    enableFocusOnHover: false,
    showXScrollbar: false,
    showYScrollbar: false,
    keyboardZoomPercent: 25,
  );

  /// Creates a default configuration (same as unnamed constructor).
  ///
  /// This is an alias for backward compatibility and clarity.
  factory InteractionConfig.defaultConfig() => const InteractionConfig();

  /// Whether the entire interaction system is enabled.
  ///
  /// When false, all interactions are disabled regardless of individual settings.
  final bool enabled;

  /// Crosshair configuration (lines following cursor, snapping to data points).
  final CrosshairConfig crosshair;

  /// Tooltip configuration (hover/tap data point information).
  final TooltipConfig tooltip;

  /// Gesture recognition configuration (tap, pan, pinch timeouts and thresholds).
  final GestureConfig gesture;

  /// Direct-touch viewport gesture policy.
  final TouchInteractionConfig touch;

  /// Keyboard navigation configuration (arrow keys, zoom keys, shortcuts).
  final KeyboardConfig keyboard;

  /// Whether zoom gestures are enabled (mouse wheel, pinch-to-zoom).
  final bool enableZoom;

  /// Whether pan gestures are enabled (drag to move viewport).
  final bool enablePan;

  /// Whether data point selection is enabled.
  final bool enableSelection;

  /// Point acquisition and set-operation policy.
  final ChartSelectionConfig selection;

  /// Cartesian value summary configuration (persistent policy-resolved
  /// datum panel).
  ///
  /// Defaults to a disabled summary; enabling it never implicitly enables
  /// the crosshair, tooltip, or axis value labels.
  final CartesianValueSummaryConfig valueSummary;

  /// Whether to show focus border when chart has keyboard focus.
  final bool showFocusBorder;

  /// Whether the chart acquires keyboard focus when the mouse enters.
  ///
  /// When true (default), the chart calls `requestFocus()` on mouse enter
  /// and `unfocus()` on mouse exit. This enables keyboard shortcuts (zoom,
  /// pan, etc.) without requiring the user to click the chart first.
  ///
  /// Set to false on pages with many charts (e.g., gallery with 21+ charts)
  /// to prevent focus thrashing that causes cascading widget rebuilds and
  /// input lag. When false, the user must click the chart to give it focus.
  final bool enableFocusOnHover;

  /// Whether to show the X-axis scrollbar for horizontal scrolling.
  final bool showXScrollbar;

  /// Whether to show the Y-axis scrollbar for vertical scrolling.
  final bool showYScrollbar;

  /// The zoom percentage applied per keyboard zoom keypress (+/- keys).
  ///
  /// For zoom in, the viewport scale is multiplied by `1 + (keyboardZoomPercent / 100)`.
  /// For zoom out, the viewport scale is multiplied by `1 - (keyboardZoomPercent / 100)`.
  ///
  /// Must be between 1 and 100. Default is 10 (10% zoom per keypress).
  /// A value of 20 would be 20% zoom per keypress.
  ///
  /// Example:
  /// ```dart
  /// InteractionConfig(
  ///   keyboardZoomPercent: 20,  // 20% zoom per keypress
  /// )
  /// ```
  final int keyboardZoomPercent;

  // Callback functions for user interaction events (FR-007)

  /// Called when a user taps/clicks on a data point.
  ///
  /// Receives the data point and screen position of the tap.
  ///
  /// Example:
  /// ```dart
  /// onDataPointTap: (point, position) {
  ///   print('Tapped point: X=${point.x}, Y=${point.y}');
  ///   showDialog(context: context, builder: (_) => ...);
  /// }
  /// ```
  final DataPointCallback? onDataPointTap;

  /// Called when the cursor hovers over a data point.
  ///
  /// Receives the data point (or null when hover exits) and screen position.
  ///
  /// Example:
  /// ```dart
  /// onDataPointHover: (point, position) {
  ///   if (point != null) {
  ///     setState(() => hoveredPoint = point);
  ///   }
  /// }
  /// ```
  final DataPointHoverCallback? onDataPointHover;

  /// Called when a user performs a long-press gesture on a data point.
  ///
  /// Useful for showing context menus or detailed information.
  ///
  /// Example:
  /// ```dart
  /// onDataPointLongPress: (point, position) {
  ///   showMenu(context: context, position: position, items: [...]);
  /// }
  /// ```
  final DataPointLongPressCallback? onDataPointLongPress;

  /// Called when the selected data points change.
  ///
  /// Receives the currently selected points after direct chart interaction or
  /// a controller point-selection command.
  ///
  /// Example:
  /// ```dart
  /// onSelectionChanged: (selectedPoints) {
  ///   print('Selected ${selectedPoints.length} points');
  /// }
  /// ```
  final SelectionCallback? onSelectionChanged;

  /// Called with stable references, data extents, and aggregate statistics.
  ///
  /// This complements [onSelectionChanged], which remains available for
  /// consumers that only need the raw selected data points.
  final SelectionResultCallback? onSelectionResultChanged;

  /// Called when the zoom level changes.
  ///
  /// Receives separate X and Y zoom levels (1.0 = 100%).
  ///
  /// Example:
  /// ```dart
  /// onZoomChanged: (zoomX, zoomY) {
  ///   print('Zoom: ${(zoomX * 100).toInt()}%');
  /// }
  /// ```
  final ZoomCallback? onZoomChanged;

  /// Called when the pan offset changes.
  ///
  /// Receives the pan offset as an Offset (dx, dy).
  ///
  /// Example:
  /// ```dart
  /// onPanChanged: (offset) {
  ///   print('Panned: dx=${offset.dx}, dy=${offset.dy}');
  /// }
  /// ```
  final PanCallback? onPanChanged;

  /// Called when the visible data range changes (due to zoom/pan).
  ///
  /// Receives the new visible data bounds as a Rect.
  ///
  /// Example:
  /// ```dart
  /// onViewportChanged: (dataBounds) {
  ///   print('Visible: X=${dataBounds.left} to ${dataBounds.right}');
  /// }
  /// ```
  final ViewportCallback? onViewportChanged;

  /// Called when the crosshair position changes.
  ///
  /// Receives the crosshair position and snap points.
  ///
  /// Example:
  /// ```dart
  /// onCrosshairChanged: (position, snapPoints) {
  ///   if (snapPoints.isNotEmpty) {
  ///     print('Snapped to: ${snapPoints.first}');
  ///   }
  /// }
  /// ```
  final CrosshairChangeCallback? onCrosshairChanged;

  /// Called when a tooltip is shown or hidden.
  ///
  /// Receives visibility state and tooltip data.
  ///
  /// Example:
  /// ```dart
  /// onTooltipChanged: (visible, data) {
  ///   if (visible) {
  ///     print('Tooltip shown for: ${data['x']}, ${data['y']}');
  ///   }
  /// }
  /// ```
  final TooltipChangeCallback? onTooltipChanged;

  /// Called when a keyboard action is performed.
  ///
  /// Receives action type and optional target point.
  ///
  /// Example:
  /// ```dart
  /// onKeyboardAction: (action, targetPoint) {
  ///   print('Keyboard: $action');
  ///   if (targetPoint != null) {
  ///     print('Target: ${targetPoint.x}, ${targetPoint.y}');
  ///   }
  /// }
  /// ```
  final KeyboardActionCallback? onKeyboardAction;

  /// Creates a copy with some properties replaced.
  ///
  /// This method supports immutable updates - all fields are optional,
  /// and unspecified fields retain their current values.
  ///
  /// Example:
  /// ```dart
  /// final newConfig = oldConfig.copyWith(
  ///   enableZoom: false,
  ///   crosshair: CrosshairConfig(lineColor: Colors.red),
  /// );
  /// ```
  InteractionConfig copyWith({
    bool? enabled,
    CrosshairConfig? crosshair,
    TooltipConfig? tooltip,
    GestureConfig? gesture,
    TouchInteractionConfig? touch,
    KeyboardConfig? keyboard,
    bool? enableZoom,
    bool? enablePan,
    bool? enableSelection,
    ChartSelectionConfig? selection,
    CartesianValueSummaryConfig? valueSummary,
    bool? showFocusBorder,
    bool? enableFocusOnHover,
    bool? showXScrollbar,
    bool? showYScrollbar,
    int? keyboardZoomPercent,
    DataPointCallback? onDataPointTap,
    DataPointHoverCallback? onDataPointHover,
    DataPointLongPressCallback? onDataPointLongPress,
    SelectionCallback? onSelectionChanged,
    SelectionResultCallback? onSelectionResultChanged,
    ZoomCallback? onZoomChanged,
    PanCallback? onPanChanged,
    ViewportCallback? onViewportChanged,
    CrosshairChangeCallback? onCrosshairChanged,
    TooltipChangeCallback? onTooltipChanged,
    KeyboardActionCallback? onKeyboardAction,
  }) {
    return InteractionConfig(
      enabled: enabled ?? this.enabled,
      crosshair: crosshair ?? this.crosshair,
      tooltip: tooltip ?? this.tooltip,
      gesture: gesture ?? this.gesture,
      touch: touch ?? this.touch,
      keyboard: keyboard ?? this.keyboard,
      enableZoom: enableZoom ?? this.enableZoom,
      enablePan: enablePan ?? this.enablePan,
      enableSelection: enableSelection ?? this.enableSelection,
      selection: selection ?? this.selection,
      valueSummary: valueSummary ?? this.valueSummary,
      showFocusBorder: showFocusBorder ?? this.showFocusBorder,
      enableFocusOnHover: enableFocusOnHover ?? this.enableFocusOnHover,
      showXScrollbar: showXScrollbar ?? this.showXScrollbar,
      showYScrollbar: showYScrollbar ?? this.showYScrollbar,
      keyboardZoomPercent: keyboardZoomPercent ?? this.keyboardZoomPercent,
      onDataPointTap: onDataPointTap ?? this.onDataPointTap,
      onDataPointHover: onDataPointHover ?? this.onDataPointHover,
      onDataPointLongPress: onDataPointLongPress ?? this.onDataPointLongPress,
      onSelectionChanged: onSelectionChanged ?? this.onSelectionChanged,
      onSelectionResultChanged:
          onSelectionResultChanged ?? this.onSelectionResultChanged,
      onZoomChanged: onZoomChanged ?? this.onZoomChanged,
      onPanChanged: onPanChanged ?? this.onPanChanged,
      onViewportChanged: onViewportChanged ?? this.onViewportChanged,
      onCrosshairChanged: onCrosshairChanged ?? this.onCrosshairChanged,
      onTooltipChanged: onTooltipChanged ?? this.onTooltipChanged,
      onKeyboardAction: onKeyboardAction ?? this.onKeyboardAction,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InteractionConfig &&
        other.enabled == enabled &&
        other.crosshair == crosshair &&
        other.tooltip == tooltip &&
        other.gesture == gesture &&
        other.touch == touch &&
        other.keyboard == keyboard &&
        other.enableZoom == enableZoom &&
        other.enablePan == enablePan &&
        other.enableSelection == enableSelection &&
        other.selection == selection &&
        other.valueSummary == valueSummary &&
        other.showFocusBorder == showFocusBorder &&
        other.enableFocusOnHover == enableFocusOnHover &&
        other.showXScrollbar == showXScrollbar &&
        other.showYScrollbar == showYScrollbar &&
        other.keyboardZoomPercent == keyboardZoomPercent;
  }

  @override
  int get hashCode => Object.hash(
    enabled,
    crosshair,
    tooltip,
    gesture,
    touch,
    keyboard,
    enableZoom,
    enablePan,
    enableSelection,
    selection,
    valueSummary,
    showFocusBorder,
    enableFocusOnHover,
    showXScrollbar,
    showYScrollbar,
    keyboardZoomPercent,
  );
}
