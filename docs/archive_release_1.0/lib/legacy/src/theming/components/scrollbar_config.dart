import 'package:flutter/material.dart';

/// Configuration for a single scrollbar (X or Y axis).
///
/// Immutable data class with copyWith() for customization.
/// Used by ScrollbarTheme to style both horizontal and vertical scrollbars.
@immutable
class ScrollbarConfig {
  /// Deserialize from JSON.
  factory ScrollbarConfig.fromJson(Map<String, dynamic> json) =>
      ScrollbarConfig(
        thickness: json['thickness'] as double,
        minHandleSize: json['minHandleSize'] as double,
        trackColor: Color(json['trackColor'] as int),
        handleColor: Color(json['handleColor'] as int),
        handleHoverColor: Color(json['handleHoverColor'] as int),
        edgeHoverColor: json['edgeHoverColor'] != null
            ? Color(json['edgeHoverColor'] as int)
            : const Color(0xFF2196F3),
        handleActiveColor: Color(json['handleActiveColor'] as int),
        handleDisabledColor: json['handleDisabledColor'] != null
            ? Color(json['handleDisabledColor'] as int)
            : const Color(0xFFEEEEEE),
        trackHoverColor: json['trackHoverColor'] != null
            ? Color(json['trackHoverColor'] as int)
            : const Color(0xFFE0E0E0),
        borderRadius: json['borderRadius'] as double,
        edgeGripWidth: json['edgeGripWidth'] as double,
        showGripIndicator: json['showGripIndicator'] as bool,
        gripIndicatorColor: Color(json['gripIndicatorColor'] as int),
        autoHide: json['autoHide'] as bool,
        autoHideDelay: Duration(milliseconds: json['autoHideDelayMs'] as int),
        fadeDuration: Duration(milliseconds: json['fadeDurationMs'] as int),
        enableResizeHandles: json['enableResizeHandles'] as bool,
        minZoomRatio: json['minZoomRatio'] as double,
        maxZoomRatio: json['maxZoomRatio'] as double,
        padding: json['padding'] as double? ?? 4.0,
        forcedColorsMode: json['forcedColorsMode'] as bool? ?? false,
        prefersReducedMotion: json['prefersReducedMotion'] as bool? ?? false,
      );
  const ScrollbarConfig({
    this.thickness = 10.0,
    this.minHandleSize = 20.0,
    this.trackColor = const Color(0xFFF5F5F5),
    this.handleColor = const Color(0xFFBDBDBD),
    this.handleHoverColor = const Color(0xFF9E9E9E),
    this.edgeHoverColor = const Color(0xFF2196F3),
    this.handleActiveColor = const Color(0xFF757575),
    this.handleDisabledColor = const Color(0xFFEEEEEE),
    this.borderRadius = 4.0,
    this.edgeGripWidth = 8.0,
    this.showGripIndicator = true,
    this.gripIndicatorColor = const Color(0xFF757575),
    this.autoHide = true,
    this.autoHideDelay = const Duration(seconds: 2),
    this.fadeDuration = const Duration(milliseconds: 200),
    this.enableResizeHandles = true, // Enabled for US3 edge zoom testing
    this.minZoomRatio = 0.01,
    this.maxZoomRatio = 1.0,
    this.padding = 4.0,
    this.trackHoverColor = const Color(0xFFE0E0E0),
    this.forcedColorsMode = false,
    this.prefersReducedMotion = false,
  });

  // === Visual Properties ===

  /// Width (for vertical) or height (for horizontal) of the scrollbar track.
  ///
  /// Default: 10.0 (compact for minimal visual footprint)
  final double thickness;

  /// Minimum size of the handle (prevents tiny handles when zoomed way out).
  ///
  /// Default: 20.0 (ensures handle remains grabbable)
  /// MUST be >= edgeGripWidth * 2 to fit both edge zones.
  final double minHandleSize;

  /// Background color of the scrollbar track.
  ///
  /// Should have 3:1 contrast ratio with chart background (WCAG 2.1 SC 1.4.11).
  /// Default: Light grey (#F5F5F5)
  final Color trackColor;

  /// Default color of the scrollbar handle (no interaction).
  ///
  /// Should have 4.5:1 contrast ratio with trackColor (WCAG 2.1 SC 1.4.3).
  /// Default: Medium grey (#BDBDBD)
  final Color handleColor;

  /// Handle color when mouse is hovering over it.
  ///
  /// Should have 3:1 contrast ratio with handleColor (WCAG 2.1 SC 1.4.11).
  /// Default: Darker grey (#9E9E9E)
  final Color handleHoverColor;

  /// Edge zone color when mouse is hovering over edge zones (for zoom affordance).
  ///
  /// Provides visual distinction between center pan (grey hover) and edge zoom (blue hover).
  /// Should have 4.5:1 contrast ratio with handleColor (WCAG 2.1 SC 1.4.3).
  /// Default: Material Blue 500 (#2196F3)
  final Color edgeHoverColor;

  /// Handle color when user is dragging it.
  ///
  /// Should have 3:1 contrast ratio with handleColor (WCAG 2.1 SC 1.4.11).
  /// Default: Dark grey (#757575)
  final Color handleActiveColor;

  /// Handle color when interaction is disabled (enablePan=false, enableZoom=false).
  ///
  /// Default: Very light grey (#EEEEEE)
  final Color handleDisabledColor;

  /// Track color when mouse is hovering over it (for click-to-jump affordance).
  ///
  /// Default: Slightly darker grey (#E0E0E0)
  final Color trackHoverColor;

  /// Corner radius for handle (rounded rectangle).
  ///
  /// Default: 4.0 (matches Material Design)
  final double borderRadius;

  /// Visual indicator lines on handle (3 parallel lines in center).
  ///
  /// Provides visual affordance for draggability.
  final bool showGripIndicator;

  /// Color of grip indicator lines.
  ///
  /// Default: Dark grey (#757575)
  final Color gripIndicatorColor;

  /// Padding between scrollbar and chart canvas edges.
  ///
  /// Default: 4.0 pixels
  final double padding;

  // === Interaction Properties ===

  /// Width of edge interaction zones (for resize handles).
  ///
  /// First/last edgeGripWidth pixels of handle trigger resize mode.
  /// Default: 8.0 (large enough for mouse, <20% of minHandleSize).
  final double edgeGripWidth;

  /// Whether to enable edge resize handles (if false, only center pan works).
  ///
  /// Disable for simplified scrollbar (pan-only, no zoom).
  final bool enableResizeHandles;

  /// Minimum zoom ratio (viewportRange / dataRange).
  ///
  /// Default: 0.01 (1% minimum - prevents zooming in so far you see <1% of data).
  final double minZoomRatio;

  /// Maximum zoom ratio (viewportRange / dataRange).
  ///
  /// Default: 1.0 (100% maximum - prevents zooming out past full data range).
  final double maxZoomRatio;

  // === Auto-Hide Properties ===

  /// Whether scrollbar auto-hides after period of inactivity.
  ///
  /// Default: true (common pattern in modern UIs).
  final bool autoHide;

  /// Delay before auto-hiding scrollbar (if autoHide is true).
  ///
  /// Timer resets on any pointer or keyboard interaction.
  /// Default: 2 seconds
  final Duration autoHideDelay;

  /// Duration of fade-in/fade-out animation when auto-hiding.
  ///
  /// Default: 200 milliseconds
  final Duration fadeDuration;

  // === Accessibility Properties (FR-024A, FR-024B, FR-024C) ===

  /// Whether to use forced colors mode (Windows High Contrast).
  ///
  /// When true, uses system colors with borders instead of custom theme colors.
  /// Default: false (detect automatically via MediaQuery in widget)
  final bool forcedColorsMode;

  /// Whether to honor prefers-reduced-motion setting.
  ///
  /// When true, disables all animations (WCAG 2.3.3 compliance).
  /// Default: false (detect automatically via MediaQuery in widget)
  final bool prefersReducedMotion;

  // === Factory Constructors ===

  /// Light theme preset (light background, dark handle).
  static const ScrollbarConfig defaultLight = ScrollbarConfig(
    trackColor: Color(0xFFF5F5F5), // Light grey
    handleColor: Color(0xFFBDBDBD), // Medium grey
    handleHoverColor: Color(0xFF9E9E9E), // Darker grey
    edgeHoverColor: Color(0xFF2196F3), // Material Blue 500
    handleActiveColor: Color(0xFF757575), // Dark grey
    handleDisabledColor: Color(0xFFEEEEEE), // Very light grey
    trackHoverColor: Color(0xFFE0E0E0), // Slightly darker grey
  );

  /// Dark theme preset (dark background, light handle).
  static const ScrollbarConfig defaultDark = ScrollbarConfig(
    trackColor: Color(0xFF212121), // Dark background
    handleColor: Color(0xFF616161), // Medium grey
    handleHoverColor: Color(0xFF757575), // Lighter grey
    edgeHoverColor: Color(
      0xFF64B5F6,
    ), // Material Blue 300 (lighter for dark theme)
    handleActiveColor: Color(0xFF9E9E9E), // Light grey
    handleDisabledColor: Color(0xFF424242), // Dark grey
    trackHoverColor: Color(0xFF303030), // Slightly lighter dark
  );

  /// High contrast preset (WCAG 2.1 AAA - 7:1 contrast ratios).
  static const ScrollbarConfig highContrast = ScrollbarConfig(
    trackColor: Color(0xFFFFFFFF), // Pure white
    handleColor: Color(0xFF000000), // Pure black
    handleHoverColor: Color(0xFF1976D2), // Blue
    edgeHoverColor: Color(0xFF0D47A1), // Dark blue for edge zones
    handleActiveColor: Color(0xFFD32F2F), // Red
    handleDisabledColor: Color(0xFFBDBDBD), // Medium grey
    trackHoverColor: Color(0xFFE0E0E0), // Light grey
    borderRadius: 2.0, // Sharper corners for better definition
  );

  /// Create copy with selective overrides.
  ScrollbarConfig copyWith({
    double? thickness,
    double? minHandleSize,
    Color? trackColor,
    Color? handleColor,
    Color? handleHoverColor,
    Color? edgeHoverColor,
    Color? handleActiveColor,
    Color? handleDisabledColor,
    Color? trackHoverColor,
    double? borderRadius,
    double? edgeGripWidth,
    bool? showGripIndicator,
    Color? gripIndicatorColor,
    bool? autoHide,
    Duration? autoHideDelay,
    Duration? fadeDuration,
    bool? enableResizeHandles,
    double? minZoomRatio,
    double? maxZoomRatio,
    double? padding,
    bool? forcedColorsMode,
    bool? prefersReducedMotion,
  }) => ScrollbarConfig(
    thickness: thickness ?? this.thickness,
    minHandleSize: minHandleSize ?? this.minHandleSize,
    trackColor: trackColor ?? this.trackColor,
    handleColor: handleColor ?? this.handleColor,
    handleHoverColor: handleHoverColor ?? this.handleHoverColor,
    edgeHoverColor: edgeHoverColor ?? this.edgeHoverColor,
    handleActiveColor: handleActiveColor ?? this.handleActiveColor,
    handleDisabledColor: handleDisabledColor ?? this.handleDisabledColor,
    trackHoverColor: trackHoverColor ?? this.trackHoverColor,
    borderRadius: borderRadius ?? this.borderRadius,
    edgeGripWidth: edgeGripWidth ?? this.edgeGripWidth,
    showGripIndicator: showGripIndicator ?? this.showGripIndicator,
    gripIndicatorColor: gripIndicatorColor ?? this.gripIndicatorColor,
    autoHide: autoHide ?? this.autoHide,
    autoHideDelay: autoHideDelay ?? this.autoHideDelay,
    fadeDuration: fadeDuration ?? this.fadeDuration,
    enableResizeHandles: enableResizeHandles ?? this.enableResizeHandles,
    minZoomRatio: minZoomRatio ?? this.minZoomRatio,
    maxZoomRatio: maxZoomRatio ?? this.maxZoomRatio,
    padding: padding ?? this.padding,
    forcedColorsMode: forcedColorsMode ?? this.forcedColorsMode,
    prefersReducedMotion: prefersReducedMotion ?? this.prefersReducedMotion,
  );

  /// Serialize to JSON (for theme persistence).
  Map<String, dynamic> toJson() => {
    'thickness': thickness,
    'minHandleSize': minHandleSize,
    'trackColor': trackColor.value,
    'handleColor': handleColor.value,
    'handleHoverColor': handleHoverColor.value,
    'edgeHoverColor': edgeHoverColor.value,
    'handleActiveColor': handleActiveColor.value,
    'handleDisabledColor': handleDisabledColor.value,
    'trackHoverColor': trackHoverColor.value,
    'borderRadius': borderRadius,
    'edgeGripWidth': edgeGripWidth,
    'showGripIndicator': showGripIndicator,
    'gripIndicatorColor': gripIndicatorColor.value,
    'autoHide': autoHide,
    'autoHideDelayMs': autoHideDelay.inMilliseconds,
    'fadeDurationMs': fadeDuration.inMilliseconds,
    'enableResizeHandles': enableResizeHandles,
    'minZoomRatio': minZoomRatio,
    'maxZoomRatio': maxZoomRatio,
    'padding': padding,
    'forcedColorsMode': forcedColorsMode,
    'prefersReducedMotion': prefersReducedMotion,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrollbarConfig &&
          thickness == other.thickness &&
          minHandleSize == other.minHandleSize &&
          trackColor == other.trackColor &&
          handleColor == other.handleColor &&
          handleHoverColor == other.handleHoverColor &&
          edgeHoverColor == other.edgeHoverColor &&
          handleActiveColor == other.handleActiveColor &&
          handleDisabledColor == other.handleDisabledColor &&
          trackHoverColor == other.trackHoverColor &&
          borderRadius == other.borderRadius &&
          edgeGripWidth == other.edgeGripWidth &&
          showGripIndicator == other.showGripIndicator &&
          gripIndicatorColor == other.gripIndicatorColor &&
          autoHide == other.autoHide &&
          autoHideDelay == other.autoHideDelay &&
          fadeDuration == other.fadeDuration &&
          enableResizeHandles == other.enableResizeHandles &&
          minZoomRatio == other.minZoomRatio &&
          maxZoomRatio == other.maxZoomRatio &&
          padding == other.padding &&
          forcedColorsMode == other.forcedColorsMode &&
          prefersReducedMotion == other.prefersReducedMotion;

  @override
  int get hashCode => Object.hashAll([
    thickness,
    minHandleSize,
    trackColor,
    handleColor,
    handleHoverColor,
    edgeHoverColor,
    handleActiveColor,
    handleDisabledColor,
    trackHoverColor,
    borderRadius,
    edgeGripWidth,
    showGripIndicator,
    gripIndicatorColor,
    autoHide,
    autoHideDelay,
    fadeDuration,
    enableResizeHandles,
    minZoomRatio,
    maxZoomRatio,
    padding,
    forcedColorsMode,
    prefersReducedMotion,
  ]);
}
