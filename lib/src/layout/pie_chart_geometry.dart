import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/chart_data_point.dart';
import '../models/pie_chart_series.dart';

const double _tau = math.pi * 2;
const double _angleEpsilon = 1e-9;

/// Immutable geometry for one visible pie slice.
class PieSliceGeometry {
  const PieSliceGeometry({
    required this.point,
    required this.pointIndex,
    required this.share,
    required this.startAngle,
    required this.sweepAngle,
    required this.midAngle,
    required this.center,
    required this.innerRadius,
    required this.outerRadius,
    required this.spacingOffset,
    required this.explodeOffset,
    required this.path,
    required this.tooltipAnchor,
    required this.insideLabelAnchor,
    required this.connectorOrigin,
    required this.outsideLabelAnchor,
  });

  /// Original, transportable source point.
  final ChartDataPoint point;

  /// Original point index, including any zero-valued points omitted from paint.
  final int pointIndex;

  /// Fraction of the validated positive total represented by this slice.
  final double share;

  /// Unmodified source start angle in radians.
  final double startAngle;

  /// Signed source sweep angle in radians.
  final double sweepAngle;

  /// Angular center in radians.
  final double midAngle;

  /// Slice center after any explode offset.
  final Offset center;

  /// Inner radius. Slice 1 keeps this at zero while retaining the radial seam.
  final double innerRadius;

  /// Outer radius in logical pixels.
  final double outerRadius;

  /// Translation that creates physical padding without sharpening the wedge.
  final Offset spacingOffset;

  /// Applied explode vector.
  final Offset explodeOffset;

  /// Closed wedge or annular-sector path.
  final Path path;

  /// Stable anchor for hover and tooltip presentation.
  final Offset tooltipAnchor;

  /// Stable candidate anchor for an inside data label.
  final Offset insideLabelAnchor;

  /// Point on the outer circumference from which a connector begins.
  final Offset connectorOrigin;

  /// Desired outside-label anchor before collision resolution.
  final Offset outsideLabelAnchor;

  /// Axis-aligned bounds of [path].
  Rect get bounds => path.getBounds();

  /// Whether [position] lies inside this gap-adjusted sector.
  bool contains(Offset position) {
    final delta = position - center;
    final radiusSquared = delta.dx * delta.dx + delta.dy * delta.dy;
    if (radiusSquared > outerRadius * outerRadius + _angleEpsilon ||
        radiusSquared < innerRadius * innerRadius - _angleEpsilon) {
      return false;
    }
    if (radiusSquared <= _angleEpsilon && innerRadius == 0) {
      return true;
    }
    final angle = math.atan2(delta.dy, delta.dx);
    return _angleIsWithinSweep(angle, startAngle, sweepAngle) &&
        path.contains(position);
  }
}

/// Immutable geometry for a complete single-ring pie.
class PieChartGeometry {
  const PieChartGeometry({
    required this.center,
    required this.innerRadius,
    required this.outerRadius,
    required this.total,
    required this.slices,
  });

  /// Shared, unexploded center of the pie.
  final Offset center;

  /// Shared inner radius.
  final double innerRadius;

  /// Shared outer radius.
  final double outerRadius;

  /// Sum of all positive contributions.
  final double total;

  /// Visible slices in source-point order.
  final List<PieSliceGeometry> slices;

  /// Returns the topmost slice containing [position], if any.
  PieSliceGeometry? sliceAt(Offset position) {
    for (final slice in slices.reversed) {
      if (slice.contains(position)) {
        return slice;
      }
    }
    return null;
  }
}

/// Pure, deterministic pie geometry calculation.
class PieChartGeometryCalculator {
  const PieChartGeometryCalculator._();

  /// Calculates visible slices within [size].
  ///
  /// [innerRadiusFactor] is an internal extension seam for a future doughnut
  /// release. Public pie configuration intentionally leaves it at zero.
  static PieChartGeometry calculate({
    required PieChartSeries series,
    required Size size,
    EdgeInsets padding = EdgeInsets.zero,
    Set<int> explodedPointIndices = const <int>{},
    double innerRadiusFactor = 0,
    double? cornerRadius,
    double animationProgress = 1,
    double selectionProgress = 1,
  }) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width < 0 ||
        size.height < 0) {
      throw ArgumentError.value(
        size,
        'size',
        'Size must be finite and positive',
      );
    }
    if (!innerRadiusFactor.isFinite ||
        innerRadiusFactor < 0 ||
        innerRadiusFactor >= 1) {
      throw ArgumentError.value(
        innerRadiusFactor,
        'innerRadiusFactor',
        'Value must be finite and in [0, 1)',
      );
    }
    if (!animationProgress.isFinite ||
        animationProgress < 0 ||
        animationProgress > 1) {
      throw ArgumentError.value(
        animationProgress,
        'animationProgress',
        'Value must be finite and in [0, 1]',
      );
    }
    if (!selectionProgress.isFinite ||
        selectionProgress < 0 ||
        selectionProgress > 1) {
      throw ArgumentError.value(
        selectionProgress,
        'selectionProgress',
        'Value must be finite and in [0, 1]',
      );
    }
    final requestedCornerRadius =
        cornerRadius ?? series.pieStyle.cornerRadius ?? 0;
    if (!requestedCornerRadius.isFinite || requestedCornerRadius < 0) {
      throw ArgumentError.value(
        requestedCornerRadius,
        'cornerRadius',
        'Value must be finite and non-negative',
      );
    }
    final paddingValues = <double>[
      padding.left,
      padding.top,
      padding.right,
      padding.bottom,
    ];
    if (paddingValues.any((value) => !value.isFinite || value < 0)) {
      throw ArgumentError.value(
        padding,
        'padding',
        'Padding must be finite and non-negative',
      );
    }

    final contentRect = Rect.fromLTRB(
      padding.left,
      padding.top,
      math.max(padding.left, size.width - padding.right),
      math.max(padding.top, size.height - padding.bottom),
    );
    final center = contentRect.center;
    final availableRadius = math.min(contentRect.width, contentRect.height) / 2;
    final visibleSliceCount = series.visiblePointIndices.length;
    final fullOuterRadius = availableRadius * series.pieStyle.radiusFactor;
    final gapInset = visibleSliceCount <= 1
        ? 0.0
        : math.min(series.pieStyle.sliceGap * 2, fullOuterRadius * 0.12);
    final outerRadius =
        math.max(0, fullOuterRadius - gapInset) * animationProgress;
    final innerRadius = outerRadius * innerRadiusFactor;
    final total = series.total;

    if (total == 0 || outerRadius <= 0) {
      return PieChartGeometry(
        center: center,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        total: total,
        slices: const <PieSliceGeometry>[],
      );
    }

    final direction = series.pieStyle.clockwise ? 1.0 : -1.0;
    var cursor = _degreesToRadians(series.pieStyle.startAngleDegrees);
    final slices = <PieSliceGeometry>[];
    for (final (pointIndex, point) in series.points.indexed) {
      if (point.y == 0) {
        continue;
      }

      final share = point.y / total;
      final rawSweepMagnitude = _tau * share;
      final startAngle = cursor;
      final sweepAngle = direction * rawSweepMagnitude;
      final midAngle = cursor + direction * rawSweepMagnitude / 2;
      final halfSweepSine = math.sin(rawSweepMagnitude / 2).abs();
      final spacingDistance = visibleSliceCount <= 1
          ? 0.0
          : math.min(
              series.pieStyle.sliceGap *
                  animationProgress /
                  (2 * math.max(0.25, halfSweepSine)),
              outerRadius * 0.12,
            );
      final spacingOffset = Offset.fromDirection(midAngle, spacingDistance);
      final explodeDistance = explodedPointIndices.contains(pointIndex)
          ? series.pieStyle.selectionExplodeOffset * selectionProgress
          : 0.0;
      final explodeOffset = Offset.fromDirection(midAngle, explodeDistance);
      final sliceCenter = center + spacingOffset + explodeOffset;
      final path = _sectorPath(
        center: sliceCenter,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        startAngle: startAngle,
        sweepAngle: sweepAngle,
        cornerRadius: requestedCornerRadius * animationProgress,
      );
      final tooltipRadius = innerRadius + (outerRadius - innerRadius) * 0.62;
      final insideRadius = innerRadius + (outerRadius - innerRadius) * 0.58;
      final connectorRadius = outerRadius;
      final outsideRadius =
          outerRadius +
          series.dataLabels.connectorLength +
          series.dataLabels.padding;

      slices.add(
        PieSliceGeometry(
          point: point,
          pointIndex: pointIndex,
          share: share,
          startAngle: startAngle,
          sweepAngle: sweepAngle,
          midAngle: midAngle,
          center: sliceCenter,
          innerRadius: innerRadius,
          outerRadius: outerRadius,
          spacingOffset: spacingOffset,
          explodeOffset: explodeOffset,
          path: path,
          tooltipAnchor:
              sliceCenter + Offset.fromDirection(midAngle, tooltipRadius),
          insideLabelAnchor:
              sliceCenter + Offset.fromDirection(midAngle, insideRadius),
          connectorOrigin:
              sliceCenter + Offset.fromDirection(midAngle, connectorRadius),
          outsideLabelAnchor:
              sliceCenter + Offset.fromDirection(midAngle, outsideRadius),
        ),
      );
      cursor += direction * rawSweepMagnitude;
    }

    return PieChartGeometry(
      center: center,
      innerRadius: innerRadius,
      outerRadius: outerRadius,
      total: total,
      slices: List<PieSliceGeometry>.unmodifiable(slices),
    );
  }
}

Path _sectorPath({
  required Offset center,
  required double innerRadius,
  required double outerRadius,
  required double startAngle,
  required double sweepAngle,
  double cornerRadius = 0,
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
    return _roundedPieSectorPath(
      center: center,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      cornerRadius: cornerRadius,
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

Path _roundedPieSectorPath({
  required Offset center,
  required double outerRadius,
  required double startAngle,
  required double sweepAngle,
  required double cornerRadius,
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
    return _sectorPath(
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
  final centerTrim = sweepMagnitude < math.pi
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

double _degreesToRadians(double degrees) => degrees * math.pi / 180;

double _normalizedAngle(double angle) {
  final normalized = angle % _tau;
  return normalized < 0 ? normalized + _tau : normalized;
}

bool _angleIsWithinSweep(double angle, double start, double sweep) {
  if (sweep.abs() >= _tau - _angleEpsilon) {
    return true;
  }
  if (sweep >= 0) {
    return _normalizedAngle(angle - start) <= sweep + _angleEpsilon;
  }
  return _normalizedAngle(start - angle) <= -sweep + _angleEpsilon;
}
