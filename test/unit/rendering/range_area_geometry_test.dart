import 'dart:ui';

import 'package:braven_charts/braven_charts.dart';
import 'package:braven_charts/src/rendering/range_area_geometry.dart';
import 'package:braven_charts/src/utils/interpolation_geometry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RangeAreaGeometryEngine', () {
    test('builds upper, lower, fill, and source identity', () {
      final points = [
        RangeAreaDataPoint(x: 0, low: 2, high: 10),
        RangeAreaDataPoint(x: 5, low: 4, high: 14),
        RangeAreaDataPoint(x: 10, low: 3, high: 12),
      ];
      final run = RangeAreaGeometryEngine.resolve(
        index: RangeAreaViewportIndex(points),
        transform: _transform(),
        interpolation: LineInterpolation.linear,
      ).single;

      expect(run.sourcePointIndices, [0, 1, 2]);
      expect(run.points.first.upper, const Offset(0, 100));
      expect(run.points.first.lower, const Offset(0, 180));
      expect(run.points.last.upper, const Offset(1000, 80));
      expect(run.points.last.lower, const Offset(1000, 170));
      expect(run.upperSegments, hasLength(2));
      expect(run.lowerSegments, hasLength(2));
      expect(run.paintBounds.left, 0);
      expect(run.paintBounds.right, 1000);
      expect(run.paintBounds.top, 60);
      expect(run.paintBounds.bottom, 180);
    });

    test('splits disconnected gaps and bridges connected gaps', () {
      final index = RangeAreaViewportIndex([
        RangeAreaDataPoint(x: 0, low: 2, high: 8),
        RangeAreaDataPoint.gap(x: 1),
        RangeAreaDataPoint(x: 2, low: 3, high: 9),
      ]);

      final split = RangeAreaGeometryEngine.resolve(
        index: index,
        transform: _transform(),
        interpolation: LineInterpolation.linear,
      );
      final connected = RangeAreaGeometryEngine.resolve(
        index: index,
        transform: _transform(),
        interpolation: LineInterpolation.linear,
        connectGaps: true,
      );

      expect(split, hasLength(2));
      expect(split.map((run) => run.sourcePointIndices), [
        [0],
        [2],
      ]);
      expect(connected, hasLength(1));
      expect(connected.single.sourcePointIndices, [0, 2]);
      expect(connected.single.upperSegments, hasLength(1));
    });

    test('uses exact reversed cubic controls for the lower boundary', () {
      final run = RangeAreaGeometryEngine.resolve(
        index: RangeAreaViewportIndex([
          RangeAreaDataPoint(x: 0, low: 2, high: 8),
          RangeAreaDataPoint(x: 5, low: 5, high: 14),
          RangeAreaDataPoint(x: 10, low: 4, high: 10),
        ]),
        transform: _transform(),
        interpolation: LineInterpolation.monotone,
      ).single;

      final lower = run.lowerSegments.last as CubicPathInterpolationSegment;
      final reversed = lower.reversed;
      expect(reversed.startX, lower.cubic.endX);
      expect(reversed.startY, lower.cubic.endY);
      expect(reversed.control1X, lower.cubic.control2X);
      expect(reversed.control1Y, lower.cubic.control2Y);
      expect(reversed.control2X, lower.cubic.control1X);
      expect(reversed.control2Y, lower.cubic.control1Y);
      expect(reversed.endX, lower.cubic.startX);
      expect(reversed.endY, lower.cubic.startY);
    });

    test('binary-searches 50,000 points and resolves only visible data', () {
      final geometry = RangeAreaGeometryEngine.resolve(
        index: RangeAreaViewportIndex([
          for (var index = 0; index < 50000; index++)
            RangeAreaDataPoint(
              x: index.toDouble(),
              low: index.isEven ? 10 : 11,
              high: index.isEven ? 20 : 21,
            ),
        ]),
        transform: const ChartTransform(
          dataXMin: 25000,
          dataXMax: 25999,
          dataYMin: 0,
          dataYMax: 30,
          plotWidth: 1000,
          plotHeight: 300,
        ),
        interpolation: LineInterpolation.monotone,
      );

      expect(geometry, hasLength(1));
      expect(geometry.single.points.length, inInclusiveRange(1000, 1002));
      expect(
        geometry.single.sourcePointIndices.first,
        inInclusiveRange(24999, 25000),
      );
      expect(
        geometry.single.sourcePointIndices.last,
        inInclusiveRange(25999, 26000),
      );
    });

    test('returns no geometry outside the source domain', () {
      final geometry = RangeAreaGeometryEngine.resolve(
        index: RangeAreaViewportIndex([
          RangeAreaDataPoint(x: 5, low: 2, high: 8),
        ]),
        transform: const ChartTransform(
          dataXMin: 10,
          dataXMax: 20,
          dataYMin: 0,
          dataYMax: 10,
          plotWidth: 100,
          plotHeight: 100,
        ),
        interpolation: LineInterpolation.linear,
      );

      expect(geometry, isEmpty);
    });
  });
}

ChartTransform _transform() => const ChartTransform(
  dataXMin: 0,
  dataXMax: 10,
  dataYMin: 0,
  dataYMax: 20,
  plotWidth: 1000,
  plotHeight: 200,
);
