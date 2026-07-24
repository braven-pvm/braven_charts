import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../models/radial_bar_chart_config.dart';
import 'annular_sector_geometry.dart';
import 'radial_pane_geometry.dart';

const double _geometryEpsilon = 1e-9;

/// Resolved geometry for one category track in a Radial Bar chart.
@immutable
class RadialBarMarkGeometry {
  const RadialBarMarkGeometry._({
    required this.category,
    required this.index,
    required this.value,
    required this.minimum,
    required this.maximum,
    required this.baseline,
    required this.innerRadius,
    required this.outerRadius,
    required this.track,
    required this.mark,
    required this.tooltipAnchor,
    required this.categoryLabelAnchor,
    required this.valueLabelAnchor,
  });

  final String category;
  final int index;
  final double value;
  final double minimum;
  final double maximum;
  final double baseline;
  final double innerRadius;
  final double outerRadius;
  final AnnularSectorGeometry track;
  final AnnularSectorGeometry mark;
  final Offset tooltipAnchor;
  final Offset categoryLabelAnchor;
  final Offset valueLabelAnchor;

  Path get trackPath => track.path;
  Path get path => mark.path;
  Rect get bounds => mark.bounds;
  double get valueFraction => (value - minimum) / (maximum - minimum);
  double get baselineFraction => (baseline - minimum) / (maximum - minimum);
  bool get isVisible => mark.sweepAngle.abs() > _geometryEpsilon;
  bool contains(Offset position) => isVisible && mark.contains(position);
}

/// Immutable category-track geometry for one Radial Bar series.
@immutable
class RadialBarGeometry {
  RadialBarGeometry._({
    required List<RadialBarMarkGeometry> marks,
    required this.effectiveTrackGap,
    required this.trackThickness,
  }) : marks = UnmodifiableListView(marks);

  final List<RadialBarMarkGeometry> marks;
  final double effectiveTrackGap;
  final double trackThickness;

  RadialBarMarkGeometry? hitTest(Offset position) {
    for (final mark in marks.reversed) {
      if (mark.contains(position)) return mark;
    }
    return null;
  }
}

/// Converts category values into concentric tracks and angular numeric marks.
abstract final class RadialBarGeometryCalculator {
  static RadialBarGeometry calculate({
    required RadialPaneGeometry pane,
    required List<String> categories,
    required List<double> values,
    required double minimum,
    required double maximum,
    required double baseline,
    double trackGap = 6,
    RadialBarTrackOrder trackOrder = RadialBarTrackOrder.outerToInner,
    double cornerRadius = 8,
  }) {
    if (categories.isEmpty || categories.length != values.length) {
      throw ArgumentError.value(
        '${categories.length} / ${values.length}',
        'categories / values',
        'Radial Bar requires matching non-empty category and value lists',
      );
    }
    if (categories.any((category) => category.trim().isEmpty) ||
        categories.toSet().length != categories.length) {
      throw ArgumentError.value(
        categories,
        'categories',
        'Categories must be visible and unique',
      );
    }
    if (!minimum.isFinite || !maximum.isFinite || minimum >= maximum) {
      throw ArgumentError.value(
        '$minimum / $maximum',
        'minimum / maximum',
        'Bounds must be finite and maximum must be greater than minimum',
      );
    }
    if (!baseline.isFinite || baseline < minimum || baseline > maximum) {
      throw ArgumentError.value(
        baseline,
        'baseline',
        'Baseline must be inside the numeric domain',
      );
    }
    if (!trackGap.isFinite || trackGap < 0) {
      throw ArgumentError.value(
        trackGap,
        'trackGap',
        'Value must be finite and non-negative',
      );
    }
    if (!cornerRadius.isFinite || cornerRadius < 0) {
      throw ArgumentError.value(
        cornerRadius,
        'cornerRadius',
        'Value must be finite and non-negative',
      );
    }
    for (final (index, value) in values.indexed) {
      if (!value.isFinite || value < minimum || value > maximum) {
        throw ArgumentError.value(
          value,
          'values[$index]',
          'Value must be finite and inside the numeric domain',
        );
      }
    }

    final radialDepth = pane.outerRadius - pane.innerRadius;
    final maximumGap = categories.length == 1
        ? 0.0
        : radialDepth / (categories.length * 3);
    final effectiveTrackGap = math.min(trackGap, maximumGap);
    final trackThickness =
        (radialDepth - effectiveTrackGap * (categories.length - 1)) /
        categories.length;
    final baselineFraction = (baseline - minimum) / (maximum - minimum);
    final marks = <RadialBarMarkGeometry>[];

    for (final (sourceIndex, category) in categories.indexed) {
      final radialIndex = trackOrder == RadialBarTrackOrder.outerToInner
          ? sourceIndex
          : categories.length - 1 - sourceIndex;
      final outerRadius =
          pane.outerRadius - radialIndex * (trackThickness + effectiveTrackGap);
      final innerRadius = outerRadius - trackThickness;
      final value = values[sourceIndex];
      final valueFraction = (value - minimum) / (maximum - minimum);
      final startAngle = pane.angleAt(baselineFraction);
      final valueSweep =
          pane.signedSweepAngle * (valueFraction - baselineFraction);
      final track = AnnularSectorGeometry(
        center: pane.center,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        startAngle: pane.startAngle,
        sweepAngle: pane.signedSweepAngle,
        cornerRadius: cornerRadius,
        roundInnerCorners: true,
      );
      final mark = AnnularSectorGeometry(
        center: pane.center,
        innerRadius: innerRadius,
        outerRadius: outerRadius,
        startAngle: startAngle,
        sweepAngle: valueSweep,
        cornerRadius: cornerRadius,
        roundInnerCorners: true,
      );
      final middleRadius = (innerRadius + outerRadius) / 2;
      final middleAngle = startAngle + valueSweep / 2;
      final endAngle = startAngle + valueSweep;
      final categoryAngle = pane.startAngle + pane.signedSweepAngle * 0.025;
      marks.add(
        RadialBarMarkGeometry._(
          category: category,
          index: sourceIndex,
          value: value,
          minimum: minimum,
          maximum: maximum,
          baseline: baseline,
          innerRadius: innerRadius,
          outerRadius: outerRadius,
          track: track,
          mark: mark,
          tooltipAnchor:
              pane.center + Offset.fromDirection(middleAngle, middleRadius),
          categoryLabelAnchor:
              pane.center + Offset.fromDirection(categoryAngle, middleRadius),
          valueLabelAnchor:
              pane.center + Offset.fromDirection(endAngle, middleRadius),
        ),
      );
    }

    return RadialBarGeometry._(
      marks: marks,
      effectiveTrackGap: effectiveTrackGap,
      trackThickness: trackThickness,
    );
  }
}
