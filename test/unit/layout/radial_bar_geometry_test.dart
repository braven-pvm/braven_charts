import 'dart:math' as math;

import 'package:braven_charts/src/layout/radial_bar_geometry.dart';
import 'package:braven_charts/src/layout/radial_pane_geometry.dart';
import 'package:braven_charts/src/models/radial_bar_chart_config.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RadialBarGeometryCalculator', () {
    test('maps categories to tracks and values to angular sweep', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 300, 300),
        innerRadiusFactor: 0.2,
        outerRadiusFactor: 0.9,
        startAngle: -math.pi / 2,
        sweepAngle: math.pi * 2,
      );
      final geometry = RadialBarGeometryCalculator.calculate(
        pane: pane,
        categories: const ['Discovery', 'Build', 'Launch'],
        values: const [75, 50, 25],
        minimum: 0,
        maximum: 100,
        baseline: 0,
        trackGap: 6,
      );

      expect(geometry.marks, hasLength(3));
      expect(geometry.marks.map((mark) => mark.category), [
        'Discovery',
        'Build',
        'Launch',
      ]);
      expect(
        geometry.marks[0].outerRadius,
        greaterThan(geometry.marks[1].outerRadius),
      );
      expect(geometry.marks[0].mark.sweepAngle, closeTo(math.pi * 1.5, 1e-9));
      expect(geometry.marks[1].mark.sweepAngle, closeTo(math.pi, 1e-9));
      expect(geometry.hitTest(geometry.marks[1].tooltipAnchor)?.index, 1);
      expect(geometry.hitTest(pane.center), isNull);

      final startDirection = Offset.fromDirection(pane.startAngle);
      for (final mark in geometry.marks) {
        final labelDirection =
            (mark.categoryLabelAnchor - pane.center) /
            (mark.categoryLabelAnchor - pane.center).distance;
        expect(
          labelDirection.dx,
          closeTo(startDirection.dx, 1e-9),
          reason: '${mark.category} must align to the shared scale origin',
        );
        expect(
          labelDirection.dy,
          closeTo(startDirection.dy, 1e-9),
          reason: '${mark.category} must align to the shared scale origin',
        );
      }
    });

    test('negative values sweep backward from a non-edge baseline', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 240, 240),
        innerRadiusFactor: 0.25,
        outerRadiusFactor: 0.9,
      );
      final geometry = RadialBarGeometryCalculator.calculate(
        pane: pane,
        categories: const ['Ahead', 'Behind'],
        values: const [20, -10],
        minimum: -25,
        maximum: 25,
        baseline: 0,
      );

      expect(geometry.marks[0].mark.sweepAngle, greaterThan(0));
      expect(geometry.marks[1].mark.sweepAngle, lessThan(0));
      expect(geometry.marks[0].baselineFraction, 0.5);
      expect(geometry.marks[1].baselineFraction, 0.5);
    });

    test('honors partial counter-clockwise panes', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 240, 240),
        innerRadiusFactor: 0.2,
        outerRadiusFactor: 0.9,
        startAngle: math.pi,
        sweepAngle: math.pi,
        clockwise: false,
      );
      final geometry = RadialBarGeometryCalculator.calculate(
        pane: pane,
        categories: const ['Half'],
        values: const [50],
        minimum: 0,
        maximum: 100,
        baseline: 0,
      );

      expect(geometry.marks.single.track.sweepAngle, closeTo(-math.pi, 1e-9));
      expect(
        geometry.marks.single.mark.sweepAngle,
        closeTo(-math.pi / 2, 1e-9),
      );
    });

    test('reverses track order without changing source identity', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 240, 240),
        innerRadiusFactor: 0.2,
        outerRadiusFactor: 0.9,
      );
      final geometry = RadialBarGeometryCalculator.calculate(
        pane: pane,
        categories: const ['A', 'B'],
        values: const [80, 60],
        minimum: 0,
        maximum: 100,
        baseline: 0,
        trackOrder: RadialBarTrackOrder.innerToOuter,
      );

      expect(geometry.marks[0].category, 'A');
      expect(
        geometry.marks[0].outerRadius,
        lessThan(geometry.marks[1].outerRadius),
      );
    });

    test('compresses excessive gaps while retaining positive track depth', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 120, 120),
        innerRadiusFactor: 0.7,
        outerRadiusFactor: 0.8,
      );
      final geometry = RadialBarGeometryCalculator.calculate(
        pane: pane,
        categories: List<String>.generate(24, (index) => 'C$index'),
        values: List<double>.filled(24, 50),
        minimum: 0,
        maximum: 100,
        baseline: 0,
        trackGap: 20,
      );

      expect(geometry.trackThickness, greaterThan(0));
      expect(geometry.effectiveTrackGap, lessThan(20));
      expect(geometry.marks, hasLength(24));
    });

    test('rejects invalid source and domain state', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 240, 240),
        innerRadiusFactor: 0.2,
        outerRadiusFactor: 0.9,
      );

      expect(
        () => RadialBarGeometryCalculator.calculate(
          pane: pane,
          categories: const ['A', 'A'],
          values: const [20, 30],
          minimum: 0,
          maximum: 100,
          baseline: 0,
        ),
        throwsArgumentError,
      );
      expect(
        () => RadialBarGeometryCalculator.calculate(
          pane: pane,
          categories: const ['A'],
          values: const [120],
          minimum: 0,
          maximum: 100,
          baseline: 0,
        ),
        throwsArgumentError,
      );
    });
  });
}
