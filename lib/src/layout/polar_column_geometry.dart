import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../axis/polar_category_scale.dart';
import '../axis/polar_numeric_scale.dart';
import 'annular_sector_geometry.dart';

const double _radiusEpsilon = 1e-9;

/// Resolved geometry for one axis-based Polar Column mark.
///
/// Unlike a Pie slice, [value] does not contribute to the angular span. The
/// category scale owns that span and the numeric scale maps the value to a
/// physical radius from [baselineRadius].
@immutable
class PolarColumnMarkGeometry {
  const PolarColumnMarkGeometry._({
    required this.category,
    required this.index,
    required this.value,
    required this.baseline,
    required this.radialValue,
    required this.band,
    required this.baselineRadius,
    required this.valueRadius,
    required this.sector,
    required this.tooltipAnchor,
    required this.labelAnchor,
  });

  /// Stable category identity from the angular axis.
  final String category;

  /// Stable category/keyboard traversal position.
  final int index;

  /// Source numeric value represented by the mark radius.
  final double value;

  /// Numeric baseline from which the mark grows.
  final double baseline;

  /// Numeric radial endpoint after applying composition geometry.
  ///
  /// This equals [value] for an ordinary column and the cumulative stack end
  /// for a stacked column. [value] always remains the raw source value.
  final double radialValue;

  /// Angular category band occupied by this mark.
  final PolarCategoryBand band;

  /// Physical radius mapped from [baseline].
  final double baselineRadius;

  /// Physical radius mapped from [radialValue].
  final double valueRadius;

  /// Shared annular-sector primitive used for painting and hit testing.
  final AnnularSectorGeometry sector;

  /// Stable tooltip anchor inside the visible mark.
  final Offset tooltipAnchor;

  /// Default direct-label anchor at the mark's visual center.
  final Offset labelAnchor;

  /// Closed mark path.
  Path get path => sector.path;

  /// Axis-aligned bounds of [path].
  Rect get bounds => sector.bounds;

  /// Whether this mark has non-zero radial depth.
  bool get isVisible => (valueRadius - baselineRadius).abs() > _radiusEpsilon;

  /// Whether [position] lies inside this mark's exact path.
  bool contains(Offset position) => isVisible && sector.contains(position);
}

/// Immutable mark collection for one Polar Column plot.
@immutable
class PolarColumnGeometry {
  PolarColumnGeometry._({required List<PolarColumnMarkGeometry> marks})
    : marks = UnmodifiableListView(marks);

  /// Marks in stable angular category order.
  final List<PolarColumnMarkGeometry> marks;

  /// Returns the topmost mark at [position], or `null` outside all marks.
  PolarColumnMarkGeometry? hitTest(Offset position) {
    for (final mark in marks.reversed) {
      if (mark.contains(position)) return mark;
    }
    return null;
  }
}

/// Resolves axis-based Polar Column values into annular-sector marks.
abstract final class PolarColumnGeometryCalculator {
  /// Builds one mark per angular category.
  ///
  /// [values] must match the category scale one-for-one. Ordinary marks grow
  /// from zero when the domain contains it. [radialStarts] and [radialEnds]
  /// provide cumulative endpoints for stacked composition while preserving
  /// [values] as the raw source values.
  static PolarColumnGeometry calculate({
    required PolarCategoryScale categoryScale,
    required PolarNumericScale numericScale,
    required List<double> values,
    double? baseline,
    List<double>? radialStarts,
    List<double>? radialEnds,
    double cornerRadius = 0,
    bool roundInnerCorners = false,
    int groupIndex = 0,
    int groupCount = 1,
    double groupInnerPadding = 0,
  }) {
    if (!identical(categoryScale.pane, numericScale.pane)) {
      throw ArgumentError(
        'Category and numeric scales must resolve against the same radial pane',
      );
    }
    if (values.length != categoryScale.categories.length) {
      throw ArgumentError.value(
        values.length,
        'values',
        'Value count must match angular category count '
            '(${categoryScale.categories.length})',
      );
    }
    if (radialStarts != null && radialStarts.length != values.length) {
      throw ArgumentError.value(
        radialStarts.length,
        'radialStarts',
        'Radial start count must match the source value count',
      );
    }
    if (radialEnds != null && radialEnds.length != values.length) {
      throw ArgumentError.value(
        radialEnds.length,
        'radialEnds',
        'Radial end count must match the source value count',
      );
    }
    if ((radialStarts == null) != (radialEnds == null)) {
      throw ArgumentError(
        'radialStarts and radialEnds must be supplied together',
      );
    }
    if (!cornerRadius.isFinite || cornerRadius < 0) {
      throw ArgumentError.value(
        cornerRadius,
        'cornerRadius',
        'Value must be finite and non-negative',
      );
    }
    if (groupCount < 1) {
      throw ArgumentError.value(
        groupCount,
        'groupCount',
        'Group count must be at least one',
      );
    }
    if (groupIndex < 0 || groupIndex >= groupCount) {
      throw ArgumentError.value(
        groupIndex,
        'groupIndex',
        'Group index must be inside the group count',
      );
    }
    if (!groupInnerPadding.isFinite ||
        groupInnerPadding < 0 ||
        groupInnerPadding >= 1) {
      throw ArgumentError.value(
        groupInnerPadding,
        'groupInnerPadding',
        'Group padding must be finite and in [0, 1)',
      );
    }

    final resolvedBaseline = baseline ?? _defaultBaseline(numericScale);
    if (!resolvedBaseline.isFinite ||
        resolvedBaseline < numericScale.minimum ||
        resolvedBaseline > numericScale.maximum) {
      throw ArgumentError.value(
        resolvedBaseline,
        'baseline',
        'Value must be finite and inside the numeric scale domain',
      );
    }
    final marks = <PolarColumnMarkGeometry>[];

    for (final (index, value) in values.indexed) {
      final radialStart = radialStarts?[index] ?? resolvedBaseline;
      final radialEnd = radialEnds?[index] ?? value;
      if (!value.isFinite || !radialStart.isFinite || !radialEnd.isFinite) {
        throw ArgumentError.value(
          value,
          'values[$index]',
          'Polar Column source, radial start, and radial end must be finite',
        );
      }
      final band = _resolveGroupBand(
        categoryScale.bandAt(index),
        groupIndex: groupIndex,
        groupCount: groupCount,
        groupInnerPadding: groupInnerPadding,
      );
      final baselineRadius = numericScale.valueToRadius(radialStart);
      final valueRadius = numericScale.valueToRadius(radialEnd);
      final innerRadius = math.min(baselineRadius, valueRadius);
      final outerRadius = math.max(baselineRadius, valueRadius);
      final sector = AnnularSectorGeometry(
        center: categoryScale.pane.center,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        startAngle: band.startAngle,
        sweepAngle: band.sweepAngle,
        cornerRadius: cornerRadius,
        roundInnerCorners: roundInnerCorners,
      );
      final radialDepth = outerRadius - innerRadius;
      final tooltipRadius = innerRadius + radialDepth * 0.68;
      final labelRadius = innerRadius + radialDepth * 0.5;
      marks.add(
        PolarColumnMarkGeometry._(
          category: band.category,
          index: index,
          value: value,
          baseline: radialStart,
          radialValue: radialEnd,
          band: band,
          baselineRadius: baselineRadius,
          valueRadius: valueRadius,
          sector: sector,
          tooltipAnchor:
              categoryScale.pane.center +
              Offset.fromDirection(band.centerAngle, tooltipRadius),
          labelAnchor:
              categoryScale.pane.center +
              Offset.fromDirection(band.centerAngle, labelRadius),
        ),
      );
    }

    return PolarColumnGeometry._(marks: marks);
  }
}

double _defaultBaseline(PolarNumericScale scale) {
  if (scale.minimum <= 0 && scale.maximum >= 0) return 0;
  return scale.minimum > 0 ? scale.minimum : scale.maximum;
}

PolarCategoryBand _resolveGroupBand(
  PolarCategoryBand categoryBand, {
  required int groupIndex,
  required int groupCount,
  required double groupInnerPadding,
}) {
  if (groupCount == 1) return categoryBand;
  final slotSweep = categoryBand.sweepAngle / groupCount;
  final gapSweep = slotSweep * groupInnerPadding;
  return PolarCategoryBand(
    category: categoryBand.category,
    index: categoryBand.index,
    startAngle: categoryBand.startAngle + slotSweep * groupIndex + gapSweep / 2,
    sweepAngle: slotSweep - gapSweep,
  );
}
