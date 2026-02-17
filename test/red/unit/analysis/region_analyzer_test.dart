// @orchestra-task: 5
// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/src/analysis/region_analyzer.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/data_region.dart';
import 'package:braven_charts/src/models/region_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const analyzer = RegionAnalyzer();

  // ===========================================================================
  // computeSeriesSummary() Tests — TDD Red Phase
  // ===========================================================================
  group('RegionAnalyzer.computeSeriesSummary', () {
    // -------------------------------------------------------------------------
    // 50-point series — all metrics verified with manually computed values
    // -------------------------------------------------------------------------
    group('50-point series with all metrics', () {
      // Generate 50 points: x = 0..49, y = 2*x + 1
      // Expected statistics (manually computed):
      //   count    = 50
      //   min      = 1.0   (y at x=0)
      //   max      = 99.0  (y at x=49)
      //   sum      = 2500.0
      //   average  = 50.0
      //   range    = 98.0
      //   firstY   = 1.0
      //   lastY    = 99.0
      //   delta    = 98.0  (lastY - firstY)
      //   duration = 49.0  (last.x - first.x)
      //   stdDev   = sqrt(833) ≈ 28.861739379323623 (population formula)
      final points = List.generate(
        50,
        (i) => ChartDataPoint(x: i.toDouble(), y: i * 2.0 + 1.0),
      );

      test('returns non-null SeriesRegionSummary for 50-point input', () {
        final result = analyzer.computeSeriesSummary(
          points: points,
          seriesId: 'test-series',
        );
        expect(result, isNotNull);
      });

      test('count equals 50', () {
        final result = analyzer.computeSeriesSummary(
          points: points,
          seriesId: 'test-series',
        );
        expect(result!.count, equals(50));
      });

      test('min equals 1.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points: points,
          seriesId: 'test-series',
        );
        expect(result!.min, closeTo(1.0, 1e-10));
      });

      test('max equals 99.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points: points,
          seriesId: 'test-series',
        );
        expect(result!.max, closeTo(99.0, 1e-10));
      });

      test('sum equals 2500.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points: points,
          seriesId: 'test-series',
        );
        expect(result!.sum, closeTo(2500.0, 1e-10));
      });

      test('average equals 50.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points: points,
          seriesId: 'test-series',
        );
        expect(result!.average, closeTo(50.0, 1e-10));
      });

      test('range equals 98.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points: points,
          seriesId: 'test-series',
        );
        expect(result!.range, closeTo(98.0, 1e-10));
      });

      test('firstY equals 1.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points: points,
          seriesId: 'test-series',
        );
        expect(result!.firstY, isNotNull);
        expect(result!.firstY!, closeTo(1.0, 1e-10));
      });

      test('lastY equals 99.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points: points,
          seriesId: 'test-series',
        );
        expect(result!.lastY, isNotNull);
        expect(result!.lastY!, closeTo(99.0, 1e-10));
      });

      test('delta equals 98.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points: points,
          seriesId: 'test-series',
        );
        expect(result!.delta, isNotNull);
        expect(result!.delta!, closeTo(98.0, 1e-10));
      });

      test(
        'duration equals 49.0 (last.x - first.x) with closeTo precision',
        () {
          final result = analyzer.computeSeriesSummary(
            points: points,
            seriesId: 'test-series',
          );
          expect(result!.duration, closeTo(49.0, 1e-10));
        },
      );

      test('stdDev equals sqrt(833) ≈ 28.8617 (population formula) '
          'with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points: points,
          seriesId: 'test-series',
        );
        expect(result!.stdDev, isNotNull);
        // Population standard deviation: sqrt(Σ(yi - mean)² / N)
        // For y = 2*x + 1, x=0..49: variance = 833, stdDev = sqrt(833)
        expect(result!.stdDev!, closeTo(math.sqrt(833), 1e-10));
      });

      test('seriesId is passed through correctly', () {
        final result = analyzer.computeSeriesSummary(
          points: points,
          seriesId: 'my-series-id',
        );
        expect(result!.seriesId, equals('my-series-id'));
      });
    });

    // -------------------------------------------------------------------------
    // 1-point series — stdDev is null, delta is null
    // -------------------------------------------------------------------------
    group('1-point series', () {
      final singlePoint = [const ChartDataPoint(x: 5.0, y: 42.0)];

      test('returns non-null for 1-point input', () {
        final result = analyzer.computeSeriesSummary(
          points: singlePoint,
          seriesId: 'single',
        );
        expect(result, isNotNull);
      });

      test('count equals 1', () {
        final result = analyzer.computeSeriesSummary(
          points: singlePoint,
          seriesId: 'single',
        );
        expect(result!.count, equals(1));
      });

      test('min and max equal the single Y value', () {
        final result = analyzer.computeSeriesSummary(
          points: singlePoint,
          seriesId: 'single',
        );
        expect(result!.min, closeTo(42.0, 1e-10));
        expect(result!.max, closeTo(42.0, 1e-10));
      });

      test('sum and average equal the single Y value', () {
        final result = analyzer.computeSeriesSummary(
          points: singlePoint,
          seriesId: 'single',
        );
        expect(result!.sum, closeTo(42.0, 1e-10));
        expect(result!.average, closeTo(42.0, 1e-10));
      });

      test('range equals 0.0 (max - min with one point)', () {
        final result = analyzer.computeSeriesSummary(
          points: singlePoint,
          seriesId: 'single',
        );
        expect(result!.range, closeTo(0.0, 1e-10));
      });

      test('stdDev is null when count < 2', () {
        final result = analyzer.computeSeriesSummary(
          points: singlePoint,
          seriesId: 'single',
        );
        expect(result!.stdDev, isNull);
      });

      test('delta is null when count < 2', () {
        final result = analyzer.computeSeriesSummary(
          points: singlePoint,
          seriesId: 'single',
        );
        expect(result!.delta, isNull);
      });

      test('firstY equals the single Y value', () {
        final result = analyzer.computeSeriesSummary(
          points: singlePoint,
          seriesId: 'single',
        );
        expect(result!.firstY, closeTo(42.0, 1e-10));
      });

      test('lastY equals the single Y value', () {
        final result = analyzer.computeSeriesSummary(
          points: singlePoint,
          seriesId: 'single',
        );
        expect(result!.lastY, closeTo(42.0, 1e-10));
      });

      test('duration equals 0.0 (single point span)', () {
        final result = analyzer.computeSeriesSummary(
          points: singlePoint,
          seriesId: 'single',
        );
        expect(result!.duration, closeTo(0.0, 1e-10));
      });
    });

    // -------------------------------------------------------------------------
    // 0-point (empty) series — returns null
    // -------------------------------------------------------------------------
    group('0-point (empty) series', () {
      test('returns null for empty points list', () {
        final result = analyzer.computeSeriesSummary(
          points: <ChartDataPoint>[],
          seriesId: 'empty',
        );
        expect(result, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // Floating-point precision validation
    // -------------------------------------------------------------------------
    group('floating-point precision', () {
      test(
        'handles values requiring closeTo precision for fractional data',
        () {
          // Points with fractional values that could cause precision issues
          final points = [
            const ChartDataPoint(x: 0.0, y: 0.1),
            const ChartDataPoint(x: 1.0, y: 0.2),
            const ChartDataPoint(x: 2.0, y: 0.3),
          ];

          final result = analyzer.computeSeriesSummary(
            points: points,
            seriesId: 'precision',
          );

          expect(result, isNotNull);
          // 0.1 + 0.2 + 0.3 = 0.6 (but floating-point may not be exact)
          expect(result!.sum, closeTo(0.6, 1e-10));
          expect(result!.average, closeTo(0.2, 1e-10));
          expect(result!.min, closeTo(0.1, 1e-10));
          expect(result!.max, closeTo(0.3, 1e-10));
        },
      );
    });
  });

  // ===========================================================================
  // computeRegionSummary() Tests — TDD Red Phase
  // ===========================================================================
  group('RegionAnalyzer.computeRegionSummary', () {
    // -------------------------------------------------------------------------
    // Multi-series DataRegion
    // -------------------------------------------------------------------------
    group('multi-series DataRegion', () {
      test(
        'returns RegionSummary with per-series SeriesRegionSummary entries',
        () {
          // Arrange — DataRegion with two series
          final region = DataRegion(
            id: 'multi-series-region',
            startX: 0.0,
            endX: 10.0,
            source: DataRegionSource.rangeAnnotation,
            seriesData: {
              'power': [
                const ChartDataPoint(x: 1.0, y: 100.0),
                const ChartDataPoint(x: 3.0, y: 300.0),
                const ChartDataPoint(x: 5.0, y: 200.0),
              ],
              'heartrate': [
                const ChartDataPoint(x: 2.0, y: 70.0),
                const ChartDataPoint(x: 4.0, y: 120.0),
                const ChartDataPoint(x: 6.0, y: 90.0),
              ],
            },
          );

          // Act
          final result = analyzer.computeRegionSummary(region: region);

          // Assert — both series should have summaries
          expect(result, isNotNull);
          expect(result.seriesSummaries, hasLength(2));
          expect(result.seriesSummaries.containsKey('power'), isTrue);
          expect(result.seriesSummaries.containsKey('heartrate'), isTrue);
        },
      );

      test('each series summary has correct metric values', () {
        // Arrange
        final region = DataRegion(
          id: 'metrics-check',
          startX: 0.0,
          endX: 10.0,
          source: DataRegionSource.rangeAnnotation,
          seriesData: {
            'temperature': [
              const ChartDataPoint(x: 1.0, y: 20.0),
              const ChartDataPoint(x: 2.0, y: 30.0),
              const ChartDataPoint(x: 3.0, y: 25.0),
            ],
          },
        );

        // Act
        final result = analyzer.computeRegionSummary(region: region);

        // Assert
        final tempSummary = result.seriesSummaries['temperature']!;
        expect(tempSummary.count, equals(3));
        expect(tempSummary.min, closeTo(20.0, 1e-10));
        expect(tempSummary.max, closeTo(30.0, 1e-10));
        expect(tempSummary.sum, closeTo(75.0, 1e-10));
        expect(tempSummary.average, closeTo(25.0, 1e-10));
        expect(tempSummary.range, closeTo(10.0, 1e-10));
        expect(tempSummary.firstY, closeTo(20.0, 1e-10));
        expect(tempSummary.lastY, closeTo(25.0, 1e-10));
        expect(tempSummary.delta, closeTo(5.0, 1e-10));
        expect(tempSummary.duration, closeTo(2.0, 1e-10));
      });

      test('region reference is preserved in result', () {
        // Arrange
        final region = DataRegion(
          id: 'region-ref-test',
          startX: 5.0,
          endX: 15.0,
          source: DataRegionSource.boxSelect,
          seriesData: {
            'series-a': [const ChartDataPoint(x: 7.0, y: 10.0)],
          },
        );

        // Act
        final result = analyzer.computeRegionSummary(region: region);

        // Assert
        expect(result.region, equals(region));
        expect(result.region.id, equals('region-ref-test'));
        expect(result.region.source, equals(DataRegionSource.boxSelect));
      });
    });

    // -------------------------------------------------------------------------
    // Empty series omission
    // -------------------------------------------------------------------------
    group('empty series omission', () {
      test('omits series with zero points from seriesSummaries map', () {
        // Arrange — one series has data, one is empty
        final region = DataRegion(
          id: 'omission-test',
          startX: 0.0,
          endX: 10.0,
          source: DataRegionSource.rangeAnnotation,
          seriesData: {
            'has-data': [
              const ChartDataPoint(x: 1.0, y: 10.0),
              const ChartDataPoint(x: 2.0, y: 20.0),
            ],
            'empty': <ChartDataPoint>[],
          },
        );

        // Act
        final result = analyzer.computeRegionSummary(region: region);

        // Assert — 'empty' series should be omitted
        expect(result.seriesSummaries.containsKey('has-data'), isTrue);
        expect(result.seriesSummaries.containsKey('empty'), isFalse);
        expect(result.seriesSummaries, hasLength(1));
      });

      test(
        'returns RegionSummary with empty map when all series are empty',
        () {
          // Arrange
          final region = DataRegion(
            id: 'all-empty',
            startX: 0.0,
            endX: 10.0,
            source: DataRegionSource.rangeAnnotation,
            seriesData: {
              'empty-a': <ChartDataPoint>[],
              'empty-b': <ChartDataPoint>[],
            },
          );

          // Act
          final result = analyzer.computeRegionSummary(region: region);

          // Assert
          expect(result.seriesSummaries, isEmpty);
        },
      );
    });

    // -------------------------------------------------------------------------
    // seriesNames and seriesUnits pass-through
    // -------------------------------------------------------------------------
    group('seriesNames and seriesUnits pass-through', () {
      test('custom seriesNames are passed to SeriesRegionSummary objects', () {
        // Arrange
        final region = DataRegion(
          id: 'names-test',
          startX: 0.0,
          endX: 10.0,
          source: DataRegionSource.rangeAnnotation,
          seriesData: {
            'power': [
              const ChartDataPoint(x: 1.0, y: 100.0),
              const ChartDataPoint(x: 2.0, y: 200.0),
            ],
            'heartrate': [
              const ChartDataPoint(x: 1.0, y: 70.0),
              const ChartDataPoint(x: 2.0, y: 90.0),
            ],
          },
        );

        // Act
        final result = analyzer.computeRegionSummary(
          region: region,
          seriesNames: {'power': 'Power Output', 'heartrate': 'Heart Rate'},
        );

        // Assert
        expect(
          result.seriesSummaries['power']!.seriesName,
          equals('Power Output'),
        );
        expect(
          result.seriesSummaries['heartrate']!.seriesName,
          equals('Heart Rate'),
        );
      });

      test('custom seriesUnits are passed to SeriesRegionSummary objects', () {
        // Arrange
        final region = DataRegion(
          id: 'units-test',
          startX: 0.0,
          endX: 10.0,
          source: DataRegionSource.rangeAnnotation,
          seriesData: {
            'power': [
              const ChartDataPoint(x: 1.0, y: 100.0),
              const ChartDataPoint(x: 2.0, y: 200.0),
            ],
            'temperature': [
              const ChartDataPoint(x: 1.0, y: 20.0),
              const ChartDataPoint(x: 2.0, y: 25.0),
            ],
          },
        );

        // Act
        final result = analyzer.computeRegionSummary(
          region: region,
          seriesUnits: {'power': 'W', 'temperature': '°C'},
        );

        // Assert
        expect(result.seriesSummaries['power']!.unit, equals('W'));
        expect(result.seriesSummaries['temperature']!.unit, equals('°C'));
      });

      test('seriesNames and seriesUnits work together', () {
        // Arrange
        final region = DataRegion(
          id: 'names-units-test',
          startX: 0.0,
          endX: 10.0,
          source: DataRegionSource.rangeAnnotation,
          seriesData: {
            'speed': [
              const ChartDataPoint(x: 1.0, y: 30.0),
              const ChartDataPoint(x: 2.0, y: 35.0),
            ],
          },
        );

        // Act
        final result = analyzer.computeRegionSummary(
          region: region,
          seriesNames: {'speed': 'Speed'},
          seriesUnits: {'speed': 'km/h'},
        );

        // Assert
        final speedSummary = result.seriesSummaries['speed']!;
        expect(speedSummary.seriesName, equals('Speed'));
        expect(speedSummary.unit, equals('km/h'));
        expect(speedSummary.seriesId, equals('speed'));
      });

      test(
        'series without name/unit mappings have null seriesName and unit',
        () {
          // Arrange
          final region = DataRegion(
            id: 'partial-metadata',
            startX: 0.0,
            endX: 10.0,
            source: DataRegionSource.rangeAnnotation,
            seriesData: {
              'mapped': [const ChartDataPoint(x: 1.0, y: 10.0)],
              'unmapped': [const ChartDataPoint(x: 1.0, y: 20.0)],
            },
          );

          // Act
          final result = analyzer.computeRegionSummary(
            region: region,
            seriesNames: {'mapped': 'Mapped Series'},
            seriesUnits: {'mapped': 'units'},
          );

          // Assert — 'mapped' has metadata, 'unmapped' does not
          expect(
            result.seriesSummaries['mapped']!.seriesName,
            equals('Mapped Series'),
          );
          expect(result.seriesSummaries['mapped']!.unit, equals('units'));
          expect(result.seriesSummaries['unmapped']!.seriesName, isNull);
          expect(result.seriesSummaries['unmapped']!.unit, isNull);
        },
      );
    });
  });
}
