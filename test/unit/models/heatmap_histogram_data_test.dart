// Copyright 2026 Braven Charts contributors
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HeatmapHistogramAxis', () {
    test('uses lower-inclusive bins and includes the final upper boundary', () {
      final axis = HeatmapHistogramAxis(boundaries: const [0, 10, 20]);

      expect(axis.indexOf(0), 0);
      expect(axis.indexOf(9.999), 0);
      expect(axis.indexOf(10), 1);
      expect(axis.indexOf(20), 1);
      expect(axis.indexOf(-0.001), isNull);
      expect(axis.indexOf(20.001), isNull);
      expect(axis.labels, const ['0–10', '10–20']);
    });

    test('validates boundaries and category labels', () {
      expect(
        () => HeatmapHistogramAxis(boundaries: const [0]),
        throwsArgumentError,
      );
      expect(
        () => HeatmapHistogramAxis(boundaries: const [0, 0, 1]),
        throwsArgumentError,
      );
      expect(
        () => HeatmapHistogramAxis(boundaries: const [0, double.infinity]),
        throwsArgumentError,
      );
      expect(
        () => HeatmapHistogramAxis(
          boundaries: const [0, 1, 2],
          labels: const ['only one'],
        ),
        throwsArgumentError,
      );
    });
  });

  group('HeatmapHistogramData', () {
    late HeatmapHistogramData data;

    setUp(() {
      data = HeatmapHistogramData(
        xAxis: HeatmapHistogramAxis(
          boundaries: const [0, 5, 10],
          labels: const ['Low X', 'High X'],
        ),
        yAxis: HeatmapHistogramAxis(
          boundaries: const [0, 50, 100],
          labels: const ['Low Y', 'High Y'],
        ),
        observations: [
          HeatmapHistogramObservation(x: 1, y: 10, weight: 2, pointKey: 'a'),
          HeatmapHistogramObservation(x: 4, y: 49, weight: 3, pointKey: 'b'),
          HeatmapHistogramObservation(
            x: 10,
            y: 100,
            weight: 4,
            pointKey: 'edge',
          ),
          HeatmapHistogramObservation(x: 20, y: 20, weight: 7),
        ],
      );
    });

    test('aggregates count and weight while retaining source identity', () {
      final low = data.binAt(xIndex: 0, yIndex: 0);
      expect(low.count, 2);
      expect(low.totalWeight, 5);
      expect(low.sourceIndices, const [0, 1]);
      expect(low.sourcePointKeys, const ['a', 'b']);

      final finalBin = data.binAt(xIndex: 1, yIndex: 1);
      expect(finalBin.count, 1);
      expect(finalBin.totalWeight, 4);
      expect(finalBin.sourcePointKeys, const ['edge']);

      expect(data.includedObservationCount, 3);
      expect(data.includedWeight, 9);
      expect(data.outsideObservationCount, 1);
      expect(data.outsideWeight, 7);
    });

    test('emits count and weighted canonical cells with stable identities', () {
      final countCells = data.cellsFor();
      final weightedCells = data.cellsFor(
        valueMode: HeatmapHistogramValueMode.weight,
      );

      expect(countCells, hasLength(4));
      expect(countCells.map((cell) => cell.value), const [2, 0, 0, 1]);
      expect(weightedCells.map((cell) => cell.value), const [5, 0, 0, 4]);
      expect(countCells.first.pointKey, 'histogram-0-0');
      expect(countCells.first.label, 'Low Y · Low X');
      expect(countCells.first.metadata, containsPair('histogramCount', 2));
      expect(
        countCells.first.metadata,
        containsPair('histogramSourcePointKeys', const ['a', 'b']),
      );
    });

    test('represents empty bins as zero, missing, or absent', () {
      final zeros = data.cellsFor();
      final missing = data.cellsFor(
        emptyBinMode: HeatmapHistogramEmptyBinMode.missing,
      );
      final omitted = data.cellsFor(
        emptyBinMode: HeatmapHistogramEmptyBinMode.omit,
      );

      expect(zeros.where((cell) => cell.value == 0), hasLength(2));
      expect(missing.where((cell) => cell.isMissing), hasLength(2));
      expect(omitted, hasLength(2));
      expect(omitted.map((cell) => cell.pointKey), [
        'histogram-0-0',
        'histogram-1-1',
      ]);
    });

    test('outputs are immutable and reject duplicate raw identities', () {
      expect(
        () => data.observations.add(HeatmapHistogramObservation(x: 1, y: 1)),
        throwsUnsupportedError,
      );
      expect(() => data.bins.add(data.bins.first), throwsUnsupportedError);
      expect(
        () => data.bins.first.sourceIndices.add(99),
        throwsUnsupportedError,
      );
      expect(
        () => HeatmapHistogramData(
          xAxis: HeatmapHistogramAxis(boundaries: const [0, 1]),
          yAxis: HeatmapHistogramAxis(boundaries: const [0, 1]),
          observations: [
            HeatmapHistogramObservation(x: 0, y: 0, pointKey: 'duplicate'),
            HeatmapHistogramObservation(x: 1, y: 1, pointKey: 'duplicate'),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid observation values and weights', () {
      expect(
        () => HeatmapHistogramObservation(x: double.nan, y: 0),
        throwsArgumentError,
      );
      expect(
        () => HeatmapHistogramObservation(x: 0, y: double.infinity),
        throwsArgumentError,
      );
      expect(
        () => HeatmapHistogramObservation(x: 0, y: 0, weight: -1),
        throwsArgumentError,
      );
      expect(
        () => HeatmapHistogramObservation(x: 0, y: 0, pointKey: ''),
        throwsArgumentError,
      );
    });
  });
}
