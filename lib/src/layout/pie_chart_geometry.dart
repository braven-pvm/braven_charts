import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/chart_data_point.dart';
import '../models/pie_chart_config.dart';
import '../models/radial_category_series.dart';

const double _tau = math.pi * 2;
const double _angleEpsilon = 1e-9;

/// Immutable geometry for one visible pie slice.
class PieSliceGeometry {
  const PieSliceGeometry({
    required this.point,
    required this.pointIndex,
    required this.sourcePointIndices,
    required this.share,
    required this.startAngle,
    required this.sweepAngle,
    required this.midAngle,
    required this.center,
    required this.innerRadius,
    required this.outerRadius,
    required this.radiusFactor,
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

  /// Original point indices represented by this visible slice.
  final List<int> sourcePointIndices;

  /// Whether this visible slice aggregates multiple source categories.
  bool get isGrouped => sourcePointIndices.length > 1;

  /// Fraction of the validated positive total represented by this slice.
  final double share;

  /// Unmodified source start angle in radians.
  final double startAngle;

  /// Signed rendered sweep angle in radians.
  ///
  /// During a [PieAnimationMode.sweep] entrance, the active edge slice can be
  /// smaller than its final source share until the reveal completes.
  final double sweepAngle;

  /// Angular center in radians.
  final double midAngle;

  /// Slice center after any explode offset.
  final Offset center;

  /// Inner radius. Slice 1 keeps this at zero while retaining the radial seam.
  final double innerRadius;

  /// Outer radius in logical pixels.
  final double outerRadius;

  /// Normalized radius multiplier applied to this slice before spacing.
  ///
  /// Uniform Pie slices use 1. Variable-radius slices map their second metric
  /// into the configured minimum-to-maximum range.
  final double radiusFactor;

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
  bool contains(Offset position) => path.contains(position);
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

  /// Maximum outer radius available to any slice.
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
  /// [innerRadiusFactor] can override the series contract in focused geometry
  /// tests. Production callers use the value declared by the radial series.
  static PieChartGeometry calculate({
    required RadialCategorySeries series,
    required Size size,
    EdgeInsets padding = EdgeInsets.zero,
    Set<int> explodedPointIndices = const <int>{},
    double? innerRadiusFactor,
    double? cornerRadius,
    PieCornerTreatment? cornerTreatment,
    PieAnimationMode animationMode = PieAnimationMode.grow,
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
    final effectiveInnerRadiusFactor =
        innerRadiusFactor ?? series.innerRadiusFactor;
    if (!effectiveInnerRadiusFactor.isFinite ||
        effectiveInnerRadiusFactor < 0 ||
        effectiveInnerRadiusFactor >= 1) {
      throw ArgumentError.value(
        effectiveInnerRadiusFactor,
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
        cornerRadius ?? series.radialStyle.cornerRadius ?? 0;
    final effectiveCornerTreatment =
        cornerTreatment ??
        series.radialStyle.cornerTreatment ??
        PieCornerTreatment.roundAll;
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

    final geometryProgress = animationMode == PieAnimationMode.grow
        ? animationProgress
        : 1.0;
    final sweepRevealProgress = animationMode == PieAnimationMode.sweep
        ? animationProgress
        : 1.0;
    final contentRect = Rect.fromLTRB(
      padding.left,
      padding.top,
      math.max(padding.left, size.width - padding.right),
      math.max(padding.top, size.height - padding.bottom),
    );
    final center = contentRect.center;
    final availableRadius = math.min(contentRect.width, contentRect.height) / 2;
    final visibleSlices = series.visibleSlices;
    final visibleSliceCount = visibleSlices.length;
    final fullOuterRadius = availableRadius * series.radialStyle.radiusFactor;
    final outerRadius = fullOuterRadius * geometryProgress;
    final configuredInnerRadius = outerRadius * effectiveInnerRadiusFactor;
    final total = series.total;
    final sliceRadiusFactors = _sliceRadiusFactors(series);
    final effectiveCornerRadius = requestedCornerRadius * geometryProgress;
    final circularCenterRadius =
        effectiveCornerTreatment == PieCornerTreatment.circularCenter &&
            configuredInnerRadius <= _angleEpsilon
        ? _circularCenterGapRadius(
            series: series,
            total: total,
            outerRadius: outerRadius,
            sliceRadiusFactors: sliceRadiusFactors,
            cornerRadius: effectiveCornerRadius,
            animationProgress: geometryProgress,
          )
        : 0.0;
    final innerRadius = math.max(configuredInnerRadius, circularCenterRadius);

    if (total == 0 || outerRadius <= 0) {
      return PieChartGeometry(
        center: center,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        total: total,
        slices: const <PieSliceGeometry>[],
      );
    }

    final direction = series.radialStyle.clockwise ? 1.0 : -1.0;
    final configuredSweep = _degreesToRadians(series.sweepAngleDegrees);
    final revealBudget = configuredSweep * sweepRevealProgress;
    var consumedSweep = 0.0;
    var cursor = _degreesToRadians(series.radialStyle.startAngleDegrees);
    final slices = <PieSliceGeometry>[];
    for (final projectedSlice in visibleSlices) {
      final point = projectedSlice.point;
      final pointIndex = projectedSlice.pointIndex;

      final share = point.y / total;
      final sliceRadiusFactor = sliceRadiusFactors[pointIndex] ?? 1;
      final sliceFullOuterRadius =
          configuredInnerRadius +
          (outerRadius - configuredInnerRadius) * sliceRadiusFactor;
      final rawSweepMagnitude = configuredSweep * share;
      final revealedSweepMagnitude = math.min(
        rawSweepMagnitude,
        math.max(0.0, revealBudget - consumedSweep),
      );
      consumedSweep += rawSweepMagnitude;
      final startAngle = cursor;
      cursor += direction * rawSweepMagnitude;
      if (revealedSweepMagnitude <= _angleEpsilon) {
        continue;
      }
      final sliceRevealProgress = rawSweepMagnitude <= _angleEpsilon
          ? 1.0
          : (revealedSweepMagnitude / rawSweepMagnitude).clamp(0.0, 1.0);
      final sweepAngle = direction * revealedSweepMagnitude;
      final midAngle = startAngle + direction * revealedSweepMagnitude / 2;
      final isAnnular = configuredInnerRadius > _angleEpsilon;
      final angularGap = isAnnular
          ? _annularSliceGapAngle(
              sliceGap: series.radialStyle.sliceGap,
              animationProgress: geometryProgress * sliceRevealProgress,
              visibleSliceCount: visibleSliceCount,
              sweepMagnitude: revealedSweepMagnitude,
              innerRadius: configuredInnerRadius,
              outerRadius: sliceFullOuterRadius,
            )
          : 0.0;
      final pathStartAngle = startAngle + direction * angularGap / 2;
      final pathSweepAngle =
          direction * math.max(0, revealedSweepMagnitude - angularGap);
      final spacingDistance = isAnnular
          ? 0.0
          : _sliceSpacingDistance(
              sliceGap: series.radialStyle.sliceGap,
              animationProgress: geometryProgress * sliceRevealProgress,
              visibleSliceCount: visibleSliceCount,
              sweepMagnitude: revealedSweepMagnitude,
              sliceOuterRadius: sliceFullOuterRadius,
            );
      final spacingOffset = Offset.fromDirection(midAngle, spacingDistance);
      // Offset the radial seams to create physical padding. The wedge apex is
      // translated, but the outer arc remains on the shared chart circle.
      final sliceOuterRadius = math
          .max(0, sliceFullOuterRadius - spacingDistance)
          .toDouble();
      final sliceInnerRadius = math
          .min(innerRadius, sliceOuterRadius)
          .toDouble();
      final explodeDistance =
          projectedSlice.sourcePointIndices.any(explodedPointIndices.contains)
          ? series.radialStyle.selectionExplodeOffset * selectionProgress
          : 0.0;
      final explodeOffset = Offset.fromDirection(midAngle, explodeDistance);
      final outerArcCenter = center + explodeOffset;
      final sliceCenter = outerArcCenter + spacingOffset;
      final usesCircularCenter = circularCenterRadius > _angleEpsilon;
      final roundsInnerCorners =
          effectiveCornerTreatment == PieCornerTreatment.roundAll;
      final sliceCornerRadius = effectiveCornerRadius * sliceRevealProgress;
      final basePath =
          spacingDistance > _angleEpsilon &&
              configuredInnerRadius <= _angleEpsilon
          ? _paddedPieSectorPath(
              apex: sliceCenter,
              outerArcCenter: outerArcCenter,
              outerRadius: sliceFullOuterRadius,
              startAngle: pathStartAngle,
              sweepAngle: pathSweepAngle,
              cornerRadius: sliceCornerRadius,
              roundInnerCorners: roundsInnerCorners,
            )
          : _sectorPath(
              center: sliceCenter,
              innerRadius: usesCircularCenter ? 0 : sliceInnerRadius,
              outerRadius: sliceOuterRadius,
              startAngle: pathStartAngle,
              sweepAngle: pathSweepAngle,
              cornerRadius: sliceCornerRadius,
              roundInnerCorners: roundsInnerCorners,
            );
      final path = usesCircularCenter
          ? _subtractCircularCenter(
              basePath,
              center: outerArcCenter,
              radius: circularCenterRadius,
            )
          : basePath;
      final tooltipRadius =
          sliceInnerRadius + (sliceOuterRadius - sliceInnerRadius) * 0.62;
      final insideRadius =
          sliceInnerRadius + (sliceOuterRadius - sliceInnerRadius) * 0.58;
      final connectorRadius = sliceOuterRadius;
      final outsideRadius =
          sliceOuterRadius +
          series.dataLabels.connectorLength +
          series.dataLabels.padding;

      slices.add(
        PieSliceGeometry(
          point: point,
          pointIndex: pointIndex,
          sourcePointIndices: projectedSlice.sourcePointIndices,
          share: share,
          startAngle: startAngle,
          sweepAngle: sweepAngle,
          midAngle: midAngle,
          center: sliceCenter,
          innerRadius: sliceInnerRadius,
          outerRadius: sliceOuterRadius,
          radiusFactor: sliceRadiusFactor,
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

double _annularSliceGapAngle({
  required double sliceGap,
  required double animationProgress,
  required int visibleSliceCount,
  required double sweepMagnitude,
  required double innerRadius,
  required double outerRadius,
}) {
  if (visibleSliceCount <= 1 || sliceGap <= 0 || sweepMagnitude <= 0) return 0;
  final middleRadius = innerRadius + (outerRadius - innerRadius) / 2;
  if (middleRadius <= _angleEpsilon) return 0;
  final requested = sliceGap * animationProgress / middleRadius;
  return math.min(requested, sweepMagnitude * 0.8);
}

double _sliceSpacingDistance({
  required double sliceGap,
  required double animationProgress,
  required int visibleSliceCount,
  required double sweepMagnitude,
  required double sliceOuterRadius,
}) {
  if (visibleSliceCount <= 1) return 0;
  final halfSweepSine = math.sin(sweepMagnitude / 2).abs();
  return math.min(
    sliceGap * animationProgress / (2 * math.max(0.25, halfSweepSine)),
    sliceOuterRadius * 0.12,
  );
}

double _circularCenterGapRadius({
  required RadialCategorySeries series,
  required double total,
  required double outerRadius,
  required Map<int, double> sliceRadiusFactors,
  required double cornerRadius,
  required double animationProgress,
}) {
  if (total <= 0 || outerRadius <= 0 || cornerRadius <= 0) return 0;

  var maximumSpacing = 0.0;
  var minimumSliceRadius = double.infinity;
  final visibleSliceCount = series.visiblePointIndices.length;
  for (final (pointIndex, point) in series.points.indexed) {
    if (point.y <= 0) continue;
    final sliceRadius = outerRadius * (sliceRadiusFactors[pointIndex] ?? 1);
    minimumSliceRadius = math.min(minimumSliceRadius, sliceRadius);
    maximumSpacing = math.max(
      maximumSpacing,
      _sliceSpacingDistance(
        sliceGap: series.radialStyle.sliceGap,
        animationProgress: animationProgress,
        visibleSliceCount: visibleSliceCount,
        sweepMagnitude: _tau * point.y / total,
        sliceOuterRadius: sliceRadius,
      ),
    );
  }

  if (!minimumSliceRadius.isFinite) return 0;
  // Preserve at least one quarter of the smallest slice's radial depth. This
  // mirrors the 24% cap used by outer corner rounding and prevents a large
  // requested radius from erasing a valid variable-radius slice entirely.
  final maximumSafeGap = minimumSliceRadius * 0.75;
  return math.min(math.max(cornerRadius, maximumSpacing), maximumSafeGap);
}

Map<int, double> _sliceRadiusFactors(RadialCategorySeries series) {
  final config = series.sliceRadiusConfig;
  if (config == null) return const <int, double>{};

  final values = <int, double>{
    for (final pointIndex in series.visiblePointIndices)
      pointIndex: series.points[pointIndex].pointStyle!.size!,
  };
  if (values.isEmpty) return const <int, double>{};

  final minimum = values.values.reduce(math.min);
  final maximum = values.values.reduce(math.max);
  if ((maximum - minimum).abs() <= _angleEpsilon) {
    return {for (final pointIndex in values.keys) pointIndex: 1};
  }

  final minimumFactor = config.minimumFactor;
  return {
    for (final entry in values.entries)
      entry.key: switch (config.scale) {
        PieSliceRadiusScale.linear =>
          minimumFactor +
              ((entry.value - minimum) / (maximum - minimum)) *
                  (1 - minimumFactor),
        PieSliceRadiusScale.area => math.sqrt(
          minimumFactor * minimumFactor +
              ((entry.value - minimum) / (maximum - minimum)) *
                  (1 - minimumFactor * minimumFactor),
        ),
      },
  };
}

Path _sectorPath({
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
    return _roundedPieSectorPath(
      center: center,
      outerRadius: outerRadius,
      startAngle: startAngle,
      sweepAngle: sweepAngle,
      cornerRadius: cornerRadius,
      roundInnerCorners: roundInnerCorners,
    );
  }
  if (cornerRadius > 0 && innerRadius > 0) {
    return _roundedAnnularSectorPath(
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

Path _roundedAnnularSectorPath({
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
    return _sectorPath(
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
    return _sectorPath(
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

Path _paddedPieSectorPath({
  required Offset apex,
  required Offset outerArcCenter,
  required double outerRadius,
  required double startAngle,
  required double sweepAngle,
  required double cornerRadius,
  required bool roundInnerCorners,
}) {
  final outerStart = _rayCircleIntersection(
    origin: apex,
    angle: startAngle,
    circleCenter: outerArcCenter,
    radius: outerRadius,
  );
  final outerEnd = _rayCircleIntersection(
    origin: apex,
    angle: startAngle + sweepAngle,
    circleCenter: outerArcCenter,
    radius: outerRadius,
  );
  final startOuterAngle = math.atan2(
    outerStart.dy - outerArcCenter.dy,
    outerStart.dx - outerArcCenter.dx,
  );
  final endOuterAngle = math.atan2(
    outerEnd.dy - outerArcCenter.dy,
    outerEnd.dx - outerArcCenter.dx,
  );
  final arcSweep = sweepAngle >= 0
      ? _normalizedAngle(endOuterAngle - startOuterAngle)
      : -_normalizedAngle(startOuterAngle - endOuterAngle);
  final outerRect = Rect.fromCircle(
    center: outerArcCenter,
    radius: outerRadius,
  );

  final startLength = (outerStart - apex).distance;
  final endLength = (outerEnd - apex).distance;
  final maximumCorner = math.min(
    outerRadius * 0.24,
    math.min(startLength, endLength) * 0.24,
  );
  final radius = math.min(cornerRadius, maximumCorner);
  if (radius <= _angleEpsilon) {
    return Path()
      ..moveTo(apex.dx, apex.dy)
      ..lineTo(outerStart.dx, outerStart.dy)
      ..arcTo(outerRect, startOuterAngle, arcSweep, false)
      ..lineTo(apex.dx, apex.dy)
      ..close();
  }

  final direction = sweepAngle.sign;
  final sweepMagnitude = arcSweep.abs();
  final angleTrim = math.min(radius / outerRadius, sweepMagnitude * 0.2);
  final arcStartAngle = startOuterAngle + direction * angleTrim;
  final trimmedArcSweep = arcSweep - direction * angleTrim * 2;
  final arcStart =
      outerArcCenter + Offset.fromDirection(arcStartAngle, outerRadius);
  final startUnit = (outerStart - apex) / startLength;
  final endUnit = (outerEnd - apex) / endLength;
  final startEdge = outerStart - startUnit * radius;
  final endEdge = outerEnd - endUnit * radius;
  final centerTrim = roundInnerCorners && sweepMagnitude < math.pi
      ? math.min(
          radius / math.max(0.2, math.tan(sweepMagnitude / 2)),
          math.min(startLength, endLength) * 0.32,
        )
      : 0.0;
  final centerStart = apex + startUnit * centerTrim;
  final centerEnd = apex + endUnit * centerTrim;

  final path = Path()
    ..moveTo(centerStart.dx, centerStart.dy)
    ..lineTo(startEdge.dx, startEdge.dy)
    ..quadraticBezierTo(outerStart.dx, outerStart.dy, arcStart.dx, arcStart.dy)
    ..arcTo(outerRect, arcStartAngle, trimmedArcSweep, false)
    ..quadraticBezierTo(outerEnd.dx, outerEnd.dy, endEdge.dx, endEdge.dy)
    ..lineTo(centerEnd.dx, centerEnd.dy);
  if (centerTrim > 0) {
    path.quadraticBezierTo(apex.dx, apex.dy, centerStart.dx, centerStart.dy);
  } else {
    path.lineTo(apex.dx, apex.dy);
  }
  return path..close();
}

Path _subtractCircularCenter(
  Path source, {
  required Offset center,
  required double radius,
}) {
  final cutout = Path()
    ..addOval(Rect.fromCircle(center: center, radius: radius));
  return Path.combine(PathOperation.difference, source, cutout);
}

Offset _rayCircleIntersection({
  required Offset origin,
  required double angle,
  required Offset circleCenter,
  required double radius,
}) {
  final direction = Offset.fromDirection(angle);
  final delta = origin - circleCenter;
  final projection = delta.dx * direction.dx + delta.dy * direction.dy;
  final discriminant = math.max(
    0,
    projection * projection - (delta.distanceSquared - radius * radius),
  );
  final distance = -projection + math.sqrt(discriminant);
  return origin + direction * distance;
}

Path _roundedPieSectorPath({
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

double _degreesToRadians(double degrees) => degrees * math.pi / 180;

double _normalizedAngle(double angle) {
  final normalized = angle % _tau;
  return normalized < 0 ? normalized + _tau : normalized;
}
