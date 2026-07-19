import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../layout/radial_pane_geometry.dart';

const double _tau = math.pi * 2;
const double _epsilon = 1e-9;

/// Raw polar coordinate resolved around a radial pane center.
@immutable
class PolarCoordinate {
  /// Creates an immutable coordinate using radians and logical pixels.
  const PolarCoordinate({required this.angle, required this.radius});

  /// Normalized canvas angle in `[0, 2*pi)`.
  final double angle;

  /// Distance from the pane center in logical pixels.
  final double radius;
}

/// Coordinate expressed in both raw and pane-normalized polar space.
@immutable
class PolarPaneCoordinate extends PolarCoordinate {
  /// Creates an immutable coordinate known to lie within a radial pane.
  const PolarPaneCoordinate({
    required super.angle,
    required super.radius,
    required this.angularFraction,
    required this.radialFraction,
  });

  /// Progress through the pane sweep in `[0, 1]`.
  final double angularFraction;

  /// Progress from the configured inner radius to outer radius in `[0, 1]`.
  final double radialFraction;
}

/// Bidirectional conversion between polar pane space and plot pixels.
///
/// This transform owns coordinate conversion only. Category/numeric scales map
/// data into normalized fractions before using this class.
@immutable
class PolarTransform {
  /// Creates a transform for [pane].
  const PolarTransform(this.pane);

  /// Resolved radial frame used by this transform.
  final RadialPaneGeometry pane;

  /// Converts a raw polar coordinate to a plot position.
  Offset toPlot({required double angle, required double radius}) {
    if (!angle.isFinite) {
      throw ArgumentError.value(angle, 'angle', 'Value must be finite');
    }
    if (!radius.isFinite || radius < 0) {
      throw ArgumentError.value(
        radius,
        'radius',
        'Value must be finite and non-negative',
      );
    }
    return pane.center + Offset.fromDirection(angle, radius);
  }

  /// Converts a plot position into raw polar space around [pane].
  PolarCoordinate fromPlot(Offset position) {
    _validatePosition(position);
    final delta = position - pane.center;
    return PolarCoordinate(
      angle: _normalizeAngle(math.atan2(delta.dy, delta.dx)),
      radius: delta.distance,
    );
  }

  /// Converts normalized angular and radial pane fractions to plot pixels.
  Offset normalizedToPlot({
    required double angularFraction,
    required double radialFraction,
  }) {
    _validateUnitFraction(angularFraction, 'angularFraction');
    _validateUnitFraction(radialFraction, 'radialFraction');
    final radius =
        pane.innerRadius +
        (pane.outerRadius - pane.innerRadius) * radialFraction;
    return toPlot(angle: pane.angleAt(angularFraction), radius: radius);
  }

  /// Converts [position] to normalized pane space for hit testing.
  ///
  /// Returns `null` when the position lies outside the configured radial band
  /// or angular sweep.
  PolarPaneCoordinate? plotToPane(Offset position) {
    final coordinate = fromPlot(position);
    if (coordinate.radius < pane.innerRadius - _epsilon ||
        coordinate.radius > pane.outerRadius + _epsilon) {
      return null;
    }

    final angularFraction = _angularFraction(coordinate);
    if (angularFraction == null) return null;
    final radialSpan = pane.outerRadius - pane.innerRadius;
    final radialFraction = ((coordinate.radius - pane.innerRadius) / radialSpan)
        .clamp(0.0, 1.0);

    return PolarPaneCoordinate(
      angle: coordinate.angle,
      radius: coordinate.radius,
      angularFraction: angularFraction,
      radialFraction: radialFraction,
    );
  }

  /// Whether [position] lies inside the configured radial and angular pane.
  bool contains(Offset position) => plotToPane(position) != null;

  double? _angularFraction(PolarCoordinate coordinate) {
    if (coordinate.radius <= _epsilon && pane.innerRadius == 0) return 0;

    var delta = pane.clockwise
        ? _normalizeAngle(coordinate.angle - pane.startAngle)
        : _normalizeAngle(pane.startAngle - coordinate.angle);
    if (delta >= _tau - _epsilon) delta = 0;

    final fullSweep = (pane.sweepAngle - _tau).abs() <= _epsilon;
    if (!fullSweep && delta > pane.sweepAngle + _epsilon) return null;
    return (delta / pane.sweepAngle).clamp(0.0, 1.0);
  }
}

double _normalizeAngle(double angle) {
  final normalized = angle % _tau;
  return normalized < 0 ? normalized + _tau : normalized;
}

void _validatePosition(Offset position) {
  if (!position.dx.isFinite || !position.dy.isFinite) {
    throw ArgumentError.value(
      position,
      'position',
      'Coordinates must be finite',
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
