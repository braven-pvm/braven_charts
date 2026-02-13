/// Interaction configuration wrapper model.
///
/// This library provides configuration models for chart interaction features,
/// including crosshair, tooltip, zoom/pan, gestures, and keyboard navigation.
library;

import 'dart:ui' show Color, StrokeCap;

import 'package:flutter/widgets.dart' show TextStyle, Widget, BuildContext;

import 'interaction_callbacks.dart';

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
    required this.isInterpolated,
    this.linkedSeriesId,
    this.isTrend = false,
  });

  final String seriesId;
  final String seriesName;
  final Color seriesColor;
  final double x;
  final double y;
  final int dataPointIndex;
  final bool isInterpolated;

  /// For trend annotations, the ID of the data series this trend is linked to.
  /// Used for axis resolution so the trend dot aligns with the correct Y axis.
  final String? linkedSeriesId;

  /// Whether this value represents a trend annotation rather than a data series.
  final bool isTrend;

  /// Returns the series ID to use for axis resolution (linked series for trends).
  String get axisSeriesId => linkedSeriesId ?? seriesId;
}

/// Complete tracking state for crosshair rendering.
class CrosshairTrackingState {
  const CrosshairTrackingState({required this.dataX, required this.screenX, required this.seriesValues});

  final double dataX;
  final double screenX;
  final List<CrosshairSeriesValue> seriesValues;
}

/// Style configuration for crosshair lines.
class CrosshairStyle {
  /// Creates a crosshair style with the specified properties.
  const CrosshairStyle({
    this.lineColor = const Color(0xFF666666),
    this.lineWidth = 1.0,
    this.dashPattern = const [5, 3], // Default dashed pattern per spec
    this.strokeCap = StrokeCap.round,
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
  /// Creates a CrosshairConfig optimized for tracking mode.
  factory CrosshairConfig.tracking({bool interpolate = true, bool showTooltip = true, bool showMarkers = true, double markerRadius = 4.0}) {
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
  }) : assert(snapRadius >= 0, 'snapRadius must be non-negative'),
       assert(trackingModeThreshold > 0, 'trackingModeThreshold must be positive'),
       assert(intersectionMarkerRadius > 0, 'intersectionMarkerRadius must be positive');

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
  }) {
    return CrosshairConfig(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      snapToDataPoint: snapToDataPoint ?? this.snapToDataPoint,
      snapRadius: snapRadius ?? this.snapRadius,
      showCoordinateLabels: showCoordinateLabels ?? this.showCoordinateLabels,
      coordinateLabelStyle: coordinateLabelStyle ?? this.coordinateLabelStyle,
      style: style ?? this.style,
      displayMode: displayMode ?? this.displayMode,
      trackingModeThreshold: trackingModeThreshold ?? this.trackingModeThreshold,
      interpolateValues: interpolateValues ?? this.interpolateValues,
      showTrackingTooltip: showTrackingTooltip ?? this.showTrackingTooltip,
      showIntersectionMarkers: showIntersectionMarkers ?? this.showIntersectionMarkers,
      intersectionMarkerRadius: intersectionMarkerRadius ?? this.intersectionMarkerRadius,
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
        other.intersectionMarkerRadius == intersectionMarkerRadius;
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
    return Object.hash(backgroundColor, borderColor, borderWidth, borderRadius, shadowColor, shadowBlurRadius, padding, textColor, fontSize);
  }
}

/// Signature for a custom tooltip builder function.
///
/// Takes a [BuildContext] and a [dataPoint] map containing the data
/// to display, and returns a [Widget] representing the custom tooltip.
typedef TooltipBuilder = Widget Function(BuildContext context, Map<String, dynamic> dataPoint);

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
    return Object.hash(enabled, triggerMode, preferredPosition, showDelay, hideDelay, followCursor, offsetFromPoint, style, customBuilder);
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
  GestureConfig copyWith({Duration? tapTimeout, Duration? longPressTimeout, double? panThreshold, double? pinchThreshold}) {
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
  int get hashCode => Object.hash(tapTimeout, longPressTimeout, panThreshold, pinchThreshold);
}

// ==============================================================================
// Keyboard Configuration
// ==============================================================================

/// Configuration for keyboard navigation.
///
/// Controls keyboard-based chart interaction including arrow key panning,
/// plus/minus zoom, and home/end navigation.
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
  int get hashCode => Object.hash(enabled, panStep, zoomStep, enableArrowKeys, enablePlusMinusKeys, enableHomeEndKeys);
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
    this.keyboard = const KeyboardConfig(),
    this.enableZoom = true,
    this.enablePan = true,
    this.enableSelection = true,
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
    this.onZoomChanged,
    this.onPanChanged,
    this.onViewportChanged,
    this.onCrosshairChanged,
    this.onTooltipChanged,
    this.onKeyboardAction,
  }) : assert(keyboardZoomPercent > 0 && keyboardZoomPercent <= 100, 'keyboardZoomPercent must be between 1 and 100');

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
    keyboard: KeyboardConfig(enabled: true),
    enableZoom: true,
    enablePan: true,
    enableSelection: true,
    showFocusBorder: true,
    enableFocusOnHover: true,
    showXScrollbar: true,
    showYScrollbar: true,
    keyboardZoomPercent: 25,
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
    keyboard: KeyboardConfig(enabled: false),
    enableZoom: false,
    enablePan: false,
    enableSelection: false,
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

  /// Keyboard navigation configuration (arrow keys, zoom keys, shortcuts).
  final KeyboardConfig keyboard;

  /// Whether zoom gestures are enabled (mouse wheel, pinch-to-zoom).
  final bool enableZoom;

  /// Whether pan gestures are enabled (drag to move viewport).
  final bool enablePan;

  /// Whether data point selection is enabled.
  final bool enableSelection;

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
  /// Receives list of currently selected points.
  ///
  /// Example:
  /// ```dart
  /// onSelectionChanged: (selectedPoints) {
  ///   print('Selected ${selectedPoints.length} points');
  /// }
  /// ```
  final SelectionCallback? onSelectionChanged;

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
    KeyboardConfig? keyboard,
    bool? enableZoom,
    bool? enablePan,
    bool? enableSelection,
    bool? showFocusBorder,
    bool? enableFocusOnHover,
    bool? showXScrollbar,
    bool? showYScrollbar,
    int? keyboardZoomPercent,
    DataPointCallback? onDataPointTap,
    DataPointHoverCallback? onDataPointHover,
    DataPointLongPressCallback? onDataPointLongPress,
    SelectionCallback? onSelectionChanged,
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
      keyboard: keyboard ?? this.keyboard,
      enableZoom: enableZoom ?? this.enableZoom,
      enablePan: enablePan ?? this.enablePan,
      enableSelection: enableSelection ?? this.enableSelection,
      showFocusBorder: showFocusBorder ?? this.showFocusBorder,
      enableFocusOnHover: enableFocusOnHover ?? this.enableFocusOnHover,
      showXScrollbar: showXScrollbar ?? this.showXScrollbar,
      showYScrollbar: showYScrollbar ?? this.showYScrollbar,
      keyboardZoomPercent: keyboardZoomPercent ?? this.keyboardZoomPercent,
      onDataPointTap: onDataPointTap ?? this.onDataPointTap,
      onDataPointHover: onDataPointHover ?? this.onDataPointHover,
      onDataPointLongPress: onDataPointLongPress ?? this.onDataPointLongPress,
      onSelectionChanged: onSelectionChanged ?? this.onSelectionChanged,
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
        other.keyboard == keyboard &&
        other.enableZoom == enableZoom &&
        other.enablePan == enablePan &&
        other.enableSelection == enableSelection &&
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
    keyboard,
    enableZoom,
    enablePan,
    enableSelection,
    showFocusBorder,
    enableFocusOnHover,
    showXScrollbar,
    showYScrollbar,
    keyboardZoomPercent,
  );
}
