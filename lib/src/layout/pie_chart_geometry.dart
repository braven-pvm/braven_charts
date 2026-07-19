import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/widgets.dart';

import '../models/chart_data_point.dart';
import '../models/pie_chart_config.dart';
import '../models/radial_selection_style.dart';
import '../models/radial_category_series.dart';
import 'annular_sector_geometry.dart';

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
    required this.liftOffset,
    required this.path,
    required this.tooltipAnchor,
    required this.insideLabelAnchor,
    required this.connectorOrigin,
    required this.outsideLabelAnchor,
    required this.isSelected,
    required this.selectionScale,
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

  /// Slice center after any explode or lift offset and selection scale.
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

  /// Applied lift translation, independent of the lift scale.
  final Offset liftOffset;

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

  /// Whether this slice represents the current durable selection.
  final bool isSelected;

  /// Scale applied around the slice's visual centroid.
  final double selectionScale;

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
    for (final slice in slices.reversed.where((slice) => slice.isSelected)) {
      if (slice.contains(position)) {
        return slice;
      }
    }
    for (final slice in slices.reversed) {
      if (!slice.isSelected && slice.contains(position)) {
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
    Offset? centerOverride,
    double? innerRadiusOverride,
    double? outerRadiusOverride,
    double insideLabelRadiusFactor = 0.58,
    double? cornerRadius,
    PieCornerTreatment? cornerTreatment,
    PieAnimationMode animationMode = PieAnimationMode.grow,
    double animationProgress = 1,
    double selectionProgress = 1,
    RadialSelectionEffect selectionEffect = RadialSelectionEffect.explode,
    double selectionLiftScale = 1.08,
    double selectionLiftOffset = 6,
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
    if (centerOverride != null &&
        (!centerOverride.dx.isFinite || !centerOverride.dy.isFinite)) {
      throw ArgumentError.value(
        centerOverride,
        'centerOverride',
        'Center must be finite',
      );
    }
    if ((innerRadiusOverride == null) != (outerRadiusOverride == null)) {
      throw ArgumentError(
        'innerRadiusOverride and outerRadiusOverride must be supplied together',
      );
    }
    if (innerRadiusOverride != null &&
        (!innerRadiusOverride.isFinite || innerRadiusOverride < 0)) {
      throw ArgumentError.value(
        innerRadiusOverride,
        'innerRadiusOverride',
        'Inner radius must be finite and non-negative',
      );
    }
    if (outerRadiusOverride != null &&
        (!outerRadiusOverride.isFinite ||
            outerRadiusOverride <= innerRadiusOverride!)) {
      throw ArgumentError.value(
        outerRadiusOverride,
        'outerRadiusOverride',
        'Outer radius must be finite and greater than inner radius',
      );
    }
    if (!insideLabelRadiusFactor.isFinite ||
        insideLabelRadiusFactor < 0 ||
        insideLabelRadiusFactor > 1) {
      throw ArgumentError.value(
        insideLabelRadiusFactor,
        'insideLabelRadiusFactor',
        'Value must be finite and in [0, 1]',
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
    if (!selectionLiftScale.isFinite ||
        selectionLiftScale < 1 ||
        selectionLiftScale > 1.5) {
      throw ArgumentError.value(
        selectionLiftScale,
        'selectionLiftScale',
        'Value must be finite and in [1, 1.5]',
      );
    }
    if (!selectionLiftOffset.isFinite ||
        selectionLiftOffset < 0 ||
        selectionLiftOffset > 40) {
      throw ArgumentError.value(
        selectionLiftOffset,
        'selectionLiftOffset',
        'Value must be finite and in [0, 40]',
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
    final center = centerOverride ?? contentRect.center;
    final availableRadius = math.min(contentRect.width, contentRect.height) / 2;
    final visibleSlices = series.visibleSlices;
    final visibleSliceCount = visibleSlices.length;
    final fullOuterRadius =
        outerRadiusOverride ??
        availableRadius * series.radialStyle.radiusFactor;
    final outerRadius = fullOuterRadius * geometryProgress;
    final fullInnerRadius =
        innerRadiusOverride ?? fullOuterRadius * effectiveInnerRadiusFactor;
    final configuredInnerRadius = fullInnerRadius * geometryProgress;
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
      final annularSeamInset = isAnnular
          ? _annularSliceSeamInset(
              sliceGap: series.radialStyle.sliceGap,
              animationProgress: geometryProgress * sliceRevealProgress,
              visibleSliceCount: visibleSliceCount,
            )
          : 0.0;
      final pathStartAngle = startAngle;
      final pathSweepAngle = sweepAngle;
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
      final isSelected = projectedSlice.sourcePointIndices.any(
        explodedPointIndices.contains,
      );
      final explodeDistance =
          isSelected && selectionEffect == RadialSelectionEffect.explode
          ? series.radialStyle.selectionExplodeOffset * selectionProgress
          : 0.0;
      final explodeOffset = Offset.fromDirection(midAngle, explodeDistance);
      final liftDistance =
          isSelected && selectionEffect == RadialSelectionEffect.lift
          ? selectionLiftOffset * selectionProgress
          : 0.0;
      final liftOffset = Offset.fromDirection(midAngle, liftDistance);
      final outerArcCenter = center + explodeOffset + liftOffset;
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
          : AnnularSectorGeometry(
              center: sliceCenter,
              innerRadius: usesCircularCenter ? 0 : sliceInnerRadius,
              outerRadius: sliceOuterRadius,
              startAngle: pathStartAngle,
              sweepAngle: pathSweepAngle,
              cornerRadius: sliceCornerRadius,
              roundInnerCorners: roundsInnerCorners,
              seamInset: annularSeamInset,
            ).path;
      final unscaledPath = usesCircularCenter
          ? _subtractCircularCenter(
              basePath,
              center: outerArcCenter,
              radius: circularCenterRadius,
            )
          : basePath;
      final selectionScale =
          isSelected && selectionEffect == RadialSelectionEffect.lift
          ? 1 + (selectionLiftScale - 1) * selectionProgress
          : 1.0;
      final selectionPivot = _annularSectorCentroid(
        center: sliceCenter,
        innerRadius: sliceInnerRadius,
        outerRadius: sliceOuterRadius,
        sweepAngle: pathSweepAngle,
        midAngle: midAngle,
      );
      final path = selectionScale == 1
          ? unscaledPath
          : _scalePathAround(
              unscaledPath,
              pivot: selectionPivot,
              scale: selectionScale,
            );
      final effectiveSliceCenter = _scalePointAround(
        sliceCenter,
        pivot: selectionPivot,
        scale: selectionScale,
      );
      final tooltipRadius =
          sliceInnerRadius + (sliceOuterRadius - sliceInnerRadius) * 0.62;
      final insideRadius =
          (sliceInnerRadius +
                  (sliceOuterRadius - sliceInnerRadius) *
                      insideLabelRadiusFactor +
                  series.dataLabels.insideOffset)
              .clamp(sliceInnerRadius, sliceOuterRadius)
              .toDouble();
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
          center: effectiveSliceCenter,
          innerRadius: sliceInnerRadius * selectionScale,
          outerRadius: sliceOuterRadius * selectionScale,
          radiusFactor: sliceRadiusFactor,
          spacingOffset: spacingOffset,
          explodeOffset: explodeOffset,
          liftOffset: liftOffset,
          path: path,
          tooltipAnchor: _scalePointAround(
            sliceCenter + Offset.fromDirection(midAngle, tooltipRadius),
            pivot: selectionPivot,
            scale: selectionScale,
          ),
          insideLabelAnchor: _scalePointAround(
            sliceCenter + Offset.fromDirection(midAngle, insideRadius),
            pivot: selectionPivot,
            scale: selectionScale,
          ),
          connectorOrigin: _scalePointAround(
            sliceCenter + Offset.fromDirection(midAngle, connectorRadius),
            pivot: selectionPivot,
            scale: selectionScale,
          ),
          outsideLabelAnchor: _scalePointAround(
            sliceCenter + Offset.fromDirection(midAngle, outsideRadius),
            pivot: selectionPivot,
            scale: selectionScale,
          ),
          isSelected: isSelected,
          selectionScale: selectionScale,
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

Offset _annularSectorCentroid({
  required Offset center,
  required double innerRadius,
  required double outerRadius,
  required double sweepAngle,
  required double midAngle,
}) {
  final theta = sweepAngle.abs();
  final squaredDifference =
      outerRadius * outerRadius - innerRadius * innerRadius;
  if (theta <= _angleEpsilon || squaredDifference <= _angleEpsilon) {
    return center +
        Offset.fromDirection(midAngle, (innerRadius + outerRadius) / 2);
  }
  final cubedDifference =
      outerRadius * outerRadius * outerRadius -
      innerRadius * innerRadius * innerRadius;
  final radius =
      4 *
      math.sin(theta / 2).abs() *
      cubedDifference /
      (3 * theta * squaredDifference);
  return center + Offset.fromDirection(midAngle, radius);
}

Offset _scalePointAround(
  Offset point, {
  required Offset pivot,
  required double scale,
}) => pivot + (point - pivot) * scale;

Path _scalePathAround(
  Path path, {
  required Offset pivot,
  required double scale,
}) {
  final translateX = pivot.dx * (1 - scale);
  final translateY = pivot.dy * (1 - scale);
  return path.transform(
    Float64List.fromList(<double>[
      scale,
      0,
      0,
      0,
      0,
      scale,
      0,
      0,
      0,
      0,
      1,
      0,
      translateX,
      translateY,
      0,
      1,
    ]),
  );
}

double _annularSliceSeamInset({
  required double sliceGap,
  required double animationProgress,
  required int visibleSliceCount,
}) {
  if (visibleSliceCount <= 1 || sliceGap <= 0) return 0;
  return sliceGap * animationProgress / 2;
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

double _degreesToRadians(double degrees) => degrees * math.pi / 180;

double _normalizedAngle(double angle) {
  final normalized = angle % _tau;
  return normalized < 0 ? normalized + _tau : normalized;
}
