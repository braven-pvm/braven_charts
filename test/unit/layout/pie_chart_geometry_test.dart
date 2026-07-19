import 'dart:math' as math;

import 'package:braven_charts/src/layout/pie_chart_geometry.dart';
import 'package:braven_charts/braven_charts.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PieChartGeometryCalculator', () {
    test('builds one full slice from the configured top start angle', () {
      final series = PieChartSeries.fromMap(
        id: 'single',
        values: const {'Only': 5},
        pieStyle: const PieChartStyle(sliceGap: 12, radiusFactor: 1),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size(200, 120),
      );

      expect(geometry.center, const Offset(100, 60));
      expect(geometry.outerRadius, 60);
      expect(geometry.total, 5);
      expect(geometry.slices, hasLength(1));
      expect(geometry.slices.single.share, 1);
      expect(geometry.slices.single.startAngle, closeTo(-math.pi / 2, 1e-9));
      expect(geometry.slices.single.sweepAngle, closeTo(math.pi * 2, 1e-9));
      expect(geometry.sliceAt(const Offset(100, 20))?.pointIndex, 0);
    });

    test('preserves source indices while omitting zero-valued geometry', () {
      final series = PieChartSeries.fromMap(
        id: 'shares',
        values: const {'A': 1, 'Zero': 0, 'B': 3},
        pieStyle: const PieChartStyle(sliceGap: 0),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(200),
      );

      expect(geometry.slices.map((slice) => slice.pointIndex), [0, 2]);
      expect(geometry.slices.map((slice) => slice.share), [0.25, 0.75]);
      expect(geometry.slices.map((slice) => slice.sweepAngle), [
        closeTo(math.pi / 2, 1e-9),
        closeTo(math.pi * 1.5, 1e-9),
      ]);
    });

    test('maps a second metric to independent perceptual slice radii', () {
      final series = PieChartSeries.fromMap(
        id: 'variable-radius',
        values: const {'Small': 1, 'Medium': 1, 'Large': 1},
        radiusValues: const {'Small': 1, 'Medium': 4, 'Large': 9},
        sliceRadiusConfig: const PieSliceRadiusConfig(minimumFactor: 0.25),
        pieStyle: const PieChartStyle(sliceGap: 0, radiusFactor: 1),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(200),
      );

      expect(geometry.outerRadius, 100);
      expect(geometry.slices.map((slice) => slice.radiusFactor), [
        closeTo(0.25, 1e-9),
        closeTo(math.sqrt(0.4140625), 1e-9),
        closeTo(1, 1e-9),
      ]);
      expect(geometry.slices.map((slice) => slice.outerRadius), [
        closeTo(25, 1e-9),
        closeTo(math.sqrt(0.4140625) * 100, 1e-9),
        closeTo(100, 1e-9),
      ]);

      final smallMidAngle = geometry.slices.first.midAngle;
      expect(
        geometry
            .sliceAt(geometry.center + Offset.fromDirection(smallMidAngle, 20))
            ?.pointIndex,
        0,
      );
      expect(
        geometry.sliceAt(
          geometry.center + Offset.fromDirection(smallMidAngle, 50),
        ),
        isNull,
      );
    });

    test(
      'supports linear scaling and treats an equal radius domain uniformly',
      () {
        final linear = PieChartSeries.fromMap(
          id: 'linear-radius',
          values: const {'A': 1, 'B': 1, 'C': 1},
          radiusValues: const {'A': 1, 'B': 4, 'C': 9},
          sliceRadiusConfig: const PieSliceRadiusConfig(
            minimumFactor: 0.25,
            scale: PieSliceRadiusScale.linear,
          ),
          pieStyle: const PieChartStyle(sliceGap: 0, radiusFactor: 1),
        );
        final equal = PieChartSeries.fromMap(
          id: 'equal-radius',
          values: const {'A': 1, 'B': 1},
          radiusValues: const {'A': 5, 'B': 5},
          pieStyle: const PieChartStyle(sliceGap: 0, radiusFactor: 1),
        );

        final linearGeometry = PieChartGeometryCalculator.calculate(
          series: linear,
          size: const Size.square(200),
        );
        final equalGeometry = PieChartGeometryCalculator.calculate(
          series: equal,
          size: const Size.square(200),
        );

        expect(linearGeometry.slices[1].radiusFactor, closeTo(0.53125, 1e-9));
        expect(equalGeometry.slices.map((slice) => slice.radiusFactor), [1, 1]);
        expect(equalGeometry.slices.map((slice) => slice.outerRadius), [
          100,
          100,
        ]);
      },
    );

    test('counter-clockwise configuration produces signed negative sweeps', () {
      final series = PieChartSeries.fromMap(
        id: 'counter',
        values: const {'A': 1, 'B': 1},
        pieStyle: const PieChartStyle(
          clockwise: false,
          startAngleDegrees: 0,
          sliceGap: 0,
        ),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(100),
      );

      expect(geometry.slices.first.sweepAngle, closeTo(-math.pi, 1e-9));
      expect(geometry.slices.last.startAngle, closeTo(-math.pi, 1e-9));
      expect(geometry.sliceAt(const Offset(50, 25))?.pointIndex, 0);
    });

    test('wraparound hit testing resolves both sides of zero radians', () {
      final series = PieChartSeries.fromMap(
        id: 'wrap',
        values: const {'Wide': 3, 'Narrow': 1},
        pieStyle: const PieChartStyle(
          startAngleDegrees: 315,
          sliceGap: 0,
          radiusFactor: 1,
        ),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(200),
      );

      expect(geometry.sliceAt(const Offset(180, 100))?.pointIndex, 0);
      expect(geometry.sliceAt(const Offset(180, 80))?.pointIndex, 0);
      expect(geometry.sliceAt(const Offset(100, 20))?.pointIndex, 1);
    });

    test('physical gaps preserve sweep and translate slices apart', () {
      final series = PieChartSeries.fromMap(
        id: 'gapped',
        values: const {'A': 1, 'B': 1},
        pieStyle: const PieChartStyle(
          startAngleDegrees: 0,
          radiusFactor: 1,
          sliceGap: 10,
        ),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(200),
      );

      expect(geometry.slices.first.sweepAngle, closeTo(math.pi, 1e-9));
      expect(geometry.slices.first.spacingOffset, isNot(Offset.zero));
      expect(geometry.slices.last.spacingOffset, isNot(Offset.zero));
      expect(geometry.slices.first.spacingOffset.dy, greaterThan(0));
      expect(geometry.slices.last.spacingOffset.dy, lessThan(0));
      expect(geometry.sliceAt(const Offset(200, 100)), isNull);
      expect(geometry.sliceAt(const Offset(100, 100)), isNull);
      expect(geometry.sliceAt(const Offset(100, 180))?.pointIndex, 0);
    });

    test('uneven gapped slices terminate on one shared outer ring', () {
      final series = PieChartSeries.fromMap(
        id: 'uneven-gaps',
        values: const {'Largest': 55, 'Medium': 25, 'Small': 12, 'Tiny': 8},
        pieStyle: const PieChartStyle(radiusFactor: 1, sliceGap: 16),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(240),
      );

      expect(
        geometry.slices.map((slice) => slice.outerRadius).toSet().length,
        greaterThan(1),
      );
      for (final slice in geometry.slices) {
        expect(
          (slice.connectorOrigin - geometry.center).distance,
          closeTo(geometry.outerRadius, 1e-7),
          reason: slice.point.label,
        );
        for (final fraction in const [0.25, 0.5, 0.75]) {
          final angle = slice.startAngle + slice.sweepAngle * fraction;
          final nearOuterRing =
              geometry.center +
              Offset.fromDirection(angle, geometry.outerRadius - 0.5);
          expect(
            slice.contains(nearOuterRing),
            isTrue,
            reason: '${slice.point.label} at sweep fraction $fraction',
          );
        }
      }
    });

    test('rounded corners retain the slice centerline and trim sharp tips', () {
      final series = PieChartSeries.fromMap(
        id: 'rounded',
        values: const {'A': 1, 'B': 1, 'C': 1, 'D': 1},
        pieStyle: const PieChartStyle(
          startAngleDegrees: 0,
          radiusFactor: 1,
          sliceGap: 4,
          cornerRadius: 12,
        ),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(200),
      );
      final first = geometry.slices.first;

      expect(first.sweepAngle, closeTo(math.pi / 2, 1e-9));
      expect(first.contains(first.insideLabelAnchor), isTrue);
      expect(first.path.contains(first.center), isFalse);
      expect(first.path.getBounds(), isNot(Rect.zero));
    });

    test('outer-only rounding preserves a sharp center apex', () {
      final series = PieChartSeries.fromMap(
        id: 'outer-only',
        values: const {'A': 1, 'B': 1, 'C': 1, 'D': 1},
        pieStyle: const PieChartStyle(
          startAngleDegrees: 0,
          radiusFactor: 1,
          sliceGap: 4,
          cornerRadius: 12,
          cornerTreatment: PieCornerTreatment.outerOnly,
        ),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(200),
      );
      final first = geometry.slices.first;
      final nearApex = first.center + Offset.fromDirection(first.midAngle, 0.5);

      expect(geometry.innerRadius, 0);
      expect(first.path.contains(nearApex), isTrue);
      expect(first.path.contains(first.insideLabelAnchor), isTrue);
    });

    test('circular-center rounding cuts one uniform variable-radius gap', () {
      final series = PieChartSeries.fromMap(
        id: 'circular-center',
        values: const {'A': 8, 'B': 6, 'C': 5, 'D': 4},
        radiusValues: const {'A': 100, 'B': 72, 'C': 45, 'D': 20},
        sliceRadiusConfig: const PieSliceRadiusConfig(minimumFactor: 0.35),
        pieStyle: const PieChartStyle(
          startAngleDegrees: 0,
          radiusFactor: 1,
          sliceGap: 7,
          cornerRadius: 14,
          cornerTreatment: PieCornerTreatment.circularCenter,
        ),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(240),
      );

      expect(geometry.innerRadius, greaterThan(0));
      expect(
        geometry.innerRadius,
        lessThan(
          geometry.slices.map((slice) => slice.outerRadius).reduce(math.min),
        ),
      );
      for (final slice in geometry.slices) {
        expect(slice.innerRadius, geometry.innerRadius);
        expect(
          slice.path.contains(
            geometry.center +
                Offset.fromDirection(
                  slice.midAngle,
                  geometry.innerRadius * 0.75,
                ),
          ),
          isFalse,
        );
        expect(
          slice.path.contains(
            geometry.center +
                Offset.fromDirection(slice.midAngle, geometry.innerRadius + 2),
          ),
          isTrue,
        );
      }
    });

    test('grow progress scales radius without changing category shares', () {
      final series = PieChartSeries.fromMap(
        id: 'animated',
        values: const {'A': 1, 'B': 3},
        pieStyle: const PieChartStyle(sliceGap: 0, radiusFactor: 1),
      );

      final full = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(200),
      );
      final halfway = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(200),
        animationProgress: 0.5,
      );

      expect(halfway.outerRadius, closeTo(full.outerRadius / 2, 1e-9));
      expect(halfway.slices.map((slice) => slice.share), [0.25, 0.75]);
      expect(halfway.slices.map((slice) => slice.sweepAngle), [
        closeTo(math.pi / 2, 1e-9),
        closeTo(math.pi * 1.5, 1e-9),
      ]);
    });

    test(
      'explosion shifts only selected source indices along the mid-angle',
      () {
        final series = PieChartSeries.fromMap(
          id: 'exploded',
          values: const {'A': 1, 'B': 1},
          pieStyle: const PieChartStyle(
            startAngleDegrees: 0,
            sliceGap: 0,
            selectionExplodeOffset: 12,
          ),
        );

        final geometry = PieChartGeometryCalculator.calculate(
          series: series,
          size: const Size.square(200),
          explodedPointIndices: const {1},
        );

        expect(geometry.slices.first.explodeOffset, Offset.zero);
        expect(geometry.slices.last.explodeOffset.dx, closeTo(0, 1e-9));
        expect(geometry.slices.last.explodeOffset.dy, closeTo(-12, 1e-9));
        expect(geometry.slices.last.center.dy, closeTo(88, 1e-9));
      },
    );

    test(
      'lift scales the selected slice around its centroid without exploding',
      () {
        final series = PieChartSeries.fromMap(
          id: 'lifted',
          values: const {'A': 2, 'B': 1, 'C': 1},
          pieStyle: const PieChartStyle(
            startAngleDegrees: 0,
            radiusFactor: 0.8,
            sliceGap: 0,
            selectionExplodeOffset: 24,
          ),
          selectionStyle: const RadialSelectionStyle(
            effect: RadialSelectionEffect.lift,
            liftScale: 1.12,
            liftOffset: 8,
          ),
        );

        final base = PieChartGeometryCalculator.calculate(
          series: series,
          size: const Size.square(240),
        );
        final lifted = PieChartGeometryCalculator.calculate(
          series: series,
          size: const Size.square(240),
          explodedPointIndices: const {0},
          selectionEffect: RadialSelectionEffect.lift,
          selectionLiftScale: 1.12,
          selectionLiftOffset: 8,
        );
        final baseSlice = base.slices.first;
        final liftedSlice = lifted.slices.first;

        expect(liftedSlice.isSelected, isTrue);
        expect(liftedSlice.explodeOffset, Offset.zero);
        expect(liftedSlice.liftOffset.distance, closeTo(8, 1e-9));
        expect(liftedSlice.selectionScale, closeTo(1.12, 1e-9));
        expect(
          liftedSlice.path.getBounds().width,
          greaterThan(baseSlice.path.getBounds().width),
        );
        expect(
          liftedSlice.path.getBounds().height,
          greaterThan(baseSlice.path.getBounds().height),
        );
        expect(liftedSlice.tooltipAnchor, isNot(baseSlice.tooltipAnchor));
        expect(lifted.sliceAt(liftedSlice.tooltipAnchor)?.pointIndex, 0);
      },
    );

    test('anchors are deterministic functions of the slice mid-angle', () {
      final series = PieChartSeries.fromMap(
        id: 'anchors',
        values: const {'A': 1, 'B': 3},
        pieStyle: const PieChartStyle(
          startAngleDegrees: 0,
          sliceGap: 0,
          radiusFactor: 1,
        ),
        dataLabels: const PieDataLabelConfig(connectorLength: 10, padding: 5),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(200),
      );
      final first = geometry.slices.first;

      expect(first.midAngle, closeTo(math.pi / 4, 1e-9));
      expect(
        (first.connectorOrigin - first.center).distance,
        closeTo(100, 1e-9),
      );
      expect(
        (first.outsideLabelAnchor - first.center).distance,
        closeTo(115, 1e-9),
      );
      expect(first.path.getBounds(), isNot(Rect.zero));
    });

    test(
      'inside label offset moves radially and stays inside the slice band',
      () {
        PieSliceGeometry sliceAt(double offset) {
          final series = PieChartSeries.fromMap(
            id: 'inside-label-offset-$offset',
            values: const {'Only': 1},
            pieStyle: const PieChartStyle(sliceGap: 0, radiusFactor: 1),
            dataLabels: PieDataLabelConfig(insideOffset: offset),
          );
          return PieChartGeometryCalculator.calculate(
            series: series,
            size: const Size.square(200),
          ).slices.single;
        }

        double anchorRadius(PieSliceGeometry slice) =>
            (slice.insideLabelAnchor - slice.center).distance;

        expect(anchorRadius(sliceAt(0)), closeTo(58, 1e-9));
        expect(anchorRadius(sliceAt(20)), closeTo(78, 1e-9));
        expect(anchorRadius(sliceAt(-20)), closeTo(38, 1e-9));
        expect(anchorRadius(sliceAt(200)), closeTo(100, 1e-9));
        expect(anchorRadius(sliceAt(-200)), closeTo(0, 1e-9));
      },
    );

    test('inside label radius factor can center an allocated ring band', () {
      PieSliceGeometry sliceAt({
        double insideLabelRadiusFactor = 0.58,
        double insideOffset = 0,
      }) {
        final series = DonutChartSeries.fromMap(
          id: 'allocated-ring',
          values: const {'Only': 1},
          dataLabels: PieDataLabelConfig(insideOffset: insideOffset),
          donutStyle: const DonutChartStyle(
            sliceGap: 0,
            animationMode: PieAnimationMode.none,
          ),
        );
        return PieChartGeometryCalculator.calculate(
          series: series,
          size: const Size.square(200),
          centerOverride: const Offset(100, 100),
          innerRadiusOverride: 20,
          outerRadiusOverride: 80,
          insideLabelRadiusFactor: insideLabelRadiusFactor,
        ).slices.single;
      }

      double anchorRadius(PieSliceGeometry slice) =>
          (slice.insideLabelAnchor - slice.center).distance;

      expect(anchorRadius(sliceAt()), closeTo(54.8, 1e-9));
      expect(
        anchorRadius(sliceAt(insideLabelRadiusFactor: 0.5)),
        closeTo(50, 1e-9),
      );
      expect(
        anchorRadius(sliceAt(insideLabelRadiusFactor: 0.5, insideOffset: 8)),
        closeTo(58, 1e-9),
      );
    });

    test('inner-radius seam rejects the center and accepts the ring', () {
      final series = PieChartSeries.fromMap(
        id: 'future-ring',
        values: const {'A': 1},
        pieStyle: const PieChartStyle(sliceGap: 0, radiusFactor: 1),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(200),
        innerRadiusFactor: 0.5,
      );

      expect(geometry.sliceAt(const Offset(100, 100)), isNull);
      expect(geometry.sliceAt(const Offset(175, 100))?.pointIndex, 0);
    });

    test('all-zero and zero-size inputs produce stable empty geometry', () {
      final allZero = PieChartSeries.fromMap(
        id: 'zero',
        values: const {'A': 0, 'B': 0},
      );
      final positive = PieChartSeries.fromMap(
        id: 'positive',
        values: const {'A': 1},
      );

      final zeroDataGeometry = PieChartGeometryCalculator.calculate(
        series: allZero,
        size: const Size.square(200),
      );
      final zeroSizeGeometry = PieChartGeometryCalculator.calculate(
        series: positive,
        size: Size.zero,
      );

      expect(zeroDataGeometry.total, 0);
      expect(zeroDataGeometry.slices, isEmpty);
      expect(zeroSizeGeometry.total, 1);
      expect(zeroSizeGeometry.outerRadius, 0);
      expect(zeroSizeGeometry.slices, isEmpty);
    });

    test(
      'padding and radius factor determine the shared center and radius',
      () {
        final series = PieChartSeries.fromMap(
          id: 'padded',
          values: const {'A': 1},
          pieStyle: const PieChartStyle(radiusFactor: 0.5),
        );

        final geometry = PieChartGeometryCalculator.calculate(
          series: series,
          size: const Size(300, 200),
          padding: const EdgeInsets.fromLTRB(20, 10, 40, 30),
        );

        expect(geometry.center, const Offset(140, 90));
        expect(geometry.outerRadius, 40);
      },
    );

    test('rejects invalid size and future inner-radius requests', () {
      final series = PieChartSeries.fromMap(
        id: 'invalid-geometry',
        values: const {'A': 1},
      );

      expect(
        () => PieChartGeometryCalculator.calculate(
          series: series,
          size: const Size(double.infinity, 100),
        ),
        throwsArgumentError,
      );
      expect(
        () => PieChartGeometryCalculator.calculate(
          series: series,
          size: const Size.square(100),
          padding: const EdgeInsets.only(left: -1),
        ),
        throwsArgumentError,
      );
      expect(
        () => PieChartGeometryCalculator.calculate(
          series: series,
          size: const Size.square(100),
          innerRadiusFactor: 1,
        ),
        throwsArgumentError,
      );
    });
  });
}
