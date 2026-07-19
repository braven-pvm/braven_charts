import 'dart:math' as math;

import 'package:flutter/widgets.dart';

const double _tau = math.pi * 2;
const double _angleEpsilon = 1e-9;

/// Immutable layout frame shared by axis-based polar chart families.
///
/// The pane owns only viewport allocation and angular/radial geometry. It does
/// not know about series data, scales, ticks, labels, marks, or interaction.
@immutable
class RadialPaneGeometry {
  /// Validates and resolves a pane inside [viewportBounds].
  factory RadialPaneGeometry.resolve({
    required Rect viewportBounds,
    EdgeInsets viewportInsets = EdgeInsets.zero,
    EdgeInsets reservedLabelInsets = EdgeInsets.zero,
    double innerRadiusFactor = 0,
    double outerRadiusFactor = 1,
    double startAngle = -math.pi / 2,
    double sweepAngle = _tau,
    bool clockwise = true,
  }) {
    _validateBounds(viewportBounds);
    _validateInsets(viewportInsets, 'viewportInsets');
    _validateInsets(reservedLabelInsets, 'reservedLabelInsets');
    _validateRadiusFactors(
      innerRadiusFactor: innerRadiusFactor,
      outerRadiusFactor: outerRadiusFactor,
    );
    if (!startAngle.isFinite) {
      throw ArgumentError.value(
        startAngle,
        'startAngle',
        'Value must be finite',
      );
    }
    if (!sweepAngle.isFinite ||
        sweepAngle <= 0 ||
        sweepAngle > _tau + _angleEpsilon) {
      throw ArgumentError.value(
        sweepAngle,
        'sweepAngle',
        'Value must be finite and in (0, 2*pi]',
      );
    }

    final combinedInsets = EdgeInsets.fromLTRB(
      viewportInsets.left + reservedLabelInsets.left,
      viewportInsets.top + reservedLabelInsets.top,
      viewportInsets.right + reservedLabelInsets.right,
      viewportInsets.bottom + reservedLabelInsets.bottom,
    );
    final availableBounds = Rect.fromLTRB(
      viewportBounds.left + combinedInsets.left,
      viewportBounds.top + combinedInsets.top,
      viewportBounds.right - combinedInsets.right,
      viewportBounds.bottom - combinedInsets.bottom,
    );
    if (!availableBounds.width.isFinite ||
        !availableBounds.height.isFinite ||
        availableBounds.width <= 0 ||
        availableBounds.height <= 0) {
      throw ArgumentError.value(
        combinedInsets,
        'viewportInsets + reservedLabelInsets',
        'Insets must leave positive finite pane bounds',
      );
    }

    final center = availableBounds.center;
    final availableOuterRadius =
        math.min(availableBounds.width, availableBounds.height) / 2;
    final innerRadius = availableOuterRadius * innerRadiusFactor;
    final outerRadius = availableOuterRadius * outerRadiusFactor;

    return RadialPaneGeometry._(
      viewportBounds: viewportBounds,
      viewportInsets: viewportInsets,
      reservedLabelInsets: reservedLabelInsets,
      availableBounds: availableBounds,
      center: center,
      availableOuterRadius: availableOuterRadius,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: math.min(sweepAngle, _tau),
      clockwise: clockwise,
    );
  }

  const RadialPaneGeometry._({
    required this.viewportBounds,
    required this.viewportInsets,
    required this.reservedLabelInsets,
    required this.availableBounds,
    required this.center,
    required this.availableOuterRadius,
    required this.innerRadius,
    required this.outerRadius,
    required this.startAngle,
    required this.sweepAngle,
    required this.clockwise,
  });

  /// Full bounds offered to the radial pane before internal reservations.
  final Rect viewportBounds;

  /// Space reserved for pane overflow such as selection or clipping margins.
  final EdgeInsets viewportInsets;

  /// Space reserved for labels outside the radial plot.
  final EdgeInsets reservedLabelInsets;

  /// Remaining rectangular bounds after both inset layers are applied.
  final Rect availableBounds;

  /// Center of the largest circle that fits inside [availableBounds].
  final Offset center;

  /// Radius of that largest fitting circle before radius factors are applied.
  final double availableOuterRadius;

  /// Resolved inner plotting radius in logical pixels.
  final double innerRadius;

  /// Resolved outer plotting radius in logical pixels.
  final double outerRadius;

  /// Start angle in Flutter canvas radians.
  final double startAngle;

  /// Positive angular span in radians.
  final double sweepAngle;

  /// Whether increasing angular fractions follow Flutter's clockwise direction.
  final bool clockwise;

  /// Square bounds of the complete available radial pane.
  Rect get plotBounds =>
      Rect.fromCircle(center: center, radius: availableOuterRadius);

  /// Bounds of the configured outer mark radius.
  Rect get markBounds => Rect.fromCircle(center: center, radius: outerRadius);

  /// Signed angular span used by canvas geometry.
  double get signedSweepAngle => clockwise ? sweepAngle : -sweepAngle;

  /// End angle reached after applying [signedSweepAngle].
  double get endAngle => startAngle + signedSweepAngle;

  /// Returns the canvas angle at an angular fraction through this pane.
  double angleAt(double angularFraction) {
    _validateUnitFraction(angularFraction, 'angularFraction');
    return startAngle + signedSweepAngle * angularFraction;
  }
}

void _validateBounds(Rect bounds) {
  final values = [bounds.left, bounds.top, bounds.right, bounds.bottom];
  if (values.any((value) => !value.isFinite) ||
      bounds.width <= 0 ||
      bounds.height <= 0) {
    throw ArgumentError.value(
      bounds,
      'viewportBounds',
      'Bounds must be finite with positive width and height',
    );
  }
}

void _validateInsets(EdgeInsets insets, String name) {
  final values = [insets.left, insets.top, insets.right, insets.bottom];
  if (values.any((value) => !value.isFinite || value < 0)) {
    throw ArgumentError.value(
      insets,
      name,
      'Insets must be finite and non-negative',
    );
  }
}

void _validateRadiusFactors({
  required double innerRadiusFactor,
  required double outerRadiusFactor,
}) {
  if (!innerRadiusFactor.isFinite ||
      innerRadiusFactor < 0 ||
      innerRadiusFactor >= 1) {
    throw ArgumentError.value(
      innerRadiusFactor,
      'innerRadiusFactor',
      'Value must be finite and in [0, 1)',
    );
  }
  if (!outerRadiusFactor.isFinite ||
      outerRadiusFactor <= 0 ||
      outerRadiusFactor > 1) {
    throw ArgumentError.value(
      outerRadiusFactor,
      'outerRadiusFactor',
      'Value must be finite and in (0, 1]',
    );
  }
  if (innerRadiusFactor >= outerRadiusFactor) {
    throw ArgumentError.value(
      '$innerRadiusFactor >= $outerRadiusFactor',
      'innerRadiusFactor',
      'Inner radius factor must be smaller than outer radius factor',
    );
  }
}

void _validateUnitFraction(double value, String name) {
  if (!value.isFinite || value < 0 || value > 1) {
    throw ArgumentError.value(
      value,
      name,
      'Value must be finite and in [0, 1]',
    );
  }
}
