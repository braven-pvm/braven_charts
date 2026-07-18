// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HistogramChartData', () {
    test('creates equal-width fixed bins and includes the maximum', () {
      final data = HistogramChartData(
        samples: const [0, 1, 2, 3, 4, 5, 6, 7],
        method: HistogramBinningMethod.fixedCount,
        requestedBinCount: 4,
      );

      expect(data.bins, hasLength(4));
      expect(data.binWidth, 1.75);
      expect(data.bins.map((bin) => bin.count), [2, 2, 2, 2]);
      expect(data.bins.last.contains(7), isTrue);
      expect(
        data.bins.take(3).every((bin) => !bin.contains(bin.upperBound)),
        isTrue,
      );
    });

    test('supports automatic binning methods with bounded counts', () {
      final samples = [
        for (var index = 1; index <= 100; index++) index.toDouble(),
      ];

      expect(
        HistogramChartData(
          samples: samples,
          method: HistogramBinningMethod.squareRoot,
        ).bins,
        hasLength(10),
      );
      expect(
        HistogramChartData(
          samples: samples,
          method: HistogramBinningMethod.sturges,
        ).bins,
        hasLength(8),
      );
      expect(
        HistogramChartData(
          samples: samples,
          method: HistogramBinningMethod.freedmanDiaconis,
          maxBinCount: 3,
        ).bins,
        hasLength(3),
      );
    });

    test('exposes count, percentage, and density point values', () {
      final data = HistogramChartData(
        samples: const [0, 1, 2, 3],
        method: HistogramBinningMethod.fixedCount,
        requestedBinCount: 2,
      );

      expect(data.pointsFor(HistogramValueMode.count).map((point) => point.y), [
        2,
        2,
      ]);
      expect(
        data.pointsFor(HistogramValueMode.percentage).map((point) => point.y),
        [50, 50],
      );
      expect(
        data.pointsFor(HistogramValueMode.density).map((point) => point.y),
        everyElement(closeTo(1 / 3, 0.000001)),
      );
      expect(
        data.pointsFor(HistogramValueMode.count).map((point) => point.label),
        data.bins.map((bin) => bin.label),
      );
    });

    test('collapses a constant sample into one visible bin', () {
      final data = HistogramChartData(samples: const [5, 5, 5]);

      expect(data.bins, hasLength(1));
      expect(data.bins.single.count, 3);
      expect(data.bins.single.contains(5), isTrue);
      expect(data.binWidth, 0.5);
    });

    test('supports empty data and immutable outputs', () {
      final empty = HistogramChartData(samples: const []);
      expect(empty.bins, isEmpty);
      expect(empty.pointsFor(HistogramValueMode.count), isEmpty);
      expect(empty.minimum, isNull);
      expect(empty.maximum, isNull);

      final data = HistogramChartData(samples: const [1, 2]);
      expect(() => data.samples.add(3), throwsUnsupportedError);
      expect(
        () => data
            .pointsFor(HistogramValueMode.count)
            .add(const ChartDataPoint(x: 2, y: 1)),
        throwsUnsupportedError,
      );
    });

    test('rejects invalid samples and bin limits', () {
      for (final value in [double.nan, double.infinity]) {
        expect(() => HistogramChartData(samples: [value]), throwsArgumentError);
      }
      expect(
        () => HistogramChartData(samples: const [1], requestedBinCount: 0),
        throwsArgumentError,
      );
      expect(
        () => HistogramChartData(samples: const [1], maxBinCount: 0),
        throwsArgumentError,
      );
    });
  });
}
