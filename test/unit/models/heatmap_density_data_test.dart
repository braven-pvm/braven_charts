import 'dart:math' as math;

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapDensityAxis', () {
    test('samples deterministic cell centres and bounds', () {
      final axis = HeatmapDensityAxis(minimum: 0, maximum: 10, cellCount: 4);

      expect(axis.cellExtent, 2.5);
      expect(axis.centerAt(0), 1.25);
      expect(axis.centerAt(3), 8.75);
      expect(axis.lowerBoundAt(0), 0);
      expect(axis.upperBoundAt(3), 10);
      expect(axis.labels, ['1.3', '3.8', '6.3', '8.8']);
    });

    test('validates domain cell count and labels', () {
      expect(
        () => HeatmapDensityAxis(minimum: 1, maximum: 1, cellCount: 2),
        throwsArgumentError,
      );
      expect(
        () => HeatmapDensityAxis(minimum: 0, maximum: 1, cellCount: 0),
        throwsArgumentError,
      );
      expect(
        () => HeatmapDensityAxis(
          minimum: 0,
          maximum: 1,
          cellCount: 2,
          labels: const ['only-one'],
        ),
        throwsArgumentError,
      );
    });
  });

  group('HeatmapDensityData', () {
    test('evaluates finite-support Epanechnikov density and provenance', () {
      final data = HeatmapDensityData(
        xAxis: HeatmapDensityAxis(minimum: 0, maximum: 10, cellCount: 2),
        yAxis: HeatmapDensityAxis(minimum: 0, maximum: 10, cellCount: 2),
        bandwidthX: 2,
        bandwidthY: 2,
        kernel: HeatmapDensityKernel.epanechnikov,
        observations: [
          HeatmapDensityObservation(x: 2.5, y: 2.5, pointKey: 'origin-cluster'),
        ],
      );

      expect(data.cells, hasLength(4));
      expect(data.cellAt(xIndex: 0, yIndex: 0).density, 0.140625);
      expect(data.cellAt(xIndex: 0, yIndex: 0).relativeDensity, 1);
      expect(data.cellAt(xIndex: 0, yIndex: 0).sourcePointKeys, [
        'origin-cluster',
      ]);
      expect(data.cellAt(xIndex: 1, yIndex: 0).density, 0);
      expect(data.cellAt(xIndex: 1, yIndex: 0).sourceIndices, isEmpty);
    });

    test('Gaussian estimate is normalized and symmetric', () {
      final data = HeatmapDensityData(
        xAxis: HeatmapDensityAxis(minimum: -2, maximum: 2, cellCount: 5),
        yAxis: HeatmapDensityAxis(minimum: -2, maximum: 2, cellCount: 5),
        bandwidthX: 1,
        bandwidthY: 1,
        observations: [HeatmapDensityObservation(x: 0, y: 0)],
      );

      final center = data.cellAt(xIndex: 2, yIndex: 2);
      expect(center.density, closeTo(1 / (2 * math.pi), 1e-12));
      expect(center.relativeDensity, 1);
      expect(
        data.cellAt(xIndex: 1, yIndex: 2).density,
        closeTo(data.cellAt(xIndex: 3, yIndex: 2).density, 1e-12),
      );
    });

    test('wider bandwidth raises density away from a source', () {
      HeatmapDensityData estimate(double bandwidth) => HeatmapDensityData(
        xAxis: HeatmapDensityAxis(minimum: -4, maximum: 4, cellCount: 9),
        yAxis: HeatmapDensityAxis(minimum: -4, maximum: 4, cellCount: 9),
        bandwidthX: bandwidth,
        bandwidthY: bandwidth,
        observations: [HeatmapDensityObservation(x: 0, y: 0)],
      );

      final narrow = estimate(0.5);
      final wide = estimate(2);
      expect(
        wide.cellAt(xIndex: 6, yIndex: 4).density,
        greaterThan(narrow.cellAt(xIndex: 6, yIndex: 4).density),
      );
    });

    test('canonical cells retain stable identity and density metadata', () {
      final data = HeatmapDensityData(
        xAxis: HeatmapDensityAxis(
          minimum: 0,
          maximum: 2,
          cellCount: 2,
          labels: const ['Left', 'Right'],
        ),
        yAxis: HeatmapDensityAxis(
          minimum: 0,
          maximum: 2,
          cellCount: 2,
          labels: const ['Bottom', 'Top'],
        ),
        bandwidthX: 1,
        bandwidthY: 1,
        observations: [
          HeatmapDensityObservation(x: 0.5, y: 0.5, pointKey: 'sample-a'),
        ],
      );

      final relative = data.cellsFor();
      final absolute = data.cellsFor(
        valueMode: HeatmapDensityValueMode.density,
      );
      expect(relative.map((cell) => cell.pointKey), [
        'density-0-0',
        'density-0-1',
        'density-1-0',
        'density-1-1',
      ]);
      expect(relative.first.value, 1);
      expect(absolute.first.value, data.maximumDensity);
      expect(relative.first.label, 'Bottom · Left');
      expect(relative.first.metadata?['densityKernel'], 'gaussian');
      expect(relative.first.metadata?['densitySourcePointKeys'], ['sample-a']);
    });

    test('zero-weight sources produce a finite zero raster', () {
      final data = HeatmapDensityData(
        xAxis: HeatmapDensityAxis(minimum: 0, maximum: 1, cellCount: 2),
        yAxis: HeatmapDensityAxis(minimum: 0, maximum: 1, cellCount: 2),
        bandwidthX: 0.2,
        bandwidthY: 0.2,
        observations: [HeatmapDensityObservation(x: 0.5, y: 0.5, weight: 0)],
      );

      expect(data.totalWeight, 0);
      expect(data.maximumDensity, 0);
      expect(data.cells.every((cell) => cell.relativeDensity == 0), isTrue);
    });

    test('rejects invalid bandwidths observations and duplicate keys', () {
      final axis = HeatmapDensityAxis(minimum: 0, maximum: 1, cellCount: 2);
      expect(
        () => HeatmapDensityData(
          xAxis: axis,
          yAxis: axis,
          bandwidthX: 0,
          bandwidthY: 1,
          observations: const [],
        ),
        throwsArgumentError,
      );
      expect(
        () => HeatmapDensityObservation(x: double.nan, y: 0),
        throwsArgumentError,
      );
      expect(
        () => HeatmapDensityData(
          xAxis: axis,
          yAxis: axis,
          bandwidthX: 1,
          bandwidthY: 1,
          observations: [
            HeatmapDensityObservation(x: 0, y: 0, pointKey: 'duplicate'),
            HeatmapDensityObservation(x: 1, y: 1, pointKey: 'duplicate'),
          ],
        ),
        throwsArgumentError,
      );
    });
  });
}
