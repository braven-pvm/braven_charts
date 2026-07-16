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

    test('physical gaps reduce sweep and reject points in the gap', () {
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

      expect(geometry.slices.first.sweepAngle, lessThan(math.pi));
      expect(geometry.sliceAt(const Offset(200, 100)), isNull);
      expect(geometry.sliceAt(const Offset(100, 180))?.pointIndex, 0);
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
