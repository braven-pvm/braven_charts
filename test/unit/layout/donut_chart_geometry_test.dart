import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/layout/pie_chart_geometry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Donut radial geometry', () {
    test('creates a shared circular opening with annular hit testing', () {
      final series = DonutChartSeries.fromMap(
        id: 'ring',
        values: const {'Only': 1},
        donutStyle: const DonutChartStyle(
          innerRadiusFactor: 0.5,
          radiusFactor: 1,
          sliceGap: 0,
        ),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(200),
      );

      expect(geometry.center, const Offset(100, 100));
      expect(geometry.innerRadius, 50);
      expect(geometry.outerRadius, 100);
      expect(geometry.sliceAt(geometry.center), isNull);
      expect(geometry.sliceAt(const Offset(125, 100)), isNull);
      expect(geometry.sliceAt(const Offset(175, 100))?.pointIndex, 0);
    });

    test('distributes category shares across a configured partial sweep', () {
      final series = DonutChartSeries.fromMap(
        id: 'semi',
        values: const {'First': 1, 'Second': 1},
        donutStyle: const DonutChartStyle(
          innerRadiusFactor: 0.5,
          startAngleDegrees: -90,
          sweepAngleDegrees: 180,
          radiusFactor: 1,
          sliceGap: 0,
        ),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(200),
      );

      expect(geometry.slices.map((slice) => slice.sweepAngle), [
        closeTo(math.pi / 2, 1e-9),
        closeTo(math.pi / 2, 1e-9),
      ]);
      expect(geometry.sliceAt(const Offset(150, 50))?.pointIndex, 0);
      expect(geometry.sliceAt(const Offset(150, 150))?.pointIndex, 1);
      expect(geometry.sliceAt(const Offset(25, 100)), isNull);
    });

    test('supports counter-clockwise partial sweeps', () {
      final series = DonutChartSeries.fromMap(
        id: 'counter-clockwise',
        values: const {'A': 1, 'B': 1},
        donutStyle: const DonutChartStyle(
          clockwise: false,
          sweepAngleDegrees: 240,
          sliceGap: 0,
        ),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(200),
      );

      expect(geometry.slices.every((slice) => slice.sweepAngle < 0), isTrue);
      expect(
        geometry.slices.fold<double>(
          0,
          (sum, slice) => sum + slice.sweepAngle.abs(),
        ),
        closeTo(240 * math.pi / 180, 1e-9),
      );
    });

    test('maps variable radius across available ring thickness', () {
      final series = DonutChartSeries.fromMap(
        id: 'variable-ring',
        values: const {'Small': 1, 'Large': 1},
        radiusValues: const {'Small': 1, 'Large': 9},
        sliceRadiusConfig: const RadialSliceRadiusConfig(
          minimumFactor: 0.25,
          scale: PieSliceRadiusScale.linear,
        ),
        donutStyle: const DonutChartStyle(
          innerRadiusFactor: 0.5,
          radiusFactor: 1,
          sliceGap: 0,
        ),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(200),
      );

      expect(geometry.innerRadius, 50);
      expect(geometry.slices.first.outerRadius, closeTo(62.5, 1e-9));
      expect(geometry.slices.last.outerRadius, closeTo(100, 1e-9));
      expect(
        geometry.slices.every(
          (slice) => slice.outerRadius > geometry.innerRadius,
        ),
        isTrue,
      );
    });

    test('uses angular padding while retaining one unexploded ring center', () {
      final series = DonutChartSeries.fromMap(
        id: 'gapped-ring',
        values: const {'A': 1, 'B': 1, 'C': 1},
        donutStyle: const DonutChartStyle(
          innerRadiusFactor: 0.55,
          radiusFactor: 1,
          sliceGap: 10,
        ),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(240),
      );

      expect(
        geometry.slices.every((slice) => slice.center == geometry.center),
        isTrue,
      );
      expect(
        geometry.slices.every((slice) => slice.spacingOffset == Offset.zero),
        isTrue,
      );
      final firstBoundary =
          geometry.slices.first.startAngle + geometry.slices.first.sweepAngle;
      final gapPoint =
          geometry.center + Offset.fromDirection(firstBoundary, 90);
      expect(geometry.sliceAt(gapPoint), isNull);
    });

    test('rounded annular sectors retain the circular center opening', () {
      final series = DonutChartSeries.fromMap(
        id: 'rounded-ring',
        values: const {'A': 3, 'B': 2, 'C': 1},
        donutStyle: const DonutChartStyle(
          innerRadiusFactor: 0.52,
          radiusFactor: 1,
          sliceGap: 4,
          cornerRadius: 10,
          cornerTreatment: PieCornerTreatment.roundAll,
        ),
      );

      final geometry = PieChartGeometryCalculator.calculate(
        series: series,
        size: const Size.square(240),
        cornerRadius: 10,
        cornerTreatment: PieCornerTreatment.roundAll,
      );

      expect(geometry.sliceAt(geometry.center), isNull);
      expect(
        geometry.slices.every((slice) => slice.path.getBounds() != Rect.zero),
        isTrue,
      );
      for (final slice in geometry.slices) {
        final ringMidpoint =
            geometry.center +
            Offset.fromDirection(
              slice.midAngle,
              slice.innerRadius + (slice.outerRadius - slice.innerRadius) * 0.5,
            );
        expect(slice.contains(ringMidpoint), isTrue);
      }
    });
  });
}
