// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;

import 'package:braven_charts/src/analysis/region_analyzer.dart';
import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/data_region.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const analyzer = RegionAnalyzer();

  // ===========================================================================
  // filterPointsInRange() Tests
  // ===========================================================================
  group('RegionAnalyzer.filterPointsInRange', () {
    // -------------------------------------------------------------------------
    // Sorted data — binary-search fast-path (isSorted: true, the default)
    // -------------------------------------------------------------------------
    group('sorted data (binary search path, isSorted: true)', () {
      test('returns points within range for sorted ascending data', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 4.0, y: 40.0),
          const ChartDataPoint(x: 5.0, y: 50.0),
          const ChartDataPoint(x: 6.0, y: 60.0),
          const ChartDataPoint(x: 7.0, y: 70.0),
          const ChartDataPoint(x: 8.0, y: 80.0),
          const ChartDataPoint(x: 9.0, y: 90.0),
          const ChartDataPoint(x: 10.0, y: 100.0),
        ];

        // Act — isSorted defaults to true, uses binary search
        final result = analyzer.filterPointsInRange(
          points,
          startX: 3.0,
          endX: 7.0,
        );

        // Assert
        expect(result, hasLength(5));
        expect(
          result.map((p) => p.x),
          containsAllInOrder([3.0, 4.0, 5.0, 6.0, 7.0]),
        );
      });

      test('returns correct Y values for filtered range', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 1.0, y: 100.0),
          const ChartDataPoint(x: 2.0, y: 200.0),
          const ChartDataPoint(x: 3.0, y: 300.0),
          const ChartDataPoint(x: 4.0, y: 400.0),
          const ChartDataPoint(x: 5.0, y: 500.0),
        ];

        // Act — explicit isSorted: true
        final result = analyzer.filterPointsInRange(
          points,
          startX: 2.0,
          endX: 4.0,
          isSorted: true,
        );

        // Assert
        expect(result, hasLength(3));
        expect(result[0].y, equals(200.0));
        expect(result[1].y, equals(300.0));
        expect(result[2].y, equals(400.0));
      });
    });

    // -------------------------------------------------------------------------
    // Unsorted data — linear-scan fallback (isSorted: false)
    // -------------------------------------------------------------------------
    group('unsorted data (linear scan fallback, isSorted: false)', () {
      test('returns points within range for unsorted data', () {
        // Arrange — data intentionally out of order
        final points = [
          const ChartDataPoint(x: 5.0, y: 50.0),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 8.0, y: 80.0),
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 4.0, y: 40.0),
          const ChartDataPoint(x: 9.0, y: 90.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 7.0, y: 70.0),
          const ChartDataPoint(x: 6.0, y: 60.0),
          const ChartDataPoint(x: 10.0, y: 100.0),
        ];

        // Act — explicit isSorted: false forces linear scan
        final result = analyzer.filterPointsInRange(
          points,
          startX: 3.0,
          endX: 7.0,
          isSorted: false,
        );

        // Assert — should contain same 5 points regardless of order
        expect(result, hasLength(5));
        expect(
          result.map((p) => p.x).toSet(),
          equals({3.0, 4.0, 5.0, 6.0, 7.0}),
        );
      });

      test('returns same results as sorted path for equivalent data', () {
        // Arrange — descending order, must use isSorted: false
        final unsortedPoints = [
          const ChartDataPoint(x: 10.0, y: 100.0),
          const ChartDataPoint(x: 7.0, y: 70.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 5.0, y: 50.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          unsortedPoints,
          startX: 3.0,
          endX: 7.0,
          isSorted: false,
        );

        // Assert — all points with x in [3.0, 7.0]
        expect(result, hasLength(3));
        expect(result.map((p) => p.x).toSet(), equals({3.0, 5.0, 7.0}));
      });
    });

    // -------------------------------------------------------------------------
    // Inclusive boundaries
    // -------------------------------------------------------------------------
    group('inclusive boundaries', () {
      test('includes points exactly at startX boundary', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 2.0,
          endX: 5.0,
        );

        // Assert
        expect(result.any((p) => p.x == 2.0), isTrue);
      });

      test('includes points exactly at endX boundary', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 0.0,
          endX: 2.0,
        );

        // Assert
        expect(result.any((p) => p.x == 2.0), isTrue);
      });

      test(
        'includes points at both startX and endX boundaries simultaneously',
        () {
          // Arrange
          final points = [
            const ChartDataPoint(x: 1.0, y: 10.0),
            const ChartDataPoint(x: 2.0, y: 20.0),
            const ChartDataPoint(x: 3.0, y: 30.0),
            const ChartDataPoint(x: 4.0, y: 40.0),
            const ChartDataPoint(x: 5.0, y: 50.0),
          ];

          // Act
          final result = analyzer.filterPointsInRange(
            points,
            startX: 2.0,
            endX: 4.0,
          );

          // Assert
          expect(result, hasLength(3));
          expect(result.first.x, equals(2.0));
          expect(result.last.x, equals(4.0));
        },
      );
    });

    // -------------------------------------------------------------------------
    // Empty input
    // -------------------------------------------------------------------------
    group('empty input', () {
      test('returns empty list when input points list is empty', () {
        // Arrange
        final points = <ChartDataPoint>[];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 0.0,
          endX: 10.0,
        );

        // Assert
        expect(result, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // Boundary duplicates
    // -------------------------------------------------------------------------
    group('boundary duplicates', () {
      test('includes all duplicate points at the startX boundary', () {
        // Arrange — three points share x=3.0
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 3.0, y: 35.0),
          const ChartDataPoint(x: 3.0, y: 38.0),
          const ChartDataPoint(x: 4.0, y: 40.0),
          const ChartDataPoint(x: 5.0, y: 50.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 3.0,
          endX: 5.0,
        );

        // Assert — all three x=3.0 points plus x=4.0 and x=5.0
        expect(result, hasLength(5));
        expect(result.where((p) => p.x == 3.0), hasLength(3));
      });

      test('includes all duplicate points at the endX boundary', () {
        // Arrange — multiple points at x=5.0
        final points = [
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 4.0, y: 40.0),
          const ChartDataPoint(x: 5.0, y: 50.0),
          const ChartDataPoint(x: 5.0, y: 55.0),
          const ChartDataPoint(x: 6.0, y: 60.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 3.0,
          endX: 5.0,
        );

        // Assert
        expect(result, hasLength(4));
        expect(result.where((p) => p.x == 5.0), hasLength(2));
      });
    });

    // -------------------------------------------------------------------------
    // Single-point match (startX == endX)
    // -------------------------------------------------------------------------
    group('single-point match', () {
      test('returns matching point when startX equals endX', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 4.0, y: 40.0),
          const ChartDataPoint(x: 5.0, y: 50.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 3.0,
          endX: 3.0,
        );

        // Assert
        expect(result, hasLength(1));
        expect(result.first.x, equals(3.0));
        expect(result.first.y, equals(30.0));
      });

      test('returns empty when no point matches single-point query', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 5.0, y: 50.0),
        ];

        // Act — query at x=2.0 where no point exists
        final result = analyzer.filterPointsInRange(
          points,
          startX: 2.0,
          endX: 2.0,
        );

        // Assert
        expect(result, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // Range outside data
    // -------------------------------------------------------------------------
    group('range outside data', () {
      test('returns empty when range is entirely before all data points', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 5.0, y: 50.0),
          const ChartDataPoint(x: 6.0, y: 60.0),
          const ChartDataPoint(x: 7.0, y: 70.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 1.0,
          endX: 4.0,
        );

        // Assert
        expect(result, isEmpty);
      });

      test('returns empty when range is entirely after all data points', () {
        // Arrange
        final points = [
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 30.0),
        ];

        // Act
        final result = analyzer.filterPointsInRange(
          points,
          startX: 10.0,
          endX: 20.0,
        );

        // Assert
        expect(result, isEmpty);
      });

      test(
        'returns empty when range falls between non-contiguous data points',
        () {
          // Arrange — gap between x=3.0 and x=7.0
          final points = [
            const ChartDataPoint(x: 1.0, y: 10.0),
            const ChartDataPoint(x: 3.0, y: 30.0),
            const ChartDataPoint(x: 7.0, y: 70.0),
            const ChartDataPoint(x: 9.0, y: 90.0),
          ];

          // Act — query x=4.0 to x=6.0 falls in the gap
          final result = analyzer.filterPointsInRange(
            points,
            startX: 4.0,
            endX: 6.0,
          );

          // Assert
          expect(result, isEmpty);
        },
      );
    });
  });

  // ===========================================================================
  // regionFromAnnotation() Tests
  // ===========================================================================
  group('RegionAnalyzer.regionFromAnnotation', () {
    group('builds DataRegion from RangeAnnotation and multi-series data', () {
      test('creates DataRegion with correct source and X-range', () {
        // Arrange
        final annotation = RangeAnnotation(
          id: 'test-range',
          startX: 2.0,
          endX: 8.0,
          label: 'Test Range',
        );
        final allSeriesData = <String, List<ChartDataPoint>>{
          'series-a': [
            const ChartDataPoint(x: 1.0, y: 10.0),
            const ChartDataPoint(x: 3.0, y: 30.0),
            const ChartDataPoint(x: 5.0, y: 50.0),
            const ChartDataPoint(x: 7.0, y: 70.0),
            const ChartDataPoint(x: 9.0, y: 90.0),
          ],
        };

        // Act — positional args per spec contract
        final region = analyzer.regionFromAnnotation(annotation, allSeriesData);

        // Assert
        expect(region.source, equals(DataRegionSource.rangeAnnotation));
        expect(region.startX, equals(2.0));
        expect(region.endX, equals(8.0));
        expect(region.id, isNotEmpty);
      });

      test('maps filtered points correctly per series', () {
        // Arrange
        final annotation = RangeAnnotation(
          id: 'multi-series-range',
          startX: 3.0,
          endX: 7.0,
        );
        final allSeriesData = <String, List<ChartDataPoint>>{
          'power': [
            const ChartDataPoint(x: 1.0, y: 100.0),
            const ChartDataPoint(x: 3.0, y: 300.0),
            const ChartDataPoint(x: 5.0, y: 500.0),
            const ChartDataPoint(x: 7.0, y: 700.0),
            const ChartDataPoint(x: 9.0, y: 900.0),
          ],
          'heartrate': [
            const ChartDataPoint(x: 1.0, y: 70.0),
            const ChartDataPoint(x: 4.0, y: 120.0),
            const ChartDataPoint(x: 6.0, y: 150.0),
            const ChartDataPoint(x: 10.0, y: 80.0),
          ],
        };

        // Act
        final region = analyzer.regionFromAnnotation(annotation, allSeriesData);

        // Assert — power series: x=3,5,7 (3 points in range)
        expect(region.seriesData['power'], hasLength(3));
        expect(
          region.seriesData['power']!.map((p) => p.x).toList(),
          equals([3.0, 5.0, 7.0]),
        );

        // Assert — heartrate series: x=4,6 (2 points in range)
        expect(region.seriesData['heartrate'], hasLength(2));
        expect(
          region.seriesData['heartrate']!.map((p) => p.x).toList(),
          equals([4.0, 6.0]),
        );
      });
    });

    group('excludes series with no matching points', () {
      test('omits series with zero points in range from seriesData', () {
        // Arrange
        final annotation = RangeAnnotation(
          id: 'partial-range',
          startX: 3.0,
          endX: 5.0,
        );
        final allSeriesData = <String, List<ChartDataPoint>>{
          'in-range': [
            const ChartDataPoint(x: 3.0, y: 30.0),
            const ChartDataPoint(x: 4.0, y: 40.0),
          ],
          'out-of-range': [
            const ChartDataPoint(x: 1.0, y: 10.0),
            const ChartDataPoint(x: 2.0, y: 20.0),
            const ChartDataPoint(x: 6.0, y: 60.0),
          ],
        };

        // Act
        final region = analyzer.regionFromAnnotation(annotation, allSeriesData);

        // Assert — only 'in-range' series should be in result
        expect(region.seriesData.containsKey('in-range'), isTrue);
        expect(region.seriesData.containsKey('out-of-range'), isFalse);
        expect(region.seriesData['in-range'], hasLength(2));
      });
    });

    group('handles empty series gracefully', () {
      test(
        'returns DataRegion with empty seriesData when no series provided',
        () {
          // Arrange
          final annotation = RangeAnnotation(
            id: 'empty-range',
            startX: 3.0,
            endX: 5.0,
          );
          final allSeriesData = <String, List<ChartDataPoint>>{};

          // Act
          final region = analyzer.regionFromAnnotation(
            annotation,
            allSeriesData,
          );

          // Assert
          expect(region.seriesData, isEmpty);
          expect(region.source, equals(DataRegionSource.rangeAnnotation));
        },
      );

      test(
        'returns DataRegion with empty seriesData when series have empty point lists',
        () {
          // Arrange
          final annotation = RangeAnnotation(
            id: 'empty-points-range',
            startX: 1.0,
            endX: 10.0,
          );
          final allSeriesData = <String, List<ChartDataPoint>>{
            'empty-series': <ChartDataPoint>[],
          };

          // Act
          final region = analyzer.regionFromAnnotation(
            annotation,
            allSeriesData,
          );

          // Assert — empty series should be excluded from result
          expect(region.seriesData, isEmpty);
        },
      );

      test('handles mix of populated and empty series', () {
        // Arrange
        final annotation = RangeAnnotation(
          id: 'mix-range',
          startX: 2.0,
          endX: 6.0,
        );
        final allSeriesData = <String, List<ChartDataPoint>>{
          'has-data': [
            const ChartDataPoint(x: 3.0, y: 30.0),
            const ChartDataPoint(x: 5.0, y: 50.0),
          ],
          'empty': <ChartDataPoint>[],
          'none-in-range': [const ChartDataPoint(x: 10.0, y: 100.0)],
        };

        // Act
        final region = analyzer.regionFromAnnotation(annotation, allSeriesData);

        // Assert — only 'has-data' should remain
        expect(region.seriesData.keys, equals(['has-data']));
        expect(region.seriesData['has-data'], hasLength(2));
      });
    });
  });

  // ===========================================================================
  // computeSeriesSummary() Tests
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
      //   duration = 49.0  (regionEndX - regionStartX = 49.0 - 0.0)
      //   stdDev   = sqrt(833) ≈ 28.861739379323623 (population formula)
      final points = List.generate(
        50,
        (i) => ChartDataPoint(x: i.toDouble(), y: i * 2.0 + 1.0),
      );

      test('returns non-null SeriesRegionSummary for 50-point input', () {
        final result = analyzer.computeSeriesSummary(
          points,
          seriesId: 'test-series',
          regionStartX: 0.0,
          regionEndX: 49.0,
        );
        expect(result, isNotNull);
      });

      test('count equals 50', () {
        final result = analyzer.computeSeriesSummary(
          points,
          seriesId: 'test-series',
          regionStartX: 0.0,
          regionEndX: 49.0,
        );
        expect(result!.count, equals(50));
      });

      test('min equals 1.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points,
          seriesId: 'test-series',
          regionStartX: 0.0,
          regionEndX: 49.0,
        );
        expect(result!.min, closeTo(1.0, 1e-10));
      });

      test('max equals 99.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points,
          seriesId: 'test-series',
          regionStartX: 0.0,
          regionEndX: 49.0,
        );
        expect(result!.max, closeTo(99.0, 1e-10));
      });

      test('sum equals 2500.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points,
          seriesId: 'test-series',
          regionStartX: 0.0,
          regionEndX: 49.0,
        );
        expect(result!.sum, closeTo(2500.0, 1e-10));
      });

      test('average equals 50.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points,
          seriesId: 'test-series',
          regionStartX: 0.0,
          regionEndX: 49.0,
        );
        expect(result!.average, closeTo(50.0, 1e-10));
      });

      test('range equals 98.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points,
          seriesId: 'test-series',
          regionStartX: 0.0,
          regionEndX: 49.0,
        );
        expect(result!.range, closeTo(98.0, 1e-10));
      });

      test('firstY equals 1.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points,
          seriesId: 'test-series',
          regionStartX: 0.0,
          regionEndX: 49.0,
        );
        expect(result!.firstY, isNotNull);
        expect(result.firstY!, closeTo(1.0, 1e-10));
      });

      test('lastY equals 99.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points,
          seriesId: 'test-series',
          regionStartX: 0.0,
          regionEndX: 49.0,
        );
        expect(result!.lastY, isNotNull);
        expect(result.lastY!, closeTo(99.0, 1e-10));
      });

      test('delta equals 98.0 with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points,
          seriesId: 'test-series',
          regionStartX: 0.0,
          regionEndX: 49.0,
        );
        expect(result!.delta, isNotNull);
        expect(result.delta!, closeTo(98.0, 1e-10));
      });

      test(
        'duration equals regionEndX - regionStartX (49.0) per data-model spec',
        () {
          // duration = endX - startX from the parent region's bounds
          final result = analyzer.computeSeriesSummary(
            points,
            seriesId: 'test-series',
            regionStartX: 0.0,
            regionEndX: 49.0,
          );
          expect(result!.duration, closeTo(49.0, 1e-10));
        },
      );

      test('stdDev equals sqrt(833) ≈ 28.8617 (population formula) '
          'with closeTo precision', () {
        final result = analyzer.computeSeriesSummary(
          points,
          seriesId: 'test-series',
          regionStartX: 0.0,
          regionEndX: 49.0,
        );
        expect(result!.stdDev, isNotNull);
        // Population standard deviation: sqrt(Σ(yi - mean)² / N)
        // For y = 2*x + 1, x=0..49: variance = 833, stdDev = sqrt(833)
        expect(result.stdDev!, closeTo(math.sqrt(833), 1e-10));
      });

      test('seriesId is passed through correctly', () {
        final result = analyzer.computeSeriesSummary(
          points,
          seriesId: 'my-series-id',
          regionStartX: 0.0,
          regionEndX: 49.0,
        );
        expect(result!.seriesId, equals('my-series-id'));
      });
    });

    // -------------------------------------------------------------------------
    // 1-point series — stdDev is null, delta is null
    // -------------------------------------------------------------------------
    group('1-point series', () {
      final singlePoint = [const ChartDataPoint(x: 5.0, y: 42.0)];

      // Region bounds intentionally different from data point x to verify
      // duration is computed from region bounds, not data points.
      // regionStartX=0.0, regionEndX=10.0 → duration=10.0 (not 0.0)

      test('returns non-null for 1-point input', () {
        final result = analyzer.computeSeriesSummary(
          singlePoint,
          seriesId: 'single',
          regionStartX: 0.0,
          regionEndX: 10.0,
        );
        expect(result, isNotNull);
      });

      test('count equals 1', () {
        final result = analyzer.computeSeriesSummary(
          singlePoint,
          seriesId: 'single',
          regionStartX: 0.0,
          regionEndX: 10.0,
        );
        expect(result!.count, equals(1));
      });

      test('min and max equal the single Y value', () {
        final result = analyzer.computeSeriesSummary(
          singlePoint,
          seriesId: 'single',
          regionStartX: 0.0,
          regionEndX: 10.0,
        );
        expect(result!.min, closeTo(42.0, 1e-10));
        expect(result.max, closeTo(42.0, 1e-10));
      });

      test('sum and average equal the single Y value', () {
        final result = analyzer.computeSeriesSummary(
          singlePoint,
          seriesId: 'single',
          regionStartX: 0.0,
          regionEndX: 10.0,
        );
        expect(result!.sum, closeTo(42.0, 1e-10));
        expect(result.average, closeTo(42.0, 1e-10));
      });

      test('range equals 0.0 (max - min with one point)', () {
        final result = analyzer.computeSeriesSummary(
          singlePoint,
          seriesId: 'single',
          regionStartX: 0.0,
          regionEndX: 10.0,
        );
        expect(result!.range, closeTo(0.0, 1e-10));
      });

      test('stdDev is null when count < 2', () {
        final result = analyzer.computeSeriesSummary(
          singlePoint,
          seriesId: 'single',
          regionStartX: 0.0,
          regionEndX: 10.0,
        );
        expect(result!.stdDev, isNull);
      });

      test('delta is null when count < 2', () {
        final result = analyzer.computeSeriesSummary(
          singlePoint,
          seriesId: 'single',
          regionStartX: 0.0,
          regionEndX: 10.0,
        );
        expect(result!.delta, isNull);
      });

      test('firstY equals the single Y value', () {
        final result = analyzer.computeSeriesSummary(
          singlePoint,
          seriesId: 'single',
          regionStartX: 0.0,
          regionEndX: 10.0,
        );
        expect(result!.firstY, closeTo(42.0, 1e-10));
      });

      test('lastY equals the single Y value', () {
        final result = analyzer.computeSeriesSummary(
          singlePoint,
          seriesId: 'single',
          regionStartX: 0.0,
          regionEndX: 10.0,
        );
        expect(result!.lastY, closeTo(42.0, 1e-10));
      });

      test('duration equals regionEndX - regionStartX (10.0), not 0.0', () {
        // Per data-model.md: duration = endX - startX from the parent
        // region's bounds, NOT from the data points.
        final result = analyzer.computeSeriesSummary(
          singlePoint,
          seriesId: 'single',
          regionStartX: 0.0,
          regionEndX: 10.0,
        );
        expect(result!.duration, closeTo(10.0, 1e-10));
      });
    });

    // -------------------------------------------------------------------------
    // 0-point (empty) series — returns null
    // -------------------------------------------------------------------------
    group('0-point (empty) series', () {
      test('returns null for empty points list', () {
        final result = analyzer.computeSeriesSummary(
          <ChartDataPoint>[],
          seriesId: 'empty',
          regionStartX: 0.0,
          regionEndX: 10.0,
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
            points,
            seriesId: 'precision',
            regionStartX: 0.0,
            regionEndX: 2.0,
          );

          expect(result, isNotNull);
          // 0.1 + 0.2 + 0.3 = 0.6 (but floating-point may not be exact)
          expect(result!.sum, closeTo(0.6, 1e-10));
          expect(result.average, closeTo(0.2, 1e-10));
          expect(result.min, closeTo(0.1, 1e-10));
          expect(result.max, closeTo(0.3, 1e-10));
        },
      );
    });
  });

  // ===========================================================================
  // computeRegionSummary() Tests
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
            seriesData: const {
              'power': [
                ChartDataPoint(x: 1.0, y: 100.0),
                ChartDataPoint(x: 3.0, y: 300.0),
                ChartDataPoint(x: 5.0, y: 200.0),
              ],
              'heartrate': [
                ChartDataPoint(x: 2.0, y: 70.0),
                ChartDataPoint(x: 4.0, y: 120.0),
                ChartDataPoint(x: 6.0, y: 90.0),
              ],
            },
          );

          // Act
          final result = analyzer.computeRegionSummary(region);

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
          seriesData: const {
            'temperature': [
              ChartDataPoint(x: 1.0, y: 20.0),
              ChartDataPoint(x: 2.0, y: 30.0),
              ChartDataPoint(x: 3.0, y: 25.0),
            ],
          },
        );

        // Act
        final result = analyzer.computeRegionSummary(region);

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
        // duration = region.endX - region.startX = 10.0 - 0.0 = 10.0
        expect(tempSummary.duration, closeTo(10.0, 1e-10));
      });

      test('region reference is preserved in result', () {
        // Arrange
        final region = DataRegion(
          id: 'region-ref-test',
          startX: 5.0,
          endX: 15.0,
          source: DataRegionSource.boxSelect,
          seriesData: const {
            'series-a': [ChartDataPoint(x: 7.0, y: 10.0)],
          },
        );

        // Act
        final result = analyzer.computeRegionSummary(region);

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
          seriesData: const {
            'has-data': [
              ChartDataPoint(x: 1.0, y: 10.0),
              ChartDataPoint(x: 2.0, y: 20.0),
            ],
            'empty': <ChartDataPoint>[],
          },
        );

        // Act
        final result = analyzer.computeRegionSummary(region);

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
            seriesData: const {
              'empty-a': <ChartDataPoint>[],
              'empty-b': <ChartDataPoint>[],
            },
          );

          // Act
          final result = analyzer.computeRegionSummary(region);

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
          seriesData: const {
            'power': [
              ChartDataPoint(x: 1.0, y: 100.0),
              ChartDataPoint(x: 2.0, y: 200.0),
            ],
            'heartrate': [
              ChartDataPoint(x: 1.0, y: 70.0),
              ChartDataPoint(x: 2.0, y: 90.0),
            ],
          },
        );

        // Act
        final result = analyzer.computeRegionSummary(
          region,
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
          seriesData: const {
            'power': [
              ChartDataPoint(x: 1.0, y: 100.0),
              ChartDataPoint(x: 2.0, y: 200.0),
            ],
            'temperature': [
              ChartDataPoint(x: 1.0, y: 20.0),
              ChartDataPoint(x: 2.0, y: 25.0),
            ],
          },
        );

        // Act
        final result = analyzer.computeRegionSummary(
          region,
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
          seriesData: const {
            'speed': [
              ChartDataPoint(x: 1.0, y: 30.0),
              ChartDataPoint(x: 2.0, y: 35.0),
            ],
          },
        );

        // Act
        final result = analyzer.computeRegionSummary(
          region,
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
            seriesData: const {
              'mapped': [ChartDataPoint(x: 1.0, y: 10.0)],
              'unmapped': [ChartDataPoint(x: 1.0, y: 20.0)],
            },
          );

          // Act
          final result = analyzer.computeRegionSummary(
            region,
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
