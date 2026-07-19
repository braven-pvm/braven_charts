import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../layout/radial_pane_geometry.dart';

/// Mapping used by a radial numeric axis.
enum PolarNumericScaleMode {
  /// Equal value differences produce equal radial distances.
  linear,

  /// Equal value proportions produce equal annular-sector areas.
  areaCorrect,
}

/// Maps a non-negative numeric domain into the real radii of a radial pane.
///
/// Mapping into physical radii, rather than an abstract square-root fraction,
/// keeps [PolarNumericScaleMode.areaCorrect] statistically correct when the
/// pane has a non-zero inner radius.
@immutable
class PolarNumericScale {
  /// Creates a validated numeric scale for [pane].
  factory PolarNumericScale({
    required RadialPaneGeometry pane,
    required double minimum,
    required double maximum,
    PolarNumericScaleMode mode = PolarNumericScaleMode.linear,
  }) {
    _validateDomain(minimum: minimum, maximum: maximum);
    return PolarNumericScale._(
      pane: pane,
      minimum: minimum,
      maximum: maximum,
      mode: mode,
    );
  }

  /// Derives a stable V1 domain from [values].
  ///
  /// The default baseline is zero. Empty and all-zero datasets use `[0, 1]`
  /// so layout, ticks, and empty-state transitions remain finite.
  factory PolarNumericScale.fromValues({
    required RadialPaneGeometry pane,
    required Iterable<double> values,
    double? minimum,
    double? maximum,
    PolarNumericScaleMode mode = PolarNumericScaleMode.linear,
  }) {
    final snapshot = List<double>.unmodifiable(values);
    for (final (index, value) in snapshot.indexed) {
      if (!value.isFinite || value < 0) {
        throw ArgumentError.value(
          value,
          'values[$index]',
          'Polar Column V1 values must be finite and non-negative',
        );
      }
    }

    final resolvedMinimum = minimum ?? 0;
    var resolvedMaximum = maximum;
    if (resolvedMaximum == null) {
      final dataMaximum = snapshot.isEmpty
          ? resolvedMinimum
          : snapshot.reduce(math.max);
      resolvedMaximum = dataMaximum > resolvedMinimum
          ? dataMaximum
          : resolvedMinimum + math.max(resolvedMinimum.abs() * 0.1, 1);
    }
    return PolarNumericScale(
      pane: pane,
      minimum: resolvedMinimum,
      maximum: resolvedMaximum,
      mode: mode,
    );
  }

  const PolarNumericScale._({
    required this.pane,
    required this.minimum,
    required this.maximum,
    required this.mode,
  });

  /// Pane whose radii define the output range.
  final RadialPaneGeometry pane;

  /// Inclusive lower domain boundary.
  final double minimum;

  /// Inclusive upper domain boundary.
  final double maximum;

  /// Radial mapping applied between [minimum] and [maximum].
  final PolarNumericScaleMode mode;

  /// Numeric domain span.
  double get domainSpan => maximum - minimum;

  /// Converts [value] to a physical pane radius.
  ///
  /// Finite values outside the configured domain clamp to the nearest edge.
  /// Negative values remain invalid for Polar Column V1.
  double valueToRadius(double value) {
    _validateValue(value);
    final normalized = ((value - minimum) / domainSpan).clamp(0.0, 1.0);
    return switch (mode) {
      PolarNumericScaleMode.linear =>
        pane.innerRadius + normalized * (pane.outerRadius - pane.innerRadius),
      PolarNumericScaleMode.areaCorrect => math.sqrt(
        pane.innerRadius * pane.innerRadius +
            normalized *
                (pane.outerRadius * pane.outerRadius -
                    pane.innerRadius * pane.innerRadius),
      ),
    };
  }

  /// Converts a physical [radius] back to its clamped domain value.
  double radiusToValue(double radius) {
    _validateRadius(radius);
    final clamped = radius.clamp(pane.innerRadius, pane.outerRadius);
    final normalized = switch (mode) {
      PolarNumericScaleMode.linear =>
        (clamped - pane.innerRadius) / (pane.outerRadius - pane.innerRadius),
      PolarNumericScaleMode.areaCorrect =>
        (clamped * clamped - pane.innerRadius * pane.innerRadius) /
            (pane.outerRadius * pane.outerRadius -
                pane.innerRadius * pane.innerRadius),
    };
    return minimum + normalized * domainSpan;
  }

  /// Converts [value] to the pane's linear radial fraction in `[0, 1]`.
  double valueToRadialFraction(double value) {
    final radius = valueToRadius(value);
    return (radius - pane.innerRadius) / (pane.outerRadius - pane.innerRadius);
  }

  /// Converts a pane [fraction] back to its numeric value.
  double radialFractionToValue(double fraction) {
    _validateUnitFraction(fraction, 'fraction');
    final radius =
        pane.innerRadius + fraction * (pane.outerRadius - pane.innerRadius);
    return radiusToValue(radius);
  }
}

void _validateDomain({required double minimum, required double maximum}) {
  if (!minimum.isFinite || minimum < 0) {
    throw ArgumentError.value(
      minimum,
      'minimum',
      'Polar Column V1 minimum must be finite and non-negative',
    );
  }
  if (!maximum.isFinite || maximum <= minimum) {
    throw ArgumentError.value(
      maximum,
      'maximum',
      'Maximum must be finite and greater than minimum',
    );
  }
}

void _validateValue(double value) {
  if (!value.isFinite || value < 0) {
    throw ArgumentError.value(
      value,
      'value',
      'Polar Column V1 values must be finite and non-negative',
    );
  }
}

void _validateRadius(double radius) {
  if (!radius.isFinite || radius < 0) {
    throw ArgumentError.value(
      radius,
      'radius',
      'Radius must be finite and non-negative',
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
