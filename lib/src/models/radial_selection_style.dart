import 'package:flutter/foundation.dart';

import '../meta/chart_surface.dart';

/// Visual treatment applied to a durably selected partition-radial slice.
///
/// Selection identity remains owned by the controller, legend, table, and
/// chart interaction model. This enum only chooses how that shared identity is
/// presented by Pie, Donut, and Concentric Donut charts.
enum RadialSelectionEffect {
  /// Translate the selected slice away from the shared center.
  explode,

  /// Scale the selected slice around its visual centroid and paint it above
  /// its siblings so it reads as moving towards the viewer.
  lift,
}

/// Presentation controls for durable partition-radial slice selection.
@immutable
@chartSurface
class RadialSelectionStyle {
  /// Creates a radial slice-selection presentation.
  const RadialSelectionStyle({
    this.effect = RadialSelectionEffect.explode,
    this.liftScale = 1.08,
    this.liftOffset = 6,
    this.backdropBlur = 1.25,
  });

  /// Spatial treatment applied to a selected slice.
  final RadialSelectionEffect effect;

  /// Final centroid-relative scale used by [RadialSelectionEffect.lift].
  final double liftScale;

  /// Final radial translation used by [RadialSelectionEffect.lift].
  ///
  /// The scale creates the towards-viewer depth cue. This independent offset
  /// pulls the raised slice slightly away from the rest of the composition.
  final double liftOffset;

  /// Blur sigma applied to unselected radial content during a lift.
  final double backdropBlur;

  /// Returns a copy with selected fields replaced.
  RadialSelectionStyle copyWith({
    RadialSelectionEffect? effect,
    double? liftScale,
    double? liftOffset,
    double? backdropBlur,
  }) => RadialSelectionStyle(
    effect: effect ?? this.effect,
    liftScale: liftScale ?? this.liftScale,
    liftOffset: liftOffset ?? this.liftOffset,
    backdropBlur: backdropBlur ?? this.backdropBlur,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RadialSelectionStyle &&
          effect == other.effect &&
          liftScale == other.liftScale &&
          liftOffset == other.liftOffset &&
          backdropBlur == other.backdropBlur;

  @override
  int get hashCode => Object.hash(effect, liftScale, liftOffset, backdropBlur);
}
