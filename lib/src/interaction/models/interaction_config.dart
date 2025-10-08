/// Interaction configuration wrapper model.
library;

import 'crosshair_config.dart';
import 'tooltip_config.dart';

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

  InteractionConfig copyWith({
    bool? enabled,
    CrosshairConfig? crosshair,
    TooltipConfig? tooltip,
    GestureConfig? gesture,
    KeyboardConfig? keyboard,
    bool? enableZoom,
    bool? enablePan,
    bool? enableSelection,
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
