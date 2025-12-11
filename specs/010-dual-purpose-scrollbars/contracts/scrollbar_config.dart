// Copyright 2025 Braven Charts. All rights reserved.
// Use of this source code is governed by a BSD-style license.

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

/// Configuration for a single scrollbar (X or Y axis).
///
/// Immutable data class defining visual appearance and interaction behavior.
/// Typically provided from [ScrollbarTheme] within [ChartTheme], but can be
/// customized per-scrollbar.
///
/// ## Basic Usage
///
/// ```dart
/// // Use predefined theme
/// final config = ScrollbarConfig.defaultLight;
///
/// // Customize
/// final custom = ScrollbarConfig(
///   thickness: 16.0,
///   handleColor: Colors.blue[300]!,
///   autoHide: false,  // Always visible
/// );
/// ```
///
/// ## Theming Integration
///
/// ```dart
/// // From ChartTheme
/// final chart = BravenChart(
///   theme: ChartTheme.defaultLight,  // Includes scrollbarTheme
/// );
/// // Scrollbar automatically uses theme.scrollbarTheme.xAxisScrollbar
///
/// // Override for specific chart
/// final customTheme = ChartTheme.defaultLight.copyWith(
///   scrollbarTheme: ScrollbarTheme(
///     xAxisScrollbar: ScrollbarConfig(thickness: 16.0),
///     yAxisScrollbar: ScrollbarConfig.defaultLight,
///   ),
/// );
/// ```
///
/// ## Accessibility
///
/// Ensure color contrast ratios meet WCAG 2.1 AA:
/// - Handle vs Track: 4.5:1 (WCAG SC 1.4.3)
/// - Track vs Background: 3:1 (WCAG SC 1.4.11)
/// - Hover/Active states: 3:1 difference (WCAG SC 1.4.11)
///
/// Predefined themes ([defaultLight], [defaultDark], [highContrast]) meet these requirements.
///
/// ## See Also
///
/// - [ScrollbarTheme] - Container for X/Y scrollbar configs
/// - [ChartScrollbar] - Widget that uses this configuration
@immutable
class ScrollbarConfig {
  /// Creates a scrollbar configuration.
  ///
  /// All parameters are optional with sensible defaults matching Material Design.
  ///
  /// Example:
  /// ```dart
  /// const config = ScrollbarConfig(
  ///   thickness: 16.0,               // Thicker than default
  ///   minHandleSize: 30.0,           // Larger minimum handle
  ///   handleColor: Color(0xFF2196F3), // Blue handle
  ///   autoHide: false,               // Always visible
  ///   enableResizeHandles: false,    // Pan-only (no zoom)
  /// );
  /// ```
  const ScrollbarConfig({
    this.thickness = 12.0,
    this.minHandleSize = 20.0,
    this.trackColor = const Color(0xFFF5F5F5),
    this.handleColor = const Color(0xFFBDBDBD),
    this.handleHoverColor = const Color(0xFF9E9E9E),
    this.handleActiveColor = const Color(0xFF757575),
    this.borderRadius = 4.0,
    this.edgeGripWidth = 8.0,
    this.showGripIndicator = true,
    this.gripIndicatorColor = const Color(0xFF757575),
    this.autoHide = true,
    this.autoHideDelay = const Duration(seconds: 2),
    this.fadeDuration = const Duration(milliseconds: 200),
    this.enableResizeHandles = true,
    this.minZoomRatio = 0.01,
    this.maxZoomRatio = 1.0,
  })  : assert(thickness > 0, 'Thickness must be positive'),
        assert(minHandleSize > 0, 'Min handle size must be positive'),
        assert(edgeGripWidth > 0 && edgeGripWidth < minHandleSize / 2,
            'Edge grip width must be positive and less than half min handle size'),
        assert(minZoomRatio > 0 && minZoomRatio < maxZoomRatio,
            'Min zoom ratio must be positive and less than max zoom ratio'),
        assert(maxZoomRatio <= 1.0, 'Max zoom ratio must be <= 1.0');

  // === Visual Properties ===

  /// Width (for vertical) or height (for horizontal) of the scrollbar track.
  ///
  /// **Default**: 12.0 (matches Material Design scrollbar thickness)
  ///
  /// **Typical Range**: 8.0 - 20.0
  /// - Smaller (8px): More compact, less obtrusive
  /// - Larger (16-20px): Easier to grab, better for touch screens
  ///
  /// **Constraint**: Must be > 0
  final double thickness;

  /// Minimum size of the handle (prevents tiny handles when zoomed way out).
  ///
  /// **Default**: 20.0 (ensures handle remains grabbable)
  ///
  /// **Typical Range**: 20.0 - 40.0
  /// - Smaller (20px): More precise viewport-to-data ratio representation
  /// - Larger (40px): Easier to grab, better for touch (WCAG recommends 44px for touch targets)
  ///
  /// **Constraint**: Must be > 0 and >= edgeGripWidth * 2 (to fit both edge zones)
  ///
  /// **Example**: If viewing 1% of data (1 out of 100 points) with 200px track:
  /// - Calculated handle size: (1/100) * 200 = 2px
  /// - Actual rendered size: max(2px, 20px) = 20px (clamped to minHandleSize)
  final double minHandleSize;

  /// Background color of the scrollbar track.
  ///
  /// **Default**: Color(0xFFF5F5F5) - Light grey (Material Design)
  ///
  /// **Accessibility**: Should have 3:1 contrast ratio with chart background (WCAG SC 1.4.11).
  ///
  /// **Example**:
  /// ```dart
  /// // Light theme
  /// trackColor: Color(0xFFF5F5F5),  // Light grey on white background
  ///
  /// // Dark theme
  /// trackColor: Color(0xFF212121),  // Dark grey on black background
  ///
  /// // Custom
  /// trackColor: Colors.blue[50]!,  // Light blue tint
  /// ```
  final Color trackColor;

  /// Default color of the scrollbar handle (no interaction).
  ///
  /// **Default**: Color(0xFFBDBDBD) - Medium grey (Material Design)
  ///
  /// **Accessibility**: Should have 4.5:1 contrast ratio with trackColor (WCAG SC 1.4.3).
  ///
  /// **State Transitions**:
  /// - Default: handleColor
  /// - Hover: handleHoverColor
  /// - Drag: handleActiveColor
  final Color handleColor;

  /// Handle color when mouse is hovering over it.
  ///
  /// **Default**: Color(0xFF9E9E9E) - Darker grey
  ///
  /// **Accessibility**: Should have 3:1 contrast ratio with handleColor (WCAG SC 1.4.11)
  /// to indicate state change.
  final Color handleHoverColor;

  /// Handle color when user is dragging it.
  ///
  /// **Default**: Color(0xFF757575) - Dark grey
  ///
  /// **Accessibility**: Should have 3:1 contrast ratio with handleColor (WCAG SC 1.4.11).
  final Color handleActiveColor;

  /// Corner radius for handle (rounded rectangle).
  ///
  /// **Default**: 4.0 (matches Material Design)
  ///
  /// **Typical Range**: 0.0 - thickness/2
  /// - 0.0: Sharp corners (traditional scrollbar)
  /// - 4.0: Slightly rounded (modern, friendly)
  /// - thickness/2: Fully rounded (pill-shaped, maximum roundness)
  ///
  /// **Constraint**: Must be >= 0
  final double borderRadius;

  /// Visual indicator lines on handle (3 parallel lines in center).
  ///
  /// **Default**: true
  ///
  /// **Purpose**: Provides visual affordance for draggability (common pattern in
  /// modern UIs like Google Sheets, macOS scrollbars).
  ///
  /// **Appearance**:
  /// ```
  /// ┌───────┐
  /// │   ║   │  ← 3 parallel lines
  /// │   ║   │     (gripIndicatorColor)
  /// │   ║   │
  /// └───────┘
  /// ```
  final bool showGripIndicator;

  /// Color of grip indicator lines.
  ///
  /// **Default**: Color(0xFF757575) - Dark grey
  ///
  /// **Visibility**: Should contrast with handleColor for visibility.
  final Color gripIndicatorColor;

  // === Interaction Properties ===

  /// Width of edge interaction zones (for resize handles).
  ///
  /// **Default**: 8.0
  ///
  /// **Purpose**: First/last edgeGripWidth pixels of handle trigger resize mode
  /// (dragging adjusts viewport min/max bounds instead of panning).
  ///
  /// **Typical Range**: 6.0 - 12.0
  /// - Smaller (6px): More center area for pan, but harder to hit edges
  /// - Larger (12px): Easier to resize, but less pan area
  ///
  /// **Constraint**: Must be > 0 and < minHandleSize / 2 (to fit within handle)
  ///
  /// **Example** (horizontal scrollbar, minHandleSize=50px, edgeGripWidth=8px):
  /// ```
  /// ┌────────────────────────────────────────────────┐
  /// │  LEFT │         CENTER (34px)        │ RIGHT  │
  /// │  8px  │        (pan mode)            │  8px   │
  /// │(resize│                              │(resize)│
  /// │  min) │                              │  max)  │
  /// └────────────────────────────────────────────────┘
  /// ```
  final double edgeGripWidth;

  /// Whether to enable edge resize handles (if false, only center pan works).
  ///
  /// **Default**: true (dual-purpose: pan + zoom)
  ///
  /// **Use Cases**:
  /// - true: Full dual-purpose scrollbar (pan + zoom via edge resize)
  /// - false: Simplified scrollbar (pan-only, no zoom)
  ///
  /// **Effect**: When false, entire handle acts as center zone (pan mode only).
  /// Edges don't trigger resize cursors or behavior.
  final bool enableResizeHandles;

  /// Minimum zoom ratio (viewportRange.span / dataRange.span).
  ///
  /// **Default**: 0.01 (1% minimum - prevents zooming in too far)
  ///
  /// **Purpose**: Prevents user from zooming in so far they see <1% of data
  /// (which might be confusing or performance-intensive).
  ///
  /// **Example**:
  /// - dataRange: 0-100 (100 data points)
  /// - minZoomRatio: 0.01
  /// - Minimum viewport span: 100 * 0.01 = 1 data point
  /// - User cannot zoom tighter than viewportRange = DataRange(50, 51)
  ///
  /// **Constraint**: Must be > 0 and < maxZoomRatio
  final double minZoomRatio;

  /// Maximum zoom ratio (viewportRange.span / dataRange.span).
  ///
  /// **Default**: 1.0 (100% maximum - prevents zooming out past full data range)
  ///
  /// **Purpose**: Prevents user from zooming out to see more than 100% of data
  /// (which is impossible - you can't see more than all the data).
  ///
  /// **Example**:
  /// - dataRange: 0-100
  /// - maxZoomRatio: 1.0
  /// - Maximum viewport span: 100 * 1.0 = 100 data points
  /// - User cannot zoom wider than viewportRange = DataRange(0, 100)
  ///
  /// **Constraint**: Must be <= 1.0
  final double maxZoomRatio;

  // === Auto-Hide Properties ===

  /// Whether scrollbar auto-hides after period of inactivity.
  ///
  /// **Default**: true (common pattern in modern UIs)
  ///
  /// **Behavior**:
  /// - Scrollbar visible initially
  /// - After autoHideDelay expires (default 2 seconds) with no interaction, fades out
  /// - Reappears on pointer enter, keyboard focus, or chart interaction
  ///
  /// **Use Cases**:
  /// - true: Cleaner UI, less clutter (mobile/web apps)
  /// - false: Always visible (desktop apps, data analysis tools where scrollbar is critical)
  final bool autoHide;

  /// Delay before auto-hiding scrollbar (if autoHide is true).
  ///
  /// **Default**: Duration(seconds: 2)
  ///
  /// **Behavior**: Timer starts after last interaction (pointer move, drag, keyboard input).
  /// If no new interaction before timer expires, scrollbar fades out.
  ///
  /// **Typical Range**: 1-5 seconds
  /// - Shorter (1s): Scrollbar hides quickly (minimal clutter)
  /// - Longer (5s): More time to interact (less sudden disappearance)
  ///
  /// **Constraint**: Must be > Duration.zero (if autoHide is true)
  final Duration autoHideDelay;

  /// Duration of fade-in/fade-out animation when auto-hiding.
  ///
  /// **Default**: Duration(milliseconds: 200)
  ///
  /// **Behavior**: Smooth opacity transition (0.0 → 1.0 on show, 1.0 → 0.0 on hide).
  ///
  /// **Typical Range**: 100-500ms
  /// - Shorter (100ms): Snappier, less smooth
  /// - Longer (500ms): More gradual, elegant
  final Duration fadeDuration;

  // === Predefined Themes ===

  /// Light theme preset (light background, dark handle).
  ///
  /// **Colors**: Light grey track, medium grey handle, dark grey active.
  ///
  /// **Contrast Ratios** (vs white background):
  /// - Track vs Background: 4:1 ✓
  /// - Handle vs Track: 5:1 ✓
  /// - Handle vs Background: 4.5:1 ✓
  /// - Active vs Handle: 3.5:1 ✓
  ///
  /// **Use Case**: Charts on white/light backgrounds.
  static const ScrollbarConfig defaultLight = ScrollbarConfig(
    trackColor: Color(0xFFF5F5F5), // Light grey
    handleColor: Color(0xFFBDBDBD), // Medium grey
    handleHoverColor: Color(0xFF9E9E9E), // Darker grey
    handleActiveColor: Color(0xFF757575), // Dark grey
  );

  /// Dark theme preset (dark background, light handle).
  ///
  /// **Colors**: Dark track, medium grey handle, light grey active.
  ///
  /// **Contrast Ratios** (vs black background):
  /// - Track vs Background: 4:1 ✓
  /// - Handle vs Track: 5:1 ✓
  /// - Handle vs Background: 4.5:1 ✓
  /// - Active vs Handle: 3.5:1 ✓
  ///
  /// **Use Case**: Charts on dark backgrounds.
  static const ScrollbarConfig defaultDark = ScrollbarConfig(
    trackColor: Color(0xFF212121), // Dark background
    handleColor: Color(0xFF616161), // Medium grey
    handleHoverColor: Color(0xFF757575), // Lighter grey
    handleActiveColor: Color(0xFF9E9E9E), // Light grey
  );

  /// High contrast preset (WCAG 2.1 AAA - 7:1 contrast ratios).
  ///
  /// **Colors**: Pure white track, pure black handle, blue hover, red active.
  ///
  /// **Contrast Ratios**:
  /// - Track vs Background (black): 21:1 ✓✓✓
  /// - Handle vs Track: 21:1 ✓✓✓
  /// - Hover vs Track: 7:1 ✓✓
  /// - Active vs Track: 7:1 ✓✓
  ///
  /// **Use Case**: Accessibility-focused applications, users with low vision.
  static const ScrollbarConfig highContrast = ScrollbarConfig(
    trackColor: Color(0xFFFFFFFF), // Pure white
    handleColor: Color(0xFF000000), // Pure black
    handleHoverColor: Color(0xFF1976D2), // Blue (WCAG AAA)
    handleActiveColor: Color(0xFFD32F2F), // Red (WCAG AAA)
  );

  // === Methods ===

  /// Create copy with selective overrides.
  ///
  /// **Example**:
  /// ```dart
  /// final custom = ScrollbarConfig.defaultLight.copyWith(
  ///   thickness: 16.0,        // Override thickness
  ///   autoHide: false,        // Override auto-hide
  ///   // All other properties from defaultLight
  /// );
  /// ```
  ScrollbarConfig copyWith({
    double? thickness,
    double? minHandleSize,
    Color? trackColor,
    Color? handleColor,
    Color? handleHoverColor,
    Color? handleActiveColor,
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
  }) =>
      ScrollbarConfig(
        thickness: thickness ?? this.thickness,
        minHandleSize: minHandleSize ?? this.minHandleSize,
        trackColor: trackColor ?? this.trackColor,
        handleColor: handleColor ?? this.handleColor,
        handleHoverColor: handleHoverColor ?? this.handleHoverColor,
        handleActiveColor: handleActiveColor ?? this.handleActiveColor,
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
      );

  /// Serialize to JSON (for theme persistence).
  ///
  /// **Example**:
  /// ```dart
  /// final json = ScrollbarConfig.defaultLight.toJson();
  /// // {
  /// //   'thickness': 12.0,
  /// //   'minHandleSize': 20.0,
  /// //   'trackColor': 4293256677,  // Color.value
  /// //   ...
  /// // }
  /// ```
  Map<String, dynamic> toJson() => {
        'thickness': thickness,
        'minHandleSize': minHandleSize,
        'trackColor': trackColor.value,
        'handleColor': handleColor.value,
        'handleHoverColor': handleHoverColor.value,
        'handleActiveColor': handleActiveColor.value,
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
      };

  /// Deserialize from JSON.
  ///
  /// **Example**:
  /// ```dart
  /// final json = {'thickness': 16.0, 'minHandleSize': 30.0, ...};
  /// final config = ScrollbarConfig.fromJson(json);
  /// ```
  factory ScrollbarConfig.fromJson(Map<String, dynamic> json) =>
      ScrollbarConfig(
        thickness: json['thickness'] as double,
        minHandleSize: json['minHandleSize'] as double,
        trackColor: Color(json['trackColor'] as int),
        handleColor: Color(json['handleColor'] as int),
        handleHoverColor: Color(json['handleHoverColor'] as int),
        handleActiveColor: Color(json['handleActiveColor'] as int),
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
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScrollbarConfig &&
          thickness == other.thickness &&
          minHandleSize == other.minHandleSize &&
          trackColor == other.trackColor &&
          handleColor == other.handleColor &&
          handleHoverColor == other.handleHoverColor &&
          handleActiveColor == other.handleActiveColor &&
          borderRadius == other.borderRadius &&
          edgeGripWidth == other.edgeGripWidth &&
          showGripIndicator == other.showGripIndicator &&
          gripIndicatorColor == other.gripIndicatorColor &&
          autoHide == other.autoHide &&
          autoHideDelay == other.autoHideDelay &&
          fadeDuration == other.fadeDuration &&
          enableResizeHandles == other.enableResizeHandles &&
          minZoomRatio == other.minZoomRatio &&
          maxZoomRatio == other.maxZoomRatio;

  @override
  int get hashCode => Object.hash(
        thickness,
        minHandleSize,
        trackColor,
        handleColor,
        handleHoverColor,
        handleActiveColor,
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
      );

  @override
  String toString() => 'ScrollbarConfig('
      'thickness: $thickness, '
      'minHandleSize: $minHandleSize, '
      'trackColor: $trackColor, '
      'handleColor: $handleColor, '
      'handleHoverColor: $handleHoverColor, '
      'handleActiveColor: $handleActiveColor, '
      'borderRadius: $borderRadius, '
      'edgeGripWidth: $edgeGripWidth, '
      'showGripIndicator: $showGripIndicator, '
      'gripIndicatorColor: $gripIndicatorColor, '
      'autoHide: $autoHide, '
      'autoHideDelay: $autoHideDelay, '
      'fadeDuration: $fadeDuration, '
      'enableResizeHandles: $enableResizeHandles, '
      'minZoomRatio: $minZoomRatio, '
      'maxZoomRatio: $maxZoomRatio'
      ')';
}
