import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show immutable, listEquals;

/// Interaction policy for a [CartesianNavigator].
@immutable
class CartesianNavigatorBehavior {
  /// Creates navigator interaction behavior.
  const CartesianNavigatorBehavior({
    this.allowPan = true,
    this.allowResize = true,
    this.livePreview = true,
    this.minimumSpan = 0,
    this.allowExternalDomainGrowth = false,
  });

  /// Whether dragging or keyboard-operating the selected window moves it.
  final bool allowPan;

  /// Whether dragging or keyboard-operating either edge resizes the window.
  final bool allowResize;

  /// Whether viewport changes are published while an interaction is active.
  ///
  /// When false, the navigator still updates its local preview and publishes
  /// the final viewport when the interaction commits.
  final bool livePreview;

  /// Smallest permitted selected X span, expressed in data-domain units.
  ///
  /// A value of zero permits any finite, ordered viewport.
  final double minimumSpan;

  /// Whether an external viewport may temporarily extend beyond `fullDomain`.
  ///
  /// Enable this when the interaction-group viewport follows live data faster
  /// than the navigator's overview snapshot is rebuilt. The navigator keeps
  /// the external controller authoritative and locally clamps only its visual
  /// selection until the next expanded domain arrives. It never publishes the
  /// temporary clamp back to the group.
  final bool allowExternalDomainGrowth;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartesianNavigatorBehavior &&
          other.allowPan == allowPan &&
          other.allowResize == allowResize &&
          other.livePreview == livePreview &&
          other.minimumSpan == minimumSpan &&
          other.allowExternalDomainGrowth == allowExternalDomainGrowth;

  @override
  int get hashCode => Object.hash(
    allowPan,
    allowResize,
    livePreview,
    minimumSpan,
    allowExternalDomainGrowth,
  );
}

/// Built-in snapping strategies for Cartesian navigator interactions.
enum CartesianNavigatorSnapMode {
  /// Preserve the exact data-space value produced by the interaction.
  none,

  /// Snap to fixed intervals anchored at the full-domain minimum.
  interval,

  /// Snap to the nearest member of an ordered data-X value set.
  orderedValues,
}

/// Snapping policy applied to active navigator edges.
@immutable
class CartesianNavigatorSnapPolicy {
  const CartesianNavigatorSnapPolicy._({
    required this.mode,
    this.interval,
    this.values = const <double>[],
  });

  /// Creates a policy that does not snap interaction values.
  const CartesianNavigatorSnapPolicy.none()
    : this._(mode: CartesianNavigatorSnapMode.none);

  /// Creates fixed-interval snapping anchored at the full-domain minimum.
  factory CartesianNavigatorSnapPolicy.interval(double interval) {
    if (!interval.isFinite || interval <= 0) {
      throw ArgumentError.value(
        interval,
        'interval',
        'must be finite and greater than zero',
      );
    }
    return CartesianNavigatorSnapPolicy._(
      mode: CartesianNavigatorSnapMode.interval,
      interval: interval,
    );
  }

  /// Creates snapping to a finite, strictly increasing data-X value set.
  factory CartesianNavigatorSnapPolicy.values(Iterable<double> values) {
    final copiedValues = List<double>.unmodifiable(values);
    if (copiedValues.isEmpty) {
      throw ArgumentError.value(values, 'values', 'must not be empty');
    }
    for (var index = 0; index < copiedValues.length; index += 1) {
      final value = copiedValues[index];
      if (!value.isFinite) {
        throw ArgumentError.value(value, 'values[$index]', 'must be finite');
      }
      if (index > 0 && value <= copiedValues[index - 1]) {
        throw ArgumentError.value(
          values,
          'values',
          'must be strictly increasing',
        );
      }
    }
    return CartesianNavigatorSnapPolicy._(
      mode: CartesianNavigatorSnapMode.orderedValues,
      values: copiedValues,
    );
  }

  /// Active snapping strategy.
  final CartesianNavigatorSnapMode mode;

  /// Fixed interval for [CartesianNavigatorSnapMode.interval].
  final double? interval;

  /// Ordered values for [CartesianNavigatorSnapMode.orderedValues].
  final List<double> values;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartesianNavigatorSnapPolicy &&
          other.mode == mode &&
          other.interval == interval &&
          listEquals(other.values, values);

  @override
  int get hashCode => Object.hash(mode, interval, Object.hashAll(values));
}

/// Visual styling for a [CartesianNavigator] selection window.
///
/// Null colors inherit accessible values from the surrounding Material and
/// chart themes. Visual handles remain compact while [handleHitWidth] controls
/// their larger pointer and touch target.
@immutable
class CartesianNavigatorStyle {
  /// Creates navigator selection styling.
  const CartesianNavigatorStyle({
    this.selectionFillColor,
    this.selectionBorderColor,
    this.outsideMaskColor,
    this.handleColor,
    this.handleBorderColor,
    this.hoverOverlayColor,
    this.pressedOverlayColor,
    this.focusColor,
    this.disabledOverlayColor,
    this.borderWidth = 1.5,
    this.handleVisualWidth = 4,
    this.handleVisualHeight = 28,
    this.handleHitWidth = 48,
    this.borderRadius = 4,
  });

  final Color? selectionFillColor;
  final Color? selectionBorderColor;
  final Color? outsideMaskColor;
  final Color? handleColor;
  final Color? handleBorderColor;
  final Color? hoverOverlayColor;
  final Color? pressedOverlayColor;
  final Color? focusColor;
  final Color? disabledOverlayColor;

  /// Width of the selected-window border.
  final double borderWidth;

  /// Painted width of each edge handle.
  final double handleVisualWidth;

  /// Painted height of each edge handle.
  final double handleVisualHeight;

  /// Pointer and touch target width centered on each edge.
  ///
  /// Defaults to 48 logical pixels while keeping the painted handle narrow.
  final double handleHitWidth;

  /// Corner radius of the selected window and handles.
  final double borderRadius;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartesianNavigatorStyle &&
          other.selectionFillColor == selectionFillColor &&
          other.selectionBorderColor == selectionBorderColor &&
          other.outsideMaskColor == outsideMaskColor &&
          other.handleColor == handleColor &&
          other.handleBorderColor == handleBorderColor &&
          other.hoverOverlayColor == hoverOverlayColor &&
          other.pressedOverlayColor == pressedOverlayColor &&
          other.focusColor == focusColor &&
          other.disabledOverlayColor == disabledOverlayColor &&
          other.borderWidth == borderWidth &&
          other.handleVisualWidth == handleVisualWidth &&
          other.handleVisualHeight == handleVisualHeight &&
          other.handleHitWidth == handleHitWidth &&
          other.borderRadius == borderRadius;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    selectionFillColor,
    selectionBorderColor,
    outsideMaskColor,
    handleColor,
    handleBorderColor,
    hoverOverlayColor,
    pressedOverlayColor,
    focusColor,
    disabledOverlayColor,
    borderWidth,
    handleVisualWidth,
    handleVisualHeight,
    handleHitWidth,
    borderRadius,
  ]);
}
