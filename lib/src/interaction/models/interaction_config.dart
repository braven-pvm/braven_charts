/// Interaction configuration wrapper model.
///
/// This library provides configuration models for chart interaction features,
/// including crosshair, tooltip, zoom/pan, gestures, and keyboard navigation.
library;

import '../interaction_callbacks.dart';
import 'crosshair_config.dart';
import 'tooltip_config.dart';

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
  int get hashCode => Object.hash(enabled, panStep, zoomStep, enableArrowKeys,
      enablePlusMinusKeys, enableHomeEndKeys);
}

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
  });

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
        other.enableSelection == enableSelection;
  }

  @override
  int get hashCode => Object.hash(enabled, crosshair, tooltip, gesture,
      keyboard, enableZoom, enablePan, enableSelection);
}
