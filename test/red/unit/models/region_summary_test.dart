// @orchestra-task: 1
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:braven_charts/src/models/region_summary.dart';
import 'package:braven_charts/src/models/region_summary_config.dart';
import 'package:braven_charts/src/models/data_region.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';

void main() {
  group('RegionMetric', () {
    test('has exactly 11 values', () {
      expect(RegionMetric.values, hasLength(11));
    });

    test('contains all expected metric types', () {
      expect(
        RegionMetric.values,
        containsAll([
          RegionMetric.min,
          RegionMetric.max,
          RegionMetric.average,
          RegionMetric.sum,
          RegionMetric.count,
          RegionMetric.range,
          RegionMetric.stdDev,
          RegionMetric.delta,
          RegionMetric.firstY,
          RegionMetric.lastY,
          RegionMetric.duration,
        ]),
      );
    });

    test('min has displayLabel "Min"', () {
      expect(RegionMetric.min.displayLabel, equals('Min'));
    });

    test('max has displayLabel "Max"', () {
      expect(RegionMetric.max.displayLabel, equals('Max'));
    });

    test('average has displayLabel "Avg"', () {
      expect(RegionMetric.average.displayLabel, equals('Avg'));
    });

    test('sum has displayLabel "Sum"', () {
      expect(RegionMetric.sum.displayLabel, equals('Sum'));
    });

    test('count has displayLabel "Count"', () {
      expect(RegionMetric.count.displayLabel, equals('Count'));
    });

    test('range has displayLabel "Range"', () {
      expect(RegionMetric.range.displayLabel, equals('Range'));
    });

    test('stdDev has displayLabel "Std Dev"', () {
      expect(RegionMetric.stdDev.displayLabel, equals('Std Dev'));
    });

    test('delta has displayLabel "Δ"', () {
      expect(RegionMetric.delta.displayLabel, equals('Δ'));
    });

    test('firstY has displayLabel "First"', () {
      expect(RegionMetric.firstY.displayLabel, equals('First'));
    });

    test('lastY has displayLabel "Last"', () {
      expect(RegionMetric.lastY.displayLabel, equals('Last'));
    });

    test('duration has displayLabel "Duration"', () {
      expect(RegionMetric.duration.displayLabel, equals('Duration'));
    });

    test('all metrics have non-empty displayLabel', () {
      for (final metric in RegionMetric.values) {
        expect(
          metric.displayLabel,
          isNotEmpty,
          reason: '${metric.name} should have a non-empty displayLabel',
        );
      }
    });
  });

  group('SeriesRegionSummary', () {
    group('constructor', () {
      test('creates instance with all required fields', () {
        final summary = SeriesRegionSummary(
          seriesId: 'series-1',
          count: 5,
          min: 10.0,
          max: 50.0,
          sum: 150.0,
          average: 30.0,
          range: 40.0,
          duration: 100.0,
        );

        expect(summary.seriesId, equals('series-1'));
        expect(summary.count, equals(5));
        expect(summary.min, equals(10.0));
        expect(summary.max, equals(50.0));
        expect(summary.sum, equals(150.0));
        expect(summary.average, equals(30.0));
        expect(summary.range, equals(40.0));
        expect(summary.duration, equals(100.0));
      });

      test('creates instance with optional fields', () {
        final summary = SeriesRegionSummary(
          seriesId: 'series-2',
          seriesName: 'Temperature',
          unit: '°C',
          count: 10,
          min: 18.0,
          max: 32.0,
          sum: 250.0,
          average: 25.0,
          range: 14.0,
          stdDev: 4.5,
          firstY: 20.0,
          lastY: 28.0,
          delta: 8.0,
          duration: 3600.0,
        );

        expect(summary.seriesName, equals('Temperature'));
        expect(summary.unit, equals('°C'));
        expect(summary.stdDev, equals(4.5));
        expect(summary.firstY, equals(20.0));
        expect(summary.lastY, equals(28.0));
        expect(summary.delta, equals(8.0));
      });

      test('optional fields default to null', () {
        final summary = SeriesRegionSummary(
          seriesId: 'series-3',
          count: 3,
          min: 1.0,
          max: 3.0,
          sum: 6.0,
          average: 2.0,
          range: 2.0,
          duration: 10.0,
        );

        expect(summary.seriesName, isNull);
        expect(summary.unit, isNull);
        expect(summary.stdDev, isNull);
        expect(summary.firstY, isNull);
        expect(summary.lastY, isNull);
        expect(summary.delta, isNull);
      });
    });

    group('null rules for stdDev', () {
      test('stdDev is null when count is 0', () {
        final summary = SeriesRegionSummary(
          seriesId: 'empty-series',
          count: 0,
          min: 0.0,
          max: 0.0,
          sum: 0.0,
          average: 0.0,
          range: 0.0,
          duration: 10.0,
        );

        expect(summary.stdDev, isNull);
      });

      test('stdDev is null when count is 1', () {
        final summary = SeriesRegionSummary(
          seriesId: 'single-point',
          count: 1,
          min: 5.0,
          max: 5.0,
          sum: 5.0,
          average: 5.0,
          range: 0.0,
          firstY: 5.0,
          lastY: 5.0,
          duration: 0.0,
        );

        expect(summary.stdDev, isNull);
      });

      test('stdDev can have value when count >= 2', () {
        final summary = SeriesRegionSummary(
          seriesId: 'multi-point',
          count: 3,
          min: 1.0,
          max: 3.0,
          sum: 6.0,
          average: 2.0,
          range: 2.0,
          stdDev: 0.816,
          firstY: 1.0,
          lastY: 3.0,
          delta: 2.0,
          duration: 10.0,
        );

        expect(summary.stdDev, isNotNull);
        expect(summary.stdDev, equals(0.816));
      });
    });

    group('null rules for delta', () {
      test('delta is null when count is 0', () {
        final summary = SeriesRegionSummary(
          seriesId: 'empty-delta',
          count: 0,
          min: 0.0,
          max: 0.0,
          sum: 0.0,
          average: 0.0,
          range: 0.0,
          duration: 10.0,
        );

        expect(summary.delta, isNull);
      });

      test('delta is null when count is 1', () {
        final summary = SeriesRegionSummary(
          seriesId: 'single-delta',
          count: 1,
          min: 7.0,
          max: 7.0,
          sum: 7.0,
          average: 7.0,
          range: 0.0,
          firstY: 7.0,
          lastY: 7.0,
          duration: 5.0,
        );

        expect(summary.delta, isNull);
      });

      test('delta can have value when count >= 2', () {
        final summary = SeriesRegionSummary(
          seriesId: 'multi-delta',
          count: 4,
          min: 2.0,
          max: 8.0,
          sum: 20.0,
          average: 5.0,
          range: 6.0,
          stdDev: 2.16,
          firstY: 2.0,
          lastY: 8.0,
          delta: 6.0,
          duration: 15.0,
        );

        expect(summary.delta, isNotNull);
        expect(summary.delta, equals(6.0));
      });
    });

    group('null rules for firstY and lastY', () {
      test('firstY is null when count is 0', () {
        final summary = SeriesRegionSummary(
          seriesId: 'empty-firsty',
          count: 0,
          min: 0.0,
          max: 0.0,
          sum: 0.0,
          average: 0.0,
          range: 0.0,
          duration: 10.0,
        );

        expect(summary.firstY, isNull);
      });

      test('lastY is null when count is 0', () {
        final summary = SeriesRegionSummary(
          seriesId: 'empty-lasty',
          count: 0,
          min: 0.0,
          max: 0.0,
          sum: 0.0,
          average: 0.0,
          range: 0.0,
          duration: 10.0,
        );

        expect(summary.lastY, isNull);
      });

      test('firstY has value when count >= 1', () {
        final summary = SeriesRegionSummary(
          seriesId: 'has-firsty',
          count: 1,
          min: 5.0,
          max: 5.0,
          sum: 5.0,
          average: 5.0,
          range: 0.0,
          firstY: 5.0,
          lastY: 5.0,
          duration: 0.0,
        );

        expect(summary.firstY, isNotNull);
        expect(summary.firstY, equals(5.0));
      });

      test('lastY has value when count >= 1', () {
        final summary = SeriesRegionSummary(
          seriesId: 'has-lasty',
          count: 1,
          min: 5.0,
          max: 5.0,
          sum: 5.0,
          average: 5.0,
          range: 0.0,
          firstY: 5.0,
          lastY: 5.0,
          duration: 0.0,
        );

        expect(summary.lastY, isNotNull);
        expect(summary.lastY, equals(5.0));
      });
    });

    group('count zero edge case', () {
      test(
        'all numeric fields are 0.0 and all nullable fields are null when count is 0',
        () {
          final summary = SeriesRegionSummary(
            seriesId: 'zero-count',
            count: 0,
            min: 0.0,
            max: 0.0,
            sum: 0.0,
            average: 0.0,
            range: 0.0,
            duration: 10.0,
          );

          expect(summary.count, equals(0));
          expect(summary.min, equals(0.0));
          expect(summary.max, equals(0.0));
          expect(summary.sum, equals(0.0));
          expect(summary.average, equals(0.0));
          expect(summary.range, equals(0.0));
          expect(summary.stdDev, isNull);
          expect(summary.firstY, isNull);
          expect(summary.lastY, isNull);
          expect(summary.delta, isNull);
        },
      );
    });
  });

  group('RegionSummary', () {
    test('creates instance with region and empty seriesSummaries', () {
      final region = DataRegion(
        id: 'summary-region',
        startX: 0.0,
        endX: 100.0,
        source: DataRegionSource.rangeAnnotation,
        seriesData: const {},
      );

      final summary = RegionSummary(region: region, seriesSummaries: const {});

      expect(summary.region, equals(region));
      expect(summary.seriesSummaries, isEmpty);
    });

    test('creates instance with region and populated seriesSummaries', () {
      final region = DataRegion(
        id: 'populated-region',
        startX: 10.0,
        endX: 50.0,
        source: DataRegionSource.segment,
        seriesData: const {},
      );

      final seriesSummary = SeriesRegionSummary(
        seriesId: 'series-1',
        seriesName: 'Power',
        unit: 'W',
        count: 5,
        min: 100.0,
        max: 250.0,
        sum: 875.0,
        average: 175.0,
        range: 150.0,
        stdDev: 55.9,
        firstY: 120.0,
        lastY: 200.0,
        delta: 80.0,
        duration: 40.0,
      );

      final summary = RegionSummary(
        region: region,
        seriesSummaries: {'series-1': seriesSummary},
      );

      expect(summary.seriesSummaries, hasLength(1));
      expect(summary.seriesSummaries['series-1'], equals(seriesSummary));
    });

    test('supports multiple series summaries', () {
      final region = DataRegion(
        id: 'multi-region',
        startX: 0.0,
        endX: 100.0,
        source: DataRegionSource.boxSelect,
        seriesData: const {},
      );

      final summary1 = SeriesRegionSummary(
        seriesId: 'series-a',
        count: 3,
        min: 1.0,
        max: 3.0,
        sum: 6.0,
        average: 2.0,
        range: 2.0,
        duration: 100.0,
      );

      final summary2 = SeriesRegionSummary(
        seriesId: 'series-b',
        count: 5,
        min: 10.0,
        max: 50.0,
        sum: 150.0,
        average: 30.0,
        range: 40.0,
        duration: 100.0,
      );

      final regionSummary = RegionSummary(
        region: region,
        seriesSummaries: {'series-a': summary1, 'series-b': summary2},
      );

      expect(regionSummary.seriesSummaries, hasLength(2));
      expect(regionSummary.seriesSummaries.containsKey('series-a'), isTrue);
      expect(regionSummary.seriesSummaries.containsKey('series-b'), isTrue);
    });

    test('region reference is accessible', () {
      final region = DataRegion(
        id: 'accessible-region',
        label: 'My Region',
        startX: 5.0,
        endX: 25.0,
        source: DataRegionSource.rangeAnnotation,
        seriesData: const {},
      );

      final summary = RegionSummary(region: region, seriesSummaries: const {});

      expect(summary.region.id, equals('accessible-region'));
      expect(summary.region.label, equals('My Region'));
      expect(summary.region.startX, equals(5.0));
      expect(summary.region.endX, equals(25.0));
    });
  });

  group('RegionSummaryConfig', () {
    test('default metrics are {min, max, average}', () {
      final config = RegionSummaryConfig();

      expect(
        config.metrics,
        equals({RegionMetric.min, RegionMetric.max, RegionMetric.average}),
      );
    });

    test('default position is aboveRegion', () {
      final config = RegionSummaryConfig();

      expect(config.position, equals(RegionSummaryPosition.aboveRegion));
    });

    test('default valueFormatter is null', () {
      final config = RegionSummaryConfig();

      expect(config.valueFormatter, isNull);
    });

    test('creates instance with custom metrics', () {
      final config = RegionSummaryConfig(
        metrics: {RegionMetric.sum, RegionMetric.count, RegionMetric.duration},
      );

      expect(
        config.metrics,
        equals({RegionMetric.sum, RegionMetric.count, RegionMetric.duration}),
      );
    });

    test('creates instance with custom position', () {
      final config = RegionSummaryConfig(
        position: RegionSummaryPosition.insideTop,
      );

      expect(config.position, equals(RegionSummaryPosition.insideTop));
    });

    test('creates instance with custom valueFormatter', () {
      String formatter(double value, String? unit) =>
          '${value.toStringAsFixed(1)}${unit != null ? ' $unit' : ''}';

      final config = RegionSummaryConfig(valueFormatter: formatter);

      expect(config.valueFormatter, isNotNull);
      expect(config.valueFormatter!(42.567, 'W'), equals('42.6 W'));
      expect(config.valueFormatter!(42.567, null), equals('42.6'));
    });

    test('creates instance with all custom parameters', () {
      String formatter(double value, String? unit) => value.toString();

      final config = RegionSummaryConfig(
        metrics: {RegionMetric.min, RegionMetric.max, RegionMetric.stdDev},
        valueFormatter: formatter,
        position: RegionSummaryPosition.insideBottom,
      );

      expect(config.metrics, hasLength(3));
      expect(config.valueFormatter, isNotNull);
      expect(config.position, equals(RegionSummaryPosition.insideBottom));
    });

    test('metrics can be empty set', () {
      final config = RegionSummaryConfig(metrics: {});

      expect(config.metrics, isEmpty);
    });

    test('metrics can contain all values', () {
      final config = RegionSummaryConfig(
        metrics: Set.from(RegionMetric.values),
      );

      expect(config.metrics, hasLength(11));
    });
  });

  group('RegionSummaryPosition', () {
    test('has aboveRegion value', () {
      expect(RegionSummaryPosition.aboveRegion, isNotNull);
    });

    test('has insideTop value', () {
      expect(RegionSummaryPosition.insideTop, isNotNull);
    });

    test('has insideBottom value', () {
      expect(RegionSummaryPosition.insideBottom, isNotNull);
    });

    test('has exactly 3 values', () {
      expect(RegionSummaryPosition.values, hasLength(3));
    });

    test('values contain all expected positions', () {
      expect(
        RegionSummaryPosition.values,
        containsAll([
          RegionSummaryPosition.aboveRegion,
          RegionSummaryPosition.insideTop,
          RegionSummaryPosition.insideBottom,
        ]),
      );
    });
  });
}
