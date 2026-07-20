import 'package:braven_charts/braven_charts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChartSelectionMetricSummary', () {
    test('summarizes finite values and ignores absent or invalid values', () {
      final summary = ChartSelectionMetricSummary.summarize([
        null,
        double.nan,
        double.infinity,
        -2,
        4,
        10,
      ]);

      expect(summary, isNotNull);
      expect(summary!.count, 3);
      expect(summary.minimum, -2);
      expect(summary.maximum, 10);
      expect(summary.sum, 12);
      expect(summary.mean, 4);
    });

    test('returns null when no finite values are available', () {
      expect(
        ChartSelectionMetricSummary.summarize([
          null,
          double.nan,
          double.negativeInfinity,
        ]),
        isNull,
      );
    });
  });

  test('empty result has no references, extents, or aggregates', () {
    const result = ChartSelectionResult.empty();

    expect(result.isEmpty, isTrue);
    expect(result.pointRefs, isEmpty);
    expect(result.extents, isNull);
    expect(result.statistics.pointCount, 0);
    expect(result.statistics.seriesCount, 0);
  });

  test('category summary equality is independent of insertion order', () {
    const first = ChartSelectionStatistics(
      pointCount: 3,
      seriesCount: 1,
      categoryCounts: {'priority': 2, 'monitor': 1},
    );
    const second = ChartSelectionStatistics(
      pointCount: 3,
      seriesCount: 1,
      categoryCounts: {'monitor': 1, 'priority': 2},
    );

    expect(first, second);
    expect(first.hashCode, second.hashCode);
  });
}
