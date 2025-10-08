/// Interaction configuration wrapper model.
library;

import 'crosshair_config.dart';
import 'tooltip_config.dart';
import '../interaction_callbacks.dart';

class GestureConfig {
  const GestureConfig({
    this.tapTimeout = const Duration(milliseconds: 200),
    this.longPressTimeout = const Duration(milliseconds: 500),
    this.panThreshold = 10.0,
    this.pinchThreshold = 0.1,
  });

  final Duration tapTimeout;
  final Duration longPressTimeout;
  final double panThreshold;
  final double pinchThreshold;

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
  int get hashCode => Object.hash(tapTimeout, longPressTimeout, panThreshold, pinchThreshold);
}

class KeyboardConfig {
  const KeyboardConfig({
    this.enabled = true,
    this.panStep = 10.0,
    this.zoomStep = 0.1,
    this.enableArrowKeys = true,
    this.enablePlusMinusKeys = true,
    this.enableHomeEndKeys = true,
  });

  final bool enabled;
  final double panStep;
  final double zoomStep;
  final bool enableArrowKeys;
  final bool enablePlusMinusKeys;
  final bool enableHomeEndKeys;

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

class InteractionConfig {
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

  factory InteractionConfig.defaultConfig() => const InteractionConfig();

  final bool enabled;
  final CrosshairConfig crosshair;
  final TooltipConfig tooltip;
  final GestureConfig gesture;
  final KeyboardConfig keyboard;
  final bool enableZoom;
  final bool enablePan;
  final bool enableSelection;

  // Callback functions for user interaction events (FR-007)
  /// Called when a user taps/clicks on a data point.
  final DataPointCallback? onDataPointTap;

  /// Called when the cursor hovers over a data point.
  final DataPointHoverCallback? onDataPointHover;

  /// Called when a user performs a long-press gesture on a data point.
  final DataPointLongPressCallback? onDataPointLongPress;

  /// Called when the selected data points change.
  final SelectionCallback? onSelectionChanged;

  /// Called when the zoom level changes.
  final ZoomCallback? onZoomChanged;

  /// Called when the pan offset changes.
  final PanCallback? onPanChanged;

  /// Called when the visible data range changes.
  final ViewportCallback? onViewportChanged;

  /// Called when the crosshair position changes.
  final CrosshairChangeCallback? onCrosshairChanged;

  /// Called when a tooltip is shown or hidden.
  final TooltipChangeCallback? onTooltipChanged;

  /// Called when a keyboard action is performed.
  final KeyboardActionCallback? onKeyboardAction;

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
  int get hashCode => Object.hash(enabled, crosshair, tooltip, gesture, keyboard, enableZoom, enablePan, enableSelection);
}
