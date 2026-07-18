// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ParetoChartData', () {
    test('sorts descending, preserves ties, and aligns both point sets', () {
      final data = ParetoChartData(
        categories: const [
          ParetoCategory(label: 'Low', value: 20),
          ParetoCategory(label: 'First tie', value: 30),
          ParetoCategory(label: 'High', value: 50),
          ParetoCategory(label: 'Second tie', value: 30),
        ],
      );

      expect(data.categories.map((category) => category.label), [
        'High',
        'First tie',
        'Second tie',
        'Low',
      ]);
      expect(data.valuePoints.map((point) => point.x), [0, 1, 2, 3]);
      expect(
        data.valuePoints.map((point) => point.label),
        data.cumulativePoints.map((point) => point.label),
      );
    });

    test(
      'calculates cumulative percentages and pins the final value to 100',
      () {
        final data = ParetoChartData(
          categories: const [
            ParetoCategory(label: 'A', value: 50),
            ParetoCategory(label: 'B', value: 30),
            ParetoCategory(label: 'C', value: 20),
          ],
        );

        expect(data.total, 100);
        expect(data.cumulativePercentages, [50, 80, 100]);
        expect(data.cumulativePoints.map((point) => point.y), [50, 80, 100]);
        expect(data.firstIndexAtOrAbove(80), 1);
        expect(data.firstIndexAtOrAbove(100), 2);
      },
    );

    test('supports an empty composition', () {
      final data = ParetoChartData(categories: const []);

      expect(data.categories, isEmpty);
      expect(data.valuePoints, isEmpty);
      expect(data.cumulativePoints, isEmpty);
      expect(data.total, 0);
      expect(data.firstIndexAtOrAbove(80), isNull);
    });

    test('exposes unmodifiable prepared collections', () {
      final data = ParetoChartData(
        categories: const [ParetoCategory(label: 'A', value: 1)],
      );

      expect(
        () => data.categories.add(const ParetoCategory(label: 'B', value: 2)),
        throwsUnsupportedError,
      );
      expect(() => data.cumulativePercentages.add(50), throwsUnsupportedError);
      expect(
        () => data.valuePoints.add(const ChartDataPoint(x: 1, y: 2)),
        throwsUnsupportedError,
      );
    });

    test('rejects invalid category inputs', () {
      expect(
        () => ParetoChartData(
          categories: const [ParetoCategory(label: '', value: 1)],
        ),
        throwsArgumentError,
      );
      expect(
        () => ParetoChartData(
          categories: const [
            ParetoCategory(label: 'A', value: 1),
            ParetoCategory(label: 'A', value: 2),
          ],
        ),
        throwsArgumentError,
      );
      for (final value in [-1.0, double.nan, double.infinity]) {
        expect(
          () => ParetoChartData(
            categories: [ParetoCategory(label: 'A', value: value)],
          ),
          throwsArgumentError,
        );
      }
      expect(
        () => ParetoChartData(
          categories: const [
            ParetoCategory(label: 'A', value: 0),
            ParetoCategory(label: 'B', value: 0),
          ],
        ),
        throwsArgumentError,
      );
    });

    test('rejects invalid threshold percentages', () {
      final data = ParetoChartData(
        categories: const [ParetoCategory(label: 'A', value: 1)],
      );

      for (final value in [-1.0, 101.0, double.nan]) {
        expect(() => data.firstIndexAtOrAbove(value), throwsArgumentError);
      }
    });
  });
}
