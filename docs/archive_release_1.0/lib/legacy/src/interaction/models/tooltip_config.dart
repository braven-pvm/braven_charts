/// Tooltip configuration model for chart interactions.
///
/// Defines the appearance, behavior, and positioning of tooltips that
/// display data point information on the chart.
///
/// This model is immutable and uses copyWith for updates.
library;

import 'package:flutter/material.dart';

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
    this.shadowColor = Colors.transparent,
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
/// Takes a [BuildContext] and a [dataPoint] map containing the data
/// to display, and returns a [Widget] representing the custom tooltip.
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
class TooltipConfig {
  /// Creates a tooltip configuration with the specified properties.
  const TooltipConfig({
    this.enabled = true,
    this.triggerMode = TooltipTriggerMode.hover,
    this.preferredPosition = TooltipPosition.auto,
    this.showDelay = const Duration(milliseconds: 100),
    this.hideDelay = const Duration(milliseconds: 200),
    this.followCursor = false,
    this.offsetFromPoint = 2.0,
    this.style = const TooltipStyle(),
    this.customBuilder,
  });

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
