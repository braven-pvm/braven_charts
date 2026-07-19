import 'dart:collection';

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

  /// Angular category band occupied by this mark.
  final PolarCategoryBand band;

  /// Physical radius mapped from [baseline].
  final double baselineRadius;

  /// Physical radius mapped from [value].
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
  bool get isVisible => valueRadius - baselineRadius > _radiusEpsilon;

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
  /// [values] must match the category scale one-for-one. V1 grows every mark
  /// outward from [baseline], which defaults to the numeric scale minimum.
  static PolarColumnGeometry calculate({
    required PolarCategoryScale categoryScale,
    required PolarNumericScale numericScale,
    required List<double> values,
    double? baseline,
    double cornerRadius = 0,
    bool roundInnerCorners = false,
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
    if (!cornerRadius.isFinite || cornerRadius < 0) {
      throw ArgumentError.value(
        cornerRadius,
        'cornerRadius',
        'Value must be finite and non-negative',
      );
    }

    final resolvedBaseline = baseline ?? numericScale.minimum;
    if (!resolvedBaseline.isFinite ||
        resolvedBaseline < numericScale.minimum ||
        resolvedBaseline > numericScale.maximum) {
      throw ArgumentError.value(
        resolvedBaseline,
        'baseline',
        'Value must be finite and inside the numeric scale domain',
      );
    }
    final baselineRadius = numericScale.valueToRadius(resolvedBaseline);
    final marks = <PolarColumnMarkGeometry>[];

    for (final (index, value) in values.indexed) {
      if (!value.isFinite || value < resolvedBaseline) {
        throw ArgumentError.value(
          value,
          'values[$index]',
          'Polar Column V1 values must be finite and at least the baseline',
        );
      }
      final band = categoryScale.bandAt(index);
      final valueRadius = numericScale.valueToRadius(value);
      final sector = AnnularSectorGeometry(
        center: categoryScale.pane.center,
        innerRadius: baselineRadius,
        outerRadius: valueRadius,
        startAngle: band.startAngle,
        sweepAngle: band.sweepAngle,
        cornerRadius: cornerRadius,
        roundInnerCorners: roundInnerCorners,
      );
      final radialDepth = valueRadius - baselineRadius;
      final tooltipRadius = baselineRadius + radialDepth * 0.68;
      final labelRadius = baselineRadius + radialDepth * 0.5;
      marks.add(
        PolarColumnMarkGeometry._(
          category: band.category,
          index: index,
          value: value,
          baseline: resolvedBaseline,
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
