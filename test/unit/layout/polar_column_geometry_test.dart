import 'dart:math' as math;

import 'package:braven_charts/src/axis/polar_category_scale.dart';
import 'package:braven_charts/src/axis/polar_numeric_scale.dart';
import 'package:braven_charts/src/layout/polar_column_geometry.dart';
import 'package:braven_charts/src/layout/radial_pane_geometry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PolarColumnGeometryCalculator', () {
    test('maps equal category bands and numeric values independently', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
        innerRadiusFactor: 0.2,
        outerRadiusFactor: 0.9,
      );
      final categories = PolarCategoryScale(
        pane: pane,
        categories: const ['North', 'East', 'South', 'West'],
        innerPadding: 0.1,
      );
      final values = PolarNumericScale(pane: pane, minimum: 0, maximum: 100);

      final geometry = PolarColumnGeometryCalculator.calculate(
        categoryScale: categories,
        numericScale: values,
        values: const [25, 50, 75, 100],
      );

      expect(geometry.marks, hasLength(4));
      expect(geometry.marks.map((mark) => mark.category), [
        'North',
        'East',
        'South',
        'West',
      ]);
      expect(
        geometry.marks[0].band.sweepAngle,
        closeTo(categories.bandSweepAngle, 1e-12),
      );
      expect(geometry.marks[0].baselineRadius, 20);
      expect(geometry.marks[0].valueRadius, 37.5);
      expect(geometry.marks[1].valueRadius, 55);
      expect(geometry.marks[3].valueRadius, 90);
      expect(geometry.marks[0].contains(geometry.marks[0].labelAnchor), isTrue);
      expect(geometry.hitTest(geometry.marks[2].tooltipAnchor)?.index, 2);
      expect(geometry.hitTest(pane.center), isNull);
    });

    test('grows from an explicit non-zero baseline', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
        outerRadiusFactor: 0.8,
      );
      final geometry = PolarColumnGeometryCalculator.calculate(
        categoryScale: PolarCategoryScale(
          pane: pane,
          categories: const ['A', 'B'],
        ),
        numericScale: PolarNumericScale(pane: pane, minimum: 0, maximum: 100),
        values: const [60, 100],
        baseline: 20,
      );

      expect(geometry.marks[0].baselineRadius, 16);
      expect(geometry.marks[0].valueRadius, 48);
      expect(geometry.marks[0].sector.innerRadius, 16);
      expect(geometry.marks[0].sector.outerRadius, 48);
    });

    test('divides each category into parallel grouped sub-bands', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 240, 240),
      );
      final categories = PolarCategoryScale(
        pane: pane,
        categories: const ['A', 'B'],
        innerPadding: 0.2,
      );
      final values = PolarNumericScale(pane: pane, minimum: 0, maximum: 100);

      PolarColumnGeometry group(int index) =>
          PolarColumnGeometryCalculator.calculate(
            categoryScale: categories,
            numericScale: values,
            values: const [80, 60],
            groupIndex: index,
            groupCount: 3,
            groupInnerPadding: 0.15,
          );

      final first = group(0).marks.first.band;
      final second = group(1).marks.first.band;
      final third = group(2).marks.first.band;
      final slotSweep = categories.bandAt(0).sweepAngle / 3;

      expect(first.sweepAngle, closeTo(slotSweep * 0.85, 1e-12));
      expect(second.startAngle - first.startAngle, closeTo(slotSweep, 1e-12));
      expect(third.startAngle - second.startAngle, closeTo(slotSweep, 1e-12));
      expect(first.endAngle, lessThan(second.startAngle));
      expect(second.endAngle, lessThan(third.startAngle));
      expect(
        (first.startAngle + third.endAngle) / 2,
        closeTo(categories.bandAt(0).centerAngle, 1e-12),
      );
    });

    test('uses area-correct radii for Rose geometry', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
      );
      final geometry = PolarColumnGeometryCalculator.calculate(
        categoryScale: PolarCategoryScale(
          pane: pane,
          categories: const ['A', 'B'],
        ),
        numericScale: PolarNumericScale(
          pane: pane,
          minimum: 0,
          maximum: 100,
          mode: PolarNumericScaleMode.areaCorrect,
        ),
        values: const [25, 100],
      );

      expect(geometry.marks[0].valueRadius, 50);
      expect(geometry.marks[1].valueRadius, 100);
      expect(
        math.pow(geometry.marks[0].valueRadius, 2) /
            math.pow(geometry.marks[1].valueRadius, 2),
        closeTo(0.25, 1e-12),
      );
    });

    test('preserves partial counter-clockwise panes and exact hits', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 240, 180),
        startAngle: 0,
        sweepAngle: math.pi,
        clockwise: false,
      );
      final categoryScale = PolarCategoryScale(
        pane: pane,
        categories: const ['A', 'B', 'C'],
        innerPadding: 0.15,
        outerPadding: 0.1,
      );
      final geometry = PolarColumnGeometryCalculator.calculate(
        categoryScale: categoryScale,
        numericScale: PolarNumericScale(pane: pane, minimum: 0, maximum: 10),
        values: const [6, 8, 10],
        cornerRadius: 4,
      );

      expect(geometry.marks.every((mark) => mark.band.sweepAngle < 0), isTrue);
      for (final mark in geometry.marks) {
        expect(mark.contains(mark.tooltipAnchor), isTrue);
        expect(geometry.hitTest(mark.tooltipAnchor), same(mark));
      }
      expect(geometry.hitTest(pane.center + const Offset(60, 30)), isNull);
    });

    test('anchors and hit regions follow the pane through resize', () {
      PolarColumnGeometry build(double size) {
        final pane = RadialPaneGeometry.resolve(
          viewportBounds: Rect.fromLTWH(0, 0, size, size),
          innerRadiusFactor: 0.1,
          outerRadiusFactor: 0.8,
        );
        return PolarColumnGeometryCalculator.calculate(
          categoryScale: PolarCategoryScale(
            pane: pane,
            categories: const ['A', 'B'],
            innerPadding: 0.1,
          ),
          numericScale: PolarNumericScale(pane: pane, minimum: 0, maximum: 10),
          values: const [5, 10],
        );
      }

      final small = build(200);
      final large = build(400);
      final smallCenter = const Offset(100, 100);
      final largeCenter = const Offset(200, 200);

      expect(
        (large.marks[0].tooltipAnchor - largeCenter).distance,
        closeTo(
          (small.marks[0].tooltipAnchor - smallCenter).distance * 2,
          1e-9,
        ),
      );
      expect(large.hitTest(large.marks[0].tooltipAnchor)?.category, 'A');
      expect(small.hitTest(small.marks[0].tooltipAnchor)?.category, 'A');
    });

    test('keeps zero-baseline values addressable but not hittable', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
        innerRadiusFactor: 0.2,
      );
      final geometry = PolarColumnGeometryCalculator.calculate(
        categoryScale: PolarCategoryScale(
          pane: pane,
          categories: const ['Zero', 'Value'],
        ),
        numericScale: PolarNumericScale(pane: pane, minimum: 0, maximum: 10),
        values: const [0, 10],
      );

      expect(geometry.marks[0].isVisible, isFalse);
      expect(
        geometry.marks[0].contains(geometry.marks[0].labelAnchor),
        isFalse,
      );
      expect(geometry.marks[1].isVisible, isTrue);
    });

    test('rejects mismatched scales, values, and baselines', () {
      final pane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
      );
      final otherPane = RadialPaneGeometry.resolve(
        viewportBounds: const Rect.fromLTWH(0, 0, 200, 200),
      );
      final categories = PolarCategoryScale(
        pane: pane,
        categories: const ['A', 'B'],
      );
      final values = PolarNumericScale(pane: pane, minimum: 0, maximum: 10);

      expect(
        () => PolarColumnGeometryCalculator.calculate(
          categoryScale: categories,
          numericScale: PolarNumericScale(
            pane: otherPane,
            minimum: 0,
            maximum: 10,
          ),
          values: const [1, 2],
        ),
        throwsArgumentError,
      );
      expect(
        () => PolarColumnGeometryCalculator.calculate(
          categoryScale: categories,
          numericScale: values,
          values: const [1],
        ),
        throwsArgumentError,
      );
      expect(
        () => PolarColumnGeometryCalculator.calculate(
          categoryScale: categories,
          numericScale: values,
          values: const [1, 2],
          baseline: 11,
        ),
        throwsArgumentError,
      );
      expect(
        () => PolarColumnGeometryCalculator.calculate(
          categoryScale: categories,
          numericScale: values,
          values: const [1, -1],
        ),
        throwsArgumentError,
      );
      expect(
        () => PolarColumnGeometryCalculator.calculate(
          categoryScale: categories,
          numericScale: values,
          values: const [1, 2],
          cornerRadius: double.nan,
        ),
        throwsArgumentError,
      );
      expect(
        () => PolarColumnGeometryCalculator.calculate(
          categoryScale: categories,
          numericScale: values,
          values: const [1, 2],
          groupIndex: 2,
          groupCount: 2,
        ),
        throwsArgumentError,
      );
      expect(
        () => PolarColumnGeometryCalculator.calculate(
          categoryScale: categories,
          numericScale: values,
          values: const [1, 2],
          groupInnerPadding: 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
