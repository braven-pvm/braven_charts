// Model: InteractionConfig
// Feature: Layer 7 Interaction System
// Purpose: Main configuration wrapper for all interaction features

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'crosshair_config.dart';
import 'tooltip_config.dart';
import 'zoom_pan_state.dart';

// ============================================================================
// Enums
// ============================================================================

/// Interaction mode determines which features are active.
enum InteractionMode {
  /// Full exploration mode - all interactions enabled.
  ///
  /// Enables: crosshair, tooltip, zoom, pan, keyboard navigation
  explore,

  /// Analysis mode - focus on data inspection.
  ///
  /// Enables: crosshair, tooltip, selection, keyboard
  /// Note: Zoom/pan may be limited to prevent accidental viewport changes
  analyze,

  /// Presentation mode - minimal interactions.
  ///
  /// Enables: tooltip on tap only
  /// Note: Designed for presentations where viewport should remain fixed
  present,
}

// ============================================================================
// Main Configuration Class
// ============================================================================

/// Main configuration class for chart interactions.
///
/// Provides two configuration modes:
/// 1. **Simple**: Boolean flags for quick enablement
/// 2. **Advanced**: Detailed sub-config objects for full customization
///
/// Example - Simple mode:
/// ```dart
/// InteractionConfig(
///   enableCrosshair: true,
///   enableTooltip: true,
///   enableZoom: true,
///   enablePan: true,
/// )
/// ```
///
/// Example - Advanced mode:
/// ```dart
/// InteractionConfig(
///   crosshair: CrosshairConfig(
///     mode: CrosshairMode.both,
///     snapToDataPoint: true,
///     style: CrosshairStyle(lineColor: Colors.blue),
///   ),
///   tooltip: TooltipConfig(
///     customBuilder: (context, point, seriesId) => CustomTooltip(),
///   ),
///   zoomPan: ZoomPanConfig(zoomMode: ZoomMode.xOnly),
///   keyboard: KeyboardConfig(enabled: true),
/// )
/// ```
class InteractionConfig {
  /// Creates an interaction configuration.
  ///
  /// Use either simple boolean flags or detailed config objects.
  /// Detailed configs take precedence over simple flags.
  const InteractionConfig({
    this.crosshair,
    this.tooltip,
    this.zoomPan,
    this.keyboard,
    this.enableCrosshair = false,
    this.enableTooltip = false,
    this.enableZoom = false,
    this.enablePan = false,
    this.mode = InteractionMode.explore,
    this.onDataPointTap,
    this.onDataPointHover,
    this.onDataPointLongPress,
    this.onSelectionChange,
    this.onZoomChange,
    this.onPanChange,
    this.onViewportChange,
    this.onDataPointFocus,
    this.onModeChanged,
  });

  /// Creates a configuration with all interactions enabled (defaults).
  factory InteractionConfig.all() {
    return const InteractionConfig(
      enableCrosshair: true,
      enableTooltip: true,
      enableZoom: true,
      enablePan: true,
    );
  }

  /// Creates a configuration with no interactions enabled.
  factory InteractionConfig.none() {
    return const InteractionConfig();
  }

  /// Detailed crosshair configuration.
  ///
  /// If null and [enableCrosshair] is true, uses default config.
  final CrosshairConfig? crosshair;

  /// Detailed tooltip configuration.
  ///
  /// If null and [enableTooltip] is true, uses default config.
  final TooltipConfig? tooltip;

  /// Detailed zoom/pan configuration.
  ///
  /// If null and ([enableZoom] or [enablePan]) is true, uses default config.
  final ZoomPanConfig? zoomPan;

  /// Detailed keyboard navigation configuration.
  ///
  /// If null, keyboard interactions are disabled.
  final KeyboardConfig? keyboard;

  // Simple enablers (convenience shortcuts)

  /// Simple flag to enable crosshair with default settings.
  ///
  /// Overridden by [crosshair] if provided.
  final bool enableCrosshair;

  /// Simple flag to enable tooltip with default settings.
  ///
  /// Overridden by [tooltip] if provided.
  final bool enableTooltip;

  /// Simple flag to enable zoom with default settings.
  ///
  /// Overridden by [zoomPan] if provided.
  final bool enableZoom;

  /// Simple flag to enable pan with default settings.
  ///
  /// Overridden by [zoomPan] if provided.
  final bool enablePan;

  // Interaction mode

  /// Interaction mode determines which features are active.
  ///
  /// - [InteractionMode.explore]: All interactions enabled
  /// - [InteractionMode.analyze]: Focus on data inspection, limited zoom/pan
  /// - [InteractionMode.present]: Minimal interactions (tooltip on tap only)
  final InteractionMode mode;

  // Interaction callbacks

  /// Called when a data point is tapped/clicked.
  ///
  /// Parameters:
  /// - [point]: The data point that was tapped
  /// - [seriesId]: ID of the series containing the point
  final DataPointCallback? onDataPointTap;

  /// Called when cursor hovers over a data point.
  ///
  /// Parameters:
  /// - [point]: The data point being hovered
  /// - [seriesId]: ID of the series containing the point
  final DataPointCallback? onDataPointHover;

  /// Called when a data point is long-pressed (mobile).
  ///
  /// Parameters:
  /// - [point]: The data point that was long-pressed
  /// - [seriesId]: ID of the series containing the point
  final DataPointCallback? onDataPointLongPress;

  /// Called when the selection of data points changes.
  ///
  /// Parameters:
  /// - [selectedPoints]: List of currently selected points
  final SelectionCallback? onSelectionChange;

  /// Called when the zoom level changes.
  ///
  /// Parameters:
  /// - [zoomLevel]: Current zoom level (1.0 = 100%)
  final ZoomCallback? onZoomChange;

  /// Called when the pan offset changes.
  ///
  /// Parameters:
  /// - [offset]: Current pan offset
  final PanCallback? onPanChange;

  /// Called when the visible viewport changes.
  ///
  /// Parameters:
  /// - [visibleBounds]: Rectangle representing visible data bounds
  final ViewportCallback? onViewportChange;

  /// Called when keyboard focus moves to a data point.
  ///
  /// Parameters:
  /// - [point]: The focused data point (null if no focus)
  /// - [seriesId]: ID of the series (null if no focus)
  /// - [index]: Index of the point within series (null if no focus)
  final FocusCallback? onDataPointFocus;

  /// Called when interaction mode changes.
  ///
  /// Parameters:
  /// - [newMode]: The new interaction mode
  final ModeChangeCallback? onModeChanged;

  /// Gets the effective crosshair configuration.
  ///
  /// Returns the detailed [crosshair] config if provided,
  /// otherwise returns default config if [enableCrosshair] is true,
  /// otherwise returns null.
  CrosshairConfig? get effectiveCrosshairConfig {
    if (crosshair != null) return crosshair;
    if (enableCrosshair) return CrosshairConfig.defaultConfig();
    return null;
  }

  /// Gets the effective tooltip configuration.
  ///
  /// Returns the detailed [tooltip] config if provided,
  /// otherwise returns default config if [enableTooltip] is true,
  /// otherwise returns null.
  TooltipConfig? get effectiveTooltipConfig {
    if (tooltip != null) return tooltip;
    if (enableTooltip) return TooltipConfig.defaultConfig();
    return null;
  }

  /// Gets the effective zoom/pan configuration.
  ///
  /// Returns the detailed [zoomPan] config if provided,
  /// otherwise returns default config if [enableZoom] or [enablePan] is true,
  /// otherwise returns null.
  ZoomPanConfig? get effectiveZoomPanConfig {
    if (zoomPan != null) return zoomPan;
    if (enableZoom || enablePan) return ZoomPanConfig.defaultConfig();
    return null;
  }

  /// Gets the effective keyboard configuration.
  ///
  /// Returns the detailed [keyboard] config if provided,
  /// otherwise returns null.
  KeyboardConfig? get effectiveKeyboardConfig => keyboard;

  /// Creates a copy with modified properties.
  InteractionConfig copyWith({
    CrosshairConfig? crosshair,
    TooltipConfig? tooltip,
    ZoomPanConfig? zoomPan,
    KeyboardConfig? keyboard,
    bool? enableCrosshair,
    bool? enableTooltip,
    bool? enableZoom,
    bool? enablePan,
    InteractionMode? mode,
    DataPointCallback? onDataPointTap,
    DataPointCallback? onDataPointHover,
    DataPointCallback? onDataPointLongPress,
    SelectionCallback? onSelectionChange,
    ZoomCallback? onZoomChange,
    PanCallback? onPanChange,
    ViewportCallback? onViewportChange,
    FocusCallback? onDataPointFocus,
    ModeChangeCallback? onModeChanged,
  }) {
    return InteractionConfig(
      crosshair: crosshair ?? this.crosshair,
      tooltip: tooltip ?? this.tooltip,
      zoomPan: zoomPan ?? this.zoomPan,
      keyboard: keyboard ?? this.keyboard,
      enableCrosshair: enableCrosshair ?? this.enableCrosshair,
      enableTooltip: enableTooltip ?? this.enableTooltip,
      enableZoom: enableZoom ?? this.enableZoom,
      enablePan: enablePan ?? this.enablePan,
      mode: mode ?? this.mode,
      onDataPointTap: onDataPointTap ?? this.onDataPointTap,
      onDataPointHover: onDataPointHover ?? this.onDataPointHover,
      onDataPointLongPress: onDataPointLongPress ?? this.onDataPointLongPress,
      onSelectionChange: onSelectionChange ?? this.onSelectionChange,
      onZoomChange: onZoomChange ?? this.onZoomChange,
      onPanChange: onPanChange ?? this.onPanChange,
      onViewportChange: onViewportChange ?? this.onViewportChange,
      onDataPointFocus: onDataPointFocus ?? this.onDataPointFocus,
      onModeChanged: onModeChanged ?? this.onModeChanged,
    );
  }
}

// ============================================================================
// Callback Type Definitions
// ============================================================================

/// Callback for data point interactions (tap, hover, long-press).
///
/// Parameters:
/// - [point]: The data point involved in the interaction
/// - [seriesId]: ID of the series containing the point
typedef DataPointCallback = void Function(
  ChartDataPoint point,
  String seriesId,
);

/// Callback for selection changes.
///
/// Parameters:
/// - [selectedPoints]: List of currently selected data points
typedef SelectionCallback = void Function(
  List<ChartDataPoint> selectedPoints,
);

/// Callback for zoom level changes.
///
/// Parameters:
/// - [zoomLevel]: Current zoom level (1.0 = 100%, 2.0 = 200%, etc.)
typedef ZoomCallback = void Function(double zoomLevel);

/// Callback for pan offset changes.
///
/// Parameters:
/// - [offset]: Current pan offset from original position
typedef PanCallback = void Function(Offset offset);

/// Callback for viewport changes.
///
/// Parameters:
/// - [visibleBounds]: Rectangle representing the visible data range
typedef ViewportCallback = void Function(Rect visibleBounds);

/// Callback for keyboard focus changes.
///
/// Parameters:
/// - [point]: The focused data point (null if no point has focus)
/// - [seriesId]: ID of the series (null if no focus)
/// - [index]: Index of the point within its series (null if no focus)
typedef FocusCallback = void Function(
  ChartDataPoint? point,
  String? seriesId,
  int? index,
);

/// Callback for interaction mode changes.
///
/// Parameters:
/// - [newMode]: The new interaction mode that was activated
typedef ModeChangeCallback = void Function(InteractionMode newMode);

// ============================================================================
// Placeholder Types (to be defined in their respective files)
// ============================================================================

/// Placeholder for ChartDataPoint (defined in foundation layer).
class ChartDataPoint {
  const ChartDataPoint({required this.x, required this.y});
  final double x;
  final double y;
}

/// Configuration for zoom/pan behavior.
///
/// Full implementation in zoom_pan_state.dart
class ZoomPanConfig {
  const ZoomPanConfig({
    this.enabled = true,
    this.zoomMode = ZoomMode.xy,
    this.minZoomLevel = 0.5,
    this.maxZoomLevel = 10.0,
    this.allowOverscroll = false,
    this.mouseWheelZoomEnabled = true,
    this.dragPanEnabled = true,
    this.pinchZoomEnabled = true,
    this.doubleTapZoomEnabled = true,
    this.doubleTapZoomFactor = 2.0,
    this.resetOnDoubleTap = false,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  factory ZoomPanConfig.defaultConfig() => const ZoomPanConfig();
  final bool enabled;
  final ZoomMode zoomMode;
  final double minZoomLevel;
  final double maxZoomLevel;
  final bool allowOverscroll;
  final bool mouseWheelZoomEnabled;
  final bool dragPanEnabled;
  final bool pinchZoomEnabled;
  final bool doubleTapZoomEnabled;
  final double doubleTapZoomFactor;
  final bool resetOnDoubleTap;
  final Duration animationDuration;
}

/// Zoom mode enumeration.
enum ZoomMode {
  /// Zoom X-axis only (horizontal).
  xOnly,

  /// Zoom Y-axis only (vertical).
  yOnly,

  /// Zoom both axes independently.
  xy,

  /// Zoom both axes uniformly (maintain aspect ratio).
  uniform,
}

/// Configuration for keyboard navigation.
///
/// Full implementation to be added in keyboard_config.dart
class KeyboardConfig {
  const KeyboardConfig({
    this.enabled = true,
    this.navigationEnabled = true,
    this.zoomEnabled = true,
    this.panEnabled = true,
    this.focusIndicatorStyle = const FocusIndicatorStyle(),
    this.customBindings,
  });
  final bool enabled;
  final bool navigationEnabled;
  final bool zoomEnabled;
  final bool panEnabled;
  final FocusIndicatorStyle focusIndicatorStyle;
  final Map<LogicalKeyboardKey, Function>? customBindings;
}

/// Style for focus indicator.
class FocusIndicatorStyle {
  const FocusIndicatorStyle({
    this.color = Colors.blue,
    this.strokeWidth = 2.0,
    this.radius = 6.0,
    this.contrastRatio = 3.0,
  });
  final Color color;
  final double strokeWidth;
  final double radius;
  final double contrastRatio;
}
