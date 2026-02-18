// Copyright 2025 Braven Charts
// SPDX-License-Identifier: MIT

import 'dart:math' as math;
import 'dart:ui';

import 'package:braven_charts/src/analysis/region_analyzer.dart';
import 'package:braven_charts/src/models/chart_annotation.dart';
import 'package:braven_charts/src/models/chart_data_point.dart';
import 'package:braven_charts/src/models/data_region.dart';
import 'package:braven_charts/src/models/segment_style.dart';
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

  // ===========================================================================
  // detectSegmentGroups() Tests
  // ===========================================================================
  group('RegionAnalyzer.detectSegmentGroups', () {
    // -------------------------------------------------------------------------
    // Contiguous same-style groups
    // -------------------------------------------------------------------------
    group('contiguous same-style groups', () {
      test('detects a single contiguous group of same-style points', () {
        // Arrange — points 0-4 all styled blue
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        final points = List.generate(
          5,
          (i) => ChartDataPoint(
            x: i.toDouble(),
            y: i * 10.0,
            segmentStyle: blueStyle,
          ),
        );

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert
        expect(groups, hasLength(1));
        expect(groups.first.source, equals(DataRegionSource.segment));
        expect(groups.first.startX, equals(0.0));
        expect(groups.first.endX, equals(4.0));
      });

      test('detects two contiguous groups with different styles', () {
        // Arrange — points 0-4 styled blue, points 5-9 styled red
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        const redStyle = SegmentStyle(color: Color(0xFFFF0000));

        final points = <ChartDataPoint>[
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: (i + 5).toDouble(),
              y: (i + 5) * 10.0,
              segmentStyle: redStyle,
            ),
          ),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert
        expect(groups, hasLength(2));
        expect(groups[0].startX, equals(0.0));
        expect(groups[0].endX, equals(4.0));
        expect(groups[1].startX, equals(5.0));
        expect(groups[1].endX, equals(9.0));
      });

      test('groups three contiguous segments with alternating styles', () {
        // Arrange — blue 0-2, red 3-5, green 6-8
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        const redStyle = SegmentStyle(color: Color(0xFFFF0000));
        const greenStyle = SegmentStyle(color: Color(0xFF00FF00));

        final points = <ChartDataPoint>[
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: (i + 3).toDouble(),
              y: (i + 3) * 10.0,
              segmentStyle: redStyle,
            ),
          ),
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: (i + 6).toDouble(),
              y: (i + 6) * 10.0,
              segmentStyle: greenStyle,
            ),
          ),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert
        expect(groups, hasLength(3));
        expect(groups[0].startX, equals(0.0));
        expect(groups[0].endX, equals(2.0));
        expect(groups[1].startX, equals(3.0));
        expect(groups[1].endX, equals(5.0));
        expect(groups[2].startX, equals(6.0));
        expect(groups[2].endX, equals(8.0));
      });
    });

    // -------------------------------------------------------------------------
    // FR-017: Non-adjacent same-style treated as separate
    // -------------------------------------------------------------------------
    group('non-adjacent same-style groups (FR-017 contiguity)', () {
      test('non-adjacent same-style groups are separate DataRegions', () {
        // Arrange — blue 0-4, red 5-9, blue 10-14
        // Even though groups 1 and 3 share the same style,
        // they MUST be separate because they are non-adjacent.
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        const redStyle = SegmentStyle(color: Color(0xFFFF0000));

        final points = <ChartDataPoint>[
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: (i + 5).toDouble(),
              y: (i + 5) * 10.0,
              segmentStyle: redStyle,
            ),
          ),
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: (i + 10).toDouble(),
              y: (i + 10) * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert — three separate groups, NOT two merged blue groups
        expect(groups, hasLength(3));
        expect(groups[0].startX, equals(0.0));
        expect(groups[0].endX, equals(4.0));
        expect(groups[1].startX, equals(5.0));
        expect(groups[1].endX, equals(9.0));
        expect(groups[2].startX, equals(10.0));
        expect(groups[2].endX, equals(14.0));
      });

      test(
        'non-adjacent same-style with unstyled gap produces separate groups',
        () {
          // Arrange — blue 0-2, unstyled 3-4, blue 5-7
          const blueStyle = SegmentStyle(color: Color(0xFF0000FF));

          final points = <ChartDataPoint>[
            ...List.generate(
              3,
              (i) => ChartDataPoint(
                x: i.toDouble(),
                y: i * 10.0,
                segmentStyle: blueStyle,
              ),
            ),
            // Unstyled gap
            const ChartDataPoint(x: 3.0, y: 30.0),
            const ChartDataPoint(x: 4.0, y: 40.0),
            ...List.generate(
              3,
              (i) => ChartDataPoint(
                x: (i + 5).toDouble(),
                y: (i + 5) * 10.0,
                segmentStyle: blueStyle,
              ),
            ),
          ];

          // Act
          final groups = analyzer.detectSegmentGroups('series-a', points);

          // Assert — two separate blue groups, unstyled gap excluded
          expect(groups, hasLength(2));
          expect(groups[0].startX, equals(0.0));
          expect(groups[0].endX, equals(2.0));
          expect(groups[1].startX, equals(5.0));
          expect(groups[1].endX, equals(7.0));
        },
      );
    });

    // -------------------------------------------------------------------------
    // Unstyled points excluded
    // -------------------------------------------------------------------------
    group('unstyled points excluded', () {
      test('returns empty list when all points are unstyled', () {
        // Arrange — no segment styles
        final points = List.generate(
          10,
          (i) => ChartDataPoint(x: i.toDouble(), y: i * 10.0),
        );

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert
        expect(groups, isEmpty);
      });

      test('unstyled points between styled groups are excluded', () {
        // Arrange — styled 0-2, unstyled 3-6, styled 7-9
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));

        final points = <ChartDataPoint>[
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          // Unstyled gap
          ...List.generate(
            4,
            (i) => ChartDataPoint(x: (i + 3).toDouble(), y: (i + 3) * 10.0),
          ),
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: (i + 7).toDouble(),
              y: (i + 7) * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert — two groups, unstyled points excluded
        expect(groups, hasLength(2));
        expect(groups[0].startX, equals(0.0));
        expect(groups[0].endX, equals(2.0));
        expect(groups[1].startX, equals(7.0));
        expect(groups[1].endX, equals(9.0));
      });
    });

    // -------------------------------------------------------------------------
    // Single-point segments
    // -------------------------------------------------------------------------
    group('single-point segments', () {
      test('single styled point creates a valid group with startX == endX', () {
        // Arrange — only one styled point among unstyled
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        final points = <ChartDataPoint>[
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.0, y: 20.0, segmentStyle: blueStyle),
          const ChartDataPoint(x: 3.0, y: 30.0),
          const ChartDataPoint(x: 4.0, y: 40.0),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert — single-point segment is valid
        expect(groups, hasLength(1));
        expect(groups.first.startX, equals(2.0));
        expect(groups.first.endX, equals(2.0));
        expect(groups.first.source, equals(DataRegionSource.segment));
      });

      test('multiple isolated styled points each create their own group', () {
        // Arrange — styled at index 1, 3, 5 with unstyled in between
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        final points = <ChartDataPoint>[
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 10.0, segmentStyle: blueStyle),
          const ChartDataPoint(x: 2.0, y: 20.0),
          const ChartDataPoint(x: 3.0, y: 30.0, segmentStyle: blueStyle),
          const ChartDataPoint(x: 4.0, y: 40.0),
          const ChartDataPoint(x: 5.0, y: 50.0, segmentStyle: blueStyle),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert — three separate single-point groups
        expect(groups, hasLength(3));
        expect(groups[0].startX, equals(1.0));
        expect(groups[0].endX, equals(1.0));
        expect(groups[1].startX, equals(3.0));
        expect(groups[1].endX, equals(3.0));
        expect(groups[2].startX, equals(5.0));
        expect(groups[2].endX, equals(5.0));
      });
    });

    // -------------------------------------------------------------------------
    // All-same-style series
    // -------------------------------------------------------------------------
    group('all-same-style series', () {
      test('all points with same style form a single group', () {
        // Arrange
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        final points = List.generate(
          20,
          (i) => ChartDataPoint(
            x: i.toDouble(),
            y: i * 5.0,
            segmentStyle: blueStyle,
          ),
        );

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert
        expect(groups, hasLength(1));
        expect(groups.first.startX, equals(0.0));
        expect(groups.first.endX, equals(19.0));
        expect(groups.first.source, equals(DataRegionSource.segment));
      });
    });

    // -------------------------------------------------------------------------
    // ID format and source type
    // -------------------------------------------------------------------------
    group('segment ID format and source type', () {
      test(
        'segment group ID follows format segment_<seriesId>_<startIndex>',
        () {
          // Arrange
          const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
          const redStyle = SegmentStyle(color: Color(0xFFFF0000));

          final points = <ChartDataPoint>[
            ...List.generate(
              3,
              (i) => ChartDataPoint(
                x: i.toDouble(),
                y: i * 10.0,
                segmentStyle: blueStyle,
              ),
            ),
            ...List.generate(
              3,
              (i) => ChartDataPoint(
                x: (i + 3).toDouble(),
                y: (i + 3) * 10.0,
                segmentStyle: redStyle,
              ),
            ),
          ];

          // Act
          final groups = analyzer.detectSegmentGroups('my-series', points);

          // Assert — verify ID format
          expect(groups, hasLength(2));
          expect(groups[0].id, equals('segment_my-series_0'));
          expect(groups[1].id, equals('segment_my-series_3'));
        },
      );

      test('all segment groups have source DataRegionSource.segment', () {
        // Arrange
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        const redStyle = SegmentStyle(color: Color(0xFFFF0000));

        final points = <ChartDataPoint>[
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: (i + 3).toDouble(),
              y: (i + 3) * 10.0,
              segmentStyle: redStyle,
            ),
          ),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert
        for (final group in groups) {
          expect(group.source, equals(DataRegionSource.segment));
        }
      });
    });

    // -------------------------------------------------------------------------
    // startX/endX from group's first/last point X values
    // -------------------------------------------------------------------------
    group('startX/endX from group first/last point X values', () {
      test('startX and endX match the X values of grouped points', () {
        // Arrange — styled from x=2.5 to x=7.5
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        final points = <ChartDataPoint>[
          const ChartDataPoint(x: 0.0, y: 0.0),
          const ChartDataPoint(x: 1.0, y: 10.0),
          const ChartDataPoint(x: 2.5, y: 25.0, segmentStyle: blueStyle),
          const ChartDataPoint(x: 5.0, y: 50.0, segmentStyle: blueStyle),
          const ChartDataPoint(x: 7.5, y: 75.0, segmentStyle: blueStyle),
          const ChartDataPoint(x: 9.0, y: 90.0),
        ];

        // Act
        final groups = analyzer.detectSegmentGroups('series-a', points);

        // Assert
        expect(groups, hasLength(1));
        expect(groups.first.startX, equals(2.5));
        expect(groups.first.endX, equals(7.5));
      });
    });

    // -------------------------------------------------------------------------
    // Empty input
    // -------------------------------------------------------------------------
    group('empty input', () {
      test('returns empty list for empty points', () {
        final groups = analyzer.detectSegmentGroups(
          'series-a',
          <ChartDataPoint>[],
        );
        expect(groups, isEmpty);
      });
    });

    // -------------------------------------------------------------------------
    // seriesData content verification
    // -------------------------------------------------------------------------
    group('seriesData content', () {
      test('seriesData contains actual points from contiguous group', () {
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        const redStyle = SegmentStyle(color: Color(0xFFFF0000));

        final points = <ChartDataPoint>[
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            3,
            (i) => ChartDataPoint(
              x: (i + 3).toDouble(),
              y: (i + 3) * 10.0,
              segmentStyle: redStyle,
            ),
          ),
        ];

        final groups = analyzer.detectSegmentGroups('series-a', points);

        // First group should contain the blue points
        expect(groups[0].seriesData.containsKey('series-a'), isTrue);
        expect(groups[0].seriesData['series-a'], hasLength(3));
        expect(
          groups[0].seriesData['series-a']!.map((p) => p.x).toList(),
          equals([0.0, 1.0, 2.0]),
        );

        // Second group should contain the red points
        expect(groups[1].seriesData.containsKey('series-a'), isTrue);
        expect(groups[1].seriesData['series-a'], hasLength(3));
        expect(
          groups[1].seriesData['series-a']!.map((p) => p.x).toList(),
          equals([3.0, 4.0, 5.0]),
        );
      });
    });
  });

  // ===========================================================================
  // segmentGroupForPoint() Tests
  // ===========================================================================
  group('RegionAnalyzer.segmentGroupForPoint', () {
    // -------------------------------------------------------------------------
    // Point inside a group returns correct DataRegion
    // -------------------------------------------------------------------------
    group('point inside a group', () {
      test(
        'returns correct DataRegion for a point in the middle of a group',
        () {
          // Arrange — points 0-9 styled blue, 10-19 styled red
          const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
          const redStyle = SegmentStyle(color: Color(0xFFFF0000));

          final points = <ChartDataPoint>[
            ...List.generate(
              10,
              (i) => ChartDataPoint(
                x: i.toDouble(),
                y: i * 10.0,
                segmentStyle: blueStyle,
              ),
            ),
            ...List.generate(
              10,
              (i) => ChartDataPoint(
                x: (i + 10).toDouble(),
                y: (i + 10) * 10.0,
                segmentStyle: redStyle,
              ),
            ),
          ];

          // Act — query point 5 which is in the blue group (0-9)
          final result = analyzer.segmentGroupForPoint('series-a', points, 5);

          // Assert
          expect(result, isNotNull);
          expect(result!.source, equals(DataRegionSource.segment));
          expect(result.startX, equals(0.0));
          expect(result.endX, equals(9.0));
        },
      );

      test('returns correct DataRegion for a point in the second group', () {
        // Arrange — points 0-4 styled blue, 5-9 styled red
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        const redStyle = SegmentStyle(color: Color(0xFFFF0000));

        final points = <ChartDataPoint>[
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: (i + 5).toDouble(),
              y: (i + 5) * 10.0,
              segmentStyle: redStyle,
            ),
          ),
        ];

        // Act — query point 7 which is in the red group (5-9)
        final result = analyzer.segmentGroupForPoint('series-a', points, 7);

        // Assert
        expect(result, isNotNull);
        expect(result!.startX, equals(5.0));
        expect(result.endX, equals(9.0));
      });
    });

    // -------------------------------------------------------------------------
    // Point outside any group returns null
    // -------------------------------------------------------------------------
    group('point outside any group', () {
      test('returns null for an unstyled point', () {
        // Arrange — styled 0-4, unstyled 5-9
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));

        final points = <ChartDataPoint>[
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            5,
            (i) => ChartDataPoint(x: (i + 5).toDouble(), y: (i + 5) * 10.0),
          ),
        ];

        // Act — query point 7 which is unstyled
        final result = analyzer.segmentGroupForPoint('series-a', points, 7);

        // Assert
        expect(result, isNull);
      });

      test('returns null when all points are unstyled', () {
        // Arrange
        final points = List.generate(
          10,
          (i) => ChartDataPoint(x: i.toDouble(), y: i * 10.0),
        );

        // Act
        final result = analyzer.segmentGroupForPoint('series-a', points, 5);

        // Assert
        expect(result, isNull);
      });
    });

    // -------------------------------------------------------------------------
    // Boundary points (first/last in group) included
    // -------------------------------------------------------------------------
    group('boundary points (first/last in group)', () {
      test('returns correct DataRegion for the first point in a group', () {
        // Arrange — blue 0-4
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        final points = List.generate(
          5,
          (i) => ChartDataPoint(
            x: i.toDouble(),
            y: i * 10.0,
            segmentStyle: blueStyle,
          ),
        );

        // Act — query the first point (index 0)
        final result = analyzer.segmentGroupForPoint('series-a', points, 0);

        // Assert
        expect(result, isNotNull);
        expect(result!.startX, equals(0.0));
        expect(result.endX, equals(4.0));
      });

      test('returns correct DataRegion for the last point in a group', () {
        // Arrange — blue 0-4
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        final points = List.generate(
          5,
          (i) => ChartDataPoint(
            x: i.toDouble(),
            y: i * 10.0,
            segmentStyle: blueStyle,
          ),
        );

        // Act — query the last point (index 4)
        final result = analyzer.segmentGroupForPoint('series-a', points, 4);

        // Assert
        expect(result, isNotNull);
        expect(result!.startX, equals(0.0));
        expect(result.endX, equals(4.0));
      });

      test('first point of second group returns second group, not first', () {
        // Arrange — blue 0-4, red 5-9
        const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
        const redStyle = SegmentStyle(color: Color(0xFFFF0000));

        final points = <ChartDataPoint>[
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: i.toDouble(),
              y: i * 10.0,
              segmentStyle: blueStyle,
            ),
          ),
          ...List.generate(
            5,
            (i) => ChartDataPoint(
              x: (i + 5).toDouble(),
              y: (i + 5) * 10.0,
              segmentStyle: redStyle,
            ),
          ),
        ];

        // Act — query point 5 which is the first point of the red group
        final result = analyzer.segmentGroupForPoint('series-a', points, 5);

        // Assert
        expect(result, isNotNull);
        expect(result!.startX, equals(5.0));
        expect(result.endX, equals(9.0));
      });
    });

    // -------------------------------------------------------------------------
    // Contiguity verification
    // -------------------------------------------------------------------------
    group('contiguity verification', () {
      test(
        'non-adjacent same-style: tap point 12 returns only group 10-14',
        () {
          // Arrange — blue 0-4, red 5-9, blue 10-14
          const blueStyle = SegmentStyle(color: Color(0xFF0000FF));
          const redStyle = SegmentStyle(color: Color(0xFFFF0000));

          final points = <ChartDataPoint>[
            ...List.generate(
              5,
              (i) => ChartDataPoint(
                x: i.toDouble(),
                y: i * 10.0,
                segmentStyle: blueStyle,
              ),
            ),
            ...List.generate(
              5,
              (i) => ChartDataPoint(
                x: (i + 5).toDouble(),
                y: (i + 5) * 10.0,
                segmentStyle: redStyle,
              ),
            ),
            ...List.generate(
              5,
              (i) => ChartDataPoint(
                x: (i + 10).toDouble(),
                y: (i + 10) * 10.0,
                segmentStyle: blueStyle,
              ),
            ),
          ];

          // Act — query point 12 which is in the second blue group
          final result = analyzer.segmentGroupForPoint('series-a', points, 12);

          // Assert — must return the 10-14 group, NOT the 0-4 group
          expect(result, isNotNull);
          expect(result!.startX, equals(10.0));
          expect(result.endX, equals(14.0));
          expect(result.source, equals(DataRegionSource.segment));
        },
      );
    });
  });

  // ===========================================================================
  // Edge-Case Tests — Required by spec (T054–T057)
  // ===========================================================================

  // ---------------------------------------------------------------------------
  // Edge-case 1: Region X-range extends beyond data boundaries
  //
  // Spec requirement: A region whose X-range extends before the first data
  // point or past the last data point must return ONLY the actual data points
  // that exist within the range — no synthetic/extrapolated points added.
  // ---------------------------------------------------------------------------
  group('Edge-case: region beyond data boundaries', () {
    test(
      'startX before first data point returns only actual points in range',
      () {
        // Arrange — data starts at x=10; query starts at x=0 (before data)
        final points = [
          const ChartDataPoint(x: 10.0, y: 100.0),
          const ChartDataPoint(x: 20.0, y: 200.0),
          const ChartDataPoint(x: 30.0, y: 300.0),
        ];

        // Act — startX=0.0 is before the first data point (x=10)
        final result = analyzer.filterPointsInRange(
          points,
          startX: 0.0,
          endX: 25.0,
        );

        // Assert — only actual data points in range are returned
        expect(result, hasLength(2));
        expect(result[0].x, equals(10.0));
        expect(result[1].x, equals(20.0));
        // No synthetic point at x=0.0 was added
        expect(result.any((p) => p.x == 0.0), isFalse);
      },
    );

    test('endX after last data point returns only actual points in range', () {
      // Arrange — data ends at x=30; query ends at x=50 (after data)
      final points = [
        const ChartDataPoint(x: 10.0, y: 100.0),
        const ChartDataPoint(x: 20.0, y: 200.0),
        const ChartDataPoint(x: 30.0, y: 300.0),
      ];

      // Act — endX=50.0 is after the last data point (x=30)
      final result = analyzer.filterPointsInRange(
        points,
        startX: 15.0,
        endX: 50.0,
      );

      // Assert — only actual data points returned, no synthetic x=50 point
      expect(result, hasLength(2));
      expect(result[0].x, equals(20.0));
      expect(result[1].x, equals(30.0));
      // No synthetic point at x=50.0 was added
      expect(result.any((p) => p.x == 50.0), isFalse);
    });

    test('range spanning the entire data set returns all data points', () {
      // Arrange — data range is x=5 to x=15; query covers x=-100 to x=100
      final points = [
        const ChartDataPoint(x: 5.0, y: 50.0),
        const ChartDataPoint(x: 10.0, y: 100.0),
        const ChartDataPoint(x: 15.0, y: 150.0),
      ];

      // Act — query range is much wider than the data
      final result = analyzer.filterPointsInRange(
        points,
        startX: -100.0,
        endX: 100.0,
      );

      // Assert — all 3 actual points returned, count is exact
      expect(result, hasLength(3));
      expect(result.map((p) => p.x).toSet(), equals({5.0, 10.0, 15.0}));
    });
  });

  // ---------------------------------------------------------------------------
  // Edge-case 2: Unsorted data fallback produces correct results identical to
  // the sorted (binary-search) path.
  //
  // Spec requirement: When isSorted:false is passed, the linear-scan fallback
  // must produce the same result as the binary-search path for equivalent data.
  // ---------------------------------------------------------------------------
  group('Edge-case: unsorted data correctness (isSorted:false)', () {
    test('isSorted:false with random-order points returns same values as '
        'isSorted:true with sorted equivalent', () {
      // Arrange — same data in two orders
      final sortedPoints = [
        const ChartDataPoint(x: 1.0, y: 10.0),
        const ChartDataPoint(x: 2.0, y: 20.0),
        const ChartDataPoint(x: 3.0, y: 30.0),
        const ChartDataPoint(x: 4.0, y: 40.0),
        const ChartDataPoint(x: 5.0, y: 50.0),
        const ChartDataPoint(x: 6.0, y: 60.0),
        const ChartDataPoint(x: 7.0, y: 70.0),
      ];

      final unsortedPoints = [
        const ChartDataPoint(x: 5.0, y: 50.0),
        const ChartDataPoint(x: 2.0, y: 20.0),
        const ChartDataPoint(x: 7.0, y: 70.0),
        const ChartDataPoint(x: 1.0, y: 10.0),
        const ChartDataPoint(x: 4.0, y: 40.0),
        const ChartDataPoint(x: 3.0, y: 30.0),
        const ChartDataPoint(x: 6.0, y: 60.0),
      ];

      // Act — sorted path (binary search) vs unsorted path (linear scan)
      final sortedResult = analyzer.filterPointsInRange(
        sortedPoints,
        startX: 2.0,
        endX: 6.0,
        isSorted: true,
      );
      final unsortedResult = analyzer.filterPointsInRange(
        unsortedPoints,
        startX: 2.0,
        endX: 6.0,
        isSorted: false,
      );

      // Assert — same points returned regardless of order
      expect(sortedResult, hasLength(5));
      expect(unsortedResult, hasLength(5));
      expect(
        sortedResult.map((p) => p.x).toSet(),
        equals(unsortedResult.map((p) => p.x).toSet()),
      );
      expect(
        sortedResult.map((p) => p.y).toSet(),
        equals(unsortedResult.map((p) => p.y).toSet()),
      );
    });

    test(
      'isSorted:false with strictly descending data produces correct results',
      () {
        // Arrange — descending order, binary search would give WRONG results
        final descendingPoints = [
          const ChartDataPoint(x: 100.0, y: 1000.0),
          const ChartDataPoint(x: 80.0, y: 800.0),
          const ChartDataPoint(x: 60.0, y: 600.0),
          const ChartDataPoint(x: 40.0, y: 400.0),
          const ChartDataPoint(x: 20.0, y: 200.0),
          const ChartDataPoint(x: 10.0, y: 100.0),
        ];

        // Act — must use isSorted:false for descending data
        final result = analyzer.filterPointsInRange(
          descendingPoints,
          startX: 30.0,
          endX: 70.0,
          isSorted: false,
        );

        // Assert — correct 2 points in [30, 70] range (x=40 and x=60)
        // Note: x=80.0 is OUTSIDE the range [30, 70] and must NOT be included.
        expect(result, hasLength(2));
        expect(result.map((p) => p.x).toSet(), equals({40.0, 60.0}));
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Edge-case 3: Duplicate X values at boundary are included (inclusive filter)
  //
  // Spec requirement: When startX or endX exactly matches the X value of
  // multiple data points (duplicates), ALL duplicates at that boundary must
  // be included in the result.
  // ---------------------------------------------------------------------------
  group('Edge-case: duplicate X values at boundary (inclusive)', () {
    test('multiple points sharing startX value are ALL included', () {
      // Arrange — three data points share x=5.0 (the startX boundary)
      final points = [
        const ChartDataPoint(x: 3.0, y: 30.0),
        const ChartDataPoint(x: 5.0, y: 50.0), // duplicate 1 at boundary
        const ChartDataPoint(x: 5.0, y: 55.0), // duplicate 2 at boundary
        const ChartDataPoint(x: 5.0, y: 58.0), // duplicate 3 at boundary
        const ChartDataPoint(x: 7.0, y: 70.0),
        const ChartDataPoint(x: 9.0, y: 90.0),
      ];

      // Act — startX = 5.0 exactly matches 3 duplicate points
      final result = analyzer.filterPointsInRange(
        points,
        startX: 5.0,
        endX: 8.0,
      );

      // Assert — all 3 duplicates at x=5.0 PLUS x=7.0 are included
      expect(result, hasLength(4));
      expect(result.where((p) => p.x == 5.0), hasLength(3));
      expect(result.any((p) => p.x == 7.0), isTrue);
    });

    test('multiple points sharing endX value are ALL included', () {
      // Arrange — three points share x=10.0 (the endX boundary)
      final points = [
        const ChartDataPoint(x: 5.0, y: 50.0),
        const ChartDataPoint(x: 7.0, y: 70.0),
        const ChartDataPoint(x: 10.0, y: 100.0), // duplicate 1 at boundary
        const ChartDataPoint(x: 10.0, y: 105.0), // duplicate 2 at boundary
        const ChartDataPoint(x: 10.0, y: 110.0), // duplicate 3 at boundary
        const ChartDataPoint(x: 12.0, y: 120.0),
      ];

      // Act — endX = 10.0 exactly matches 3 duplicate points
      final result = analyzer.filterPointsInRange(
        points,
        startX: 6.0,
        endX: 10.0,
      );

      // Assert — x=7.0 plus all 3 duplicates at x=10.0 are included
      expect(result, hasLength(4));
      expect(result.where((p) => p.x == 10.0), hasLength(3));
      expect(result.any((p) => p.x == 7.0), isTrue);
      // x=12.0 is EXCLUDED (beyond endX)
      expect(result.any((p) => p.x == 12.0), isFalse);
    });

    test('duplicates at both startX and endX are ALL included', () {
      // Arrange — duplicates at both boundaries
      final points = [
        const ChartDataPoint(x: 2.0, y: 20.0),
        const ChartDataPoint(x: 4.0, y: 40.0), // dup 1 at startX
        const ChartDataPoint(x: 4.0, y: 42.0), // dup 2 at startX
        const ChartDataPoint(x: 6.0, y: 60.0),
        const ChartDataPoint(x: 8.0, y: 80.0), // dup 1 at endX
        const ChartDataPoint(x: 8.0, y: 85.0), // dup 2 at endX
        const ChartDataPoint(x: 10.0, y: 100.0),
      ];

      // Act — both boundaries have duplicates
      final result = analyzer.filterPointsInRange(
        points,
        startX: 4.0,
        endX: 8.0,
      );

      // Assert — 2 (startX) + 1 (x=6) + 2 (endX) = 5 total
      expect(result, hasLength(5));
      expect(result.where((p) => p.x == 4.0), hasLength(2));
      expect(result.where((p) => p.x == 8.0), hasLength(2));
    });
  });

  // ---------------------------------------------------------------------------
  // Edge-case 4: Multi-axis filtering uses raw data coordinates (FR-008).
  //
  // Spec requirement (FR-008): Analysis must use ORIGINAL (non-normalised)
  // data values regardless of any multi-axis normalisation applied for
  // rendering. Each series must be filtered independently against the
  // region X-range using its raw data coordinates.
  //
  // We simulate this by applying filterPointsInRange to two series whose
  // data live on very different Y-scales (representing independent axes),
  // and verifying that filtering is based purely on X coordinates for each
  // series independently — unaffected by the other series' scale.
  // ---------------------------------------------------------------------------
  group('Edge-case: multi-axis filtering uses raw coordinates (FR-008)', () {
    test(
      'two series on different Y-scales are filtered independently by X',
      () {
        // Arrange — two series with dramatically different Y-ranges
        // (simulating power in Watts vs heart rate in bpm on separate axes)
        final powerSeriesPoints = [
          const ChartDataPoint(x: 0.0, y: 0.0), // 0 W
          const ChartDataPoint(x: 10.0, y: 150.0), // 150 W
          const ChartDataPoint(x: 20.0, y: 300.0), // 300 W — in range
          const ChartDataPoint(x: 30.0, y: 380.0), // 380 W — in range
          const ChartDataPoint(x: 40.0, y: 420.0), // 420 W — in range
          const ChartDataPoint(x: 50.0, y: 200.0), // 200 W
        ];

        final hrSeriesPoints = [
          const ChartDataPoint(x: 0.0, y: 60.0), // 60 bpm
          const ChartDataPoint(x: 15.0, y: 130.0), // 130 bpm — in range
          const ChartDataPoint(x: 25.0, y: 145.0), // 145 bpm — in range
          const ChartDataPoint(x: 35.0, y: 160.0), // 160 bpm — in range
          const ChartDataPoint(x: 45.0, y: 155.0), // 155 bpm — in range
          const ChartDataPoint(x: 60.0, y: 100.0), // 100 bpm
        ];

        // Act — filter both series against the same region X-range [15, 45]
        // Each series is filtered INDEPENDENTLY using its raw data X-values
        const regionStartX = 15.0;
        const regionEndX = 45.0;

        final powerFiltered = analyzer.filterPointsInRange(
          powerSeriesPoints,
          startX: regionStartX,
          endX: regionEndX,
        );

        final hrFiltered = analyzer.filterPointsInRange(
          hrSeriesPoints,
          startX: regionStartX,
          endX: regionEndX,
        );

        // Assert — power series: x=20,30,40 (3 points)
        expect(powerFiltered, hasLength(3));
        expect(
          powerFiltered.map((p) => p.x).toSet(),
          equals({20.0, 30.0, 40.0}),
        );
        // Raw Y values preserved — normalization does NOT alter the data
        expect(
          powerFiltered.map((p) => p.y).toSet(),
          equals({300.0, 380.0, 420.0}),
        );

        // Assert — hr series: x=15,25,35,45 (4 points)
        expect(hrFiltered, hasLength(4));
        expect(
          hrFiltered.map((p) => p.x).toSet(),
          equals({15.0, 25.0, 35.0, 45.0}),
        );
        // Raw Y values preserved — heart rate values are in bpm, not normalised
        expect(
          hrFiltered.map((p) => p.y).toSet(),
          equals({130.0, 145.0, 160.0, 155.0}),
        );
      },
    );

    test(
      'series with sparse data and different X densities are filtered correctly',
      () {
        // Arrange — two series with very different data densities
        // (one measured every second, one every 10 seconds)
        final denseSeriesPoints = List.generate(
          100,
          (i) => ChartDataPoint(x: i.toDouble(), y: i * 3.0),
        );

        final sparseSeriesPoints = List.generate(
          10,
          (i) => ChartDataPoint(x: (i * 10).toDouble(), y: i * 50.0),
        );

        // Act — same region for both
        final denseFiltered = analyzer.filterPointsInRange(
          denseSeriesPoints,
          startX: 20.0,
          endX: 50.0,
        );

        final sparseFiltered = analyzer.filterPointsInRange(
          sparseSeriesPoints,
          startX: 20.0,
          endX: 50.0,
        );

        // Assert — dense series: 31 points (x=20 to x=50 inclusive)
        expect(denseFiltered, hasLength(31));

        // Assert — sparse series: 4 points (x=20, 30, 40, 50)
        expect(sparseFiltered, hasLength(4));
        expect(
          sparseFiltered.map((p) => p.x).toSet(),
          equals({20.0, 30.0, 40.0, 50.0}),
        );
      },
    );
  });

  // ---------------------------------------------------------------------------
  // Edge-case 5: Streaming snapshot analysis — analysis of a region
  // mid-stream uses the data snapshot at query time.
  //
  // Spec requirement: When a chart is receiving streaming data, analyzing
  // a region should use the data that is CURRENTLY available (i.e., the
  // snapshot at the time of the query). Points that arrive AFTER the
  // analysis call should NOT appear in the result.
  //
  // We simulate this by:
  //   1. Creating an initial snapshot of data (simulating "data so far").
  //   2. Computing the region summary on that snapshot.
  //   3. Adding more data points to simulate "new data arriving".
  //   4. Verifying that the computed summary reflects ONLY the snapshot.
  // ---------------------------------------------------------------------------
  group('Edge-case: streaming snapshot analysis', () {
    test(
      'analysis on data snapshot produces correct summary from available data',
      () {
        // Arrange — simulate "data so far" in a streaming scenario
        // (first 30 seconds of a ride; more data will arrive later)
        final snapshotPoints = [
          const ChartDataPoint(x: 0.0, y: 200.0),
          const ChartDataPoint(x: 5.0, y: 220.0),
          const ChartDataPoint(x: 10.0, y: 240.0),
          const ChartDataPoint(x: 15.0, y: 260.0),
          const ChartDataPoint(x: 20.0, y: 280.0),
          const ChartDataPoint(x: 25.0, y: 300.0),
          const ChartDataPoint(x: 30.0, y: 320.0),
        ];

        // Act — compute summary at-time-of-query (using snapshot)
        final result = analyzer.computeSeriesSummary(
          snapshotPoints,
          seriesId: 'power',
          regionStartX: 0.0,
          regionEndX: 30.0,
        );

        // Assert — summary reflects ONLY the snapshot data (7 points)
        expect(result, isNotNull);
        expect(result!.count, equals(7));
        expect(result.min, closeTo(200.0, 1e-10));
        expect(result.max, closeTo(320.0, 1e-10));
        expect(result.firstY, closeTo(200.0, 1e-10));
        expect(result.lastY, closeTo(320.0, 1e-10));

        // "New data" arrives after the query — simulate streaming continuation
        // ignore: unused_local_variable
        final laterPoints = [
          const ChartDataPoint(x: 35.0, y: 350.0),
          const ChartDataPoint(x: 40.0, y: 380.0),
          const ChartDataPoint(x: 45.0, y: 400.0),
        ];

        // Assert — the result is based on snapshotPoints ONLY.
        // laterPoints are NOT in the result because they were not present
        // when computeSeriesSummary was called.
        expect(result.count, equals(7)); // still 7, not 10
        expect(result.max, closeTo(320.0, 1e-10)); // not 400.0
      },
    );

    test(
      'partial stream region analysis gives statistically correct results',
      () {
        // Arrange — 50 points available mid-stream (out of eventual 100)
        final availablePoints = List.generate(
          50,
          (i) => ChartDataPoint(x: i.toDouble() * 2.0, y: 100.0 + i * 4.0),
        );
        // x ranges from 0.0 to 98.0, y ranges from 100.0 to 296.0

        // Act — region analysis on currently available data only
        final result = analyzer.computeSeriesSummary(
          availablePoints,
          seriesId: 'heartrate',
          regionStartX: 0.0,
          regionEndX: 98.0,
        );

        // Assert — correct statistics for the 50 available points
        expect(result, isNotNull);
        expect(result!.count, equals(50));
        expect(result.min, closeTo(100.0, 1e-10)); // y at x=0
        expect(
          result.max,
          closeTo(296.0, 1e-10),
        ); // y at x=98 (i=49: 100+49*4=296)
        expect(result.firstY, closeTo(100.0, 1e-10));
        expect(result.lastY, closeTo(296.0, 1e-10));
        expect(result.duration, closeTo(98.0, 1e-10));
      },
    );

    test('regionFromAnnotation uses data snapshot — only currently-known '
        'series data is included', () {
      // Arrange — simulate streaming with partial data for two series.
      // Series 'speed' has data for the whole range; 'altitude' only has
      // data for the second half (not yet streamed for the first half).
      final annotation = RangeAnnotation(
        id: 'effort-zone',
        startX: 0.0,
        endX: 60.0,
      );

      // Snapshot of data available NOW (mid-stream)
      final currentSeriesData = <String, List<ChartDataPoint>>{
        'speed': [
          // speed data available for full range
          const ChartDataPoint(x: 10.0, y: 28.0),
          const ChartDataPoint(x: 20.0, y: 32.0),
          const ChartDataPoint(x: 30.0, y: 35.0),
          const ChartDataPoint(x: 40.0, y: 30.0),
          const ChartDataPoint(x: 50.0, y: 27.0),
        ],
        'altitude': [
          // altitude data only available for later part of range
          const ChartDataPoint(x: 40.0, y: 450.0),
          const ChartDataPoint(x: 50.0, y: 480.0),
          const ChartDataPoint(x: 60.0, y: 510.0),
        ],
      };

      // Act — build region from annotation using current snapshot
      final region = analyzer.regionFromAnnotation(
        annotation,
        currentSeriesData,
      );

      // Assert — region reflects ONLY data in the current snapshot
      expect(region.seriesData['speed'], hasLength(5));
      expect(region.seriesData['altitude'], hasLength(3));

      // The region summary reflects snapshot statistics
      final summary = analyzer.computeRegionSummary(region);
      expect(summary.seriesSummaries['speed']!.count, equals(5));
      expect(summary.seriesSummaries['altitude']!.count, equals(3));
    });
  });
}
