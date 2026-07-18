import 'dart:math' as math;

import 'package:flutter/widgets.dart';

const double _tau = math.pi * 2;
const double _angleEpsilon = 1e-9;

/// Pure geometry for one wedge or annular sector.
///
/// This primitive owns only polar sector shape construction and point lookup.
/// It deliberately does not know about chart data, totals, category shares,
/// grouping, axes, labels, selection, animation, or chart-family semantics.
class AnnularSectorGeometry {
  /// Creates a validated sector and its immutable calculated path.
  factory AnnularSectorGeometry({
    required Offset center,
    required double innerRadius,
    required double outerRadius,
    required double startAngle,
    required double sweepAngle,
    double cornerRadius = 0,
    bool roundInnerCorners = true,
  }) {
    if (!center.dx.isFinite || !center.dy.isFinite) {
      throw ArgumentError.value(center, 'center', 'Center must be finite');
    }
    if (!innerRadius.isFinite || innerRadius < 0) {
      throw ArgumentError.value(
        innerRadius,
        'innerRadius',
        'Value must be finite and non-negative',
      );
    }
    if (!outerRadius.isFinite || outerRadius < innerRadius) {
      throw ArgumentError.value(
        outerRadius,
        'outerRadius',
        'Value must be finite and at least innerRadius',
      );
    }
    if (!startAngle.isFinite) {
      throw ArgumentError.value(
        startAngle,
        'startAngle',
        'Value must be finite',
      );
    }
    if (!sweepAngle.isFinite || sweepAngle.abs() > _tau + _angleEpsilon) {
      throw ArgumentError.value(
        sweepAngle,
        'sweepAngle',
        'Value must be finite and no greater than one complete turn',
      );
    }
    if (!cornerRadius.isFinite || cornerRadius < 0) {
      throw ArgumentError.value(
        cornerRadius,
        'cornerRadius',
        'Value must be finite and non-negative',
      );
    }

    return AnnularSectorGeometry._(
      center: center,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      cornerRadius: cornerRadius,
      roundInnerCorners: roundInnerCorners,
      path: _buildSectorPath(
        center: center,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
        cornerRadius: cornerRadius,
        roundInnerCorners: roundInnerCorners,
      ),
    );
  }

  const AnnularSectorGeometry._({
    required this.center,
    required this.innerRadius,
    required this.outerRadius,
    required this.startAngle,
    required this.sweepAngle,
    required this.cornerRadius,
    required this.roundInnerCorners,
    required this.path,
  });

  /// Shared center of the sector's inner and outer arcs.
  final Offset center;

  /// Radius of the inner arc. Zero produces a wedge.
  final double innerRadius;

  /// Radius of the outer arc.
  final double outerRadius;

  /// Start angle in radians.
  final double startAngle;

  /// Signed sweep in radians. Positive sweeps follow Flutter's clockwise
  /// screen-coordinate direction; negative sweeps run counter-clockwise.
  final double sweepAngle;

  /// Requested corner radius before geometry-safe clamping.
  final double cornerRadius;

  /// Whether corners on the inner arc or wedge apex are rounded.
  final bool roundInnerCorners;

  /// Closed, gap-free sector path.
  final Path path;

  /// Axis-aligned bounds of [path].
  Rect get bounds => path.getBounds();

  /// Whether [position] lies inside [path].
  bool contains(Offset position) => path.contains(position);

  /// Returns a point interpolated through the angular and radial dimensions.
  Offset pointAt({double angularFraction = 0.5, double radialFraction = 0.5}) {
    _requireUnitFraction(angularFraction, 'angularFraction');
    _requireUnitFraction(radialFraction, 'radialFraction');
    final angle = startAngle + sweepAngle * angularFraction;
    final radius = innerRadius + (outerRadius - innerRadius) * radialFraction;
    return center + Offset.fromDirection(angle, radius);
  }
}

void _requireUnitFraction(double value, String name) {
  if (!value.isFinite || value < 0 || value > 1) {
    throw ArgumentError.value(
      value,
      name,
      'Value must be finite and in [0, 1]',
    );
  }
}

Path _buildSectorPath({
  required Offset center,
  required double innerRadius,
  required double outerRadius,
  required double startAngle,
  required double sweepAngle,
  double cornerRadius = 0,
  bool roundInnerCorners = true,
}) {
  final outerRect = Rect.fromCircle(center: center, radius: outerRadius);
  final path = Path();
  if (sweepAngle.abs() >= _tau - _angleEpsilon) {
    if (innerRadius > 0) {
      path.fillType = PathFillType.evenOdd;
    }
    path.addOval(outerRect);
    if (innerRadius > 0) {
      path.addOval(Rect.fromCircle(center: center, radius: innerRadius));
    }
    return path;
  }

  if (cornerRadius > 0 && innerRadius == 0) {
    return _buildRoundedPieSectorPath(
      center: center,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      cornerRadius: cornerRadius,
      roundInnerCorners: roundInnerCorners,
    );
  }
  if (cornerRadius > 0 && innerRadius > 0) {
    return _buildRoundedAnnularSectorPath(
      center: center,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      cornerRadius: cornerRadius,
      roundInnerCorners: roundInnerCorners,
    );
  }

  final outerStart = center + Offset.fromDirection(startAngle, outerRadius);
  path.moveTo(outerStart.dx, outerStart.dy);
  path.arcTo(outerRect, startAngle, sweepAngle, false);

  if (innerRadius == 0) {
    path.lineTo(center.dx, center.dy);
  } else {
    final innerEnd =
        center + Offset.fromDirection(startAngle + sweepAngle, innerRadius);
    path.lineTo(innerEnd.dx, innerEnd.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      startAngle + sweepAngle,
      -sweepAngle,
      false,
    );
  }
  path.close();
  return path;
}

Path _buildRoundedAnnularSectorPath({
  required Offset center,
  required double innerRadius,
  required double outerRadius,
  required double startAngle,
  required double sweepAngle,
  required double cornerRadius,
  required bool roundInnerCorners,
}) {
  final sweepMagnitude = sweepAngle.abs();
  final thickness = outerRadius - innerRadius;
  if (thickness <= _angleEpsilon || sweepMagnitude <= _angleEpsilon) {
    return _buildSectorPath(
      center: center,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );
  }

  final maximumByOuterSweep =
      outerRadius * math.sin(sweepMagnitude / 2).abs() * 0.45;
  final maximumByInnerSweep = roundInnerCorners
      ? innerRadius * math.sin(sweepMagnitude / 2).abs() * 0.45
      : double.infinity;
  final radius = math.min(
    cornerRadius,
    math.min(
      thickness * 0.45,
      math.min(maximumByOuterSweep, maximumByInnerSweep),
    ),
  );
  if (radius <= _angleEpsilon) {
    return _buildSectorPath(
      center: center,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );
  }

  final direction = sweepAngle.sign;
  final endAngle = startAngle + sweepAngle;
  final outerTrim = math.min(radius / outerRadius, sweepMagnitude * 0.2);
  final innerTrim = roundInnerCorners
      ? math.min(radius / innerRadius, sweepMagnitude * 0.2)
      : 0.0;
  final outerArcStartAngle = startAngle + direction * outerTrim;
  final outerArcSweep = sweepAngle - direction * outerTrim * 2;
  final outerStart = center + Offset.fromDirection(startAngle, outerRadius);
  final outerEnd = center + Offset.fromDirection(endAngle, outerRadius);
  final outerStartEdge =
      center + Offset.fromDirection(startAngle, outerRadius - radius);
  final outerEndEdge =
      center + Offset.fromDirection(endAngle, outerRadius - radius);
  final outerArcStart =
      center + Offset.fromDirection(outerArcStartAngle, outerRadius);

  final path = Path()
    ..moveTo(outerStartEdge.dx, outerStartEdge.dy)
    ..quadraticBezierTo(
      outerStart.dx,
      outerStart.dy,
      outerArcStart.dx,
      outerArcStart.dy,
    )
    ..arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      outerArcStartAngle,
      outerArcSweep,
      false,
    )
    ..quadraticBezierTo(
      outerEnd.dx,
      outerEnd.dy,
      outerEndEdge.dx,
      outerEndEdge.dy,
    );

  if (!roundInnerCorners) {
    final innerEnd = center + Offset.fromDirection(endAngle, innerRadius);
    path
      ..lineTo(innerEnd.dx, innerEnd.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        endAngle,
        -sweepAngle,
        false,
      )
      ..close();
    return path;
  }

  final innerEndOuter =
      center + Offset.fromDirection(endAngle, innerRadius + radius);
  final innerEnd = center + Offset.fromDirection(endAngle, innerRadius);
  final innerArcEndAngle = endAngle - direction * innerTrim;
  final innerArcEnd =
      center + Offset.fromDirection(innerArcEndAngle, innerRadius);
  final innerArcSweep = -sweepAngle + direction * innerTrim * 2;
  final innerStart = center + Offset.fromDirection(startAngle, innerRadius);
  final innerStartOuter =
      center + Offset.fromDirection(startAngle, innerRadius + radius);
  path
    ..lineTo(innerEndOuter.dx, innerEndOuter.dy)
    ..quadraticBezierTo(
      innerEnd.dx,
      innerEnd.dy,
      innerArcEnd.dx,
      innerArcEnd.dy,
    )
    ..arcTo(
      Rect.fromCircle(center: center, radius: innerRadius),
      innerArcEndAngle,
      innerArcSweep,
      false,
    )
    ..quadraticBezierTo(
      innerStart.dx,
      innerStart.dy,
      innerStartOuter.dx,
      innerStartOuter.dy,
    )
    ..close();
  return path;
}

Path _buildRoundedPieSectorPath({
  required Offset center,
  required double outerRadius,
  required double startAngle,
  required double sweepAngle,
  required double cornerRadius,
  required bool roundInnerCorners,
}) {
  final sweepMagnitude = sweepAngle.abs();
  final direction = sweepAngle.sign;
  final maximumBySweep =
      outerRadius * math.sin(sweepMagnitude / 2).abs() * 0.45;
  final radius = math.min(
    cornerRadius,
    math.min(outerRadius * 0.24, maximumBySweep),
  );
  if (radius <= _angleEpsilon || outerRadius <= _angleEpsilon) {
    return _buildSectorPath(
      center: center,
      innerRadius: 0,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );
  }

  final endAngle = startAngle + sweepAngle;
  final angleTrim = math.min(radius / outerRadius, sweepMagnitude * 0.2);
  final arcStartAngle = startAngle + direction * angleTrim;
  final arcSweep = sweepAngle - direction * angleTrim * 2;
  final outerStart = center + Offset.fromDirection(startAngle, outerRadius);
  final outerEnd = center + Offset.fromDirection(endAngle, outerRadius);
  final startEdge =
      center + Offset.fromDirection(startAngle, outerRadius - radius);
  final endEdge = center + Offset.fromDirection(endAngle, outerRadius - radius);
  final arcStart = center + Offset.fromDirection(arcStartAngle, outerRadius);
  final centerTrim = roundInnerCorners && sweepMagnitude < math.pi
      ? math.min(
          radius / math.max(0.2, math.tan(sweepMagnitude / 2)),
          outerRadius * 0.32,
        )
      : 0.0;
  final centerStart = center + Offset.fromDirection(startAngle, centerTrim);
  final centerEnd = center + Offset.fromDirection(endAngle, centerTrim);

  final path = Path()
    ..moveTo(centerStart.dx, centerStart.dy)
    ..lineTo(startEdge.dx, startEdge.dy)
    ..quadraticBezierTo(outerStart.dx, outerStart.dy, arcStart.dx, arcStart.dy)
    ..arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      arcStartAngle,
      arcSweep,
      false,
    )
    ..quadraticBezierTo(outerEnd.dx, outerEnd.dy, endEdge.dx, endEdge.dy)
    ..lineTo(centerEnd.dx, centerEnd.dy);
  if (centerTrim > 0) {
    path.quadraticBezierTo(
      center.dx,
      center.dy,
      centerStart.dx,
      centerStart.dy,
    );
  } else {
    path.lineTo(center.dx, center.dy);
  }
  return path..close();
}
