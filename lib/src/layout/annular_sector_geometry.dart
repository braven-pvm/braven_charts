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
    bool roundOuterCorners = true,
    bool roundInnerCorners = true,
    double seamInset = 0,
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
    if (!seamInset.isFinite || seamInset < 0) {
      throw ArgumentError.value(
        seamInset,
        'seamInset',
        'Value must be finite and non-negative',
      );
    }

    final effectiveSeamInset = _effectiveSeamInset(
      requested: seamInset,
      innerRadius: innerRadius,
      sweepAngle: sweepAngle,
    );

    return AnnularSectorGeometry._(
      center: center,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      cornerRadius: cornerRadius,
      roundOuterCorners: roundOuterCorners,
      roundInnerCorners: roundInnerCorners,
      seamInset: effectiveSeamInset,
      path: _buildSectorPath(
        center: center,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
        cornerRadius: cornerRadius,
        roundOuterCorners: roundOuterCorners,
        roundInnerCorners: roundInnerCorners,
        seamInset: effectiveSeamInset,
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
    required this.roundOuterCorners,
    required this.roundInnerCorners,
    required this.seamInset,
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

  /// Whether corners on the outer arc are rounded.
  final bool roundOuterCorners;

  /// Whether corners on the inner arc or wedge apex are rounded.
  final bool roundInnerCorners;

  /// Physical inset applied to each straight annular seam.
  ///
  /// Adjacent sectors normally use half the requested slice gap. Moving both
  /// sides along the shared boundary normal keeps them parallel and produces
  /// one constant-width channel instead of an outward-widening angular wedge.
  final double seamInset;

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
  bool roundOuterCorners = true,
  bool roundInnerCorners = true,
  double seamInset = 0,
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

  if (seamInset > _angleEpsilon && innerRadius > _angleEpsilon) {
    return _buildParallelSeamAnnularSectorPath(
      center: center,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      seamInset: seamInset,
      cornerRadius: cornerRadius,
      roundOuterCorners: roundOuterCorners,
      roundInnerCorners: roundInnerCorners,
    );
  }

  if (cornerRadius > 0 && innerRadius == 0) {
    return _buildRoundedPieSectorPath(
      center: center,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      cornerRadius: cornerRadius,
      roundOuterCorners: roundOuterCorners,
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
      roundOuterCorners: roundOuterCorners,
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

double _effectiveSeamInset({
  required double requested,
  required double innerRadius,
  required double sweepAngle,
}) {
  final sweepMagnitude = sweepAngle.abs();
  if (requested <= _angleEpsilon ||
      innerRadius <= _angleEpsilon ||
      sweepMagnitude <= _angleEpsilon ||
      sweepMagnitude >= _tau - _angleEpsilon) {
    return 0;
  }

  // Retain at least 20% of a narrow slice at its limiting inner arc. The
  // additional 95% radius cap keeps square roots and arc endpoints stable for
  // unusually large requested gaps on broad slices.
  final maximumTrim = math.min(sweepMagnitude * 0.4, math.pi / 2);
  final maximumBySweep = innerRadius * math.sin(maximumTrim);
  return math.min(requested, math.min(maximumBySweep, innerRadius * 0.95));
}

Path _buildParallelSeamAnnularSectorPath({
  required Offset center,
  required double innerRadius,
  required double outerRadius,
  required double startAngle,
  required double sweepAngle,
  required double seamInset,
  required double cornerRadius,
  required bool roundOuterCorners,
  required bool roundInnerCorners,
}) {
  final direction = sweepAngle.sign;
  final endAngle = startAngle + sweepAngle;
  final startRadial = Offset.fromDirection(startAngle, 1);
  final endRadial = Offset.fromDirection(endAngle, 1);
  final startNormal = Offset(-startRadial.dy, startRadial.dx);
  final endNormal = Offset(-endRadial.dy, endRadial.dx);
  final startLineOffset = startNormal * (direction * seamInset);
  final endLineOffset = endNormal * (-direction * seamInset);
  final outerLineDistance = math.sqrt(
    math.max(0, outerRadius * outerRadius - seamInset * seamInset),
  );
  final innerLineDistance = math.sqrt(
    math.max(0, innerRadius * innerRadius - seamInset * seamInset),
  );

  final outerStart = center + startLineOffset + startRadial * outerLineDistance;
  final outerEnd = center + endLineOffset + endRadial * outerLineDistance;
  final innerEnd = center + endLineOffset + endRadial * innerLineDistance;
  final innerStart = center + startLineOffset + startRadial * innerLineDistance;
  final outerSeamTrim = math.asin(seamInset / outerRadius);
  final innerSeamTrim = math.asin(seamInset / innerRadius);
  final outerStartAngle = startAngle + direction * outerSeamTrim;
  final innerEndAngle = endAngle - direction * innerSeamTrim;
  final outerSweep = sweepAngle - direction * outerSeamTrim * 2;
  final innerSweep = -sweepAngle + direction * innerSeamTrim * 2;

  final sideLength = math.max(0, outerLineDistance - innerLineDistance);
  if (!roundOuterCorners && !roundInnerCorners) {
    return Path()
      ..moveTo(outerStart.dx, outerStart.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        outerStartAngle,
        outerSweep,
        false,
      )
      ..lineTo(innerEnd.dx, innerEnd.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        innerEndAngle,
        innerSweep,
        false,
      )
      ..close();
  }

  final maximumOuterCorner = roundOuterCorners
      ? outerRadius * outerSweep.abs() * 0.2
      : double.infinity;
  final maximumInnerCorner = roundInnerCorners
      ? innerRadius * innerSweep.abs() * 0.2
      : double.infinity;
  final radius = math.min(
    cornerRadius,
    math.min(
      sideLength * 0.45,
      math.min(maximumOuterCorner, maximumInnerCorner),
    ),
  );

  if (radius <= _angleEpsilon) {
    return Path()
      ..moveTo(outerStart.dx, outerStart.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        outerStartAngle,
        outerSweep,
        false,
      )
      ..lineTo(innerEnd.dx, innerEnd.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        innerEndAngle,
        innerSweep,
        false,
      )
      ..close();
  }

  final outerCornerTrim = roundOuterCorners
      ? math.min(radius / outerRadius, outerSweep.abs() * 0.2)
      : 0.0;
  final innerCornerTrim = roundInnerCorners
      ? math.min(radius / innerRadius, innerSweep.abs() * 0.2)
      : 0.0;
  final roundedOuterStartAngle = outerStartAngle + direction * outerCornerTrim;
  final roundedOuterSweep = outerSweep - direction * outerCornerTrim * 2;
  final outerStartEdge = roundOuterCorners
      ? outerStart - startRadial * radius
      : outerStart;
  final outerEndEdge = roundOuterCorners
      ? outerEnd - endRadial * radius
      : outerEnd;
  final outerArcStart =
      center + Offset.fromDirection(roundedOuterStartAngle, outerRadius);

  final path = Path()..moveTo(outerStartEdge.dx, outerStartEdge.dy);
  if (roundOuterCorners) {
    path
      ..quadraticBezierTo(
        outerStart.dx,
        outerStart.dy,
        outerArcStart.dx,
        outerArcStart.dy,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        roundedOuterStartAngle,
        roundedOuterSweep,
        false,
      )
      ..quadraticBezierTo(
        outerEnd.dx,
        outerEnd.dy,
        outerEndEdge.dx,
        outerEndEdge.dy,
      );
  } else {
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      outerStartAngle,
      outerSweep,
      false,
    );
  }

  if (!roundInnerCorners) {
    return path
      ..lineTo(innerEnd.dx, innerEnd.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: innerRadius),
        innerEndAngle,
        innerSweep,
        false,
      )
      ..close();
  }

  final innerEndOuter = innerEnd + endRadial * radius;
  final innerStartOuter = innerStart + startRadial * radius;
  final roundedInnerEndAngle = innerEndAngle - direction * innerCornerTrim;
  final roundedInnerSweep = innerSweep + direction * innerCornerTrim * 2;
  final innerArcEnd =
      center + Offset.fromDirection(roundedInnerEndAngle, innerRadius);
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
      roundedInnerEndAngle,
      roundedInnerSweep,
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

Path _buildRoundedAnnularSectorPath({
  required Offset center,
  required double innerRadius,
  required double outerRadius,
  required double startAngle,
  required double sweepAngle,
  required double cornerRadius,
  required bool roundOuterCorners,
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

  if (!roundOuterCorners && !roundInnerCorners) {
    return _buildSectorPath(
      center: center,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );
  }

  final maximumByOuterSweep = roundOuterCorners
      ? outerRadius * math.sin(sweepMagnitude / 2).abs() * 0.45
      : double.infinity;
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
  final outerTrim = roundOuterCorners
      ? math.min(radius / outerRadius, sweepMagnitude * 0.2)
      : 0.0;
  final innerTrim = roundInnerCorners
      ? math.min(radius / innerRadius, sweepMagnitude * 0.2)
      : 0.0;
  final outerArcStartAngle = startAngle + direction * outerTrim;
  final outerArcSweep = sweepAngle - direction * outerTrim * 2;
  final outerStart = center + Offset.fromDirection(startAngle, outerRadius);
  final outerEnd = center + Offset.fromDirection(endAngle, outerRadius);
  final outerStartEdge =
      center +
      Offset.fromDirection(
        startAngle,
        roundOuterCorners ? outerRadius - radius : outerRadius,
      );
  final outerEndEdge =
      center +
      Offset.fromDirection(
        endAngle,
        roundOuterCorners ? outerRadius - radius : outerRadius,
      );
  final outerArcStart =
      center + Offset.fromDirection(outerArcStartAngle, outerRadius);

  final path = Path()..moveTo(outerStartEdge.dx, outerStartEdge.dy);
  if (roundOuterCorners) {
    path
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
  } else {
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepAngle,
      false,
    );
  }

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
  required bool roundOuterCorners,
  required bool roundInnerCorners,
}) {
  final sweepMagnitude = sweepAngle.abs();
  final direction = sweepAngle.sign;
  if (!roundOuterCorners && !roundInnerCorners) {
    return _buildSectorPath(
      center: center,
      innerRadius: 0,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
    );
  }
  final maximumBySweep = roundOuterCorners
      ? outerRadius * math.sin(sweepMagnitude / 2).abs() * 0.45
      : double.infinity;
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
  final angleTrim = roundOuterCorners
      ? math.min(radius / outerRadius, sweepMagnitude * 0.2)
      : 0.0;
  final arcStartAngle = startAngle + direction * angleTrim;
  final arcSweep = sweepAngle - direction * angleTrim * 2;
  final outerStart = center + Offset.fromDirection(startAngle, outerRadius);
  final outerEnd = center + Offset.fromDirection(endAngle, outerRadius);
  final startEdge =
      center +
      Offset.fromDirection(
        startAngle,
        roundOuterCorners ? outerRadius - radius : outerRadius,
      );
  final endEdge =
      center +
      Offset.fromDirection(
        endAngle,
        roundOuterCorners ? outerRadius - radius : outerRadius,
      );
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
    ..lineTo(startEdge.dx, startEdge.dy);
  if (roundOuterCorners) {
    path
      ..quadraticBezierTo(
        outerStart.dx,
        outerStart.dy,
        arcStart.dx,
        arcStart.dy,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: outerRadius),
        arcStartAngle,
        arcSweep,
        false,
      )
      ..quadraticBezierTo(outerEnd.dx, outerEnd.dy, endEdge.dx, endEdge.dy);
  } else {
    path.arcTo(
      Rect.fromCircle(center: center, radius: outerRadius),
      startAngle,
      sweepAngle,
      false,
    );
  }
  path.lineTo(centerEnd.dx, centerEnd.dy);
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
